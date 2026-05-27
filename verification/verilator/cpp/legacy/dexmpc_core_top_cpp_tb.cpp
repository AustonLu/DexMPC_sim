#include "VDexMPCCoreTop.h"
#include "verilated.h"

#include <array>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

using Word128 = std::array<uint32_t, 4>;
using Cmd96 = unsigned __int128;

constexpr int kFpw = 16;
constexpr int kSramW = 128;
constexpr int kFp16PerWord = kSramW / kFpw;
constexpr int kGlobalDepth = 2048;
constexpr int kLocalDepth = 512;
constexpr int kTempDepth = 896;
constexpr int kAddrW = 11;

constexpr uint32_t kOpAbs = 0b001;
constexpr uint32_t kSubAbs = 0x0;
constexpr uint32_t kOpDataLayout = 0b101;
constexpr uint32_t kSubAssemble = 0x0;
constexpr uint32_t kSubTranspose = 0x1;

Word128 zero_word() {
    return Word128{0, 0, 0, 0};
}

Word128 full_word() {
    return Word128{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
}

template <typename Wide>
void set_wide(Wide& dst, const Word128& src) {
    for (int i = 0; i < 4; ++i) {
        dst[i] = src[i];
    }
}

template <typename Wide>
Word128 get_wide(const Wide& src) {
    return Word128{src[0], src[1], src[2], src[3]};
}

std::string bin_value(uint64_t value, int width) {
    std::string out;
    out.reserve(width);
    for (int bit = width - 1; bit >= 0; --bit) {
        out.push_back(((value >> bit) & 1u) ? '1' : '0');
    }
    return out;
}

std::string bin_word(const Word128& word) {
    std::string out;
    out.reserve(128);
    for (int part = 3; part >= 0; --part) {
        for (int bit = 31; bit >= 0; --bit) {
            out.push_back(((word[part] >> bit) & 1u) ? '1' : '0');
        }
    }
    return out;
}

void set_fp16_lane(Word128& word, int lane, uint16_t value) {
    const int bit = lane * 16;
    const int part = bit / 32;
    const int shift = bit % 32;
    word[part] &= ~(0xffffu << shift);
    word[part] |= (uint32_t(value) << shift);
}

uint16_t rand_fp16_non_extreme(std::mt19937& rng) {
    std::uniform_int_distribution<int> sign_dist(0, 1);
    std::uniform_int_distribution<int> exp_dist(1, 30);
    std::uniform_int_distribution<int> frac_dist(0, 1023);
    const uint16_t sign = static_cast<uint16_t>(sign_dist(rng));
    const uint16_t exp = static_cast<uint16_t>(exp_dist(rng));
    const uint16_t frac = static_cast<uint16_t>(frac_dist(rng));
    return static_cast<uint16_t>((sign << 15) | (exp << 10) | frac);
}

int ceil_div(int num, int den) {
    return den == 0 ? 0 : (num + den - 1) / den;
}

uint16_t pack_addr(int sram_id, int word_idx) {
    return static_cast<uint16_t>(((sram_id & 0x3) << 11) | (word_idx & 0x7ff));
}

uint16_t pack_buf_addr(int mem_id, int word_idx) {
    uint16_t mem_sel = 0xf;
    uint16_t word_sel = 0;
    switch (mem_id) {
    case 0:
        mem_sel = 0x0;
        word_sel = static_cast<uint16_t>(word_idx & 0x7ff);
        break;
    case 1:
        mem_sel = 0x1;
        word_sel = static_cast<uint16_t>(word_idx & 0x1ff);
        break;
    case 2:
        mem_sel = 0x5;
        word_sel = static_cast<uint16_t>(word_idx & 0x3ff);
        break;
    default:
        break;
    }
    return static_cast<uint16_t>((mem_sel << 11) | word_sel);
}

Cmd96 make_cmd(uint32_t cmd_id, uint32_t opcode, uint32_t subop, bool group_end,
               uint32_t addr0, uint32_t addr1, uint32_t addr2,
               uint32_t dim0, uint32_t dim1, uint32_t dim2) {
    Cmd96 cmd = 0;
    auto append = [&cmd](uint64_t value, int width) {
        cmd <<= width;
        cmd |= (Cmd96(value) & ((Cmd96(1) << width) - 1));
    };
    append(cmd_id, 12);
    append(opcode, 3);
    append(subop, 4);
    append(group_end ? 1 : 0, 1);
    append(0, 1);
    append(addr0, 13);
    append(addr1, 13);
    append(addr2, 13);
    append(dim0, 12);
    append(dim1, 12);
    append(dim2, 12);
    return cmd;
}

uint32_t cmd_word(Cmd96 cmd, int word_idx) {
    return static_cast<uint32_t>((cmd >> (word_idx * 32)) & 0xffffffffu);
}

class Sim {
public:
    explicit Sim(int argc, char** argv)
        : context_(new VerilatedContext), dut_(nullptr) {
        context_->commandArgs(argc, argv);
        dut_ = new VDexMPCCoreTop(context_);
        init_inputs();
        dut_->eval();
    }

    ~Sim() {
        dut_->final();
        delete dut_;
        delete context_;
    }

    VDexMPCCoreTop* dut() { return dut_; }
    uint64_t cycle() const { return cycle_; }

    void tick() {
        dut_->clock = 0;
        dut_->eval();
        context_->timeInc(5);

        dut_->clock = 1;
        dut_->eval();
        context_->timeInc(5);

        dut_->clock = 0;
        dut_->eval();
        ++cycle_;
    }

    void init_inputs() {
        dut_->clock = 0;
        dut_->reset = 1;
        dut_->io_cmdWord_0_0 = 0;
        dut_->io_cmdWord_0_1 = 0;
        dut_->io_cmdWord_0_2 = 0;
        dut_->io_cmdWord_1_0 = 0;
        dut_->io_cmdWord_1_1 = 0;
        dut_->io_cmdWord_1_2 = 0;
        dut_->io_cmdWord_2_0 = 0;
        dut_->io_cmdWord_2_1 = 0;
        dut_->io_cmdWord_2_2 = 0;
        dut_->io_cmdWord_3_0 = 0;
        dut_->io_cmdWord_3_1 = 0;
        dut_->io_cmdWord_3_2 = 0;
        dut_->io_cmdCtrl_0 = 0;
        dut_->io_cmdCtrl_1 = 0;
        dut_->io_cmdCtrl_2 = 0;
        dut_->io_cmdCtrl_3 = 0;
        dut_->io_cycleRdAddr_0 = 0;
        dut_->io_cycleRdAddr_1 = 0;
        dut_->io_cycleRdAddr_2 = 0;
        dut_->io_cycleRdAddr_3 = 0;
        dut_->io_spareIn0 = 0;
        dut_->io_spareIn1 = 0;
        dut_->io_Buffer_exts_address = 0;
        dut_->io_Buffer_exts_enable = 0;
        dut_->io_Buffer_exts_isWrite = 0;
        set_wide(dut_->io_Buffer_exts_writeData, zero_word());
        set_wide(dut_->io_Buffer_exts_bweb, full_word());
    }

private:
    VerilatedContext* context_;
    VDexMPCCoreTop* dut_;
    uint64_t cycle_ = 0;
};

class TestBase {
public:
    explicit TestBase(Sim& sim) : sim_(sim) {}
    virtual ~TestBase() = default;

protected:
    void tick() {
        sim_.tick();
        monitor_done();
    }

    void tick_raw() {
        sim_.tick();
    }

    virtual void monitor_done() {}

    void mem_write_word(int mem_id, int addr, const Word128& data) {
        check_mem_addr(mem_id, addr);
        auto* d = sim_.dut();
        d->io_Buffer_exts_enable = 1;
        d->io_Buffer_exts_isWrite = 1;
        d->io_Buffer_exts_address = pack_buf_addr(mem_id, addr);
        set_wide(d->io_Buffer_exts_writeData, data);
        set_wide(d->io_Buffer_exts_bweb, zero_word());
        tick();

        d->io_Buffer_exts_enable = 0;
        d->io_Buffer_exts_isWrite = 0;
        d->io_Buffer_exts_address = 0;
        set_wide(d->io_Buffer_exts_writeData, zero_word());
        set_wide(d->io_Buffer_exts_bweb, full_word());
        sim_.dut()->eval();
    }

    Word128 mem_read_word_1cycle(int mem_id, int addr) {
        check_mem_addr(mem_id, addr);
        auto* d = sim_.dut();
        d->io_Buffer_exts_enable = 1;
        d->io_Buffer_exts_isWrite = 0;
        d->io_Buffer_exts_address = pack_buf_addr(mem_id, addr);
        set_wide(d->io_Buffer_exts_writeData, zero_word());
        set_wide(d->io_Buffer_exts_bweb, full_word());
        tick();

        Word128 data = get_wide(d->io_Buffer_exts_readData);
        d->io_Buffer_exts_enable = 0;
        d->io_Buffer_exts_address = 0;
        sim_.dut()->eval();
        return data;
    }

    void push_cmd(Cmd96 cmd) {
        auto* d = sim_.dut();
        while ((d->io_cmdStatus_0 & 0x1u) != 0) {
            tick();
        }

        d->io_cmdWord_0_0 = cmd_word(cmd, 0);
        d->io_cmdWord_0_1 = cmd_word(cmd, 1);
        d->io_cmdWord_0_2 = cmd_word(cmd, 2);
        d->io_cmdCtrl_0 = 1;
        tick();

        d->io_cmdCtrl_0 = 0;
        tick();
    }

    void reset_sequence() {
        auto* d = sim_.dut();
        d->reset = 1;
        for (int i = 0; i < 4; ++i) {
            tick_raw();
        }
    }

    void release_reset() {
        auto* d = sim_.dut();
        for (int i = 0; i < 4; ++i) {
            tick_raw();
        }
        d->reset = 0;
        for (int i = 0; i < 2; ++i) {
            tick();
        }
    }

    void check_mem_addr(int mem_id, int addr) {
        if (mem_id == 0 && addr >= kGlobalDepth) throw std::runtime_error("Global SRAM address overflow");
        if (mem_id == 1 && addr >= kLocalDepth) throw std::runtime_error("Local SRAM address overflow");
        if (mem_id == 2 && addr >= kTempDepth) throw std::runtime_error("Temp SRAM address overflow");
        if (mem_id < 0 || mem_id > 2) throw std::runtime_error("Unknown SRAM id");
    }

    Sim& sim_;
};

struct AbsCase {
    int rows = 0;
    int cols = 0;
    int elem_count = 0;
    int word_count = 0;
    int seq = 0;
    int src_id = 0;
    int dst_id = 0;
    uint32_t cmd_id = 0;
    int src_base = 0;
    int dst_base = 0;
    Cmd96 cmd = 0;
    std::array<Word128, 8> pre_words{};
    std::array<Word128, 8> post_words{};
    bool done_seen = false;
};

class AbsTest : public TestBase {
public:
    AbsTest(Sim& sim, const std::filesystem::path& out_dir)
        : TestBase(sim), out_dir_(out_dir) {}

    void run() {
        std::filesystem::create_directories(out_dir_);
        build_cases();
        write_input_csv();

        reset_sequence();
        preload_cases_to_sram();
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
            throw std::runtime_error("ABS timeout waiting for done_count");
        }

        for (int i = 0; i < 4; ++i) tick();
        capture_post_words();
        write_output_csv();
        std::cout << "ABS C++ test passed at cycle " << sim_.cycle()
                  << ", cases=" << cases_.size() << "\n";
    }

protected:
    void monitor_done() override {
        auto* d = sim_.dut();
        if (d->reset) return;
        if ((d->io_cmdStatus_0 & (1u << 5)) != 0) {
            throw std::runtime_error("ABS cmdStatus overflow set");
        }
        if (d->io_doneCount_0 != last_done_count_) {
            if (d->io_doneCount_0 != last_done_count_ + 1) {
                throw std::runtime_error("ABS doneCount jump");
            }
            const uint32_t last = d->io_lastDone_0;
            const uint32_t done_cmd_id = last & 0xfffu;
            const uint32_t done_opcode = (last >> 12) & 0x7u;
            const uint32_t done_subop = (last >> 15) & 0xfu;
            const bool group_end = ((last >> 19) & 1u) != 0;
            const bool illegal = ((last >> 20) & 1u) != 0;

            if (illegal) throw std::runtime_error("ABS illegal command reported");
            if (done_cmd_id != static_cast<uint32_t>(expected_done_)) {
                throw std::runtime_error("ABS doneCmdId out of order");
            }
            if (done_opcode != kOpAbs || done_subop != kSubAbs) {
                throw std::runtime_error("ABS done opcode/subop mismatch");
            }
            if (group_end != (expected_done_ == static_cast<int>(cases_.size()) - 1)) {
                throw std::runtime_error("ABS group_end mismatch");
            }
            cases_.at(done_cmd_id).done_seen = true;
            ++done_count_;
            ++expected_done_;
            last_done_count_ = d->io_doneCount_0;
        }
    }

private:
    static constexpr int kBaseCases = 12;
    static constexpr int kCombos = 9;
    static constexpr int kInplaceCombos = 3;
    static constexpr int kCases = (kBaseCases * kCombos) + (kBaseCases * kInplaceCombos);
    static constexpr int kMaxWords = 8;
    static constexpr int kTimeoutCycles = 400000;
    const std::array<int, kBaseCases> base_rows_{{1, 3, 4, 1, 3, 4, 1, 3, 1, 4, 3, 5}};
    const std::array<int, kBaseCases> base_cols_{{5, 4, 4, 17, 11, 5, 31, 16, 9, 6, 5, 8}};

    void reserve_base(int mem_id, int words, int& base) {
        const int delta = words == 0 ? 1 : words;
        if (mem_id == 0) {
            base = next_base_global_;
            next_base_global_ += delta + 1;
            if (next_base_global_ >= kGlobalDepth) throw std::runtime_error("Global SRAM overflow");
        } else if (mem_id == 1) {
            base = next_base_local_;
            next_base_local_ += delta + 1;
            if (next_base_local_ >= kLocalDepth) throw std::runtime_error("Local SRAM overflow");
        } else if (mem_id == 2) {
            base = next_base_temp_;
            next_base_temp_ += delta + 1;
            if (next_base_temp_ >= kTempDepth) throw std::runtime_error("Temp SRAM overflow");
        } else {
            throw std::runtime_error("Unknown SRAM id");
        }
    }

    void build_cases() {
        cases_.assign(kCases, {});
        std::mt19937 rng(0x20260306u);
        next_base_global_ = 1024;
        next_base_local_ = 0;
        next_base_temp_ = 0;

        for (int src_id = 0; src_id < 3; ++src_id) {
            for (int dst_id = 0; dst_id < 3; ++dst_id) {
                for (int b = 0; b < kBaseCases; ++b) {
                    const int cid = (src_id * 3 + dst_id) * kBaseCases + b;
                    fill_case(cases_[cid], cid, src_id, dst_id, false, b, rng);
                }
            }
        }
        for (int src_id = 0; src_id < 3; ++src_id) {
            for (int b = 0; b < kBaseCases; ++b) {
                const int cid = (kBaseCases * kCombos) + (src_id * kBaseCases) + b;
                fill_case(cases_[cid], cid, src_id, src_id, true, b, rng);
            }
        }
    }

    void fill_case(AbsCase& c, int cid, int src_id, int dst_id, bool inplace,
                   int base_idx, std::mt19937& rng) {
        c.rows = base_rows_[base_idx];
        c.cols = base_cols_[base_idx];
        c.seq = 0;
        c.src_id = src_id;
        c.dst_id = dst_id;
        c.cmd_id = static_cast<uint32_t>(cid);
        c.elem_count = c.rows * c.cols;
        c.word_count = ceil_div(c.elem_count, kFp16PerWord);
        if (c.word_count > kMaxWords) throw std::runtime_error("ABS case exceeds MAX_WORDS");

        reserve_base(c.src_id, c.word_count, c.src_base);
        if (inplace) {
            c.dst_base = c.src_base;
        } else {
            reserve_base(c.dst_id, c.word_count, c.dst_base);
        }

        for (auto& w : c.pre_words) w = zero_word();
        for (auto& w : c.post_words) w = zero_word();
        c.done_seen = false;

        for (int w = 0; w < c.word_count; ++w) {
            Word128 word = zero_word();
            for (int lane = 0; lane < kFp16PerWord; ++lane) {
                set_fp16_lane(word, lane, rand_fp16_non_extreme(rng));
            }
            c.pre_words[w] = word;
        }

        c.cmd = make_cmd(c.cmd_id, kOpAbs, kSubAbs, cid == kCases - 1,
                         pack_addr(c.src_id, c.src_base),
                         pack_addr(c.dst_id, c.dst_base),
                         0, c.rows, c.cols, 0);
    }

    void preload_cases_to_sram() {
        for (const auto& c : cases_) {
            if (!(c.dst_id == c.src_id && c.dst_base == c.src_base)) {
                for (int w = 0; w < c.word_count; ++w) {
                    mem_write_word(c.dst_id, c.dst_base + w, zero_word());
                }
            }
            for (int w = 0; w < c.word_count; ++w) {
                mem_write_word(c.src_id, c.src_base + w, c.pre_words[w]);
            }
        }
    }

    void capture_post_words() {
        for (auto& c : cases_) {
            if (!c.done_seen) throw std::runtime_error("ABS missing done");
            for (int w = 0; w < c.word_count; ++w) {
                c.post_words[w] = mem_read_word_1cycle(c.dst_id, c.dst_base + w);
            }
        }
    }

    void write_input_csv() const {
        std::ofstream f(out_dir_ / "tb_core_top_abs_input.csv");
        if (!f) throw std::runtime_error("failed to open ABS input CSV");
        f << "case_id,seq_id_bin,req_id_bin,base_addr_bin,rows_bin,cols_bin,word_count_bin";
        for (int col = 0; col < kMaxWords; ++col) f << ",pre_word_" << col << "_bin";
        f << "\n";
        for (size_t cid = 0; cid < cases_.size(); ++cid) {
            const auto& c = cases_[cid];
            f << cid << "," << bin_value(c.seq, 2) << "," << bin_value(c.cmd_id & 0xffu, 8)
              << "," << bin_value(c.src_base, kAddrW)
              << "," << bin_value(c.rows, 16)
              << "," << bin_value(c.cols, 16)
              << "," << bin_value(c.word_count, 16);
            for (int col = 0; col < kMaxWords; ++col) f << "," << bin_word(c.pre_words[col]);
            f << "\n";
        }
    }

    void write_output_csv() const {
        std::ofstream f(out_dir_ / "tb_core_top_abs_output.csv");
        if (!f) throw std::runtime_error("failed to open ABS output CSV");
        f << "case_id,seq_id_bin,req_id_bin,base_addr_bin,rows_bin,cols_bin,word_count_bin,done_bin";
        for (int col = 0; col < kMaxWords; ++col) f << ",post_word_" << col << "_bin";
        f << "\n";
        for (size_t cid = 0; cid < cases_.size(); ++cid) {
            const auto& c = cases_[cid];
            f << cid << "," << bin_value(c.seq, 2) << "," << bin_value(c.cmd_id & 0xffu, 8)
              << "," << bin_value(c.dst_base, kAddrW)
              << "," << bin_value(c.rows, 16)
              << "," << bin_value(c.cols, 16)
              << "," << bin_value(c.word_count, 16)
              << ",1";
            for (int col = 0; col < kMaxWords; ++col) f << "," << bin_word(c.post_words[col]);
            f << "\n";
        }
    }

    std::filesystem::path out_dir_;
    std::vector<AbsCase> cases_;
    int next_base_global_ = 0;
    int next_base_local_ = 0;
    int next_base_temp_ = 0;
    int done_count_ = 0;
    int expected_done_ = 0;
    uint32_t last_done_count_ = 0;
};

