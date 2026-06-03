#pragma once

#include "dexmpc/runtime/operator.hpp"

#include <cstdint>
#include <exception>
#include <iostream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace dexmpc::tests {
namespace {

#ifndef DEXMPC_OPERATOR_MIXED_CASE_LIMIT
#define DEXMPC_OPERATOR_MIXED_CASE_LIMIT 0
#endif

#ifndef DEXMPC_OPERATOR_MIXED_TIMEOUT_CYCLES
#define DEXMPC_OPERATOR_MIXED_TIMEOUT_CYCLES 1200000
#endif

using dexmpc::runtime::Device;
using dexmpc::runtime::OperatorRuntime;
using dexmpc::runtime::Word128;
using dexsim::Matrix;

class OperatorMixedTest {
public:
    OperatorMixedTest(Device& device, std::string label)
        : runtime_(device, DEXMPC_OPERATOR_MIXED_TIMEOUT_CYCLES), label_(std::move(label)) {}

    void run() {
        runtime_.reset_program();
        runtime_.reset_device();
        std::cout << "Operator mixed " << label_ << " test starting" << std::endl;

        run_gemm_identity_case(dexsim::kMemGlobal, dexsim::kMemLocal0, dexsim::kMemTemp0, 16, 16, 1000);
        run_abs_case(dexsim::kMemGlobal, dexsim::kMemLocal0, 3, 5, 1100);
        run_reduce_add_case(dexsim::kMemTemp0, 8);
        run_layout_transpose_case(dexsim::kMemLocal0, dexsim::kMemGlobal, 3, 4, 1200);
        run_mul_copy_case(dexsim::kMemGlobal, dexsim::kMemTemp0, 3, 6, 1300);
        run_reduce_cmp_case(dexsim::kMemLocal0, 7, 3, 1400);
        run_layout_assemble_case(dexsim::kMemTemp0, dexsim::kMemGlobal, 2, 3, 1, 2, 1500);
        run_add_zero_case(dexsim::kMemGlobal, dexsim::kMemLocal0, dexsim::kMemTemp0, 4, 4, 1600);
        run_abs_case(dexsim::kMemTemp0, dexsim::kMemGlobal, 2, 7, 1700);
        run_reduce_add_case(dexsim::kMemGlobal, 4);
        run_gemm_identity_case(dexsim::kMemLocal0, dexsim::kMemTemp0, dexsim::kMemGlobal, 8, 6, 1800);
        run_layout_transpose_case(dexsim::kMemGlobal, dexsim::kMemTemp0, 2, 6, 1900);
        run_abs_case(dexsim::kMemLocal0, dexsim::kMemTemp0, 4, 3, 2000);
        run_reduce_cmp_case(dexsim::kMemGlobal, 8, 5, 2100);
        run_mul_copy_case(dexsim::kMemTemp0, dexsim::kMemLocal0, 5, 3, 2200);
        run_layout_assemble_case(dexsim::kMemGlobal, dexsim::kMemLocal0, 3, 2, 2, 1, 2300);
        run_abs_case(dexsim::kMemGlobal, dexsim::kMemGlobal, 1, 8, 2400);
        run_add_zero_case(dexsim::kMemLocal0, dexsim::kMemTemp0, dexsim::kMemGlobal, 3, 5, 2500);
        run_reduce_add_case(dexsim::kMemLocal0, 16);
        run_layout_transpose_case(dexsim::kMemTemp0, dexsim::kMemLocal0, 4, 2, 2600);
        run_gemm_identity_case(dexsim::kMemGlobal, dexsim::kMemTemp0, dexsim::kMemLocal0, 4, 7, 2700);
        run_reduce_cmp_case(dexsim::kMemTemp0, 5, 1, 2800);
        run_abs_case(dexsim::kMemTemp0, dexsim::kMemLocal0, 5, 2, 2900);
        run_layout_assemble_case(dexsim::kMemLocal0, dexsim::kMemTemp0, 2, 4, 1, 1, 3000);
        run_mul_copy_case(dexsim::kMemLocal0, dexsim::kMemGlobal, 2, 8, 3100);
        run_reduce_add_case(dexsim::kMemTemp0, 8);
        run_add_zero_case(dexsim::kMemGlobal, dexsim::kMemTemp0, dexsim::kMemLocal0, 2, 6, 3200);
        run_layout_transpose_case(dexsim::kMemLocal0, dexsim::kMemGlobal, 3, 3, 3300);
        run_abs_case(dexsim::kMemGlobal, dexsim::kMemTemp0, 6, 2, 3400);
        run_reduce_cmp_case(dexsim::kMemLocal0, 9, 7, 3500);
        run_layout_assemble_case(dexsim::kMemTemp0, dexsim::kMemGlobal, 3, 3, 1, 3, 3600);
        run_abs_case(dexsim::kMemLocal0, dexsim::kMemGlobal, 2, 5, 3700);
        run_add_zero_case(dexsim::kMemTemp0, dexsim::kMemGlobal, dexsim::kMemLocal0, 4, 3, 3800);
        run_reduce_cmp_case(dexsim::kMemGlobal, 6, 2, 3900);

        std::cout << "Operator mixed " << label_ << " test passed at cycle "
                  << runtime_.device().cycle()
                  << ", cases=" << cases_run_ << std::endl;
    }

private:
    static constexpr std::uint16_t kFp16Zero = 0x0000;
    static constexpr std::uint16_t kFp16Half = 0x3800;
    static constexpr std::uint16_t kFp16One = 0x3c00;
    static constexpr std::uint16_t kFp16Two = 0x4000;
    static constexpr std::uint16_t kFp16Three = 0x4200;
    static constexpr std::uint16_t kFp16Four = 0x4400;
    static constexpr std::uint16_t kFp16Five = 0x4500;
    static constexpr std::uint16_t kFp16Six = 0x4600;
    static constexpr std::uint16_t kFp16Seven = 0x4700;
    static constexpr std::uint16_t kFp16Eight = 0x4800;
    static constexpr std::uint16_t kFp16Sixteen = 0x4c00;
    static constexpr std::uint16_t kFp16NegHalf = 0xb800;
    static constexpr std::uint16_t kFp16NegOne = 0xbc00;
    static constexpr std::uint16_t kFp16NegTwo = 0xc000;
    static constexpr std::uint16_t kFp16NegThree = 0xc200;
    static constexpr std::uint16_t kFp16NegFive = 0xc500;

