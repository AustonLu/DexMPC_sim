import unittest

import dexsim


def flatten(value):
    if not isinstance(value, (list, tuple)):
        return [value]
    result = []
    for child in value:
        result.extend(flatten(child))
    return result


def values(count, salt):
    return [(((index * 17 + salt * 7) % 29) - 14) / 32.0 for index in range(count)]


def matrix(rows, cols, salt):
    data = values(rows * cols, salt)
    return [data[row * cols:(row + 1) * cols] for row in range(rows)]


def build_chain(*, barrier=False):
    program = dexsim.Program("resident_chain")
    source = program.input("source", (32, 8))
    weight = program.constant("weight", matrix(8, 8, 2))
    bias = program.constant("bias", matrix(32, 8, 3))
    value = program.gemm(source, weight)
    value = program.scale(value, 0.75)
    value = program.add(value, bias)
    if barrier:
        value = program.abs(value)
    value = program.scale(value, -0.5)
    program.output(value)
    return program, value


class ResidentProgramTest(unittest.TestCase):
    def test_resident_chain_is_bit_exact_and_avoids_per_op_transfers(self):
        source = matrix(32, 8, 1)
        program, output = build_chain()
        with program.compile(
            execution_policy="quad", residency_policy="off"
        ) as baseline:
            expected = baseline.run(source=source)
        with program.compile(
            execution_policy="quad", residency_policy="on"
        ) as resident:
            actual = resident.run(source=source)

        self.assertEqual(
            flatten(actual.output_bits[output.name]),
            flatten(expected.output_bits[output.name]),
        )
        decision = actual.trace.residency["decision"]
        self.assertTrue(decision["enabled"])
        metrics = actual.trace.residency["metrics"]
        self.assertGreater(metrics["avoided_stage_regions"], 0)
        self.assertGreater(metrics["deferred_gather_regions"], 0)
        self.assertLess(
            actual.trace.kernel_metrics["internal_transfer_cycles"],
            expected.trace.kernel_metrics["internal_transfer_cycles"],
        )

    def test_core_count_and_residency_switches_are_explicit(self):
        source = matrix(32, 8, 4)
        program, _ = build_chain()
        cases = [
            ("single", "on", False, {0}),
            ("dual", "on", True, {0, 1}),
            ("quad", "on", True, {0, 1, 2, 3}),
            ("quad", "off", False, {0, 1, 2, 3}),
            ("auto", "on", False, {0}),
            ("auto", "auto", False, {0}),
        ]
        for execution_policy, residency_policy, enabled, expected_cores in cases:
            with self.subTest(
                execution_policy=execution_policy,
                residency_policy=residency_policy,
            ):
                with program.compile(
                    execution_policy=execution_policy,
                    residency_policy=residency_policy,
                ) as compiled:
                    result = compiled.run(source=source)
                self.assertEqual(result.trace.residency["decision"]["enabled"], enabled)
                observed = {entry["core"] for entry in result.trace.commands}
                self.assertEqual(observed, expected_cores)

    def test_fanout_reuses_input_and_constant_replicas_across_runs(self):
        program = dexsim.Program("fanout")
        x = program.input("x", (8,))
        a = program.constant("a", matrix(32, 8, 5))
        b = program.constant("b", matrix(32, 8, 6))
        left = program.gemv(a, x)
        right = program.gemv(b, x)
        output = program.add(left, right)
        program.output(output)

        with program.compile(
            execution_policy="quad", residency_policy="on"
        ) as compiled:
            first = compiled.run(x=values(8, 7))
            second = compiled.run(x=values(8, 8))

        self.assertGreater(
            first.trace.residency["metrics"]["avoided_stage_regions"], 0
        )
        first_constant_stages = [
            item for item in first.trace.residency["transfers"]
            if item["kind"] == "resident_stage" and item["tensor"] in ("a", "b")
        ]
        second_constant_stages = [
            item for item in second.trace.residency["transfers"]
            if item["kind"] == "resident_stage" and item["tensor"] in ("a", "b")
        ]
        self.assertGreater(len(first_constant_stages), 0)
        self.assertEqual(second_constant_stages, [])

    def test_shared_engine_barrier_materializes_and_resumes(self):
        source = matrix(32, 8, 9)
        program, output = build_chain(barrier=True)
        with program.compile(
            execution_policy="quad", residency_policy="off"
        ) as baseline:
            expected = baseline.run(source=source)
        with program.compile(
            execution_policy="quad", residency_policy="on"
        ) as resident:
            actual = resident.run(source=source)

        self.assertEqual(
            flatten(actual.output_bits[output.name]),
            flatten(expected.output_bits[output.name]),
        )
        materialize_events = [
            event for event in actual.trace.residency["events"]
            if event["kind"] == "materialize"
        ]
        self.assertTrue(materialize_events)
        self.assertTrue(any(
            event["reason"] == "barrier_or_fallback"
            for event in materialize_events
        ))

    def test_sram_pressure_falls_back_to_real_single_core_hardware(self):
        # 600x8 fits Temp but a simultaneously-live output cannot fit the
        # remaining private SRAM, so the resident allocator places it Global.
        source = matrix(600, 8, 10)
        program = dexsim.Program("resident_pressure_fallback")
        value = program.input("value", (600, 8))
        output = program.scale(value, 0.5)
        program.output(output)

        with program.compile(
            execution_policy="single", residency_policy="off"
        ) as baseline:
            expected = baseline.run(value=source)
        with program.compile(
            execution_policy="quad", residency_policy="on"
        ) as resident:
            actual = resident.run(value=source)

        self.assertEqual(
            flatten(actual.output_bits[output.name]),
            flatten(expected.output_bits[output.name]),
        )
        plans = [
            entry["parallel_plan"] for entry in actual.trace.commands
            if entry["parallel_plan"] is not None
        ]
        self.assertGreaterEqual(len(plans), 1)
        self.assertTrue(all(plan["core_count"] == 1 for plan in plans))
        self.assertTrue(all(
            plan["resident_fallback_reason"]
            == "resident_requires_private_local_or_temp"
            for plan in plans
        ))

    def test_requested_intermediate_output_is_materialized_bit_exactly(self):
        source = matrix(32, 8, 11)
        program = dexsim.Program("resident_debug_materialize")
        value = program.input("value", (32, 8))
        first = program.scale(value, 0.75)
        final = program.scale(first, -0.5)
        program.output(first, final)

        with program.compile(
            execution_policy="quad", residency_policy="off"
        ) as baseline:
            expected = baseline.run(value=source)
        with program.compile(
            execution_policy="quad", residency_policy="on"
        ) as resident:
            actual = resident.run(value=source)

        for output in (first, final):
            self.assertEqual(
                flatten(actual.output_bits[output.name]),
                flatten(expected.output_bits[output.name]),
            )
        materialized = {
            event["tensor"] for event in actual.trace.residency["events"]
            if event["kind"] == "materialize"
            and event["reason"] == "program_output"
        }
        self.assertEqual(materialized, {first.name, final.name})


if __name__ == "__main__":
    unittest.main()
