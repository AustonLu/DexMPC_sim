import unittest

from dexsim.kernels.forward import _add_vectors, build_forward_sram_layout, reference_forward_stage


class ForwardKernelTest(unittest.TestCase):
    def test_add_command_reference_canonicalizes_negative_zero(self):
        self.assertEqual(_add_vectors([0x8000], [0x8000]), [0x0000])

    def test_airplane_layout_fits_single_core_sram(self):
        layout = build_forward_sram_layout(n_qvel=22, n_cmd=16, contact_rows=60)
        global_end = max(
            region.word_offset + region.words for region in layout.global_regions.values()
        )
        local_end = max(
            region.word_offset + region.words for region in layout.local_regions.values()
        )
        self.assertEqual(global_end, 431)
        self.assertEqual(local_end, 86)
        self.assertLessEqual(global_end, 2048)
        self.assertLessEqual(local_end, 512)

    def test_reference_is_deterministic_and_returns_all_intermediates(self):
        value = reference_forward_stage(
            command=[0.25, -0.5],
            object_force=[0.125],
            q_inv=[[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            robot_stiff=[[1.0, 0.0], [0.0, 1.0]],
            jac=[[1.0, 0.0, 0.0], [0.0, 1.0, 1.0]],
            phi=[0.0, 0.25],
            h=0.1,
            sigma=0.5,
        )
        repeated = reference_forward_stage(
            command=[0.25, -0.5],
            object_force=[0.125],
            q_inv=[[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            robot_stiff=[[1.0, 0.0], [0.0, 1.0]],
            jac=[[1.0, 0.0, 0.0], [0.0, 1.0, 1.0]],
            phi=[0.0, 0.25],
            h=0.1,
            sigma=0.5,
        )
        self.assertEqual(value, repeated)
        self.assertEqual(len(value["velocity"]), 3)
        self.assertEqual(len(value["s"]), 2)
        self.assertEqual(
            set(value),
            {
                "u", "b_r", "b", "x", "t", "t_plus_phi",
                "neg_sigma_sum", "neg_damping_t", "z", "beta_z",
                "softplus", "s", "jac_t_s", "q_inv_jac_t_s",
                "x_plus_contact", "velocity",
            },
        )

    def test_gemv_reference_flushes_subnormal_inputs(self):
        result = reference_forward_stage(
            command=[2.0 ** -20],
            object_force=[0.0],
            q_inv=[[1.0, 0.0], [0.0, 1.0]],
            robot_stiff=[[1.0]],
            jac=[[0.0, 0.0]],
            phi=[0.0],
            h=0.1,
            sigma=0.5,
        )
        self.assertNotEqual(result["u"][0] & 0x03FF, 0)
        self.assertEqual(result["b_r"][0] & 0x7FFF, 0)


if __name__ == "__main__":
    unittest.main()
