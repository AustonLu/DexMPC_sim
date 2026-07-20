import math
import unittest

import dexsim


class SessionTest(unittest.TestCase):
    def test_single_core_contract(self):
        self.assertEqual(dexsim.Session.capabilities()["runtime_enabled_cores"], [0])
        with self.assertRaisesRegex(ValueError, "cores=\\[0\\]"):
            dexsim.Session(cores=[1])
        with self.assertRaisesRegex(ValueError, "transport='d2d'"):
            dexsim.Session(transport="spi")

    def test_sram_roundtrip_gemm_softplus_reduce_and_persistence(self):
        with dexsim.Session() as session:
            original = [[1.0, -2.0, 3.5], [0.25, -0.5, 8.0]]
            session.write_tensor(memory="temp", offset=3, value=original)
            self.assertEqual(
                session.read_tensor(memory="temp", offset=3, shape=(2, 3)), original
            )

            session.write_tensor(memory="local", offset=0, value=[1.0, 2.0, 3.0, 4.0])
            session.write_tensor(memory="local", offset=8, value=[5.0, 6.0, 7.0, 8.0])
            gemm_trace = session.run(
                [
                    dexsim.gemm(
                        1,
                        a_memory="local",
                        a_word_offset=0,
                        b_memory="local",
                        b_word_offset=1,
                        out_memory="local",
                        out_word_offset=2,
                        n_rows=2,
                        m_cols=2,
                        k_dim=2,
                    )
                ]
            )
            self.assertEqual(
                session.read_tensor(memory="local", offset=16, shape=(2, 2)),
                [[19.0, 22.0], [43.0, 50.0]],
            )
            self.assertEqual(gemm_trace.command_count, 1)
            self.assertGreater(gemm_trace.cycles, 0)
            self.assertGreater(gemm_trace.read_bytes, 0)
            self.assertGreater(gemm_trace.write_bytes, 0)

            soft_input = [-4.0, -1.0, 0.0, 1.0, 4.0]
            session.write_tensor(memory="local", offset=24, value=soft_input)
            session.run(
                [
                    dexsim.softplus(
                        2,
                        src_memory="local",
                        src_word_offset=3,
                        out_memory="local",
                        out_word_offset=4,
                        rows=1,
                        cols=len(soft_input),
                    )
                ]
            )
            soft_output = session.read_tensor(
                memory="local", offset=32, shape=(len(soft_input),)
            )
            for actual, value in zip(soft_output, soft_input):
                expected = math.log1p(math.exp(value))
                self.assertLessEqual(abs(actual - expected), 0.032)

            session.write_tensor(memory="local", offset=40, value=[1.0, 2.0, 3.0, 4.0])
            session.run(
                [
                    dexsim.add_reduce(
                        3,
                        src_memory="local",
                        src_word_offset=5,
                        element_count=4,
                    )
                ]
            )
            reduce_result = session.read_add_reduce()
            self.assertTrue(reduce_result["valid"])
            self.assertEqual(reduce_result["command_id"], 3)
            self.assertEqual(reduce_result["value"], 10.0)

            before = session.snapshot()
            for index in range(100):
                trace = session.run(
                    [
                        dexsim.gemm(
                            100 + index,
                            a_memory="local",
                            a_word_offset=0,
                            b_memory="local",
                            b_word_offset=1,
                            out_memory="local",
                            out_word_offset=2,
                            n_rows=2,
                            m_cols=2,
                            k_dim=2,
                        )
                    ]
                )
                self.assertEqual(trace.reset_count, 1)
            after = session.snapshot()
            self.assertEqual(after.reset_count, 1)
            self.assertEqual(after.done_count - before.done_count, 100)
            self.assertGreater(after.cycle, before.cycle)

    def test_timeout_and_illegal_command_errors(self):
        with self.assertRaisesRegex(ValueError, "timeout_cycles"):
            dexsim.Session(timeout_cycles=0)

        with dexsim.Session() as timeout_session:
            timeout_command = dexsim.gemm(
                399,
                a_memory="local",
                a_word_offset=0,
                b_memory="local",
                b_word_offset=1,
                out_memory="local",
                out_word_offset=2,
                n_rows=16,
                m_cols=16,
                k_dim=16,
            )
            with self.assertRaisesRegex(dexsim.DexSimError, "timeout"):
                timeout_session.run([timeout_command], timeout_cycles=1)

        with dexsim.Session() as session:
            illegal = dexsim.make_command(400, 0, 0)
            with self.assertRaisesRegex(dexsim.DexSimError, "illegal command"):
                session.run([illegal])


if __name__ == "__main__":
    unittest.main()
