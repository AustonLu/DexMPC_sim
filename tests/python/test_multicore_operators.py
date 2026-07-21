import unittest

import dexsim

import reference_fp16 as ref


def flatten(value):
    if not isinstance(value, (list, tuple)):
        return [value]
    result = []
    for child in value:
        result.extend(flatten(child))
    return result


def values(count, salt):
    return [(((index * 13 + salt * 5) % 23) - 11) / 16.0 for index in range(count)]


def matrix(rows, cols, salt):
    data = values(rows * cols, salt)
    return [data[row * cols : (row + 1) * cols] for row in range(rows)]


class MulticoreOperatorTest(unittest.TestCase):
    def test_quad_operators_are_bit_exact_with_odd_tail(self):
        with dexsim.Device(execution_policy="quad") as device:
            gemm_a = matrix(33, 8, 1)
            gemm_b = matrix(8, 8, 2)
            gemm = device.gemm(device.tensor(gemm_a), device.tensor(gemm_b))
            self.assertEqual(
                flatten(gemm.bits()),
                ref.gemm(
                    [ref.bits(value) for value in flatten(gemm_a)],
                    [ref.bits(value) for value in flatten(gemm_b)],
                    33,
                    8,
                    8,
                ),
            )

            gemv_a = matrix(35, 8, 3)
            gemv_x = values(8, 4)
            gemv = device.gemv(device.tensor(gemv_a), device.tensor(gemv_x))
            self.assertEqual(
                flatten(gemv.bits()),
                ref.gemm(
                    [ref.bits(value) for value in flatten(gemv_a)],
                    [ref.bits(value) for value in gemv_x],
                    35,
                    1,
                    8,
                ),
            )

            outer_a = values(34, 5)
            outer_b = values(8, 6)
            outer = device.outer(device.tensor(outer_a), device.tensor(outer_b))
            self.assertEqual(
                flatten(outer.bits()),
                ref.gemm(
                    [ref.bits(value) for value in outer_a],
                    [ref.bits(value) for value in outer_b],
                    34,
                    8,
                    1,
                ),
            )

            scale_a = values(35, 7)
            scaled = device.scale(device.tensor(scale_a), -0.375)
            self.assertEqual(
                flatten(scaled.bits()),
                ref.scale_matrix(
                    [ref.bits(value) for value in scale_a], ref.bits(-0.375)
                ),
            )

            add_a = values(35, 8)
            add_b = values(35, 9)
            added = device.add(device.tensor(add_a), device.tensor(add_b))
            self.assertEqual(
                flatten(added.bits()),
                ref.add_matrix(
                    [ref.bits(value) for value in add_a],
                    [ref.bits(value) for value in add_b],
                ),
            )

            parallel = [entry["parallel"] for entry in device.trace()]
            self.assertEqual([value["plan"]["core_count"] for value in parallel], [4] * 5)
            self.assertTrue(all(value["transfers"] for value in parallel))

    def test_small_auto_shapes_remain_real_hardware_single_core(self):
        with dexsim.Device(execution_policy="auto") as device:
            left = device.tensor([[1.0, 2.0], [3.0, 4.0]])
            right = device.tensor([[0.5, -1.0], [2.0, 3.0]])
            output = device.gemm(left, right)
            self.assertEqual(len(flatten(output.bits())), 4)
            plan = device.trace()[-1]["parallel"]["plan"]
            self.assertEqual(plan["core_count"], 1)
            self.assertEqual(plan["reason"], "below_measured_parallel_threshold")

    def test_program_and_eager_share_quad_planner(self):
        left_value = matrix(32, 8, 10)
        right_value = matrix(8, 8, 11)

        program = dexsim.Program("quad_gemm")
        left = program.input("left", (32, 8))
        right = program.input("right", (8, 8))
        output = program.gemm(left, right)
        program.output(output)
        with program.compile(execution_policy="quad") as compiled:
            result = compiled.run(left=left_value, right=right_value)
            command_cores = [value["core"] for value in result.trace.commands]
            self.assertEqual(command_cores, [0, 1, 2, 3])
            program_bits = flatten(result.output_bits[output.name])

        with dexsim.Device(execution_policy="quad") as device:
            eager = device.gemm(device.tensor(left_value), device.tensor(right_value))
            self.assertEqual(program_bits, flatten(eager.bits()))
            self.assertEqual(
                device.trace()[-1]["parallel"]["plan"]["partitions"],
                result.trace.commands[0]["parallel_plan"]["partitions"],
            )


if __name__ == "__main__":
    unittest.main()
