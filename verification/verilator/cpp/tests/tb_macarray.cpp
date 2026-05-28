#ifdef DEXMPC_USE_TOPCHIP_SIM
#include "../common/topchip_sim.hpp"
#else
#include "../common/dexmpc_sim.hpp"
#endif

#include <array>

using namespace dexsim;
#ifdef DEXMPC_USE_TOPCHIP_SIM
using Sim = dexsim::topchip::Sim;
using TestBase = dexsim::topchip::TestBase;
#endif

#ifndef DEXMPC_RESULT_DIR
#define DEXMPC_RESULT_DIR "verification/results/core_top/macarray"
#endif

namespace {

class MacArrayTest : public TestBase {
public:
    MacArrayTest(Sim& sim, std::filesystem::path out_dir)
        : TestBase(sim), out_dir_(std::move(out_dir)) {}

    void run() {
        std::filesystem::create_directories(out_dir_);
        init_pool();
        open_csvs();

        reset_sequence(6);
        sim_.dut()->reset = 0;
        for (int i = 0; i < 2; ++i) tick();

        run_gemm();
        run_gemv();
        run_dot();
        run_outer();
        run_mul();
        run_add();

        std::cout << "MacArray C++ test passed at cycle " << sim_.cycle()
                  << ", commands=" << next_cmd_id_ << "\n";
    }

protected:
    void monitor_done() override {
#ifdef DEXMPC_USE_TOPCHIP_SIM
        return;
#else
        auto* d = sim_.dut();
        if (d->reset) return;
        if ((d->io_cmdStatus_0 & (1u << 5)) != 0) {
            throw std::runtime_error("macarray cmdStatus overflow set");
        }
        if (d->io_doneCount_0 == last_done_count_) return;
        if (d->io_doneCount_0 != last_done_count_ + 1) {
            throw std::runtime_error("macarray doneCount jump");
        }

        const uint32_t last = d->io_lastDone_0;
        const uint32_t done_cmd_id = last & 0xfffu;
        const uint32_t done_opcode = (last >> 12) & 0x7u;
        const uint32_t done_subop = (last >> 15) & 0xfu;
        const bool illegal = ((last >> 20) & 1u) != 0;

        if (illegal) throw std::runtime_error("macarray illegal command reported");
        if (done_cmd_id != static_cast<uint32_t>(expected_done_)) {
            throw std::runtime_error("macarray doneCmdId out of order");
        }
        if (done_opcode != kOpLa) throw std::runtime_error("macarray done opcode mismatch");
        if (done_cmd_id >= expected_subop_.size()) {
            throw std::runtime_error("macarray done cmd id out of range");
        }
        if (done_subop != expected_subop_[done_cmd_id]) {
            throw std::runtime_error("macarray done subop mismatch");
        }

        ++done_count_;
        ++expected_done_;
        last_done_count_ = d->io_doneCount_0;
#endif
    }

private:
    static constexpr int kCases = 10;
    static constexpr int kCombos = 9;
    static constexpr int kMaxCmds = kCases * kCombos * 6;
    static constexpr int kTimeoutCycles = 400000;

    void init_pool() {
        static constexpr std::array<uint16_t, 32> pattern{{
            0x3c00, 0xbc00, 0x4000, 0xc000, 0x4200, 0xc200, 0x3e00, 0xbe00,
            0x3800, 0xb800, 0x3400, 0xb400, 0x3555, 0xb555, 0x39ab, 0xb9ab,
            0x3d55, 0xbd55, 0x3a80, 0xba80, 0x3d99, 0xbd99, 0x4123, 0xc123,
            0x3c00, 0xbc00, 0x2c00, 0xac00, 0x1c00, 0x9c00, 0x0400, 0x8400,
        }};
        for (int i = 0; i < static_cast<int>(fp_pool_.size()); ++i) {
            fp_pool_[static_cast<size_t>(i)] = pattern[static_cast<size_t>(i % pattern.size())];
        }
    }

    uint16_t pick_fp(int seed) const {
        int idx = seed % static_cast<int>(fp_pool_.size());
        if (idx < 0) idx += static_cast<int>(fp_pool_.size());
        return fp_pool_[static_cast<size_t>(idx)];
    }

