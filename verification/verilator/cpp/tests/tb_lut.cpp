#include "../common/dexmpc_sim.hpp"

#include <array>

using namespace dexsim;

namespace {

struct LutCase {
    int rows = 0;
    int cols = 0;
    int elem_count = 0;
    int word_count = 0;
    int seq = 0;
    int src_id = 0;
    int dst_id = 0;
    int op = 0;
    uint32_t cmd_id = 0;
    int src_base = 0;
    int dst_base = 0;
    Cmd96 cmd = 0;
    std::array<Word128, 8> pre_words{};
    std::array<Word128, 8> post_words{};
    bool done_seen = false;
};

class LutTest : public TestBase {
public:
    LutTest(Sim& sim, std::filesystem::path out_dir)
        : TestBase(sim), out_dir_(std::move(out_dir)) {}

    void run() {
        std::filesystem::create_directories(out_dir_);
        load_luts();
        build_cases();
        write_input_csv();

        reset_sequence();
        preload_cases();
        for (int i = 0; i < 4; ++i) tick();
        init_trig_lut();
        init_softplus_lut();
        release_reset();

        for (const auto& c : cases_) {
            push_cmd(c.cmd);
        }

        int cycles = 0;
        while (done_count_ < static_cast<int>(cases_.size()) && cycles < kTimeoutCycles) {
            tick();
            ++cycles;
        }
        if (done_count_ < static_cast<int>(cases_.size())) {
            throw std::runtime_error("lut timeout waiting for done_count");
        }

        for (int i = 0; i < 4; ++i) tick();
        capture_post_words();
        write_output_csv();
        std::cout << "LUT C++ test passed at cycle " << sim_.cycle()
                  << ", cases=" << cases_.size() << "\n";
    }

protected:
    void monitor_done() override {
        auto* d = sim_.dut();
        if (d->reset) return;
        if ((d->io_cmdStatus_0 & (1u << 5)) != 0) {
            throw std::runtime_error("lut cmdStatus overflow set");
        }
        if (d->io_doneCount_0 == last_done_count_) return;
        if (d->io_doneCount_0 != last_done_count_ + 1) {
            throw std::runtime_error("lut doneCount jump");
        }

        const uint32_t last = d->io_lastDone_0;
        const uint32_t done_cmd_id = last & 0xfffu;
        const uint32_t done_opcode = (last >> 12) & 0x7u;
        const uint32_t done_subop = (last >> 15) & 0xfu;
        const bool group_end = ((last >> 19) & 1u) != 0;
        const bool illegal = ((last >> 20) & 1u) != 0;

        if (illegal) throw std::runtime_error("lut illegal command reported");
        if (done_cmd_id != static_cast<uint32_t>(expected_done_)) {
            throw std::runtime_error("lut doneCmdId out of order");
        }
        if (done_opcode != kOpLut) throw std::runtime_error("lut done opcode mismatch");

        auto& c = cases_.at(done_cmd_id);
        const uint32_t expected_subop =
            c.op == 0 ? kSubSin : (c.op == 1 ? kSubCos : kSubSoftplus);
        if (done_subop != expected_subop) throw std::runtime_error("lut done subop mismatch");
        if (group_end != (expected_done_ == static_cast<int>(cases_.size()) - 1)) {
            throw std::runtime_error("lut group_end mismatch");
        }

        c.done_seen = true;
        ++done_count_;
        ++expected_done_;
        last_done_count_ = d->io_doneCount_0;
    }

private:
    static constexpr int kBaseCases = 12;
    static constexpr int kOpCount = 3;
    static constexpr int kCombos = 9;
    static constexpr int kCases = kBaseCases * kOpCount * kCombos;
    static constexpr int kMaxWords = 8;
    static constexpr int kTimeoutCycles = 400000;
    static constexpr int kTrigBankDepth = 128;
    static constexpr int kSoftplusBankDepth = 256;
    const std::array<int, kBaseCases> base_rows_{{1, 1, 1, 2, 2, 3, 3, 4, 4, 4, 5, 5}};
    const std::array<int, kBaseCases> base_cols_{{1, 2, 3, 2, 3, 1, 3, 1, 2, 4, 1, 2}};