struct LayoutCase {
    int src_elems = 0;
    int dst_elems = 0;
    int src_words = 0;
    int dst_words = 0;
    int src_base = 0;
    int dst_base = 0;
    int seq = 0;
    int src_sram = 0;
    int dst_sram = 0;
    bool mode = false;
    int src_rows = 0;
    int src_cols = 0;
    int dst_rows = 0;
    int dst_cols = 0;
    int off_r = 0;
    int off_c = 0;
    uint32_t req_id = 0;
    uint32_t cmd_id = 0;
    Cmd96 cmd = 0;
    std::array<Word128, 16> pre_src_words{};
    std::array<Word128, 16> pre_dst_words{};
    std::array<Word128, 16> post_src_words{};
    std::array<Word128, 16> post_dst_words{};
    bool rsp_seen = false;
    bool done_seen = false;
};

class LayoutTest : public TestBase {
public:
    LayoutTest(Sim& sim, const std::filesystem::path& out_dir)
        : TestBase(sim), out_dir_(out_dir) {}

    void run() {
        std::filesystem::create_directories(out_dir_);
        build_cases();
        write_input_csv();

        reset_sequence();
        preload_cases_to_sram();
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
            throw std::runtime_error("layout timeout waiting for done_count");
        }

        for (int i = 0; i < 4; ++i) tick();
        capture_post_words();
        write_output_csv();
        std::cout << "Layout C++ test passed at cycle " << sim_.cycle()
                  << ", cases=" << cases_.size() << "\n";
    }

