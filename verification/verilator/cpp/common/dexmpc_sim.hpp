#pragma once

#ifndef DEXMPC_SIM_COMMON_ONLY
#include "VDexMPCCoreTop.h"
#endif
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

namespace dexsim {

using Word128 = std::array<uint32_t, 4>;
using Cmd96 = unsigned __int128;
using Matrix = std::vector<std::vector<uint16_t>>;

constexpr int kFpw = 16;
constexpr int kSramW = 128;
constexpr int kFp16PerWord = kSramW / kFpw;
constexpr int kGlobalDepth = 2048;
constexpr int kLocalDepth = 512;
constexpr int kTempDepth = 896;
constexpr int kAddrW = 11;

constexpr int kMemGlobal = 0;
constexpr int kMemLocal0 = 1;
constexpr int kMemTemp0 = 2;
constexpr int kMemTrigSinEven = 9;
constexpr int kMemTrigSinOdd = 10;
constexpr int kMemTrigCosEven = 11;
constexpr int kMemTrigCosOdd = 12;
constexpr int kMemSoftEven = 13;
constexpr int kMemSoftOdd = 14;

constexpr uint32_t kOpAbs = 0b001;
constexpr uint32_t kOpReduce = 0b010;
constexpr uint32_t kOpLa = 0b011;
constexpr uint32_t kOpLut = 0b100;
constexpr uint32_t kOpDataLayout = 0b101;

constexpr uint32_t kSubAbs = 0x0;
constexpr uint32_t kSubCmpReduce = 0x0;
constexpr uint32_t kSubAddTree = 0x1;
constexpr uint32_t kSubGemm = 0x0;
constexpr uint32_t kSubMul = 0x1;
constexpr uint32_t kSubAdd = 0x2;
constexpr uint32_t kSubSin = 0x0;
constexpr uint32_t kSubCos = 0x1;
constexpr uint32_t kSubSoftplus = 0x2;
constexpr uint32_t kSubAssemble = 0x0;
constexpr uint32_t kSubTranspose = 0x1;

inline Word128 zero_word() {
    return Word128{0, 0, 0, 0};
}

inline Word128 full_word() {
    return Word128{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
}

template <typename Wide>
inline void set_wide(Wide& dst, const Word128& src) {
    for (int i = 0; i < 4; ++i) {
        dst[i] = src[i];
    }
}

template <typename Wide>
inline Word128 get_wide(const Wide& src) {
    return Word128{src[0], src[1], src[2], src[3]};
}

inline std::string bin_value(uint64_t value, int width) {
    std::string out;
    out.reserve(width);
    for (int bit = width - 1; bit >= 0; --bit) {
        out.push_back(((value >> bit) & 1u) ? '1' : '0');
    }
    return out;
}

inline std::string bin_word(const Word128& word) {
    std::string out;
    out.reserve(128);
    for (int part = 3; part >= 0; --part) {
        for (int bit = 31; bit >= 0; --bit) {
            out.push_back(((word[part] >> bit) & 1u) ? '1' : '0');
        }
    }
    return out;
}

inline void set_fp16_lane(Word128& word, int lane, uint16_t value) {
    const int bit = lane * 16;
    const int part = bit / 32;
    const int shift = bit % 32;
    word[part] &= ~(0xffffu << shift);
    word[part] |= (uint32_t(value) << shift);
}

inline uint16_t get_fp16_lane(const Word128& word, int lane) {
    const int bit = lane * 16;
    const int part = bit / 32;
    const int shift = bit % 32;
    return static_cast<uint16_t>((word[part] >> shift) & 0xffffu);
}

inline uint32_t word_low32(const Word128& word) {
    return word[0];
}

inline int ceil_div(int num, int den) {
    return den == 0 ? 0 : (num + den - 1) / den;
}

inline uint16_t rand_fp16_non_extreme(std::mt19937& rng) {
    std::uniform_int_distribution<int> sign_dist(0, 1);
    std::uniform_int_distribution<int> exp_dist(1, 30);
    std::uniform_int_distribution<int> frac_dist(0, 1023);
    const uint16_t sign = static_cast<uint16_t>(sign_dist(rng));
    const uint16_t exp = static_cast<uint16_t>(exp_dist(rng));
    const uint16_t frac = static_cast<uint16_t>(frac_dist(rng));
    return static_cast<uint16_t>((sign << 15) | (exp << 10) | frac);
}

inline uint16_t rand_fp16_no_inf_nan(std::mt19937& rng) {
    for (int tries = 0; tries < 1000; ++tries) {
        const uint16_t v = static_cast<uint16_t>(rng() & 0xffffu);
        if (((v >> 10) & 0x1fu) != 0x1fu) return v;
    }
    return 0x3c00;
}

inline uint16_t rand_fp16_trig_range(std::mt19937& rng) {
    constexpr uint16_t kEightPiBits = 0x4e48;
    for (int tries = 0; tries < 2000; ++tries) {
        const uint16_t v = static_cast<uint16_t>(rng() & 0xffffu);
        if (((v >> 10) & 0x1fu) != 0x1fu && (v & 0x7fffu) <= kEightPiBits) return v;
    }
    return 0;
}

inline uint16_t pack_addr(int sram_id, int word_idx) {
    return static_cast<uint16_t>(((sram_id & 0x3) << 11) | (word_idx & 0x7ff));
}

inline uint16_t pack_buf_addr(int mem_id, int word_idx) {
    uint16_t mem_sel = 0xf;
    uint16_t word_sel = 0;
    switch (mem_id) {
    case kMemGlobal:
        mem_sel = 0x0;
        word_sel = static_cast<uint16_t>(word_idx & 0x7ff);
        break;
    case kMemLocal0:
        mem_sel = 0x1;
        word_sel = static_cast<uint16_t>(word_idx & 0x1ff);
        break;
    case kMemTemp0:
        mem_sel = 0x5;
        word_sel = static_cast<uint16_t>(word_idx & 0x3ff);
        break;
    case kMemTrigSinEven:
    case kMemTrigSinOdd:
    case kMemTrigCosEven:
    case kMemTrigCosOdd:
        mem_sel = static_cast<uint16_t>(mem_id & 0xf);
        word_sel = static_cast<uint16_t>(word_idx & 0x7f);
        break;
    case kMemSoftEven:
    case kMemSoftOdd:
        mem_sel = static_cast<uint16_t>(mem_id & 0xf);
        word_sel = static_cast<uint16_t>(word_idx & 0xff);
        break;
    default:
        break;
    }
    return static_cast<uint16_t>((mem_sel << 11) | word_sel);
}

inline int sram_depth(int mem_id) {
    switch (mem_id) {
    case kMemGlobal:
        return kGlobalDepth;
    case kMemLocal0:
        return kLocalDepth;
    case kMemTemp0:
        return kTempDepth;
    case kMemTrigSinEven:
    case kMemTrigSinOdd:
    case kMemTrigCosEven:
    case kMemTrigCosOdd:
        return 128;
    case kMemSoftEven:
    case kMemSoftOdd:
        return 256;
    default:
        return 0;
    }
}

inline Cmd96 make_cmd(uint32_t cmd_id, uint32_t opcode, uint32_t subop, bool group_end,
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

inline uint32_t cmd_word(Cmd96 cmd, int word_idx) {
    return static_cast<uint32_t>((cmd >> (word_idx * 32)) & 0xffffffffu);
}

inline std::vector<uint16_t> load_hex_u16(const std::filesystem::path& path) {
    std::ifstream f(path);
    if (!f) throw std::runtime_error("failed to open hex file: " + path.string());
    std::vector<uint16_t> values;
    std::string line;
    while (std::getline(f, line)) {
        if (line.empty()) continue;
        values.push_back(static_cast<uint16_t>(std::stoul(line, nullptr, 16) & 0xffffu));
    }
    return values;
}

inline std::vector<uint32_t> load_hex_u32(const std::filesystem::path& path) {
    std::ifstream f(path);
    if (!f) throw std::runtime_error("failed to open hex file: " + path.string());
    std::vector<uint32_t> values;
    std::string line;
    while (std::getline(f, line)) {
        if (line.empty()) continue;
        values.push_back(static_cast<uint32_t>(std::stoul(line, nullptr, 16)));
    }
    return values;
}

inline std::vector<Word128> pack_elements(const std::vector<uint16_t>& elems, int word_count = -1) {
    if (word_count < 0) word_count = ceil_div(static_cast<int>(elems.size()), kFp16PerWord);
    std::vector<Word128> words(static_cast<size_t>(word_count), zero_word());
    for (size_t i = 0; i < elems.size(); ++i) {
        set_fp16_lane(words[i / kFp16PerWord], static_cast<int>(i % kFp16PerWord), elems[i]);
    }
    return words;
}

inline std::vector<uint16_t> unpack_elements(const std::vector<Word128>& words, int elem_count) {
    std::vector<uint16_t> elems;
    elems.reserve(static_cast<size_t>(elem_count));
    for (const auto& word : words) {
        for (int lane = 0; lane < kFp16PerWord && static_cast<int>(elems.size()) < elem_count; ++lane) {
            elems.push_back(get_fp16_lane(word, lane));
        }
    }
    while (static_cast<int>(elems.size()) < elem_count) elems.push_back(0);
    return elems;
}

inline Matrix make_matrix(int rows, int cols, uint16_t init = 0) {
    return Matrix(static_cast<size_t>(rows), std::vector<uint16_t>(static_cast<size_t>(cols), init));
}

inline std::vector<Word128> matrix_to_words(const Matrix& matrix, int rows, int cols) {
    std::vector<uint16_t> elems;
    elems.reserve(static_cast<size_t>(rows * cols));
    for (int r = 0; r < rows; ++r) {
        for (int c = 0; c < cols; ++c) {
            elems.push_back(matrix.at(static_cast<size_t>(r)).at(static_cast<size_t>(c)));
        }
    }
    return pack_elements(elems);
}

inline Matrix words_to_matrix(const std::vector<Word128>& words, int rows, int cols) {
    const auto elems = unpack_elements(words, rows * cols);
    Matrix matrix = make_matrix(rows, cols);
    for (int r = 0; r < rows; ++r) {
        for (int c = 0; c < cols; ++c) {
            matrix[static_cast<size_t>(r)][static_cast<size_t>(c)] =
                elems[static_cast<size_t>(r * cols + c)];
        }
    }
    return matrix;
}

#ifndef DEXMPC_SIM_COMMON_ONLY

class Sim {
public:
    Sim(int argc, char** argv) : context_(new VerilatedContext), dut_(nullptr) {
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

    void reset_sequence(int cycles = 4) {
        sim_.dut()->reset = 1;
        for (int i = 0; i < cycles; ++i) tick_raw();
    }

    void release_reset(int pre_cycles = 4, int post_cycles = 2) {
        for (int i = 0; i < pre_cycles; ++i) tick_raw();
        sim_.dut()->reset = 0;
        for (int i = 0; i < post_cycles; ++i) tick();
    }

    void check_mem_addr(int mem_id, int addr) const {
        const int depth = sram_depth(mem_id);
        if (depth == 0) throw std::runtime_error("unknown SRAM id " + std::to_string(mem_id));
        if (addr < 0 || addr >= depth) {
            throw std::runtime_error("SRAM address overflow, mem=" + std::to_string(mem_id) +
                                     " addr=" + std::to_string(addr));
        }
    }

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
        d->eval();
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
        d->eval();
        return data;
    }

    void write_words_to_mem(int mem_id, int base, const std::vector<Word128>& words) {
        for (size_t w = 0; w < words.size(); ++w) {
            mem_write_word(mem_id, base + static_cast<int>(w), words[w]);
        }
    }

    std::vector<Word128> read_words_from_mem(int mem_id, int base, int word_count) {
        std::vector<Word128> words(static_cast<size_t>(word_count), zero_word());
        for (int w = 0; w < word_count; ++w) {
            words[static_cast<size_t>(w)] = mem_read_word_1cycle(mem_id, base + w);
        }
        return words;
    }

    void clear_mem_range(int mem_id, int base, int elem_count) {
        const int words = ceil_div(elem_count, kFp16PerWord);
        for (int w = 0; w < words; ++w) {
            mem_write_word(mem_id, base + w, zero_word());
        }
    }

    void wait_fifo_space() {
        auto* d = sim_.dut();
        while ((d->io_cmdStatus_0 & 0x1u) != 0) {
            tick();
        }
    }

    void push_cmd_raw(Cmd96 cmd) {
        auto* d = sim_.dut();
        d->io_cmdWord_0_0 = cmd_word(cmd, 0);
        d->io_cmdWord_0_1 = cmd_word(cmd, 1);
        d->io_cmdWord_0_2 = cmd_word(cmd, 2);
        d->io_cmdCtrl_0 = 1;
        tick();

        d->io_cmdCtrl_0 = 0;
        tick();
    }

    void push_cmd(Cmd96 cmd) {
        wait_fifo_space();
        push_cmd_raw(cmd);
    }

    Sim& sim_;
};

#endif // DEXMPC_SIM_COMMON_ONLY

} // namespace dexsim
