#include "../common/dexmpc_sim.hpp"

#include <array>

using namespace dexsim;

namespace {

enum CaseKind {
    kKindAbs = 0,
    kKindLayoutTranspose = 1,
    kKindLayoutAssemble = 2,
    kKindReduceAdd = 3,
    kKindReduceCmp = 4,
    kKindGemm = 5,
    kKindMul = 6,
    kKindAdd = 7,
};

struct MixedCase {
    int kind = 0;
    uint32_t opcode = 0;
    uint32_t subop = 0;
    uint32_t cmd_id = 0;
    Cmd96 cmd = 0;

    int src_mem = kMemGlobal;
    int aux_mem = kMemGlobal;
    int dst_mem = kMemGlobal;
    int src_base = 0;
    int aux_base = 0;
    int dst_base = 0;
    int rows = 0;
    int cols = 0;
    int kdim = 0;
    int dst_rows = 0;
    int dst_cols = 0;
    int len = 0;
    int off_r = 0;
    int off_c = 0;
    uint16_t alpha = 0;

    int src_elems = 0;
    int aux_elems = 0;
    int dst_elems = 0;
    int src_words = 0;
    int aux_words = 0;
    int dst_words = 0;

    std::array<Word128, 64> pre_src{};
    std::array<Word128, 64> pre_aux{};
    std::array<Word128, 64> pre_dst{};
    std::array<Word128, 64> post_dst{};

    uint16_t reduce_value = 0;
    uint16_t reduce_index = 0;
    bool reduce_seen = false;
    bool done_seen = false;
};

class MixedTest : public TestBase {
public:
    MixedTest(Sim& sim, std::filesystem::path out_dir)
        : TestBase(sim), out_dir_(std::move(out_dir)) {}

    void run() {
        std::filesystem::create_directories(out_dir_);
        build_cases();
        open_csvs();
        write_csv_headers();
        for (int cid = 0; cid < num_cases_; ++cid) {
            log_case_input(cid);
        }

        for (int i = 0; i < 4; ++i) tick_raw();
        preload_cases_to_sram();

        for (int i = 0; i < 4; ++i) tick_raw();
        sim_.dut()->reset = 0;
        for (int i = 0; i < 2; ++i) tick();

        push_initial_burst(kBurstFillCmds);
        int cycles = 0;
        while (!saw_fifo_full_ && cycles < 400) {
            tick();
            ++cycles;
        }
        if (!saw_fifo_full_) {
            throw std::runtime_error("mixed FIFO full was never observed, max count=" +
                                     std::to_string(max_fifo_count_));
        }

        for (int cid = kBurstFillCmds; cid < num_cases_; ++cid) {
            push_cmd(cases_[static_cast<size_t>(cid)].cmd);
        }

        cycles = 0;
        while (done_count_ < num_cases_ && cycles < kTimeoutCycles) {
            tick();
            ++cycles;
        }
        if (done_count_ < num_cases_) {
            throw std::runtime_error("mixed timeout waiting for done_count");
        }

        for (int i = 0; i < 8; ++i) tick();
        auto* d = sim_.dut();
        if ((d->io_cmdStatus_0 & (1u << 4)) == 0) {
            throw std::runtime_error("mixed core0 all_done bit not set");
        }
        if ((d->io_allDoneReg & 0x1u) == 0) {
            throw std::runtime_error("mixed allDoneReg bit0 not set");
        }
        if ((d->io_engineStatus & 0xfu) != 0) {
            throw std::runtime_error("mixed engineStatus still busy");
        }

        for (int cid = 0; cid < num_cases_; ++cid) {
            capture_case_output(cid);
            log_case_output(cid);
        }

        std::cout << "Mixed C++ test passed at cycle " << sim_.cycle()
                  << ", cases=" << num_cases_
                  << ", max_fifo_count=" << max_fifo_count_ << "\n";
    }

protected:
    void monitor_done() override {
        auto* d = sim_.dut();
        if (d->reset) return;

        if ((d->io_cmdStatus_0 & 0x1u) != 0) saw_fifo_full_ = true;
        const int fifo_count = static_cast<int>((d->io_cmdStatus_0 >> 8) & 0xffu);
        if (fifo_count > max_fifo_count_) max_fifo_count_ = fifo_count;
        if ((d->io_cmdStatus_0 & (1u << 5)) != 0) {
            throw std::runtime_error("mixed cmdStatus overflow set unexpectedly");
        }

        if (d->io_doneCount_0 == last_done_count_) return;
        if (d->io_doneCount_0 != last_done_count_ + 1) {
            throw std::runtime_error("mixed doneCount jump");
        }

        const uint32_t last = d->io_lastDone_0;
        const uint32_t done_cmd_id = last & 0xfffu;
        const uint32_t done_opcode = (last >> 12) & 0x7u;
        const uint32_t done_subop = (last >> 15) & 0xfu;
        const bool done_group_end = ((last >> 19) & 1u) != 0;
        const bool done_illegal = ((last >> 20) & 1u) != 0;
        const int done_idx = static_cast<int>(done_cmd_id);

        if (done_illegal) throw std::runtime_error("mixed illegal command reported");
        if (done_idx < 0 || done_idx >= num_cases_) throw std::runtime_error("mixed done cmd id out of range");
        if (done_cmd_id != static_cast<uint32_t>(expected_done_)) {
            throw std::runtime_error("mixed doneCmdId out of order");
        }

        auto& c = cases_[static_cast<size_t>(done_idx)];
        if (done_opcode != c.opcode) throw std::runtime_error("mixed done opcode mismatch");
        if (done_subop != c.subop) throw std::runtime_error("mixed done subop mismatch");
        if (done_group_end != (done_idx == num_cases_ - 1)) {
            throw std::runtime_error("mixed done group_end mismatch");
        }

        if (c.kind == kKindReduceAdd) {
            const uint32_t reg = d->io_addReduceReg_0;
            const uint16_t val = static_cast<uint16_t>(reg & 0xffffu);
            const uint32_t cmd = (reg >> 16) & 0xfffu;
            const bool valid = ((reg >> 28) & 1u) != 0;
            if (!valid) throw std::runtime_error("mixed addReduce valid not set");
            if (cmd != done_cmd_id) throw std::runtime_error("mixed addReduce cmd id mismatch");
            c.reduce_value = val;
            c.reduce_index = 0;
            c.reduce_seen = true;
        } else if (c.kind == kKindReduceCmp) {
            const uint32_t reg0 = d->io_cmpReduceReg0_0;
            const uint32_t reg1 = d->io_cmpReduceReg1_0;
            const uint16_t val = static_cast<uint16_t>(reg0 & 0xffffu);
            const uint32_t cmd = (reg0 >> 16) & 0xfffu;
            const bool valid = ((reg0 >> 28) & 1u) != 0;
            const uint16_t idx = static_cast<uint16_t>(reg1 & 0xfffu);
            if (!valid) throw std::runtime_error("mixed cmpReduce valid not set");
            if (cmd != done_cmd_id) throw std::runtime_error("mixed cmpReduce cmd id mismatch");
            c.reduce_value = val;
            c.reduce_index = idx;
            c.reduce_seen = true;
        }

        c.done_seen = true;
        ++done_count_;
        ++expected_done_;
        last_done_count_ = d->io_doneCount_0;
    }

private:
    static constexpr int kMaxCases = 40;
    static constexpr int kMaxWords = 64;
    static constexpr int kMaxReduceElems = 32;
    static constexpr int kFifoDepth = 32;
    static constexpr int kBurstFillCmds = kFifoDepth + 1;
    static constexpr int kTimeoutCycles = 1200000;