    void open_csvs() {
        gemm_in_.open(out_dir_ / "tb_core_top_macarray_gemm_input.csv");
        gemm_out_.open(out_dir_ / "tb_core_top_macarray_gemm_output.csv");
        gemv_in_.open(out_dir_ / "tb_core_top_macarray_gemv_input.csv");
        gemv_out_.open(out_dir_ / "tb_core_top_macarray_gemv_output.csv");
        dot_in_.open(out_dir_ / "tb_core_top_macarray_gevv_dot_input.csv");
        dot_out_.open(out_dir_ / "tb_core_top_macarray_gevv_dot_output.csv");
        outer_in_.open(out_dir_ / "tb_core_top_macarray_gevv_outer_input.csv");
        outer_out_.open(out_dir_ / "tb_core_top_macarray_gevv_outer_output.csv");
        mul_in_.open(out_dir_ / "tb_core_top_macarray_mul_input.csv");
        mul_out_.open(out_dir_ / "tb_core_top_macarray_mul_output.csv");
        add_in_.open(out_dir_ / "tb_core_top_macarray_add_input.csv");
        add_out_.open(out_dir_ / "tb_core_top_macarray_add_output.csv");
        if (!gemm_in_ || !gemm_out_ || !gemv_in_ || !gemv_out_ || !dot_in_ || !dot_out_ ||
            !outer_in_ || !outer_out_ || !mul_in_ || !mul_out_ || !add_in_ || !add_out_) {
            throw std::runtime_error("failed to open macarray CSV files");
        }
    }

    void wait_for_done_count(int target) {
#ifdef DEXMPC_USE_TOPCHIP_SIM
        topchip_wait_for_done_count(target, kTimeoutCycles);
        done_count_ = target;
        expected_done_ = target;
        last_done_count_ = sim_.dut()->io_doneCount_0;
#else
        int cycles = 0;
        while (done_count_ < target) {
            tick();
            if (++cycles > kTimeoutCycles) {
                throw std::runtime_error("macarray timeout waiting for done_count");
            }
        }
#endif
    }

    void issue_gemm_cmd(int n_rows, int m_cols, int k_dim,
                        int base_a, int base_b, int base_c,
                        int mem_a, int mem_b, int mem_c, bool group_end) {
        if (next_cmd_id_ >= kMaxCmds) throw std::runtime_error("macarray command id overflow");
        const Cmd96 cmd = make_cmd(
            static_cast<uint32_t>(next_cmd_id_),
            kOpLa,
            kSubGemm,
            group_end,
            pack_addr(mem_a, base_a),
            pack_addr(mem_b, base_b),
            pack_addr(mem_c, base_c),
            m_cols,
            n_rows,
            k_dim);
        expected_subop_[static_cast<size_t>(next_cmd_id_)] = kSubGemm;
        push_cmd(cmd);
        ++next_cmd_id_;
    }

    void issue_mul_cmd(int rows, int cols, uint16_t alpha,
                       int base_a, int base_c, int mem_a, int mem_c, bool group_end) {
        if (next_cmd_id_ >= kMaxCmds) throw std::runtime_error("macarray command id overflow");
        const Cmd96 cmd = make_cmd(
            static_cast<uint32_t>(next_cmd_id_),
            kOpLa,
            kSubMul,
            group_end,
            pack_addr(mem_a, base_a),
            pack_addr(mem_c, base_c),
            alpha & 0x1fff,
            rows,
            cols,
            (alpha >> 13) & 0x7);
        expected_subop_[static_cast<size_t>(next_cmd_id_)] = kSubMul;
        push_cmd(cmd);
        ++next_cmd_id_;
    }

    void issue_add_cmd(int rows, int cols,
                       int base_a, int base_b, int base_c,
                       int mem_a, int mem_b, int mem_c, bool group_end) {
        if (next_cmd_id_ >= kMaxCmds) throw std::runtime_error("macarray command id overflow");
        const Cmd96 cmd = make_cmd(
            static_cast<uint32_t>(next_cmd_id_),
            kOpLa,
            kSubAdd,
            group_end,
            pack_addr(mem_a, base_a),
            pack_addr(mem_b, base_b),
            pack_addr(mem_c, base_c),
            rows,
            cols,
            0);
        expected_subop_[static_cast<size_t>(next_cmd_id_)] = kSubAdd;
        push_cmd(cmd);
        ++next_cmd_id_;
    }

