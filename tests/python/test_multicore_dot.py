import unittest

import dexsim
from dexsim.dot_parallel import plan_dot

import reference_fp16 as ref


def fixed_tree_reference(left, right, policy):
    plan = plan_dot(len(left), policy=policy)
    partials = []
    for partition in plan.partitions:
        start = partition.start
        end = start + partition.size
        partials.append(ref.gemm(
            left[start:end], right[start:end], 1, 1, partition.size
        )[0])
    result = partials[0] if len(partials) == 1 else ref.add_reduce(partials)
    return plan, partials, result


def values(count, salt):
    return [
        ref.bits((((index * 29 + salt * 11) % 61) - 30) / 32.0)
        for index in range(count)
    ]


class MulticoreDotTest(unittest.TestCase):
    def run_eager(self, left, right, policy):
        with dexsim.Device(dot_execution_policy=policy) as device:
            a = device.tensor_bits(left, shape=(len(left),))
            b = device.tensor_bits(right, shape=(len(right),))
            output = device.dot(a, b)
            result = output.bits()[0]
            trace = device.trace()[-1]["parallel"]
        return result, trace

    def test_explicit_1_2_4_core_fixed_tree_is_bit_exact(self):
        left = values(127, 1)
        right = values(127, 2)
        for policy, expected_cores in (
            ("single", 1),
            ("dual", 2),
            ("quad", 4),
        ):
            with self.subTest(policy=policy):
                plan, partials, expected = fixed_tree_reference(
                    left, right, policy
                )
                actual, trace = self.run_eager(left, right, policy)
                self.assertEqual(actual, expected)
                self.assertEqual(trace["plan"]["core_count"], expected_cores)
                self.assertEqual(trace["partial_bits"], partials if expected_cores > 1 else [])
                self.assertEqual(trace["plan"]["core_count"], plan.core_count)
                self.assertEqual(trace["host_ops"], [])
                if expected_cores > 1:
                    self.assertEqual(
                        trace["plan"]["merge"],
                        "core0_add_reduce_fixed_tree",
                    )

    def test_dot_switch_is_independent_from_linear_policy(self):
        left = values(64, 3)
        right = values(64, 4)
        with dexsim.Device(
            execution_policy="quad", dot_execution_policy="single"
        ) as device:
            a = device.tensor_bits(left, shape=(64,))
            b = device.tensor_bits(right, shape=(64,))
            scaled = device.scale(a, 0.5)
            result = device.dot(a, b)
            traces = device.trace()
            result_bits = result.bits()[0]
        self.assertEqual(traces[0]["parallel"]["plan"]["core_count"], 4)
        self.assertEqual(traces[1]["parallel"]["plan"]["core_count"], 1)
        self.assertEqual(result_bits, ref.gemm(left, right, 1, 1, 64)[0])

    def test_auto_remains_single_until_end_to_end_gate_passes(self):
        left = values(1024, 5)
        right = values(1024, 6)
        actual, trace = self.run_eager(left, right, "auto")
        self.assertEqual(trace["plan"]["core_count"], 1)
        self.assertEqual(
            trace["plan"]["reason"], "below_measured_parallel_threshold"
        )
        self.assertEqual(actual, ref.gemm(left, right, 1, 1, 1024)[0])

    def test_k_split_has_explicit_deterministic_numeric_semantics(self):
        left = [
            -0.0009074211120605469, 0.64990234375, -0.170654296875,
            -0.88720703125, 1.990234375, 1.982421875, 1.361328125,
            0.8310546875, -0.73876953125, -1.0810546875, -0.84375,
            -1.71875, 1.0654296875, -0.3984375, 1.38671875,
            -0.453857421875,
        ]
        right = [
            1.83203125, 1.3896484375, -1.998046875, -1.1611328125,
            1.640625, -0.12005615234375, 1.921875, -0.410400390625,
            -1.7080078125, 0.517578125, 1.1142578125, -0.9208984375,
            -1.6513671875, -0.66943359375, 1.8564453125, 1.0322265625,
        ]
        left_bits = [ref.bits(value) for value in left]
        right_bits = [ref.bits(value) for value in right]
        single = ref.gemm(left_bits, right_bits, 1, 1, 16)[0]
        _, _, fixed = fixed_tree_reference(left_bits, right_bits, "dual")
        self.assertNotEqual(single, fixed)
        actual, _ = self.run_eager(left_bits, right_bits, "dual")
        self.assertEqual(actual, fixed)

    def test_special_values_tail_and_ftz_match_fixed_reference(self):
        one = ref.bits(1.0)
        cases = {
            "odd_tail": (values(31, 7), values(31, 8)),
            "positive_inf": ([0x7C00] + [one] * 30, [one] * 31),
            "nan": ([0x7E00] + [one] * 30, [one] * 31),
            "mixed_inf": ([0x7C00, 0xFC00] + [one] * 29, [one] * 31),
            "signed_zero": ([0x8000] * 31, [one] * 31),
            "subnormal_ftz": ([0x0001] * 31, [one] * 31),
        }
        for name, (left, right) in cases.items():
            with self.subTest(name=name):
                _, _, expected = fixed_tree_reference(left, right, "quad")
                actual, trace = self.run_eager(left, right, "quad")
                self.assertEqual(actual, expected)
                self.assertEqual(trace["plan"]["core_count"], 4)

    def test_program_dot_policy_and_resident_shard_reuse(self):
        program = dexsim.Program("resident_dot")
        left = program.input("left", (64,))
        right = program.input("right", (64,))
        left_scaled = program.scale(left, 0.5)
        right_scaled = program.scale(right, -0.75)
        output = program.dot(left_scaled, right_scaled)
        program.output(output)

        left_values = [ref.value(value) for value in values(64, 9)]
        right_values = [ref.value(value) for value in values(64, 10)]
        with program.compile(
            execution_policy="quad",
            residency_policy="on",
            dot_execution_policy="quad",
        ) as compiled:
            result = compiled.run(left=left_values, right=right_values)
            config = compiled.execution_config

        dot_commands = [
            item for item in result.trace.commands if item["operation"] == "dot"
        ]
        self.assertEqual(config["dot_execution_policy"], "quad")
        self.assertEqual({item["core"] for item in dot_commands}, {0, 1, 2, 3})
        dot_events = [
            item for item in result.trace.residency["events"]
            if item["kind"] == "multicore_dot"
        ]
        self.assertEqual(len(dot_events), 1)
        self.assertGreater(dot_events[0]["resident_reuse_regions"], 0)


if __name__ == "__main__":
    unittest.main()
