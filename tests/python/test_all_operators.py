import unittest
from pathlib import Path

import dexsim

import reference_fp16 as ref


ROOT = Path(__file__).resolve().parents[2]


def load_hex(name):
    path = ROOT / "rtl" / "chisel" / "top_connect" / "src" / "lut" / "tools" / name
    return [int(line, 16) for line in path.read_text().splitlines() if line]


class AllOperatorTest(unittest.TestCase):
    def test_bit_io_all_primitives_derived_forms_and_reduce_batch(self):
        with dexsim.Session() as session:
            special = [0x0000, 0x8000, 0xBC00, 0x7E55, 0xFC00, 0x0001]
            session.write_tensor_bits(memory="temp", offset=3, value=special)
            self.assertEqual(
                session.read_tensor_bits(memory="temp", offset=3, shape=(len(special),)),
                special,
            )

            session.write_tensor_bits(memory="global", offset=0, value=special)
            trace = session.run([
                dexsim.abs(1, src_memory="global", src_word_offset=0, out_memory="local", out_word_offset=0, rows=1, cols=len(special))
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="local", offset=0, shape=(len(special),)),
                [item & 0x7FFF for item in special],
            )
            self.assertEqual(trace.command_results[0].command_id, 1)

            scale_source = [ref.bits(value) for value in (1.0, -2.0, 0.25, 8.0, -0.0, 3.0)]
            alpha = ref.bits(-0.5)
            session.write_tensor_bits(memory="global", offset=16, value=scale_source)
            session.run([
                dexsim.scale(2, src_memory="global", src_word_offset=2, out_memory="local", out_word_offset=2, rows=2, cols=3, alpha_bits=alpha)
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="local", offset=16, shape=(6,)),
                ref.scale_matrix(scale_source, alpha),
            )

            add_left = [ref.bits(value) for value in (1.0, -2.0, 100.0, 0.25, -0.0, 4.0)]
            add_right = [ref.bits(value) for value in (2.0, 2.0, -100.0, 0.5, 0.0, -1.0)]
            session.write_tensor_bits(memory="global", offset=32, value=add_left)
            session.write_tensor_bits(memory="local", offset=32, value=add_right)
            session.run([
                dexsim.add(3, a_memory="global", a_word_offset=4, b_memory="local", b_word_offset=4, out_memory="temp", out_word_offset=4, rows=2, cols=3)
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="temp", offset=32, shape=(6,)),
                ref.add_matrix(add_left, add_right),
            )

            a = [ref.bits(value) for value in (1.0, 2.0, 3.0, 4.0)]
            b = [ref.bits(value) for value in (5.0, 6.0, 7.0, 8.0)]
            session.write_tensor_bits(memory="local", offset=64, value=a)
            session.write_tensor_bits(memory="local", offset=72, value=b)
            session.run([
                dexsim.gemm(4, a_memory="local", a_word_offset=8, b_memory="local", b_word_offset=9, out_memory="local", out_word_offset=10, n_rows=2, m_cols=2, k_dim=2)
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="local", offset=80, shape=(4,)),
                ref.gemm(a, b, 2, 2, 2),
            )

            matrix = [ref.bits(value) for value in (1.0, 2.0, 3.0, 4.0, 5.0, 6.0)]
            vector = [ref.bits(value) for value in (0.5, -1.0, 2.0)]
            session.write_tensor_bits(memory="global", offset=64, value=matrix)
            session.write_tensor_bits(memory="temp", offset=64, value=vector)
            session.run([
                dexsim.gemv(5, a_memory="global", a_word_offset=8, x_memory="temp", x_word_offset=8, out_memory="local", out_word_offset=12, n_rows=2, k_dim=3)
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="local", offset=96, shape=(2,)),
                ref.gemm(matrix, vector, 2, 1, 3),
            )

            dot_left = [ref.bits(value) for value in (1.0, 2.0, -3.0, 4.0, 0.5)]
            dot_right = [ref.bits(value) for value in (2.0, -1.0, 0.5, 3.0, 4.0)]
            session.write_tensor_bits(memory="global", offset=96, value=dot_left)
            session.write_tensor_bits(memory="temp", offset=96, value=dot_right)
            session.run([
                dexsim.dot(6, a_memory="global", a_word_offset=12, b_memory="temp", b_word_offset=12, out_memory="local", out_word_offset=13, element_count=5)
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="local", offset=104, shape=(1,)),
                ref.gemm(dot_left, dot_right, 1, 1, 5),
            )

            outer_left = [ref.bits(2.0), ref.bits(-1.0)]
            outer_right = [ref.bits(0.5), ref.bits(3.0), ref.bits(-2.0)]
            session.write_tensor_bits(memory="global", offset=112, value=outer_left)
            session.write_tensor_bits(memory="temp", offset=112, value=outer_right)
            session.run([
                dexsim.outer(7, a_memory="global", a_word_offset=14, b_memory="temp", b_word_offset=14, out_memory="local", out_word_offset=14, n_rows=2, m_cols=3)
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="local", offset=112, shape=(6,)),
                ref.gemm(outer_left, outer_right, 2, 3, 1),
            )

            reduce_a = [ref.bits(value) for value in (3, -1, 2, -1, 7, 0, 4, 8, 1, 5, 6, 9, 2, 3, 4, 5, -2)]
            reduce_b = [ref.bits(value) for value in (1, 2, 3, 4)]
            session.write_tensor_bits(memory="global", offset=128, value=reduce_a)
            session.write_tensor_bits(memory="local", offset=128, value=reduce_b)
            reduce_trace = session.run([
                dexsim.add_reduce(8, src_memory="global", src_word_offset=16, element_count=len(reduce_a)),
                dexsim.compare_reduce(9, src_memory="global", src_word_offset=16, element_count=len(reduce_a)),
                dexsim.add_reduce(10, src_memory="local", src_word_offset=16, element_count=len(reduce_b)),
                dexsim.compare_reduce(11, src_memory="local", src_word_offset=16, element_count=len(reduce_b)),
            ])
            expected_a_sum = ref.add_reduce(reduce_a)
            expected_a_min, expected_a_index = ref.compare_reduce(reduce_a)
            expected_b_sum = ref.add_reduce(reduce_b)
            expected_b_min, expected_b_index = ref.compare_reduce(reduce_b)
            results = reduce_trace.command_results
            self.assertEqual([item.command_id for item in results], [8, 9, 10, 11])
            self.assertEqual(results[0].reduce_value_bits, expected_a_sum)
            self.assertEqual((results[1].reduce_value_bits, results[1].reduce_index), (expected_a_min, expected_a_index))
            self.assertEqual(results[2].reduce_value_bits, expected_b_sum)
            self.assertEqual((results[3].reduce_value_bits, results[3].reduce_index), (expected_b_min, expected_b_index))
            self.assertTrue(all(item.reduce_valid for item in results))
            self.assertEqual(session.read_compare_reduce()["command_id"], 11)

            transpose_source = [ref.bits(value) for value in (1, 2, 3, 4, 5, 6)]
            session.write_tensor_bits(memory="global", offset=192, value=transpose_source)
            session.run([
                dexsim.transpose(12, src_memory="global", src_word_offset=24, out_memory="local", out_word_offset=24, rows=2, cols=3)
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="local", offset=192, shape=(6,)),
                ref.transpose(transpose_source, 2, 3),
            )

            assemble_source = [ref.bits(value) for value in (10, 11, 12, 13)]
            assemble_destination = [0x3555 + index for index in range(12)]
            session.write_tensor_bits(memory="global", offset=208, value=assemble_source)
            session.write_tensor_bits(memory="temp", offset=208, value=assemble_destination)
            session.run([
                dexsim.assemble(13, src_memory="global", src_word_offset=26, out_memory="temp", out_word_offset=26, rows=2, cols=2, offset_row=1, offset_col=2)
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="temp", offset=208, shape=(12,)),
                ref.assemble(assemble_source, assemble_destination, 2, 2, 1, 2),
            )
            self.assertEqual(session.snapshot().reset_count, 1)

    def test_lut_bit_models_and_lazy_setup_accounting(self):
        trig_words = load_hex("trig_data.hex")
        softplus_words = load_hex("softplus_data.hex")
        trig_inputs = [
            ref.bits(value)
            for value in (0.0, -0.0, 0.5, -0.5, 1.5703125, 3.140625, 4.7109375, 6.28125, 7.0)
        ]
        soft_inputs = [ref.bits(value) for value in (-8.0, -3.5, -1.0, -0.0, 0.0, 1.0, 3.5, 8.0)]
        with dexsim.Session() as session:
            session.write_tensor_bits(memory="local", offset=160, value=trig_inputs)
            sin_trace = session.run([
                dexsim.sin(20, src_memory="local", src_word_offset=20, out_memory="temp", out_word_offset=20, rows=1, cols=len(trig_inputs))
            ])
            expected_pairs = [ref.trig_pair(item, trig_words) for item in trig_inputs]
            self.assertEqual(
                session.read_tensor_bits(memory="temp", offset=160, shape=(len(trig_inputs),)),
                [pair[0] for pair in expected_pairs],
            )
            self.assertGreater(sin_trace.setup_cycles, 0)
            self.assertGreater(sin_trace.setup_write_bytes, 0)

            cos_trace = session.run([
                dexsim.cos(21, src_memory="local", src_word_offset=20, out_memory="temp", out_word_offset=22, rows=1, cols=len(trig_inputs))
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="temp", offset=176, shape=(len(trig_inputs),)),
                [pair[1] for pair in expected_pairs],
            )
            self.assertEqual(cos_trace.setup_cycles, 0)
            self.assertEqual(cos_trace.setup_write_bytes, 0)

            session.write_tensor_bits(memory="local", offset=192, value=soft_inputs)
            soft_trace = session.run([
                dexsim.softplus(22, src_memory="local", src_word_offset=24, out_memory="temp", out_word_offset=24, rows=1, cols=len(soft_inputs))
            ])
            self.assertEqual(
                session.read_tensor_bits(memory="temp", offset=192, shape=(len(soft_inputs),)),
                [ref.softplus(item, softplus_words) for item in soft_inputs],
            )
            self.assertGreater(soft_trace.setup_cycles, 0)
            self.assertGreater(soft_trace.setup_write_bytes, 0)
            second_soft = session.run([
                dexsim.softplus(23, src_memory="local", src_word_offset=24, out_memory="temp", out_word_offset=26, rows=1, cols=len(soft_inputs))
            ])
            self.assertEqual(second_soft.setup_cycles, 0)
            self.assertEqual(second_soft.setup_write_bytes, 0)

    def test_public_compatibility_aliases_and_capabilities(self):
        for name in (
            "reduce_add", "reduce_cmp", "mul", "lut_sin", "lut_cos",
            "lut_softplus", "layout_assemble", "layout_transpose",
        ):
            self.assertTrue(callable(getattr(dexsim, name)))
        capabilities = dexsim.Session.capabilities()
        self.assertEqual(len(capabilities["primitive_operators"]), 11)
        self.assertEqual(capabilities["derived_operators"], ["gemv", "dot", "outer"])
        self.assertEqual(capabilities["operator_core"], 0)


if __name__ == "__main__":
    unittest.main()