    void check_range(int mem_id, int base, int words, const std::string& label) const {
        if (base < 0 || base + words > sram_depth(mem_id)) {
            throw std::runtime_error(label + " SRAM overflow");
        }
    }

    void write_matrix_to_mem(int mem_id, int base, const Matrix& m, int rows, int cols) {
        write_words_to_mem(mem_id, base, matrix_to_words(m, rows, cols));
    }

    Matrix read_matrix_from_mem(int mem_id, int base, int rows, int cols) {
        const int words = ceil_div(rows * cols, kFp16PerWord);
        return words_to_matrix(read_words_from_mem(mem_id, base, words), rows, cols);
    }

    static void write_matrix_csv(std::ofstream& f, int case_id, const std::string& name,
                                 int rows, int cols, const Matrix& m) {
        f << "case," << case_id << "," << name << ",rows," << rows << ",cols," << cols << "\n";
        for (int r = 0; r < rows; ++r) {
            f << "row" << r;
            for (int c = 0; c < cols; ++c) {
                f << "," << bin_value(m[static_cast<size_t>(r)][static_cast<size_t>(c)], 16);
            }
            f << "\n";
        }
        f << "\n";
    }

    static void write_vector_csv_col(std::ofstream& f, int case_id, const std::string& name,
                                     int len, const std::vector<uint16_t>& v) {
        f << "case," << case_id << "," << name << ",rows," << len << ",cols,1\n";
        for (int i = 0; i < len; ++i) {
            f << "row" << i << "," << bin_value(v[static_cast<size_t>(i)], 16) << "\n";
        }
        f << "\n";
    }

    static void write_vector_csv_row(std::ofstream& f, int case_id, const std::string& name,
                                     int len, const std::vector<uint16_t>& v) {
        f << "case," << case_id << "," << name << ",rows,1,cols," << len << "\n";
        f << "row0";
        for (int i = 0; i < len; ++i) {
            f << "," << bin_value(v[static_cast<size_t>(i)], 16);
        }
        f << "\n\n";
    }

    static void write_scalar_csv(std::ofstream& f, int case_id, uint16_t alpha) {
        f << "case," << case_id << ",scalar,alpha," << bin_value(alpha, 16) << "\n";
    }

    std::array<int, 3> gemm_dims(int case_id) const {
        static constexpr std::array<int, kCases> n{{1, 2, 3, 4, 5, 6, 7, 8, 9, 16}};
        static constexpr std::array<int, kCases> m{{1, 3, 5, 7, 9, 2, 4, 6, 8, 16}};
        static constexpr std::array<int, kCases> k{{1, 4, 2, 8, 3, 6, 5, 7, 10, 16}};
        return {n[static_cast<size_t>(case_id)], m[static_cast<size_t>(case_id)], k[static_cast<size_t>(case_id)]};
    }

    std::array<int, 2> gemv_dims(int case_id) const {
        static constexpr std::array<int, kCases> n{{1, 2, 4, 6, 8, 10, 12, 14, 15, 16}};
        static constexpr std::array<int, kCases> k{{1, 3, 5, 7, 9, 2, 4, 6, 8, 16}};
        return {n[static_cast<size_t>(case_id)], k[static_cast<size_t>(case_id)]};
    }

    int dot_dim(int case_id) const {
        static constexpr std::array<int, kCases> k{{1, 2, 3, 4, 5, 7, 9, 12, 15, 16}};
        return k[static_cast<size_t>(case_id)];
    }

    std::array<int, 2> nm_dims(int case_id) const {
        static constexpr std::array<int, kCases> n{{1, 2, 3, 4, 5, 7, 9, 11, 13, 16}};
        static constexpr std::array<int, kCases> m{{1, 3, 5, 7, 9, 2, 4, 6, 8, 16}};
        return {n[static_cast<size_t>(case_id)], m[static_cast<size_t>(case_id)]};
    }

