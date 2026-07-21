import unittest
from pathlib import Path

import dexsim

import reference_fp16 as ref


ROOT = Path(__file__).resolve().parents[2]


def flatten(value):
    if not isinstance(value, (list, tuple)):
        return [value]
    result = []
    for child in value:
        result.extend(flatten(child))
    return result


def load_hex(name):
    path = ROOT / "rtl" / "chisel" / "top_connect" / "src" / "lut" / "tools" / name
    return [int(line, 16) for line in path.read_text().splitlines() if line]


class FixedProgramTest(unittest.TestCase):
    def build_program(self):
        program = dexsim.Program("gemv_add_scale")
        x = program.input("x", (3,))
        matrix = program.constant("matrix", [[1.0, 2.0, 3.0], [0.5, -1.0, 2.0]])
        bias = program.constant("bias", [0.25, -0.5])
        y = program.gemv(matrix, x)
        z = program.add(y, bias)
        out = program.scale(z, 0.5)
        reduced = program.add_reduce(out)
        program.output(out, reduced)
        return program

    def test_program_compiles_deterministically_and_runs_repeatedly(self):
        program = self.build_program()
        with program.compile() as first, program.compile() as second:
            self.assertEqual(first.address_plan, second.address_plan)
            self.assertEqual(first.command_count, 4)
            result = first.run(x=[1.0, -2.0, 0.5])
            repeated = first.run(x=[1.0, -2.0, 0.5])
            matrix_bits = [ref.bits(value) for value in (1.0, 2.0, 3.0, 0.5, -1.0, 2.0)]
            x_bits = [ref.bits(value) for value in (1.0, -2.0, 0.5)]
            bias_bits = [ref.bits(0.25), ref.bits(-0.5)]
            y_bits = ref.gemm(matrix_bits, x_bits, 2, 1, 3)
            z_bits = ref.add_matrix(y_bits, bias_bits)
            expected = ref.scale_matrix(z_bits, ref.bits(0.5))
            output_name = program.to_dict()["outputs"][0]
            scalar_name = program.to_dict()["outputs"][1]
            self.assertEqual(flatten(result.output_bits[output_name]), expected)
            self.assertEqual(flatten(repeated.output_bits[output_name]), expected)
            self.assertEqual(result.scalars[scalar_name]["value_bits"], ref.add_reduce(expected))
            self.assertEqual(result.trace.transfers["constant_write_elements_per_compile"], 8)
            self.assertEqual(result.trace.transfers["input_write_elements"], 3)
            self.assertEqual(result.trace.transfers["output_read_elements"], 2)
            self.assertEqual(len(result.trace.commands), 4)
            self.assertTrue(result.trace.commands[-1]["group_end"])
            self.assertTrue(all(not entry["group_end"] for entry in result.trace.commands[:-1]))

    def test_program_assemble_zero_initialization_and_compare_reduce(self):
        program = dexsim.Program("assemble_reduce")
        source = program.input("source", (2, 2))
        assembled = program.assemble(source, offset_row=1, offset_col=2)
        reduced = program.compare_reduce(assembled)
        program.output(assembled, reduced)
        with program.compile() as compiled:
            result = compiled.run(source=[[10.0, 11.0], [12.0, 13.0]])
            output_name, scalar_name = program.to_dict()["outputs"]
            source_bits = [ref.bits(value) for value in (10, 11, 12, 13)]
            expected = ref.assemble(source_bits, [0] * 12, 2, 2, 1, 2)
            expected_min, expected_index = ref.compare_reduce(expected)
            self.assertEqual(flatten(result.output_bits[output_name]), expected)
            self.assertEqual(
                (result.scalars[scalar_name]["value_bits"], result.scalars[scalar_name]["index"]),
                (expected_min, expected_index),
            )
            self.assertEqual(len(result.trace.runs), 2)

    def test_program_batches_every_operator_kind(self):
        program = dexsim.Program("all_operator_kinds")
        a = program.constant("a", [[1.0, -2.0], [3.0, 4.0]])
        b = program.constant("b", [[0.5, 2.0], [-1.0, 1.5]])
        v = program.input("v", (2,))
        outputs = {
            "gemm": program.gemm(a, b),
            "gemv": program.gemv(a, v),
            "dot": program.dot(v, v),
            "outer": program.outer(v, v),
            "add": program.add(a, b),
            "scale": program.scale(a, -0.5),
            "abs": program.abs(a),
            "sin": program.sin(v),
            "cos": program.cos(v),
            "softplus": program.softplus(v),
            "softplus_beta": program.softplus_beta(v, 2.0),
            "transpose": program.transpose(a),
            "assemble": program.assemble(a, offset_row=1, offset_col=1),
            "add_reduce": program.add_reduce(v),
            "compare_reduce": program.compare_reduce(v),
        }
        program.output(*outputs.values())

        a_bits = [ref.bits(value) for value in (1.0, -2.0, 3.0, 4.0)]
        b_bits = [ref.bits(value) for value in (0.5, 2.0, -1.0, 1.5)]
        v_bits = [ref.bits(0.25), ref.bits(-0.5)]
        trig_words = load_hex("trig_data.hex")
        softplus_words = load_hex("softplus_data.hex")
        expected = {
            "gemm": ref.gemm(a_bits, b_bits, 2, 2, 2),
            "gemv": ref.gemm(a_bits, v_bits, 2, 1, 2),
            "dot": ref.gemm(v_bits, v_bits, 1, 1, 2),
            "outer": ref.gemm(v_bits, v_bits, 2, 2, 1),
            "add": ref.add_matrix(a_bits, b_bits),
            "scale": ref.scale_matrix(a_bits, ref.bits(-0.5)),
            "abs": [value & 0x7FFF for value in a_bits],
            "sin": [ref.trig_pair(value, trig_words)[0] for value in v_bits],
            "cos": [ref.trig_pair(value, trig_words)[1] for value in v_bits],
            "softplus": [ref.softplus(value, softplus_words) for value in v_bits],
            "transpose": ref.transpose(a_bits, 2, 2),
            "assemble": ref.assemble(a_bits, [0] * 9, 2, 2, 1, 1),
        }
        beta_scaled = ref.scale_matrix(v_bits, ref.bits(2.0))
        beta_lut = [ref.softplus(value, softplus_words) for value in beta_scaled]
        expected["softplus_beta"] = ref.scale_matrix(beta_lut, ref.bits(0.5))

        with program.compile() as compiled:
            result = compiled.run(v=[0.25, -0.5])
            for name, tensor in outputs.items():
                if name in ("add_reduce", "compare_reduce"):
                    continue
                self.assertEqual(
                    flatten(result.output_bits[tensor.name]),
                    expected[name],
                    name,
                )
            add_result = result.scalars[outputs["add_reduce"].name]
            compare_result = result.scalars[outputs["compare_reduce"].name]
            expected_min, expected_index = ref.compare_reduce(v_bits)
            self.assertEqual(add_result["value_bits"], ref.add_reduce(v_bits))
            self.assertEqual(
                (compare_result["value_bits"], compare_result["index"]),
                (expected_min, expected_index),
            )
            self.assertEqual(compiled.command_count, 17)

    def test_program_rejects_missing_outputs_inputs_and_unplaceable_shape(self):
        program = dexsim.Program("errors")
        value = program.input("value", (4,))
        with self.assertRaisesRegex(ValueError, "Program.output"):
            program.compile()
        program.output(value)
        with program.compile() as compiled:
            with self.assertRaisesRegex(ValueError, "inputs mismatch"):
                compiled.run()

        huge = dexsim.Program("huge")
        huge_value = huge.input("huge_value", (5000, 5000))
        huge.output(huge_value)
        with self.assertRaises(dexsim.UnsupportedShapeError):
            huge.compile()


if __name__ == "__main__":
    unittest.main()
