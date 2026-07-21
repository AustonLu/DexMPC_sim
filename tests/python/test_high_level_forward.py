import unittest

import dexsim
from dexsim.kernels import HighLevelDexMPCForwardKernel
from dexsim.kernels.forward import reference_forward_stage


class HighLevelForwardKernelTest(unittest.TestCase):
    def test_high_level_forward_is_bit_exact_and_uses_only_operator_api(self):
        kwargs = {
            "object_force": [0.125],
            "q_inv": [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            "robot_stiff": [[1.0, 0.0], [0.0, 1.0]],
            "jac": [[1.0, 0.0, 0.0], [0.0, 1.0, 1.0]],
            "phi": [0.0, 0.25],
            "h": 0.1,
            "sigma": 0.5,
        }
        command = [0.25, -0.5]
        reference = reference_forward_stage(command=command, **kwargs)
        with dexsim.Device() as device:
            kernel = HighLevelDexMPCForwardKernel(device, **kwargs)
            result = kernel.run_stage(command)
            self.assertEqual(result.velocity_bits, reference["velocity"])
            self.assertTrue(result.trace["reference"]["bit_exact"])
            self.assertEqual(result.trace["command_count"], 14)
            self.assertEqual(
                [entry["operation"] for entry in result.trace["commands"]],
                [
                    "gemv", "gemv", "gemv", "add", "scale", "scale", "add",
                    "scale", "softplus", "scale", "gemv", "gemv", "add", "scale",
                ],
            )
            kernel.close()


if __name__ == "__main__":
    unittest.main()