    void run_gemm() {
        for (int case_id = 0; case_id < kCases; ++case_id) {
            const auto [n, m, k] = gemm_dims(case_id);
            Matrix a = make_matrix(n, k);
            Matrix b = make_matrix(k, m);
            for (int r = 0; r < n; ++r) {
                for (int c = 0; c < k; ++c) a[r][c] = pick_fp(case_id * 131 + r * 17 + c * 7);
            }
            for (int r = 0; r < k; ++r) {
                for (int c = 0; c < m; ++c) b[r][c] = pick_fp(case_id * 197 + r * 11 + c * 13 + 5);
            }
            run_gemm_like(case_id, n, m, k, a, b, gemm_in_, gemm_out_, "GEMM");
        }
    }

    void run_gemv() {
        for (int case_id = 0; case_id < kCases; ++case_id) {
            const auto [n, k] = gemv_dims(case_id);
            Matrix a = make_matrix(n, k);
            Matrix b = make_matrix(k, 1);
            std::vector<uint16_t> vec_b(static_cast<size_t>(k), 0);
            for (int r = 0; r < n; ++r) {
                for (int c = 0; c < k; ++c) a[r][c] = pick_fp(case_id * 131 + r * 17 + c * 7);
            }
            for (int r = 0; r < k; ++r) {
                vec_b[static_cast<size_t>(r)] = pick_fp(case_id * 197 + r * 11 + 5);
                b[r][0] = vec_b[static_cast<size_t>(r)];
            }
            run_gemm_like(case_id, n, 1, k, a, b, gemv_in_, gemv_out_, "GEMV", &vec_b);
        }
    }

    void run_dot() {
        for (int case_id = 0; case_id < kCases; ++case_id) {
            const int k = dot_dim(case_id);
            Matrix a = make_matrix(1, k);
            Matrix b = make_matrix(k, 1);
            std::vector<uint16_t> vec_a(static_cast<size_t>(k), 0);
            std::vector<uint16_t> vec_b(static_cast<size_t>(k), 0);
            for (int i = 0; i < k; ++i) {
                vec_a[static_cast<size_t>(i)] = pick_fp(case_id * 131 + i * 17);
                vec_b[static_cast<size_t>(i)] = pick_fp(case_id * 197 + i * 13 + 5);
                a[0][i] = vec_a[static_cast<size_t>(i)];
                b[i][0] = vec_b[static_cast<size_t>(i)];
            }
            run_gemm_like(case_id, 1, 1, k, a, b, dot_in_, dot_out_, "DOT", &vec_b, &vec_a);
        }
    }

    void run_outer() {
        for (int case_id = 0; case_id < kCases; ++case_id) {
            const auto [n, m] = nm_dims(case_id);
            Matrix a = make_matrix(n, 1);
            Matrix b = make_matrix(1, m);
            std::vector<uint16_t> vec_a(static_cast<size_t>(n), 0);
            std::vector<uint16_t> vec_b(static_cast<size_t>(m), 0);
            for (int i = 0; i < n; ++i) {
                vec_a[static_cast<size_t>(i)] = pick_fp(case_id * 131 + i * 17);
                a[i][0] = vec_a[static_cast<size_t>(i)];
            }
            for (int i = 0; i < m; ++i) {
                vec_b[static_cast<size_t>(i)] = pick_fp(case_id * 197 + i * 13 + 5);
                b[0][i] = vec_b[static_cast<size_t>(i)];
            }
            run_gemm_like(case_id, n, m, 1, a, b, outer_in_, outer_out_, "OUTER", &vec_b, &vec_a);
        }
    }