protected:
    void monitor_done() override {
        auto* d = sim_.dut();
        if (d->reset) return;
        if ((d->io_cmdStatus_0 & (1u << 5)) != 0) {
            throw std::runtime_error("layout cmdStatus overflow set");
        }
        if (d->io_doneCount_0 != last_done_count_) {
            if (d->io_doneCount_0 != last_done_count_ + 1) {
                throw std::runtime_error("layout doneCount jump");
            }
            const uint32_t last = d->io_lastDone_0;
            const uint32_t done_cmd_id = last & 0xfffu;
            const uint32_t done_opcode = (last >> 12) & 0x7u;
            const uint32_t done_subop = (last >> 15) & 0xfu;
            const bool group_end = ((last >> 19) & 1u) != 0;
            const bool illegal = ((last >> 20) & 1u) != 0;

            if (illegal) throw std::runtime_error("layout illegal command reported");
            if (done_cmd_id != static_cast<uint32_t>(expected_done_)) {
                throw std::runtime_error("layout doneCmdId out of order");
            }
            if (done_opcode != kOpDataLayout) {
                throw std::runtime_error("layout done opcode mismatch");
            }
            const auto& c = cases_.at(done_cmd_id);
            if (c.mode && done_subop != kSubAssemble) throw std::runtime_error("layout assemble subop mismatch");
            if (!c.mode && done_subop != kSubTranspose) throw std::runtime_error("layout transpose subop mismatch");
            if (group_end != (expected_done_ == static_cast<int>(cases_.size()) - 1)) {
                throw std::runtime_error("layout group_end mismatch");
            }

            auto& mut = cases_.at(done_cmd_id);
            if (mut.rsp_seen) throw std::runtime_error("duplicate layout completion");
            mut.rsp_seen = true;
            mut.done_seen = true;
            ++done_count_;
            ++expected_done_;
            last_done_count_ = d->io_doneCount_0;
        }
    }

