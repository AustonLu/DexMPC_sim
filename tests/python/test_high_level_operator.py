import inspect
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


class HighLevelOperatorTest(unittest.TestCase):
    def test_gemm_hardware_canonicalizes_negative_zero_on_drain(self):
        with dexsim.Device() as device:
            left = device.tensor_bits([[0x0400, 0x8401]])
            right = device.tensor_bits([[0x3C00], [0x3C00]])
            self.assertEqual(flatten(device.gemm(left, right).bits()), [0x0000])

    def test_public_operator_signatures_hide_hardware_placement(self):
        forbidden = {
            "memory", "mem_id", "word_offset", "command_id", "opcode", "subop",
            "group_end", "core", "context", "src_memory", "out_memory",
        }
        for name in (
            "tensor", "constant", "abs", "scale", "add", "gemm", "gemv", "dot",
            "outer", "sin", "cos", "softplus", "transpose", "assemble",
            "add_reduce", "compare_reduce",
        ):
            parameters = set(inspect.signature(getattr(dexsim.Device, name)).parameters)
            self.assertFalse(parameters & forbidden, (name, parameters & forbidden))

    def test_allocator_reuses_released_range_and_rejects_stale_tensor(self):
        with dexsim.Device() as device:
            first = device.tensor([1.0] * 16)
            first_info = device.allocator_snapshot()["live"][first.name]
            first.release()
            second = device.tensor([2.0] * 16)
            second_info = device.allocator_snapshot()["live"][second.name]
            self.assertEqual(
                (first_info["memory"], first_info["word_offset"]),
                (second_info["memory"], second_info["word_offset"]),
            )
            with self.assertRaises(dexsim.ReleasedTensorError):
                first.tolist()

    def test_all_high_level_operators_match_bit_references(self):
        trig_words = load_hex("trig_data.hex")
        softplus_words = load_hex("softplus_data.hex")
        with dexsim.Device() as device:
            special = [0x0000, 0x8000, 0xBC00, 0x7E55, 0xFC00, 0x0001]
            source = device.tensor_bits(special)
            absolute = device.abs(source)
            self.assertEqual(flatten(absolute.bits()), [value & 0x7FFF for value in special])

            values = [1.0, -2.0, 0.25, 8.0, -0.0, 3.0]
            value_bits = [ref.bits(value) for value in values]
            tensor = device.tensor(values)
            scaled = device.scale(tensor, -0.5)
            self.assertEqual(flatten(scaled.bits()), ref.scale_matrix(value_bits, ref.bits(-0.5)))

            other_values = [2.0, 2.0, -0.25, 0.5, 0.0, -3.0]
            other_bits = [ref.bits(value) for value in other_values]
            other = device.tensor(other_values)
            added = device.add(tensor, other)
            self.assertEqual(flatten(added.bits()), ref.add_matrix(value_bits, other_bits))

            a_values = [[1.0, 2.0], [3.0, 4.0]]
            b_values = [[5.0, 6.0], [7.0, 8.0]]
            a = device.tensor(a_values)
            b = device.tensor(b_values)
            matrix = device.gemm(a, b)
            self.assertEqual(
                flatten(matrix.bits()),
                ref.gemm([ref.bits(x) for x in flatten(a_values)], [ref.bits(x) for x in flatten(b_values)], 2, 2, 2),
            )

            vector_values = [0.5, -1.0]
            vector = device.tensor(vector_values)
            gemv = device.gemv(a, vector)
            self.assertEqual(
                flatten(gemv.bits()),
                ref.gemm([ref.bits(x) for x in flatten(a_values)], [ref.bits(x) for x in vector_values], 2, 1, 2),
            )

            dot = device.dot(vector, device.tensor([2.0, 3.0]))
            self.assertEqual(
                flatten(dot.bits()),
                ref.gemm([ref.bits(x) for x in vector_values], [ref.bits(2.0), ref.bits(3.0)], 1, 1, 2),
            )

            outer_right_values = [0.5, 3.0, -2.0]
            outer_right = device.tensor(outer_right_values)
            outer = device.outer(vector, outer_right)
            self.assertEqual(
                flatten(outer.bits()),
                ref.gemm(
                    [ref.bits(x) for x in vector_values],
                    [ref.bits(x) for x in outer_right_values],
                    2, 3, 1,
                ),
            )

            transposed = device.transpose(device.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]))
            transpose_bits = [ref.bits(value) for value in (1, 2, 3, 4, 5, 6)]
            self.assertEqual(flatten(transposed.bits()), ref.transpose(transpose_bits, 2, 3))

            assemble_source_bits = [ref.bits(value) for value in (10, 11, 12, 13)]
            assembled = device.assemble(
                device.tensor_bits(assemble_source_bits, shape=(2, 2)),
                offset_row=1,
                offset_col=2,
            )
            self.assertEqual(
                flatten(assembled.bits()),
                ref.assemble(assemble_source_bits, [0] * 12, 2, 2, 1, 2),
            )

            trig_inputs = [ref.bits(value) for value in (0.0, -0.5, 1.0, 3.140625)]
            trig = device.tensor_bits(trig_inputs)
            sine = device.sin(trig)
            cosine = device.cos(trig)
            expected_pairs = [ref.trig_pair(value, trig_words) for value in trig_inputs]
            self.assertEqual(flatten(sine.bits()), [value[0] for value in expected_pairs])
            self.assertEqual(flatten(cosine.bits()), [value[1] for value in expected_pairs])

            soft_inputs = [ref.bits(value) for value in (-3.5, -1.0, -0.0, 0.0, 1.0, 3.5)]
            soft = device.softplus(device.tensor_bits(soft_inputs))
            self.assertEqual(
                flatten(soft.bits()),
                [ref.softplus(value, softplus_words) for value in soft_inputs],
            )

            beta_source_bits = [ref.bits(value) for value in (-0.5, 0.0, 0.5)]
            beta_source = device.tensor_bits(beta_source_bits)
            beta_soft = device.softplus_beta(beta_source, 2.0)
            beta_scaled = ref.scale_matrix(beta_source_bits, ref.bits(2.0))
            beta_lut = [ref.softplus(value, softplus_words) for value in beta_scaled]
            self.assertEqual(
                flatten(beta_soft.bits()),
                ref.scale_matrix(beta_lut, ref.bits(0.5)),
            )

            reduce_bits = [ref.bits(value) for value in (3, -1, 2, -1, 7, 0, 4, -2)]
            reduce_tensor = device.tensor_bits(reduce_bits)
            add_result = device.add_reduce(reduce_tensor)
            cmp_result = device.compare_reduce(reduce_tensor)
            expected_min, expected_index = ref.compare_reduce(reduce_bits)
            self.assertEqual(add_result.value_bits, ref.add_reduce(reduce_bits))
            self.assertEqual((cmp_result.value_bits, cmp_result.index), (expected_min, expected_index))

            self.assertEqual(len(device.trace()), 17)
            self.assertTrue(all(entry["output"] is None or "memory" in entry["output"] for entry in device.trace()))

    def test_constant_residency_mixed_reuse_and_unsupported_shape(self):
        with dexsim.Device() as device:
            left = device.constant([[1.0, 0.0], [0.0, 1.0]])
            right = device.constant([[2.0, 3.0], [4.0, 5.0]])
            reset_count = device.session.snapshot().reset_count
            for _ in range(100):
                product = device.gemm(left, right)
                shifted = device.add(product, right)
                scaled = device.scale(shifted, 0.5)
                self.assertEqual(flatten(scaled.bits()), [ref.bits(value) for value in (2, 3, 4, 5)])
                product.release()
                shifted.release()
                scaled.release()
            self.assertEqual(device.session.snapshot().reset_count, reset_count)
            self.assertTrue(left.valid())
            self.assertTrue(right.valid())
            with self.assertRaises(dexsim.UnsupportedShapeError):
                device.empty((5000, 5000))


if __name__ == "__main__":
    unittest.main()