    void run_gemm_like(int case_id, int n, int m, int k, const Matrix& a, const Matrix& b,
                       std::ofstream& in_csv, std::ofstream& out_csv, const std::string& label,
                       const std::vector<uint16_t>* vec_b = nullptr,
                       const std::vector<uint16_t>* vec_a = nullptr) {
        const int elems_a = n * k;
        const int elems_b = k * m;
        const int elems_c = n * m;
        const int words_a = ceil_div(elems_a, kFp16PerWord);
        const int words_b = ceil_div(elems_b, kFp16PerWord);
        const int words_c = ceil_div(elems_c, kFp16PerWord);
        const int base_a = 0;
        const int base_b = words_a;

        for (int in_id = 0; in_id < 3; ++in_id) {
            check_range(in_id, base_a, words_a, label + " A");
            check_range(in_id, base_b, words_b, label + " B");
            write_matrix_to_mem(in_id, base_a, a, n, k);
            write_matrix_to_mem(in_id, base_b, b, k, m);

            for (int out_id = 0; out_id < 3; ++out_id) {
                const int combo = in_id * 3 + out_id;
                const int case_tag = case_id * kCombos + combo;
                const int base_c = (in_id == out_id) ? (base_b + words_b) : 0;
                check_range(out_id, base_c, words_c, label + " C");

                if (label == "GEMV") {
                    write_matrix_csv(in_csv, case_tag, "A", n, k, a);
                    write_vector_csv_col(in_csv, case_tag, "B", k, *vec_b);
                } else if (label == "DOT") {
                    write_vector_csv_row(in_csv, case_tag, "A", k, *vec_a);
                    write_vector_csv_col(in_csv, case_tag, "B", k, *vec_b);
                } else if (label == "OUTER") {
                    write_vector_csv_col(in_csv, case_tag, "A", n, *vec_a);
                    write_vector_csv_row(in_csv, case_tag, "B", m, *vec_b);
                } else {
                    write_matrix_csv(in_csv, case_tag, "A", n, k, a);
                    write_matrix_csv(in_csv, case_tag, "B", k, m, b);
                }
                clear_mem_range(out_id, base_c, elems_c);
            }

            for (int i = 0; i < 2; ++i) tick();
            const int done_target = done_count_ + 3;
            for (int out_id = 0; out_id < 3; ++out_id) {
                const int base_c = (in_id == out_id) ? (base_b + words_b) : 0;
                issue_gemm_cmd(n, m, k, base_a, base_b, base_c, in_id, in_id, out_id, out_id == 2);
            }
            wait_for_done_count(done_target);
            tick();

            for (int i = 0; i < 2; ++i) tick();
            for (int out_id = 0; out_id < 3; ++out_id) {
                const int combo = in_id * 3 + out_id;
                const int case_tag = case_id * kCombos + combo;
                const int base_c = (in_id == out_id) ? (base_b + words_b) : 0;
                Matrix c = read_matrix_from_mem(out_id, base_c, n, m);
                if (label == "GEMV") {
                    std::vector<uint16_t> vec_c(static_cast<size_t>(n), 0);
                    for (int r = 0; r < n; ++r) vec_c[static_cast<size_t>(r)] = c[r][0];
                    write_vector_csv_col(out_csv, case_tag, "C", n, vec_c);
                } else {
                    write_matrix_csv(out_csv, case_tag, "C", n, m, c);
                }
                clear_mem_range(out_id, base_c, elems_c);
            }
            clear_mem_range(in_id, base_a, elems_a);
            clear_mem_range(in_id, base_b, elems_b);
        }
    }

    void run_mul() {
        for (int case_id = 0; case_id < kCases; ++case_id) {
            const auto [n, m] = nm_dims(case_id);
            const int elems_a = n * m;
            const int elems_c = n * m;
            const int words_a = ceil_div(elems_a, kFp16PerWord);
            const int words_c = ceil_div(elems_c, kFp16PerWord);
            const int base_a = 0;
            const uint16_t alpha = pick_fp(case_id * 193 + 17);

            Matrix a = make_matrix(n, m);
            for (int r = 0; r < n; ++r) {
                for (int c = 0; c < m; ++c) a[r][c] = pick_fp(case_id * 131 + r * 17 + c * 29 + 7);
            }

            for (int in_id = 0; in_id < 3; ++in_id) {
                check_range(in_id, base_a, words_a, "MUL A");
                write_matrix_to_mem(in_id, base_a, a, n, m);

                for (int out_id = 0; out_id < 3; ++out_id) {
                    const int case_tag = case_id * kCombos + in_id * 3 + out_id;
                    const int base_c = (in_id == out_id) ? words_a : 0;
                    check_range(out_id, base_c, words_c, "MUL C");
                    write_scalar_csv(mul_in_, case_tag, alpha);
                    write_matrix_csv(mul_in_, case_tag, "A", n, m, a);
                    clear_mem_range(out_id, base_c, elems_c);
                }

                for (int i = 0; i < 2; ++i) tick();
                const int done_target = done_count_ + 3;
                for (int out_id = 0; out_id < 3; ++out_id) {
                    const int base_c = (in_id == out_id) ? words_a : 0;
                    issue_mul_cmd(n, m, alpha, base_a, base_c, in_id, out_id, out_id == 2);
                }
                wait_for_done_count(done_target);
                tick();

                for (int i = 0; i < 2; ++i) tick();
                for (int out_id = 0; out_id < 3; ++out_id) {
                    const int case_tag = case_id * kCombos + in_id * 3 + out_id;
                    const int base_c = (in_id == out_id) ? words_a : 0;
                    Matrix c = read_matrix_from_mem(out_id, base_c, n, m);
                    write_matrix_csv(mul_out_, case_tag, "C", n, m, c);
                    clear_mem_range(out_id, base_c, elems_c);
                }
                clear_mem_range(in_id, base_a, elems_a);
            }
        }
    }

