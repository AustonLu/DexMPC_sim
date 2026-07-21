import sys
import unittest
from pathlib import Path

import dexsim


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from run_multicore_capability_matrix import run_matrix


class MulticoreSessionTest(unittest.TestCase):
    def test_session_validation_and_public_surface(self):
        with self.assertRaisesRegex(ValueError, "at least one"):
            dexsim.Session(cores=())
        with self.assertRaisesRegex(ValueError, "duplicates"):
            dexsim.Session(cores=(0, 0))
        with self.assertRaisesRegex(ValueError, "subset"):
            dexsim.Session(cores=(4,))

        capabilities = dexsim.Session.capabilities()
        self.assertEqual(capabilities["runtime_enabled_cores"], [0, 1, 2, 3])
        self.assertTrue(capabilities["scheduled_wave_api"])
        self.assertEqual(capabilities["shared_engine_command_contexts"], [0])

    def test_all_linear_contexts_pairs_and_four_way(self):
        result = run_matrix()
        self.assertTrue(result["passed"])
        self.assertEqual(result["wave_count"], 55)
        self.assertEqual(result["operators"], ["gemm", "gemv", "outer", "scale", "add"])

    def test_duplicate_core_and_shared_engine_are_rejected(self):
        command = dexsim.scale(
            1, src_memory="global", src_word_offset=0,
            out_memory="local", out_word_offset=0,
            rows=1, cols=8, alpha_bits=dexsim.fp16_bits(1.0),
        )
        shared = dexsim.sin(
            2, src_memory="global", src_word_offset=0,
            out_memory="local", out_word_offset=0,
            rows=1, cols=8,
        )
        with dexsim.Session(cores=(0, 1)) as session:
            with self.assertRaisesRegex(ValueError, "one command per core"):
                session.run_scheduled([
                    dexsim.ScheduledCommand(0, command),
                    dexsim.ScheduledCommand(0, command),
                ])
            with self.assertRaisesRegex(dexsim.DexSimError, "context0"):
                session.run_scheduled([dexsim.ScheduledCommand(1, shared)])


if __name__ == "__main__":
    unittest.main()
