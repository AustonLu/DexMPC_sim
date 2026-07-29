import unittest

from dexsim.program import Op, _operation_cycle_metrics


class ProgramCycleMetricsTest(unittest.TestCase):
    def test_separates_linear_and_shared_engine_cycles(self):
        operations = [
            Op("gemm", ("a", "b"), "c", {}),
            Op("add", ("c", "d"), "e", {}),
            Op("sin", ("e",), "f", {}),
            Op("add_reduce", ("f",), "g", {}),
            Op("transpose", ("e",), "h", {}),
        ]
        records = [
            {"total_cycles": 100, "scheduled_run_cycles": 80,
             "engine_compute_cycles": 60},
            {"total_cycles": 40, "scheduled_run_cycles": 30,
             "engine_compute_cycles": 20},
            {"total_cycles": 50, "scheduled_run_cycles": 45,
             "engine_compute_cycles": 35},
            {"total_cycles": 25, "scheduled_run_cycles": 20,
             "engine_compute_cycles": 15},
            {"total_cycles": 20, "scheduled_run_cycles": 15,
             "engine_compute_cycles": 10},
        ]

        metrics = _operation_cycle_metrics(operations, records)

        self.assertEqual(metrics["linear_engine_compute_cycles"], 80)
        self.assertEqual(metrics["shared_engine_compute_cycles"], 60)
        self.assertEqual(metrics["data_layout_engine_compute_cycles"], 10)
        self.assertEqual(metrics["arithmetic_engine_compute_cycles"], 130)
        self.assertEqual(metrics["operator_gemm_engine_compute_cycles"], 60)
        self.assertEqual(metrics["operator_add_calls"], 1)
        self.assertEqual(metrics["operator_sin_scheduled_run_cycles"], 45)


if __name__ == "__main__":
    unittest.main()