    bool should_run_next() {
        const int id = cases_seen_++;
        if constexpr (DEXMPC_OPERATOR_MIXED_CASE_LIMIT > 0) {
            if (id >= DEXMPC_OPERATOR_MIXED_CASE_LIMIT) return false;
        }
        ++cases_run_;
        return true;
    }

    std::string case_name(const char* role) const {
        return "op_case_" + std::to_string(cases_seen_ - 1) + "_" + role;
    }

    std::uint16_t pick_pos_fp(int idx) const {
        switch (idx % 9) {
        case 0: return kFp16Half;
        case 1: return kFp16One;
        case 2: return kFp16Two;
        case 3: return kFp16Three;
        case 4: return kFp16Four;
        case 5: return kFp16Five;
        case 6: return kFp16Six;
        case 7: return kFp16Seven;
        default: return kFp16Eight;
        }
    }

    std::uint16_t pick_abs_fp(int idx) const {
        switch (idx % 10) {
        case 0: return kFp16NegOne;
        case 1: return kFp16Two;
        case 2: return kFp16NegThree;
        case 3: return kFp16Four;
        case 4: return kFp16NegFive;
        case 5: return kFp16Half;
        case 6: return kFp16NegHalf;
        case 7: return kFp16Eight;
        case 8: return kFp16NegTwo;
        default: return kFp16One;
        }
    }

    Matrix fill_pattern_matrix(int rows, int cols, int seed, bool use_abs_pattern) const {
        Matrix mat = dexsim::make_matrix(rows, cols);
        for (int r = 0; r < rows; ++r) {
            for (int c = 0; c < cols; ++c) {
                mat[static_cast<std::size_t>(r)][static_cast<std::size_t>(c)] =
                    use_abs_pattern ? pick_abs_fp(seed + r * cols + c)
                                    : pick_pos_fp(seed + r * cols + c);
            }
        }
        return mat;
    }