private:
    static constexpr int kSeqs = 4;
    static constexpr int kCombos = 9;
    static constexpr int kBaseCases = 12;
    static constexpr int kCases = kSeqs * kCombos;
    static constexpr int kMaxWords = 16;
    static constexpr int kTimeoutCycles = 200000;
    const std::array<bool, kBaseCases> base_mode_{{
        false, false, false, false, true, true, true, false, true, false, true, false}};
    const std::array<int, kBaseCases> base_src_rows_{{1, 3, 5, 8, 2, 3, 4, 9, 5, 2, 7, 11}};
    const std::array<int, kBaseCases> base_src_cols_{{5, 4, 7, 12, 3, 5, 8, 9, 6, 15, 4, 3}};
    const std::array<int, kBaseCases> base_off_r_{{0, 0, 0, 0, 1, 2, 3, 0, 4, 0, 1, 0}};
    const std::array<int, kBaseCases> base_off_c_{{0, 0, 0, 0, 1, 1, 1, 0, 2, 0, 5, 0}};

    void reserve_base(int mem_id, int words, int& base) {
        const int delta = words == 0 ? 1 : words;
        if (mem_id == 0) {
            base = next_base_global_;
            next_base_global_ += delta + 1;
            if (next_base_global_ >= kGlobalDepth) throw std::runtime_error("Global SRAM overflow");
        } else if (mem_id == 1) {
            base = next_base_local_;
            next_base_local_ += delta + 1;
            if (next_base_local_ >= kLocalDepth) throw std::runtime_error("Local SRAM overflow");
        } else if (mem_id == 2) {
            base = next_base_temp_;
            next_base_temp_ += delta + 1;
            if (next_base_temp_ >= kTempDepth) throw std::runtime_error("Temp SRAM overflow");
        } else {
            throw std::runtime_error("Unknown SRAM id");
        }
    }

    void build_cases() {
        cases_.assign(kCases, {});
        std::mt19937 rng(0x20260302u);
        next_base_global_ = 0;
        next_base_local_ = 0;
        next_base_temp_ = 0;

        for (int cid = 0; cid < kCases; ++cid) {
            auto& c = cases_[cid];
            const int base_idx = cid % kBaseCases;
            const int combo = cid % kCombos;
            c.src_sram = combo / 3;
            c.dst_sram = combo % 3;
            c.seq = cid / kCombos;
            c.req_id = static_cast<uint32_t>(cid & 0xff);
            c.mode = base_mode_[base_idx];
            c.src_rows = base_src_rows_[base_idx];
            c.src_cols = base_src_cols_[base_idx];
            c.off_r = base_off_r_[base_idx];
            c.off_c = base_off_c_[base_idx];
            if (c.mode) {
                c.dst_rows = c.src_rows + c.off_r;
                c.dst_cols = c.src_cols + c.off_c;
            } else {
                c.dst_rows = c.src_cols;
                c.dst_cols = c.src_rows;
            }
            c.src_elems = c.src_rows * c.src_cols;
            c.dst_elems = c.dst_rows * c.dst_cols;
            c.src_words = ceil_div(c.src_elems, kFp16PerWord);
            c.dst_words = ceil_div(c.dst_elems, kFp16PerWord);
            if (c.src_words > kMaxWords || c.dst_words > kMaxWords) {
                throw std::runtime_error("layout case word count exceeds MAX_WORDS");
            }
            reserve_base(c.src_sram, c.src_words, c.src_base);
            reserve_base(c.dst_sram, c.dst_words, c.dst_base);

            for (auto& w : c.pre_src_words) w = zero_word();
            for (auto& w : c.pre_dst_words) w = zero_word();
            for (auto& w : c.post_src_words) w = zero_word();
            for (auto& w : c.post_dst_words) w = zero_word();

            fill_words(c.pre_src_words, c.src_words, c.src_elems, rng);
            fill_words(c.pre_dst_words, c.dst_words, c.dst_elems, rng);

            c.cmd_id = static_cast<uint32_t>(cid);
            c.cmd = make_cmd(c.cmd_id, kOpDataLayout, c.mode ? kSubAssemble : kSubTranspose,
                             cid == kCases - 1,
                             pack_addr(c.src_sram, c.src_base),
                             pack_addr(c.dst_sram, c.dst_base),
                             c.mode ? (c.off_c & 0x7ff) : 0,
                             c.src_rows, c.src_cols, c.mode ? c.off_r : 0);
        }
    }

    void fill_words(std::array<Word128, kMaxWords>& words, int word_count, int elem_count,
                    std::mt19937& rng) {
        for (int w = 0; w < word_count; ++w) {
            Word128 word = zero_word();
            for (int lane = 0; lane < kFp16PerWord; ++lane) {
                const int idx = w * kFp16PerWord + lane;
                set_fp16_lane(word, lane, idx < elem_count ? rand_fp16_non_extreme(rng) : 0);
            }
            words[w] = word;
        }
    }

    void preload_cases_to_sram() {
        for (const auto& c : cases_) {
            for (int w = 0; w < c.src_words; ++w) {
                mem_write_word(c.src_sram, c.src_base + w, c.pre_src_words[w]);
            }
            for (int w = 0; w < c.dst_words; ++w) {
                mem_write_word(c.dst_sram, c.dst_base + w, c.pre_dst_words[w]);
            }
        }
    }

    void capture_post_words() {
        for (auto& c : cases_) {
            if (!c.rsp_seen) throw std::runtime_error("layout missing response");
            for (int w = 0; w < c.src_words; ++w) {
                c.post_src_words[w] = mem_read_word_1cycle(c.src_sram, c.src_base + w);
            }
            for (int w = 0; w < c.dst_words; ++w) {
                c.post_dst_words[w] = mem_read_word_1cycle(c.dst_sram, c.dst_base + w);
            }
        }
    }

    void write_input_csv() const {
        std::ofstream f(out_dir_ / "tb_core_top_layout_input.csv");
        if (!f) throw std::runtime_error("failed to open layout input CSV");
        f << "case_id,seq_id_bin,req_id_bin,mode_bin,src_base_bin,src_rows_bin,src_cols_bin,"
             "dst_base_bin,dst_rows_bin,dst_cols_bin,offset_row_bin,offset_col_bin,"
             "src_word_count_bin,dst_word_count_bin";
        for (int col = 0; col < kMaxWords; ++col) f << ",pre_src_word_" << col << "_bin";
        for (int col = 0; col < kMaxWords; ++col) f << ",pre_dst_word_" << col << "_bin";
        f << "\n";
        for (size_t cid = 0; cid < cases_.size(); ++cid) {
            const auto& c = cases_[cid];
            f << cid << "," << bin_value(c.seq, 2) << "," << bin_value(c.req_id, 8)
              << "," << bin_value(c.mode ? 1 : 0, 1)
              << "," << bin_value(c.src_base, kAddrW)
              << "," << bin_value(c.src_rows, 8)
              << "," << bin_value(c.src_cols, 8)
              << "," << bin_value(c.dst_base, kAddrW)
              << "," << bin_value(c.dst_rows, 8)
              << "," << bin_value(c.dst_cols, 8)
              << "," << bin_value(c.off_r, 8)
              << "," << bin_value(c.off_c, 8)
              << "," << bin_value(c.src_words, 16)
              << "," << bin_value(c.dst_words, 16);
            for (int col = 0; col < kMaxWords; ++col) f << "," << bin_word(c.pre_src_words[col]);
            for (int col = 0; col < kMaxWords; ++col) f << "," << bin_word(c.pre_dst_words[col]);
            f << "\n";
        }
    }

    void write_output_csv() const {
        std::ofstream f(out_dir_ / "tb_core_top_layout_output.csv");
        if (!f) throw std::runtime_error("failed to open layout output CSV");
        f << "case_id,seq_id_bin,req_id_bin,mode_bin,src_base_bin,src_rows_bin,src_cols_bin,"
             "dst_base_bin,dst_rows_bin,dst_cols_bin,offset_row_bin,offset_col_bin,"
             "src_word_count_bin,dst_word_count_bin,done_bin";
        for (int col = 0; col < kMaxWords; ++col) f << ",post_src_word_" << col << "_bin";
        for (int col = 0; col < kMaxWords; ++col) f << ",post_dst_word_" << col << "_bin";
        f << "\n";
        for (size_t cid = 0; cid < cases_.size(); ++cid) {
            const auto& c = cases_[cid];
            f << cid << "," << bin_value(c.seq, 2) << "," << bin_value(c.req_id, 8)
              << "," << bin_value(c.mode ? 1 : 0, 1)
              << "," << bin_value(c.src_base, kAddrW)
              << "," << bin_value(c.src_rows, 8)
              << "," << bin_value(c.src_cols, 8)
              << "," << bin_value(c.dst_base, kAddrW)
              << "," << bin_value(c.dst_rows, 8)
              << "," << bin_value(c.dst_cols, 8)
              << "," << bin_value(c.off_r, 8)
              << "," << bin_value(c.off_c, 8)
              << "," << bin_value(c.src_words, 16)
              << "," << bin_value(c.dst_words, 16)
              << ",1";
            for (int col = 0; col < kMaxWords; ++col) f << "," << bin_word(c.post_src_words[col]);
            for (int col = 0; col < kMaxWords; ++col) f << "," << bin_word(c.post_dst_words[col]);
            f << "\n";
        }
    }

    std::filesystem::path out_dir_;
    std::vector<LayoutCase> cases_;
    int next_base_global_ = 0;
    int next_base_local_ = 0;
    int next_base_temp_ = 0;
    int done_count_ = 0;
    int expected_done_ = 0;
    uint32_t last_done_count_ = 0;
};

void run_abs(int argc, char** argv) {
    Sim sim(argc, argv);
    AbsTest test(sim, "verification/results/core_top/abs");
    test.run();
}

void run_layout(int argc, char** argv) {
    Sim sim(argc, argv);
    LayoutTest test(sim, "verification/results/core_top/layout");
    test.run();
}

} // namespace

int main(int argc, char** argv) {
    try {
        std::string test = "both";
        for (int i = 1; i < argc; ++i) {
            std::string arg = argv[i];
            if (arg == "--test" && i + 1 < argc) {
                test = argv[++i];
            }
        }

        if (test == "abs") {
            run_abs(argc, argv);
        } else if (test == "layout") {
            run_layout(argc, argv);
        } else if (test == "both") {
            run_abs(argc, argv);
            run_layout(argc, argv);
        } else {
            throw std::runtime_error("unknown --test value: " + test);
        }
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Simulation failed: " << e.what() << "\n";
        return 1;
    }
}