    void load_luts() {
        trig_mem_ = load_hex_u16("rtl/chisel/top_connect/src/lut/tools/trig_data.hex");
        soft_mem_ = load_hex_u32("rtl/chisel/top_connect/src/lut/tools/softplus_data.hex");
        if (trig_mem_.size() != 4 * kTrigBankDepth) {
            throw std::runtime_error("trig LUT size mismatch");
        }
        if (soft_mem_.size() != 2 * kSoftplusBankDepth) {
            throw std::runtime_error("softplus LUT size mismatch");
        }
    }

    void reserve_base(int mem_id, int words, int& base) {
        const int delta = words == 0 ? 1 : words;
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
            throw std::runtime_error("unknown LUT mem id");
        }
        check_mem_addr(mem_id, base + words - 1);
    }

    void build_cases() {
        std::mt19937 rng(0x20260310u);
        cases_.assign(kCases, {});
        next_global_ = 0;
        next_local_ = 0;
        next_temp_ = 0;

        int cid = 0;
        for (int src_id = 0; src_id < 3; ++src_id) {
            for (int dst_id = 0; dst_id < 3; ++dst_id) {
                for (int op_id = 0; op_id < kOpCount; ++op_id) {
                    for (int case_idx = 0; case_idx < kBaseCases; ++case_idx) {
                        auto& c = cases_.at(static_cast<size_t>(cid));
                        c.src_id = src_id;
                        c.dst_id = dst_id;
                        c.op = op_id;
                        c.rows = base_rows_[static_cast<size_t>(case_idx)];
                        c.cols = base_cols_[static_cast<size_t>(case_idx)];
                        c.elem_count = c.rows * c.cols;
                        c.word_count = ceil_div(c.elem_count, kFp16PerWord);
                        c.seq = 0;
                        c.cmd_id = static_cast<uint32_t>(cid);
                        if (c.word_count > kMaxWords) throw std::runtime_error("LUT case exceeds MAX_WORDS");

                        for (auto& word : c.pre_words) word = zero_word();
                        for (auto& word : c.post_words) word = zero_word();

                        for (int idx = 0; idx < c.elem_count; ++idx) {
                            const uint16_t val =
                                op_id == 2 ? rand_fp16_no_inf_nan(rng) : rand_fp16_trig_range(rng);
                            set_fp16_lane(c.pre_words[static_cast<size_t>(idx / kFp16PerWord)],
                                          idx % kFp16PerWord, val);
                        }

                        reserve_base(c.src_id, c.word_count, c.src_base);
                        reserve_base(c.dst_id, c.word_count, c.dst_base);

                        const uint32_t subop =
                            op_id == 0 ? kSubSin : (op_id == 1 ? kSubCos : kSubSoftplus);
                        c.cmd = make_cmd(
                            c.cmd_id,
                            kOpLut,
                            subop,
                            cid == kCases - 1,
                            pack_addr(c.src_id, c.src_base),
                            pack_addr(c.dst_id, c.dst_base),
                            0,
                            c.rows,
                            c.cols,
                            0);
                        ++cid;
                    }
                }
            }
        }
        if (cid != kCases) throw std::runtime_error("LUT built case count mismatch");
    }

    void init_trig_lut() {
        for (int idx = 0; idx < static_cast<int>(trig_mem_.size()); ++idx) {
            Word128 word = zero_word();
            set_fp16_lane(word, 0, trig_mem_[static_cast<size_t>(idx)]);
            if (idx < kTrigBankDepth) {
                mem_write_word(kMemTrigSinEven, idx, word);
            } else if (idx < 2 * kTrigBankDepth) {
                mem_write_word(kMemTrigSinOdd, idx - kTrigBankDepth, word);
            } else if (idx < 3 * kTrigBankDepth) {
                mem_write_word(kMemTrigCosEven, idx - 2 * kTrigBankDepth, word);
            } else {
                mem_write_word(kMemTrigCosOdd, idx - 3 * kTrigBankDepth, word);
            }
        }
    }