    static Matrix abs_expected(const Matrix& src) {
        Matrix out = src;
        for (auto& row : out) {
            for (auto& value : row) value = static_cast<std::uint16_t>(value & 0x7fffu);
        }
        return out;
    }

    static Matrix transpose_expected(const Matrix& src) {
        const int rows = static_cast<int>(src.size());
        const int cols = rows == 0 ? 0 : static_cast<int>(src[0].size());
        Matrix out = dexsim::make_matrix(cols, rows);
        for (int r = 0; r < rows; ++r) {
            for (int c = 0; c < cols; ++c) {
                out[static_cast<std::size_t>(c)][static_cast<std::size_t>(r)] =
                    src[static_cast<std::size_t>(r)][static_cast<std::size_t>(c)];
            }
        }
        return out;
    }

    static Matrix assemble_expected(const Matrix& src, const Matrix& dst_pre,
                                    int offset_row, int offset_col) {
        Matrix out = dst_pre;
        const int rows = static_cast<int>(src.size());
        const int cols = rows == 0 ? 0 : static_cast<int>(src[0].size());
        for (int r = 0; r < rows; ++r) {
            for (int c = 0; c < cols; ++c) {
                out[static_cast<std::size_t>(offset_row + r)]
                   [static_cast<std::size_t>(offset_col + c)] =
                    src[static_cast<std::size_t>(r)][static_cast<std::size_t>(c)];
            }
        }
        return out;
    }

    static void expect_matrix_eq(const Matrix& got, const Matrix& expected, const std::string& label) {
        if (got.size() != expected.size()) {
            throw std::runtime_error(label + " row count mismatch");
        }
        for (std::size_t r = 0; r < expected.size(); ++r) {
            if (got[r].size() != expected[r].size()) {
                throw std::runtime_error(label + " column count mismatch");
            }
            for (std::size_t c = 0; c < expected[r].size(); ++c) {
                if (got[r][c] != expected[r][c]) {
                    throw std::runtime_error(label + " element mismatch");
                }
            }
        }
    }

    static std::uint16_t reduce_add_expected(int len) {
        switch (len) {
        case 4: return kFp16Four;
        case 8: return kFp16Eight;
        case 16: return kFp16Sixteen;
        default:
            throw std::runtime_error("operator mixed unsupported reduce_add length");
        }
    }

    void run_abs_case(int src_mem, int dst_mem, int rows, int cols, int seed) {
        if (!should_run_next()) return;
        const auto src_matrix = fill_pattern_matrix(rows, cols, seed, true);
        const auto expected = abs_expected(src_matrix);
        auto src = runtime_.upload_matrix(src_matrix, src_mem, case_name("src"));
        auto dst = runtime_.abs(src, dst_mem, case_name("dst"));
        expect_matrix_eq(runtime_.download_matrix(dst), expected, case_name("abs"));
    }

    void run_layout_transpose_case(int src_mem, int dst_mem, int rows, int cols, int seed) {
        if (!should_run_next()) return;
        const auto src_matrix = fill_pattern_matrix(rows, cols, seed, false);
        const auto expected = transpose_expected(src_matrix);
        auto src = runtime_.upload_matrix(src_matrix, src_mem, case_name("src"));
        auto dst = runtime_.layout_transpose(src, dst_mem, case_name("dst"));
        expect_matrix_eq(runtime_.download_matrix(dst), expected, case_name("transpose"));
    }

    void run_layout_assemble_case(int src_mem, int dst_mem, int src_rows, int src_cols,
                                  int off_r, int off_c, int seed) {
        if (!should_run_next()) return;
        const int dst_rows = src_rows + off_r;
        const int dst_cols = src_cols + off_c;
        const auto src_matrix = fill_pattern_matrix(src_rows, src_cols, seed, false);
        const auto dst_pre = fill_pattern_matrix(dst_rows, dst_cols, seed + 131, false);
        const auto expected = assemble_expected(src_matrix, dst_pre, off_r, off_c);
        auto src = runtime_.upload_matrix(src_matrix, src_mem, case_name("src"));
        auto dst = runtime_.empty_matrix(dst_mem, dst_rows, dst_cols, case_name("dst"));
        runtime_.write_words(dst, dexsim::matrix_to_words(dst_pre, dst_rows, dst_cols));
        runtime_.layout_assemble_into(src, dst, off_r, off_c);
        expect_matrix_eq(runtime_.download_matrix(dst), expected, case_name("assemble"));
    }