    static constexpr uint16_t kFp16Zero = 0x0000;
    static constexpr uint16_t kFp16Half = 0x3800;
    static constexpr uint16_t kFp16One = 0x3c00;
    static constexpr uint16_t kFp16Two = 0x4000;
    static constexpr uint16_t kFp16Three = 0x4200;
    static constexpr uint16_t kFp16Four = 0x4400;
    static constexpr uint16_t kFp16Five = 0x4500;
    static constexpr uint16_t kFp16Six = 0x4600;
    static constexpr uint16_t kFp16Seven = 0x4700;
    static constexpr uint16_t kFp16Eight = 0x4800;
    static constexpr uint16_t kFp16NegHalf = 0xb800;
    static constexpr uint16_t kFp16NegOne = 0xbc00;
    static constexpr uint16_t kFp16NegTwo = 0xc000;
    static constexpr uint16_t kFp16NegThree = 0xc200;
    static constexpr uint16_t kFp16NegFive = 0xc500;

    uint16_t pick_pos_fp(int idx) const {
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

    uint16_t pick_abs_fp(int idx) const {
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

    void clear_word_vec(std::array<Word128, kMaxWords>& words) {
        for (auto& word : words) word = zero_word();
    }

    Matrix fill_pattern_matrix(int rows, int cols, int seed, bool use_abs_pattern) const {
        Matrix mat = make_matrix(rows, cols);
        for (int r = 0; r < rows; ++r) {
            for (int c = 0; c < cols; ++c) {
                mat[static_cast<size_t>(r)][static_cast<size_t>(c)] =
                    use_abs_pattern ? pick_abs_fp(seed + r * cols + c)
                                    : pick_pos_fp(seed + r * cols + c);
            }
        }
        return mat;
    }

    int copy_words(std::array<Word128, kMaxWords>& dst, const std::vector<Word128>& src) {
        clear_word_vec(dst);
        if (src.size() > dst.size()) throw std::runtime_error("mixed word vector overflow");
        for (size_t i = 0; i < src.size(); ++i) dst[i] = src[i];
        return static_cast<int>(src.size());
    }

    int pack_matrix_words(std::array<Word128, kMaxWords>& dst, const Matrix& mat, int rows, int cols) {
        return copy_words(dst, matrix_to_words(mat, rows, cols));
    }

    int pack_vector_words(std::array<Word128, kMaxWords>& dst, const std::vector<uint16_t>& vec, int len) {
        std::vector<uint16_t> elems(vec.begin(), vec.begin() + len);
        return copy_words(dst, pack_elements(elems));
    }

    uint16_t get_word_vec_elem(const std::array<Word128, kMaxWords>& words, int elem_idx) const {
        if (elem_idx < 0) return 0;
        const int word_idx = elem_idx / kFp16PerWord;
        const int lane_idx = elem_idx % kFp16PerWord;
        if (word_idx >= kMaxWords) return 0;
        return get_fp16_lane(words[static_cast<size_t>(word_idx)], lane_idx);
    }

    void reserve_base(int mem_id, int words, int& base) {
        const int delta = words <= 0 ? 1 : words;
        if (mem_id == kMemGlobal) {
            base = next_global_;
            next_global_ += delta + 1;
        } else if (mem_id == kMemLocal0) {
            base = next_local_;
            next_local_ += delta + 1;
        } else if (mem_id == kMemTemp0) {
            base = next_temp_;
            next_temp_ += delta + 1;
        } else {
            throw std::runtime_error("mixed unknown SRAM id");
        }
        if (next_global_ >= kGlobalDepth || next_local_ >= kLocalDepth || next_temp_ >= kTempDepth) {
            throw std::runtime_error("mixed SRAM allocation overflow");
        }
        check_mem_addr(mem_id, base + delta - 1);
    }

    MixedCase& new_case() {
        if (num_cases_ >= kMaxCases) throw std::runtime_error("mixed MAX_CASES overflow");
        auto& c = cases_[static_cast<size_t>(num_cases_)];
        c = MixedCase{};
        clear_word_vec(c.pre_src);
        clear_word_vec(c.pre_aux);
        clear_word_vec(c.pre_dst);
        clear_word_vec(c.post_dst);
        c.cmd_id = static_cast<uint32_t>(num_cases_);
        ++num_cases_;
        return c;
    }

    void add_abs_case(int src_mem, int dst_mem, int rows, int cols, int seed) {
        auto& c = new_case();
        c.kind = kKindAbs;
        c.opcode = kOpAbs;
        c.subop = kSubAbs;
        c.src_mem = src_mem;
        c.dst_mem = dst_mem;
        c.rows = rows;
        c.cols = cols;
        c.dst_rows = rows;
        c.dst_cols = cols;
        c.src_elems = rows * cols;
        c.dst_elems = rows * cols;
        c.src_words = ceil_div(c.src_elems, kFp16PerWord);
        c.dst_words = ceil_div(c.dst_elems, kFp16PerWord);
        reserve_base(src_mem, c.src_words, c.src_base);
        reserve_base(dst_mem, c.dst_words, c.dst_base);

        Matrix src = fill_pattern_matrix(rows, cols, seed, true);
        c.src_words = pack_matrix_words(c.pre_src, src, rows, cols);
        c.cmd = make_cmd(c.cmd_id, kOpAbs, kSubAbs, false,
                         pack_addr(c.src_mem, c.src_base),
                         pack_addr(c.dst_mem, c.dst_base),
                         0, c.rows, c.cols, 0);
    }

    void add_layout_transpose_case(int src_mem, int dst_mem, int rows, int cols, int seed) {
        auto& c = new_case();
        c.kind = kKindLayoutTranspose;
        c.opcode = kOpDataLayout;
        c.subop = kSubTranspose;
        c.src_mem = src_mem;
        c.dst_mem = dst_mem;
        c.rows = rows;
        c.cols = cols;
        c.dst_rows = cols;
        c.dst_cols = rows;
        c.src_elems = rows * cols;
        c.dst_elems = cols * rows;
        c.src_words = ceil_div(c.src_elems, kFp16PerWord);
        c.dst_words = ceil_div(c.dst_elems, kFp16PerWord);
        reserve_base(src_mem, c.src_words, c.src_base);
        reserve_base(dst_mem, c.dst_words, c.dst_base);

        Matrix src = fill_pattern_matrix(rows, cols, seed, false);
        Matrix dst = fill_pattern_matrix(c.dst_rows, c.dst_cols, seed + 77, false);
        c.src_words = pack_matrix_words(c.pre_src, src, rows, cols);
        c.dst_words = pack_matrix_words(c.pre_dst, dst, c.dst_rows, c.dst_cols);
        c.cmd = make_cmd(c.cmd_id, kOpDataLayout, kSubTranspose, false,
                         pack_addr(c.src_mem, c.src_base),
                         pack_addr(c.dst_mem, c.dst_base),
                         0, c.rows, c.cols, 0);
    }

    void add_layout_assemble_case(int src_mem, int dst_mem, int src_rows, int src_cols,
                                  int off_r, int off_c, int seed) {
        auto& c = new_case();
        c.kind = kKindLayoutAssemble;
        c.opcode = kOpDataLayout;
        c.subop = kSubAssemble;
        c.src_mem = src_mem;
        c.dst_mem = dst_mem;
        c.rows = src_rows;
        c.cols = src_cols;
        c.off_r = off_r;
        c.off_c = off_c;
        c.dst_rows = src_rows + off_r;
        c.dst_cols = src_cols + off_c;
        c.src_elems = src_rows * src_cols;
        c.dst_elems = c.dst_rows * c.dst_cols;
        c.src_words = ceil_div(c.src_elems, kFp16PerWord);
        c.dst_words = ceil_div(c.dst_elems, kFp16PerWord);
        reserve_base(src_mem, c.src_words, c.src_base);
        reserve_base(dst_mem, c.dst_words, c.dst_base);

        Matrix src = fill_pattern_matrix(src_rows, src_cols, seed, false);
        Matrix dst = fill_pattern_matrix(c.dst_rows, c.dst_cols, seed + 131, false);
        c.src_words = pack_matrix_words(c.pre_src, src, src_rows, src_cols);
        c.dst_words = pack_matrix_words(c.pre_dst, dst, c.dst_rows, c.dst_cols);
        c.cmd = make_cmd(c.cmd_id, kOpDataLayout, kSubAssemble, false,
                         pack_addr(c.src_mem, c.src_base),
                         pack_addr(c.dst_mem, c.dst_base),
                         c.off_c & 0x7ff, c.rows, c.cols, c.off_r);
    }

    void add_reduce_add_case(int src_mem, int len) {
        auto& c = new_case();
        c.kind = kKindReduceAdd;
        c.opcode = kOpReduce;
        c.subop = kSubAddTree;
        c.src_mem = src_mem;
        c.len = len;
        c.src_elems = len;
        c.src_words = ceil_div(len, kFp16PerWord);
        reserve_base(src_mem, c.src_words, c.src_base);

        std::vector<uint16_t> vec(static_cast<size_t>(len), kFp16One);
        c.src_words = pack_vector_words(c.pre_src, vec, len);
        c.cmd = make_cmd(c.cmd_id, kOpReduce, kSubAddTree, false,
                         pack_addr(c.src_mem, c.src_base), 0, 0, c.len, 0, 0);
    }

    void add_reduce_cmp_case(int src_mem, int len, int min_idx, int seed) {
        auto& c = new_case();
        c.kind = kKindReduceCmp;
        c.opcode = kOpReduce;
        c.subop = kSubCmpReduce;
        c.src_mem = src_mem;
        c.len = len;
        c.src_elems = len;
        c.src_words = ceil_div(len, kFp16PerWord);
        reserve_base(src_mem, c.src_words, c.src_base);

        std::vector<uint16_t> vec(static_cast<size_t>(len), 0);
        for (int i = 0; i < len; ++i) {
            vec[static_cast<size_t>(i)] = pick_pos_fp(seed + i + 2);
            if (vec[static_cast<size_t>(i)] == kFp16Half) {
                vec[static_cast<size_t>(i)] = kFp16Three;
            }
        }
        vec[static_cast<size_t>(min_idx)] = kFp16Half;
        c.src_words = pack_vector_words(c.pre_src, vec, len);
        c.cmd = make_cmd(c.cmd_id, kOpReduce, kSubCmpReduce, false,
                         pack_addr(c.src_mem, c.src_base), 0, 0, c.len, 0, 0);
    }

    void add_gemm_identity_case(int a_mem, int b_mem, int c_mem,
                                int n_rows, int m_cols, int seed) {
        auto& c = new_case();
        c.kind = kKindGemm;
        c.opcode = kOpLa;
        c.subop = kSubGemm;
        c.src_mem = a_mem;
        c.aux_mem = b_mem;
        c.dst_mem = c_mem;
        c.rows = n_rows;
        c.cols = m_cols;
        c.kdim = n_rows;
        c.dst_rows = n_rows;
        c.dst_cols = m_cols;
        c.src_elems = n_rows * c.kdim;
        c.aux_elems = c.kdim * m_cols;
        c.dst_elems = n_rows * m_cols;
        c.src_words = ceil_div(c.src_elems, kFp16PerWord);
        c.aux_words = ceil_div(c.aux_elems, kFp16PerWord);
        c.dst_words = ceil_div(c.dst_elems, kFp16PerWord);
        reserve_base(a_mem, c.src_words, c.src_base);
        reserve_base(b_mem, c.aux_words, c.aux_base);
        reserve_base(c_mem, c.dst_words, c.dst_base);

        Matrix a = make_matrix(n_rows, c.kdim);
        for (int r = 0; r < n_rows; ++r) {
            for (int col = 0; col < c.kdim; ++col) {
                a[static_cast<size_t>(r)][static_cast<size_t>(col)] =
                    (r == col) ? kFp16One : kFp16Zero;
            }
        }
        Matrix b = fill_pattern_matrix(c.kdim, m_cols, seed, false);
        c.src_words = pack_matrix_words(c.pre_src, a, n_rows, c.kdim);
        c.aux_words = pack_matrix_words(c.pre_aux, b, c.kdim, m_cols);
        c.cmd = make_cmd(c.cmd_id, kOpLa, kSubGemm, false,
                         pack_addr(c.src_mem, c.src_base),
                         pack_addr(c.aux_mem, c.aux_base),
                         pack_addr(c.dst_mem, c.dst_base),
                         c.cols, c.rows, c.kdim);
    }

    void add_mul_copy_case(int a_mem, int c_mem, int rows, int cols, int seed) {
        auto& c = new_case();
        c.kind = kKindMul;
        c.opcode = kOpLa;
        c.subop = kSubMul;
        c.src_mem = a_mem;
        c.dst_mem = c_mem;
        c.rows = rows;
        c.cols = cols;
        c.dst_rows = rows;
        c.dst_cols = cols;
        c.alpha = kFp16One;
        c.src_elems = rows * cols;
        c.dst_elems = rows * cols;
        c.src_words = ceil_div(c.src_elems, kFp16PerWord);
        c.dst_words = ceil_div(c.dst_elems, kFp16PerWord);
        reserve_base(a_mem, c.src_words, c.src_base);
        reserve_base(c_mem, c.dst_words, c.dst_base);

        Matrix a = fill_pattern_matrix(rows, cols, seed, false);
        c.src_words = pack_matrix_words(c.pre_src, a, rows, cols);
        c.cmd = make_cmd(c.cmd_id, kOpLa, kSubMul, false,
                         pack_addr(c.src_mem, c.src_base),
                         pack_addr(c.dst_mem, c.dst_base),
                         c.alpha & 0x1fff, c.rows, c.cols, (c.alpha >> 13) & 0x7);
    }

    void add_add_zero_case(int a_mem, int b_mem, int c_mem, int rows, int cols, int seed) {
        auto& c = new_case();
        c.kind = kKindAdd;
        c.opcode = kOpLa;
        c.subop = kSubAdd;
        c.src_mem = a_mem;
        c.aux_mem = b_mem;
        c.dst_mem = c_mem;
        c.rows = rows;
        c.cols = cols;
        c.dst_rows = rows;
        c.dst_cols = cols;
        c.src_elems = rows * cols;
        c.aux_elems = rows * cols;
        c.dst_elems = rows * cols;
        c.src_words = ceil_div(c.src_elems, kFp16PerWord);
        c.aux_words = ceil_div(c.aux_elems, kFp16PerWord);
        c.dst_words = ceil_div(c.dst_elems, kFp16PerWord);
        reserve_base(a_mem, c.src_words, c.src_base);
        reserve_base(b_mem, c.aux_words, c.aux_base);
        reserve_base(c_mem, c.dst_words, c.dst_base);

        Matrix a = fill_pattern_matrix(rows, cols, seed, false);
        Matrix b = make_matrix(rows, cols);
        c.src_words = pack_matrix_words(c.pre_src, a, rows, cols);
        c.aux_words = pack_matrix_words(c.pre_aux, b, rows, cols);
        c.cmd = make_cmd(c.cmd_id, kOpLa, kSubAdd, false,
                         pack_addr(c.src_mem, c.src_base),
                         pack_addr(c.aux_mem, c.aux_base),
                         pack_addr(c.dst_mem, c.dst_base),
                         c.rows, c.cols, 0);
    }

    void build_cases() {
        num_cases_ = 0;
        next_global_ = 0;
        next_local_ = 0;
        next_temp_ = 0;

        add_gemm_identity_case(kMemGlobal, kMemLocal0, kMemTemp0, 16, 16, 1000);
        add_abs_case(kMemGlobal, kMemLocal0, 3, 5, 1100);
        add_reduce_add_case(kMemTemp0, 8);
        add_layout_transpose_case(kMemLocal0, kMemGlobal, 3, 4, 1200);
        add_mul_copy_case(kMemGlobal, kMemTemp0, 3, 6, 1300);
        add_reduce_cmp_case(kMemLocal0, 7, 3, 1400);
        add_layout_assemble_case(kMemTemp0, kMemGlobal, 2, 3, 1, 2, 1500);
        add_add_zero_case(kMemGlobal, kMemLocal0, kMemTemp0, 4, 4, 1600);
        add_abs_case(kMemTemp0, kMemGlobal, 2, 7, 1700);
        add_reduce_add_case(kMemGlobal, 4);
        add_gemm_identity_case(kMemLocal0, kMemTemp0, kMemGlobal, 8, 6, 1800);
        add_layout_transpose_case(kMemGlobal, kMemTemp0, 2, 6, 1900);
        add_abs_case(kMemLocal0, kMemTemp0, 4, 3, 2000);
        add_reduce_cmp_case(kMemGlobal, 8, 5, 2100);
        add_mul_copy_case(kMemTemp0, kMemLocal0, 5, 3, 2200);
        add_layout_assemble_case(kMemGlobal, kMemLocal0, 3, 2, 2, 1, 2300);
        add_abs_case(kMemGlobal, kMemGlobal, 1, 8, 2400);
        add_add_zero_case(kMemLocal0, kMemTemp0, kMemGlobal, 3, 5, 2500);
        add_reduce_add_case(kMemLocal0, 16);
        add_layout_transpose_case(kMemTemp0, kMemLocal0, 4, 2, 2600);
        add_gemm_identity_case(kMemGlobal, kMemTemp0, kMemLocal0, 4, 7, 2700);
        add_reduce_cmp_case(kMemTemp0, 5, 1, 2800);
        add_abs_case(kMemTemp0, kMemLocal0, 5, 2, 2900);
        add_layout_assemble_case(kMemLocal0, kMemTemp0, 2, 4, 1, 1, 3000);
        add_mul_copy_case(kMemLocal0, kMemGlobal, 2, 8, 3100);
        add_reduce_add_case(kMemTemp0, 8);
        add_add_zero_case(kMemGlobal, kMemTemp0, kMemLocal0, 2, 6, 3200);
        add_layout_transpose_case(kMemLocal0, kMemGlobal, 3, 3, 3300);
        add_abs_case(kMemGlobal, kMemTemp0, 6, 2, 3400);
        add_reduce_cmp_case(kMemLocal0, 9, 7, 3500);
        add_layout_assemble_case(kMemTemp0, kMemGlobal, 3, 3, 1, 3, 3600);
        add_abs_case(kMemLocal0, kMemGlobal, 2, 5, 3700);
        add_add_zero_case(kMemTemp0, kMemGlobal, kMemLocal0, 4, 3, 3800);
        add_reduce_cmp_case(kMemGlobal, 6, 2, 3900);

        if (num_cases_ < kBurstFillCmds) {
            throw std::runtime_error("mixed needs enough commands to validate FIFO full");
        }
        cases_[static_cast<size_t>(num_cases_ - 1)].cmd |= (Cmd96(1) << 76);
    }

    void preload_cases_to_sram() {
        for (int cid = 0; cid < num_cases_; ++cid) {
            const auto& c = cases_[static_cast<size_t>(cid)];
            for (int w = 0; w < c.dst_words; ++w) {
                mem_write_word(c.dst_mem, c.dst_base + w, c.pre_dst[static_cast<size_t>(w)]);
            }
            for (int w = 0; w < c.src_words; ++w) {
                mem_write_word(c.src_mem, c.src_base + w, c.pre_src[static_cast<size_t>(w)]);
            }
            for (int w = 0; w < c.aux_words; ++w) {
                mem_write_word(c.aux_mem, c.aux_base + w, c.pre_aux[static_cast<size_t>(w)]);
            }
        }
    }

    void push_initial_burst(int burst_count) {
        for (int cid = 0; cid < burst_count; ++cid) {
            push_cmd_raw(cases_[static_cast<size_t>(cid)].cmd);
        }
    }

    void capture_case_output(int cid) {
        auto& c = cases_[static_cast<size_t>(cid)];
        if (!c.done_seen) throw std::runtime_error("mixed missing done");
        if (c.kind == kKindReduceAdd || c.kind == kKindReduceCmp) {
            if (!c.reduce_seen) throw std::runtime_error("mixed missing reduce result");
            return;
        }
        clear_word_vec(c.post_dst);
        auto words = read_words_from_mem(c.dst_mem, c.dst_base, c.dst_words);
        for (int w = 0; w < c.dst_words; ++w) c.post_dst[static_cast<size_t>(w)] = words[static_cast<size_t>(w)];
    }

    void open_file(std::ofstream& f, const std::string& name) {
        f.open(out_dir_ / name);
        if (!f) throw std::runtime_error("failed to open " + name);
    }

    void open_csvs() {
        open_file(abs_in_, "tb_core_top_mixed_abs_input.csv");
        open_file(abs_out_, "tb_core_top_mixed_abs_output.csv");
        open_file(trans_in_, "tb_core_top_mixed_layout_transpose_input.csv");
        open_file(trans_out_, "tb_core_top_mixed_layout_transpose_output.csv");
        open_file(assem_in_, "tb_core_top_mixed_layout_assemble_input.csv");
        open_file(assem_out_, "tb_core_top_mixed_layout_assemble_output.csv");
        open_file(reduce_add_in_, "tb_core_top_mixed_reduce_add_input.csv");
        open_file(reduce_add_out_, "tb_core_top_mixed_reduce_add_output.csv");
        open_file(reduce_cmp_in_, "tb_core_top_mixed_reduce_cmp_input.csv");
        open_file(reduce_cmp_out_, "tb_core_top_mixed_reduce_cmp_output.csv");
        open_file(gemm_in_, "tb_core_top_mixed_gemm_input.csv");
        open_file(gemm_out_, "tb_core_top_mixed_gemm_output.csv");
        open_file(mul_in_, "tb_core_top_mixed_mul_input.csv");
        open_file(mul_out_, "tb_core_top_mixed_mul_output.csv");
        open_file(add_in_, "tb_core_top_mixed_add_input.csv");
        open_file(add_out_, "tb_core_top_mixed_add_output.csv");
    }

    void append_word_headers(std::ofstream& f, const std::string& prefix) const {
        for (int col = 0; col < kMaxWords; ++col) f << "," << prefix << "_" << col << "_bin";
    }

    void append_word_vec(std::ofstream& f, const std::array<Word128, kMaxWords>& words) const {
        for (const auto& word : words) f << "," << bin_word(word);
    }

    void append_elem_headers(std::ofstream& f, const std::string& prefix) const {
        for (int col = 0; col < kMaxReduceElems; ++col) f << "," << prefix << "_" << col << "_bin";
    }

    void append_reduce_elems(std::ofstream& f, const MixedCase& c) const {
        for (int col = 0; col < kMaxReduceElems; ++col) {
            f << "," << bin_value(get_word_vec_elem(c.pre_src, col), 16);
        }
    }

    void write_csv_headers() {
        abs_in_ << "cmd_id,case_id,src_mem,dst_mem,src_base_bin,dst_base_bin,rows_bin,cols_bin,src_words_bin,dst_words_bin";
        append_word_headers(abs_in_, "pre_src_word");
        append_word_headers(abs_in_, "pre_dst_word");
        abs_in_ << "\n";
        abs_out_ << "cmd_id,case_id,dst_mem,dst_base_bin,rows_bin,cols_bin,dst_words_bin";
        append_word_headers(abs_out_, "post_dst_word");
        abs_out_ << "\n";

        trans_in_ << "cmd_id,case_id,src_mem,dst_mem,src_base_bin,dst_base_bin,src_rows_bin,src_cols_bin,dst_rows_bin,dst_cols_bin,src_words_bin,dst_words_bin";
        append_word_headers(trans_in_, "pre_src_word");
        append_word_headers(trans_in_, "pre_dst_word");
        trans_in_ << "\n";
        trans_out_ << "cmd_id,case_id,dst_mem,dst_base_bin,src_rows_bin,src_cols_bin,dst_rows_bin,dst_cols_bin,dst_words_bin";
        append_word_headers(trans_out_, "post_dst_word");
        trans_out_ << "\n";

        assem_in_ << "cmd_id,case_id,src_mem,dst_mem,src_base_bin,dst_base_bin,src_rows_bin,src_cols_bin,dst_rows_bin,dst_cols_bin,offset_row_bin,offset_col_bin,src_words_bin,dst_words_bin";
        append_word_headers(assem_in_, "pre_src_word");
        append_word_headers(assem_in_, "pre_dst_word");
        assem_in_ << "\n";
        assem_out_ << "cmd_id,case_id,dst_mem,dst_base_bin,src_rows_bin,src_cols_bin,dst_rows_bin,dst_cols_bin,offset_row_bin,offset_col_bin,dst_words_bin";
        append_word_headers(assem_out_, "post_dst_word");
        assem_out_ << "\n";

        reduce_add_in_ << "cmd_id,case_id,src_mem,src_base_bin,len_bin,src_words_bin";
        append_elem_headers(reduce_add_in_, "in_elem");
        reduce_add_in_ << "\n";
        reduce_add_out_ << "cmd_id,case_id,result_value_bin,result_index_bin\n";

        reduce_cmp_in_ << "cmd_id,case_id,src_mem,src_base_bin,len_bin,src_words_bin";
        append_elem_headers(reduce_cmp_in_, "in_elem");
        reduce_cmp_in_ << "\n";
        reduce_cmp_out_ << "cmd_id,case_id,result_value_bin,result_index_bin\n";

        gemm_in_ << "cmd_id,case_id,a_mem,b_mem,c_mem,a_base_bin,b_base_bin,c_base_bin,n_rows_bin,m_cols_bin,k_dim_bin,a_words_bin,b_words_bin,c_words_bin";
        append_word_headers(gemm_in_, "pre_a_word");
        append_word_headers(gemm_in_, "pre_b_word");
        gemm_in_ << "\n";
        gemm_out_ << "cmd_id,case_id,c_mem,c_base_bin,n_rows_bin,m_cols_bin,k_dim_bin,c_words_bin";
        append_word_headers(gemm_out_, "post_c_word");
        gemm_out_ << "\n";

        mul_in_ << "cmd_id,case_id,a_mem,c_mem,a_base_bin,c_base_bin,rows_bin,cols_bin,alpha_bin,a_words_bin,c_words_bin";
        append_word_headers(mul_in_, "pre_a_word");
        mul_in_ << "\n";
        mul_out_ << "cmd_id,case_id,c_mem,c_base_bin,rows_bin,cols_bin,alpha_bin,c_words_bin";
        append_word_headers(mul_out_, "post_c_word");
        mul_out_ << "\n";

        add_in_ << "cmd_id,case_id,a_mem,b_mem,c_mem,a_base_bin,b_base_bin,c_base_bin,rows_bin,cols_bin,a_words_bin,b_words_bin,c_words_bin";
        append_word_headers(add_in_, "pre_a_word");
        append_word_headers(add_in_, "pre_b_word");
        add_in_ << "\n";
        add_out_ << "cmd_id,case_id,c_mem,c_base_bin,rows_bin,cols_bin,c_words_bin";
        append_word_headers(add_out_, "post_c_word");
        add_out_ << "\n";
    }

    void log_case_input(int cid) {
        const auto& c = cases_[static_cast<size_t>(cid)];
        switch (c.kind) {
        case kKindAbs:
            abs_in_ << c.cmd_id << "," << cid << "," << c.src_mem << "," << c.dst_mem
                    << "," << bin_value(c.src_base, 11) << "," << bin_value(c.dst_base, 11)
                    << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                    << "," << bin_value(c.src_words, 12) << "," << bin_value(c.dst_words, 12);
            append_word_vec(abs_in_, c.pre_src);
            append_word_vec(abs_in_, c.pre_dst);
            abs_in_ << "\n";
            break;
        case kKindLayoutTranspose:
            trans_in_ << c.cmd_id << "," << cid << "," << c.src_mem << "," << c.dst_mem
                      << "," << bin_value(c.src_base, 11) << "," << bin_value(c.dst_base, 11)
                      << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                      << "," << bin_value(c.dst_rows, 12) << "," << bin_value(c.dst_cols, 12)
                      << "," << bin_value(c.src_words, 12) << "," << bin_value(c.dst_words, 12);
            append_word_vec(trans_in_, c.pre_src);
            append_word_vec(trans_in_, c.pre_dst);
            trans_in_ << "\n";
            break;
        case kKindLayoutAssemble:
            assem_in_ << c.cmd_id << "," << cid << "," << c.src_mem << "," << c.dst_mem
                      << "," << bin_value(c.src_base, 11) << "," << bin_value(c.dst_base, 11)
                      << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                      << "," << bin_value(c.dst_rows, 12) << "," << bin_value(c.dst_cols, 12)
                      << "," << bin_value(c.off_r, 12) << "," << bin_value(c.off_c, 12)
                      << "," << bin_value(c.src_words, 12) << "," << bin_value(c.dst_words, 12);
            append_word_vec(assem_in_, c.pre_src);
            append_word_vec(assem_in_, c.pre_dst);
            assem_in_ << "\n";
            break;
        case kKindReduceAdd:
            reduce_add_in_ << c.cmd_id << "," << cid << "," << c.src_mem
                            << "," << bin_value(c.src_base, 11)
                            << "," << bin_value(c.len, 12)
                            << "," << bin_value(c.src_words, 12);
            append_reduce_elems(reduce_add_in_, c);
            reduce_add_in_ << "\n";
            break;
        case kKindReduceCmp:
            reduce_cmp_in_ << c.cmd_id << "," << cid << "," << c.src_mem
                            << "," << bin_value(c.src_base, 11)
                            << "," << bin_value(c.len, 12)
                            << "," << bin_value(c.src_words, 12);
            append_reduce_elems(reduce_cmp_in_, c);
            reduce_cmp_in_ << "\n";
            break;
        case kKindGemm:
            gemm_in_ << c.cmd_id << "," << cid << "," << c.src_mem << "," << c.aux_mem << "," << c.dst_mem
                     << "," << bin_value(c.src_base, 11) << "," << bin_value(c.aux_base, 11)
                     << "," << bin_value(c.dst_base, 11)
                     << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                     << "," << bin_value(c.kdim, 12)
                     << "," << bin_value(c.src_words, 12) << "," << bin_value(c.aux_words, 12)
                     << "," << bin_value(c.dst_words, 12);
            append_word_vec(gemm_in_, c.pre_src);
            append_word_vec(gemm_in_, c.pre_aux);
            gemm_in_ << "\n";
            break;
        case kKindMul:
            mul_in_ << c.cmd_id << "," << cid << "," << c.src_mem << "," << c.dst_mem
                    << "," << bin_value(c.src_base, 11) << "," << bin_value(c.dst_base, 11)
                    << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                    << "," << bin_value(c.alpha, 16)
                    << "," << bin_value(c.src_words, 12) << "," << bin_value(c.dst_words, 12);
            append_word_vec(mul_in_, c.pre_src);
            mul_in_ << "\n";
            break;
        case kKindAdd:
            add_in_ << c.cmd_id << "," << cid << "," << c.src_mem << "," << c.aux_mem << "," << c.dst_mem
                    << "," << bin_value(c.src_base, 11) << "," << bin_value(c.aux_base, 11)
                    << "," << bin_value(c.dst_base, 11)
                    << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                    << "," << bin_value(c.src_words, 12) << "," << bin_value(c.aux_words, 12)
                    << "," << bin_value(c.dst_words, 12);
            append_word_vec(add_in_, c.pre_src);
            append_word_vec(add_in_, c.pre_aux);
            add_in_ << "\n";
            break;
        default:
            throw std::runtime_error("mixed unknown case kind on input log");
        }
    }

    void log_case_output(int cid) {
        const auto& c = cases_[static_cast<size_t>(cid)];
        switch (c.kind) {
        case kKindAbs:
            abs_out_ << c.cmd_id << "," << cid << "," << c.dst_mem
                     << "," << bin_value(c.dst_base, 11)
                     << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                     << "," << bin_value(c.dst_words, 12);
            append_word_vec(abs_out_, c.post_dst);
            abs_out_ << "\n";
            break;
        case kKindLayoutTranspose:
            trans_out_ << c.cmd_id << "," << cid << "," << c.dst_mem
                       << "," << bin_value(c.dst_base, 11)
                       << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                       << "," << bin_value(c.dst_rows, 12) << "," << bin_value(c.dst_cols, 12)
                       << "," << bin_value(c.dst_words, 12);
            append_word_vec(trans_out_, c.post_dst);
            trans_out_ << "\n";
            break;
        case kKindLayoutAssemble:
            assem_out_ << c.cmd_id << "," << cid << "," << c.dst_mem
                       << "," << bin_value(c.dst_base, 11)
                       << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                       << "," << bin_value(c.dst_rows, 12) << "," << bin_value(c.dst_cols, 12)
                       << "," << bin_value(c.off_r, 12) << "," << bin_value(c.off_c, 12)
                       << "," << bin_value(c.dst_words, 12);
            append_word_vec(assem_out_, c.post_dst);
            assem_out_ << "\n";
            break;
        case kKindReduceAdd:
            reduce_add_out_ << c.cmd_id << "," << cid
                            << "," << bin_value(c.reduce_value, 16)
                            << "," << bin_value(c.reduce_index, 12) << "\n";
            break;
        case kKindReduceCmp:
            reduce_cmp_out_ << c.cmd_id << "," << cid
                            << "," << bin_value(c.reduce_value, 16)
                            << "," << bin_value(c.reduce_index, 12) << "\n";
            break;
        case kKindGemm:
            gemm_out_ << c.cmd_id << "," << cid << "," << c.dst_mem
                      << "," << bin_value(c.dst_base, 11)
                      << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                      << "," << bin_value(c.kdim, 12)
                      << "," << bin_value(c.dst_words, 12);
            append_word_vec(gemm_out_, c.post_dst);
            gemm_out_ << "\n";
            break;
        case kKindMul:
            mul_out_ << c.cmd_id << "," << cid << "," << c.dst_mem
                     << "," << bin_value(c.dst_base, 11)
                     << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                     << "," << bin_value(c.alpha, 16)
                     << "," << bin_value(c.dst_words, 12);
            append_word_vec(mul_out_, c.post_dst);
            mul_out_ << "\n";
            break;
        case kKindAdd:
            add_out_ << c.cmd_id << "," << cid << "," << c.dst_mem
                     << "," << bin_value(c.dst_base, 11)
                     << "," << bin_value(c.rows, 12) << "," << bin_value(c.cols, 12)
                     << "," << bin_value(c.dst_words, 12);
            append_word_vec(add_out_, c.post_dst);
            add_out_ << "\n";
            break;
        default:
            throw std::runtime_error("mixed unknown case kind on output log");
        }
    }

    std::filesystem::path out_dir_;
    std::array<MixedCase, kMaxCases> cases_{};
    int num_cases_ = 0;
    int next_global_ = 0;
    int next_local_ = 0;
    int next_temp_ = 0;

    bool saw_fifo_full_ = false;
    int max_fifo_count_ = 0;
    int expected_done_ = 0;
    int done_count_ = 0;
    uint32_t last_done_count_ = 0;

    std::ofstream abs_in_;
    std::ofstream abs_out_;
    std::ofstream trans_in_;
    std::ofstream trans_out_;
    std::ofstream assem_in_;
    std::ofstream assem_out_;
    std::ofstream reduce_add_in_;
    std::ofstream reduce_add_out_;
    std::ofstream reduce_cmp_in_;
    std::ofstream reduce_cmp_out_;
    std::ofstream gemm_in_;
    std::ofstream gemm_out_;
    std::ofstream mul_in_;
    std::ofstream mul_out_;
    std::ofstream add_in_;
    std::ofstream add_out_;
};

} // namespace

int main(int argc, char** argv) {
    try {
        Sim sim(argc, argv);
        MixedTest test(sim, "verification/results/core_top/mixed");
        test.run();
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Mixed simulation failed: " << e.what() << "\n";
        return 1;
    }
}