    void init_softplus_lut() {
        for (int idx = 0; idx < static_cast<int>(soft_mem_.size()); ++idx) {
            Word128 word = zero_word();
            word[0] = soft_mem_[static_cast<size_t>(idx)];
            if (idx < kSoftplusBankDepth) {
                mem_write_word(kMemSoftEven, idx, word);
            } else {
                mem_write_word(kMemSoftOdd, idx - kSoftplusBankDepth, word);
            }
        }
    }

    void preload_cases() {
        for (const auto& c : cases_) {
            for (int w = 0; w < c.word_count; ++w) {
                mem_write_word(c.dst_id, c.dst_base + w, zero_word());
            }
            for (int w = 0; w < c.word_count; ++w) {
                mem_write_word(c.src_id, c.src_base + w, c.pre_words[static_cast<size_t>(w)]);
            }
        }
    }

    void capture_post_words() {
        for (auto& c : cases_) {
            if (!c.done_seen) throw std::runtime_error("missing LUT done");
            for (int w = 0; w < c.word_count; ++w) {
                c.post_words[static_cast<size_t>(w)] = mem_read_word_1cycle(c.dst_id, c.dst_base + w);
            }
        }
    }

    void write_input_csv() const {
        std::ofstream f(out_dir_ / "tb_core_top_lut_input.csv");
        if (!f) throw std::runtime_error("failed to open LUT input CSV");
        f << "case_id,seq_id_bin,req_id_bin,base_addr_bin,rows_bin,cols_bin,word_count_bin";
        for (int col = 0; col < kMaxWords; ++col) f << ",pre_word_" << col << "_bin";
        f << "\n";
        for (size_t cid = 0; cid < cases_.size(); ++cid) {
            const auto& c = cases_[cid];
            f << cid
              << "," << bin_value(c.seq, 2)
              << "," << bin_value(c.cmd_id & 0xffu, 8)
              << "," << bin_value(c.src_base, kAddrW)
              << "," << bin_value(c.rows, 16)
              << "," << bin_value(c.cols, 16)
              << "," << bin_value(c.word_count, 16);
            for (int col = 0; col < kMaxWords; ++col) {
                f << "," << bin_word(c.pre_words[static_cast<size_t>(col)]);
            }
            f << "\n";
        }
    }

    void write_output_csv() const {
        std::ofstream f(out_dir_ / "tb_core_top_lut_output.csv");
        if (!f) throw std::runtime_error("failed to open LUT output CSV");
        f << "case_id,seq_id_bin,req_id_bin,base_addr_bin,rows_bin,cols_bin,word_count_bin,done_bin";
        for (int col = 0; col < kMaxWords; ++col) f << ",post_word_" << col << "_bin";
        f << "\n";
        for (size_t cid = 0; cid < cases_.size(); ++cid) {
            const auto& c = cases_[cid];
            f << cid
              << "," << bin_value(c.seq, 2)
              << "," << bin_value(c.cmd_id & 0xffu, 8)
              << "," << bin_value(c.dst_base, kAddrW)
              << "," << bin_value(c.rows, 16)
              << "," << bin_value(c.cols, 16)
              << "," << bin_value(c.word_count, 16)
              << "," << (c.done_seen ? "1" : "0");
            for (int col = 0; col < kMaxWords; ++col) {
                f << "," << bin_word(c.post_words[static_cast<size_t>(col)]);
            }
            f << "\n";
        }
    }

    std::filesystem::path out_dir_;
    std::vector<uint16_t> trig_mem_;
    std::vector<uint32_t> soft_mem_;
    std::vector<LutCase> cases_;
    int next_global_ = 0;
    int next_local_ = 0;
    int next_temp_ = 0;
    int done_count_ = 0;
    int expected_done_ = 0;
    uint32_t last_done_count_ = 0;
};

} // namespace

int main(int argc, char** argv) {
    try {
        Sim sim(argc, argv);
        LutTest test(sim, "verification/results/core_top/lut");
        test.run();
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "LUT simulation failed: " << e.what() << "\n";
        return 1;
    }
}