    void run_reduce_add_case(int src_mem, int len) {
        if (!should_run_next()) return;
        std::vector<std::uint16_t> vec(static_cast<std::size_t>(len), kFp16One);
        auto src = runtime_.upload_vector(vec, src_mem, case_name("src"));
        const auto result = runtime_.reduce_add(src);
        if (result.value != reduce_add_expected(len) || result.index != 0) {
            throw std::runtime_error(case_name("reduce_add") + " result mismatch");
        }
    }

    void run_reduce_cmp_case(int src_mem, int len, int min_idx, int seed) {
        if (!should_run_next()) return;
        std::vector<std::uint16_t> vec(static_cast<std::size_t>(len), 0);
        for (int i = 0; i < len; ++i) {
            vec[static_cast<std::size_t>(i)] = pick_pos_fp(seed + i + 2);
            if (vec[static_cast<std::size_t>(i)] == kFp16Half) {
                vec[static_cast<std::size_t>(i)] = kFp16Three;
            }
        }
        vec[static_cast<std::size_t>(min_idx)] = kFp16Half;
        auto src = runtime_.upload_vector(vec, src_mem, case_name("src"));
        const auto result = runtime_.reduce_cmp(src);
        if (result.value != kFp16Half || result.index != static_cast<std::uint16_t>(min_idx)) {
            throw std::runtime_error(case_name("reduce_cmp") + " result mismatch");
        }
    }

    void run_gemm_identity_case(int a_mem, int b_mem, int c_mem,
                                int n_rows, int m_cols, int seed) {
        if (!should_run_next()) return;
        Matrix a = dexsim::make_matrix(n_rows, n_rows);
        for (int r = 0; r < n_rows; ++r) {
            for (int c = 0; c < n_rows; ++c) {
                a[static_cast<std::size_t>(r)][static_cast<std::size_t>(c)] =
                    (r == c) ? kFp16One : kFp16Zero;
            }
        }
        Matrix b = fill_pattern_matrix(n_rows, m_cols, seed, false);
        auto a_tensor = runtime_.upload_matrix(a, a_mem, case_name("a"));
        auto b_tensor = runtime_.upload_matrix(b, b_mem, case_name("b"));
        auto c_tensor = runtime_.gemm(a_tensor, b_tensor, c_mem, case_name("c"));
        expect_matrix_eq(runtime_.download_matrix(c_tensor), b, case_name("gemm"));
    }

    void run_mul_copy_case(int a_mem, int c_mem, int rows, int cols, int seed) {
        if (!should_run_next()) return;
        Matrix a = fill_pattern_matrix(rows, cols, seed, false);
        auto a_tensor = runtime_.upload_matrix(a, a_mem, case_name("a"));
        auto c_tensor = runtime_.mul(a_tensor, kFp16One, c_mem, case_name("c"));
        expect_matrix_eq(runtime_.download_matrix(c_tensor), a, case_name("mul"));
    }

    void run_add_zero_case(int a_mem, int b_mem, int c_mem, int rows, int cols, int seed) {
        if (!should_run_next()) return;
        Matrix a = fill_pattern_matrix(rows, cols, seed, false);
        Matrix b = dexsim::make_matrix(rows, cols);
        auto a_tensor = runtime_.upload_matrix(a, a_mem, case_name("a"));
        auto b_tensor = runtime_.upload_matrix(b, b_mem, case_name("b"));
        auto c_tensor = runtime_.add(a_tensor, b_tensor, c_mem, case_name("c"));
        expect_matrix_eq(runtime_.download_matrix(c_tensor), a, case_name("add"));
    }

    OperatorRuntime runtime_;
    std::string label_;
    int cases_seen_ = 0;
    int cases_run_ = 0;
};

} // namespace
} // namespace dexmpc::tests
