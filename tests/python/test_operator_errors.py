import unittest

import dexsim


class OperatorErrorTest(unittest.TestCase):
    def test_invalid_dimensions_and_ranges(self):
        with self.assertRaisesRegex(ValueError, "positive"):
            dexsim.abs(1, src_memory="global", src_word_offset=0, out_memory="local", out_word_offset=0, rows=0, cols=1)
        with self.assertRaisesRegex(ValueError, "exceeds global SRAM"):
            dexsim.gemm(2, a_memory="global", a_word_offset=2047, b_memory="local", b_word_offset=0, out_memory="temp", out_word_offset=0, n_rows=2, m_cols=2, k_dim=8)
        with self.assertRaisesRegex(ValueError, "11 bits"):
            dexsim.assemble(3, src_memory="global", src_word_offset=0, out_memory="local", out_word_offset=0, rows=1, cols=1, offset_row=0, offset_col=2048)
        with self.assertRaisesRegex(ValueError, "16 bits"):
            dexsim.scale(4, src_memory="global", src_word_offset=0, out_memory="local", out_word_offset=0, rows=1, cols=1, alpha_bits=0x10000)

    def test_unverified_in_place_aliases_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "overlapping"):
            dexsim.abs(1, src_memory="local", src_word_offset=0, out_memory="local", out_word_offset=0, rows=1, cols=8)
        with self.assertRaisesRegex(ValueError, "overlapping"):
            dexsim.add(2, a_memory="local", a_word_offset=0, b_memory="global", b_word_offset=0, out_memory="local", out_word_offset=0, rows=1, cols=8)
        with self.assertRaisesRegex(ValueError, "overlapping"):
            dexsim.transpose(3, src_memory="temp", src_word_offset=2, out_memory="temp", out_word_offset=2, rows=2, cols=3)

    def test_tensor_bit_io_validation_without_constructing_simulator(self):
        self.assertEqual(dexsim.fp16_bits(-1.5), 0xBE00)
        self.assertEqual(dexsim.fp16_value(0xBE00), -1.5)
        with self.assertRaisesRegex(ValueError, "16 bits"):
            dexsim.fp16_value(0x10000)


if __name__ == "__main__":
    unittest.main()
