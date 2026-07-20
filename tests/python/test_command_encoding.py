import unittest

import dexsim


class CommandEncodingTest(unittest.TestCase):
    def test_all_primitive_golden_words(self):
        cases = [
            (
                dexsim.abs(0x123, src_memory="local", src_word_offset=3, out_memory="temp", out_word_offset=5, rows=2, cols=3, group_end=False),
                (0x02003000, 0xE00A0000, 0x12320200),
            ),
            (
                dexsim.add_reduce(0x124, src_memory="global", src_word_offset=7, element_count=17),
                (0x11000000, 0xC0000000, 0x12443001),
            ),
            (
                dexsim.compare_reduce(0x125, src_memory="temp", src_word_offset=9, element_count=31),
                (0x1F000000, 0x40000000, 0x12541402),
            ),
            (
                dexsim.gemm(0x126, a_memory="local", a_word_offset=1, b_memory="temp", b_word_offset=2, out_memory="global", out_word_offset=4, n_rows=3, m_cols=5, k_dim=7),
                (0x05003007, 0x60040040, 0x12661200),
            ),
            (
                dexsim.scale(0x127, src_memory="global", src_word_offset=1, out_memory="local", out_word_offset=2, rows=2, cols=4, alpha_bits=0xC100),
                (0x02004006, 0x50041000, 0x12763000),
            ),
            (
                dexsim.add(0x128, a_memory="global", a_word_offset=1, b_memory="local", b_word_offset=2, out_memory="temp", out_word_offset=3, rows=2, cols=4),
                (0x02004000, 0x50050030, 0x12865000),
            ),
            (
                dexsim.sin(0x129, src_memory="local", src_word_offset=1, out_memory="global", out_word_offset=2, rows=3, cols=3),
                (0x03003000, 0x40040000, 0x12981200),
            ),
            (
                dexsim.cos(0x12A, src_memory="temp", src_word_offset=1, out_memory="local", out_word_offset=2, rows=3, cols=3),
                (0x03003000, 0x50040000, 0x12A83400),
            ),
            (
                dexsim.softplus(0x12B, src_memory="global", src_word_offset=1, out_memory="temp", out_word_offset=2, rows=3, cols=3),
                (0x03003000, 0x60040000, 0x12B85000),
            ),
            (
                dexsim.assemble(0x12C, src_memory="local", src_word_offset=1, out_memory="temp", out_word_offset=2, rows=2, cols=3, offset_row=1, offset_col=2),
                (0x02003001, 0x60040020, 0x12CA1200),
            ),
            (
                dexsim.transpose(0x12D, src_memory="temp", src_word_offset=1, out_memory="global", out_word_offset=2, rows=2, cols=3),
                (0x02003000, 0x40040000, 0x12DA3400),
            ),
        ]
        for command, expected in cases:
            self.assertEqual(command.words, expected)

    def test_gemm_derived_forms_are_exact_encodings(self):
        gemv = dexsim.gemv(1, a_memory="global", a_word_offset=0, x_memory="local", x_word_offset=0, out_memory="temp", out_word_offset=0, n_rows=3, k_dim=5)
        gemm = dexsim.gemm(1, a_memory="global", a_word_offset=0, b_memory="local", b_word_offset=0, out_memory="temp", out_word_offset=0, n_rows=3, m_cols=1, k_dim=5)
        self.assertEqual(gemv, gemm)
        dot = dexsim.dot(2, a_memory="global", a_word_offset=0, b_memory="local", b_word_offset=0, out_memory="temp", out_word_offset=0, element_count=5)
        dot_gemm = dexsim.gemm(2, a_memory="global", a_word_offset=0, b_memory="local", b_word_offset=0, out_memory="temp", out_word_offset=0, n_rows=1, m_cols=1, k_dim=5)
        self.assertEqual(dot, dot_gemm)
        outer = dexsim.outer(3, a_memory="global", a_word_offset=0, b_memory="local", b_word_offset=0, out_memory="temp", out_word_offset=0, n_rows=3, m_cols=5)
        outer_gemm = dexsim.gemm(3, a_memory="global", a_word_offset=0, b_memory="local", b_word_offset=0, out_memory="temp", out_word_offset=0, n_rows=3, m_cols=5, k_dim=1)
        self.assertEqual(outer, outer_gemm)


if __name__ == "__main__":
    unittest.main()