    void run_add() {
        for (int case_id = 0; case_id < kCases; ++case_id) {
            const auto [n, m] = nm_dims(case_id);
            const int elems = n * m;
            const int words = ceil_div(elems, kFp16PerWord);
            const int base_a = 0;
            const int base_b = words;

            Matrix a = make_matrix(n, m);
            Matrix b = make_matrix(n, m);
            for (int r = 0; r < n; ++r) {
                for (int c = 0; c < m; ++c) {
                    a[r][c] = pick_fp(case_id * 131 + r * 17 + c * 29 + 7);
                    b[r][c] = pick_fp(case_id * 173 + r * 23 + c * 31 + 11);
                }
            }

            for (int in_id = 0; in_id < 3; ++in_id) {
                check_range(in_id, base_a, words, "ADD A");
                check_range(in_id, base_b, words, "ADD B");
                write_matrix_to_mem(in_id, base_a, a, n, m);
                write_matrix_to_mem(in_id, base_b, b, n, m);

                for (int out_id = 0; out_id < 3; ++out_id) {
                    const int case_tag = case_id * kCombos + in_id * 3 + out_id;
                    const int base_c = (in_id == out_id) ? (base_b + words) : 0;
                    check_range(out_id, base_c, words, "ADD C");
                    write_matrix_csv(add_in_, case_tag, "A", n, m, a);
                    write_matrix_csv(add_in_, case_tag, "B", n, m, b);
                    clear_mem_range(out_id, base_c, elems);
                }

                for (int i = 0; i < 2; ++i) tick();
                const int done_target = done_count_ + 3;
                for (int out_id = 0; out_id < 3; ++out_id) {
                    const int base_c = (in_id == out_id) ? (base_b + words) : 0;
                    issue_add_cmd(n, m, base_a, base_b, base_c, in_id, in_id, out_id, out_id == 2);
                }
                wait_for_done_count(done_target);
                tick();

                for (int i = 0; i < 2; ++i) tick();
                for (int out_id = 0; out_id < 3; ++out_id) {
                    const int case_tag = case_id * kCombos + in_id * 3 + out_id;
                    const int base_c = (in_id == out_id) ? (base_b + words) : 0;
                    Matrix c = read_matrix_from_mem(out_id, base_c, n, m);
                    write_matrix_csv(add_out_, case_tag, "C", n, m, c);
                    clear_mem_range(out_id, base_c, elems);
                }
                clear_mem_range(in_id, base_a, elems);
                clear_mem_range(in_id, base_b, elems);
            }
        }
    }

    std::filesystem::path out_dir_;
    std::array<uint16_t, 96> fp_pool_{};
    std::array<uint32_t, kMaxCmds> expected_subop_{};
    int next_cmd_id_ = 0;
    int expected_done_ = 0;
    int done_count_ = 0;
    uint32_t last_done_count_ = 0;

    std::ofstream gemm_in_;
    std::ofstream gemm_out_;
    std::ofstream gemv_in_;
    std::ofstream gemv_out_;
    std::ofstream dot_in_;
    std::ofstream dot_out_;
    std::ofstream outer_in_;
    std::ofstream outer_out_;
    std::ofstream mul_in_;
    std::ofstream mul_out_;
    std::ofstream add_in_;
    std::ofstream add_out_;
};

} // namespace

int main(int argc, char** argv) {
    try {
        Sim sim(argc, argv);
        MacArrayTest test(sim, DEXMPC_RESULT_DIR);
        test.run();
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "MacArray simulation failed: " << e.what() << "\n";
        return 1;
    }
}
