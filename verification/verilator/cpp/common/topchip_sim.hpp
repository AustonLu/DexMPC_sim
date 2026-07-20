#pragma once

#define DEXMPC_SIM_COMMON_ONLY
#include "dexmpc_sim.hpp"
#undef DEXMPC_SIM_COMMON_ONLY

#if defined(DEX_TOPCHIP_TRANSPORT_SPI)
#include "VTopChipTop.h"
#elif defined(DEX_TOPCHIP_TRANSPORT_D2D)
#include "VTopChipTopD2dHarness.h"
#else
#error "Define DEX_TOPCHIP_TRANSPORT_SPI or DEX_TOPCHIP_TRANSPORT_D2D before including topchip_sim.hpp"
#endif

#include "verilated.h"

#include <algorithm>
#include <array>
#include <cstdint>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

namespace dexsim::topchip {

constexpr std::uint32_t kBaseDexmpcAddr = 0x00000000u;
constexpr int kNumCommandContexts = 4;

constexpr int kCfgCmdWord00 = 0;
constexpr int kCfgCmdWord01 = 1;
constexpr int kCfgCmdWord02 = 2;
constexpr int kCfgCmdCtrl0 = 12;
constexpr int kCfgCmdStatus0 = 22;
constexpr int kCfgDoneCount0 = 26;
constexpr int kCfgLastDone0 = 30;
constexpr int kCfgAddReduceReg0 = 42;
constexpr int kCfgCmpReduceReg00 = 46;
constexpr int kCfgCmpReduceReg10 = 50;
constexpr int kCfgEngineStatus = 54;
constexpr int kCfgAllDoneReg = 55;
constexpr int kCfgIsLoop = 63;

inline int checked_core(int core) {
    if (core < 0 || core >= kNumCommandContexts) {
        throw std::runtime_error("invalid TopChip core index " + std::to_string(core));
    }
    return core;
}

inline int cfg_cmd_word(int core, int word) {
    checked_core(core);
    if (word < 0 || word >= 3) {
        throw std::runtime_error("invalid TopChip command word index " + std::to_string(word));
    }
    return core * 3 + word;
}

inline int cfg_cmd_ctrl(int core) { return 12 + checked_core(core); }
inline int cfg_cmd_status(int core) { return 22 + checked_core(core); }
inline int cfg_done_count(int core) { return 26 + checked_core(core); }
inline int cfg_last_done(int core) { return 30 + checked_core(core); }
inline int cfg_last_done_cycle(int core) { return 34 + checked_core(core); }
inline int cfg_add_reduce(int core) { return 42 + checked_core(core); }
inline int cfg_cmp_reduce0(int core) { return 46 + checked_core(core); }
inline int cfg_cmp_reduce1(int core) { return 50 + checked_core(core); }

inline int mpc_local_mem(int core) { return 1 + checked_core(core); }
inline int mpc_temp_mem(int core) { return 5 + checked_core(core); }

inline int mpc_mem_depth(int mpc_mem_id) {
    if (mpc_mem_id == 0) return kGlobalDepth;
    if (mpc_mem_id >= 1 && mpc_mem_id <= 4) return kLocalDepth;
    if (mpc_mem_id >= 5 && mpc_mem_id <= 8) return kTempDepth;
    if (mpc_mem_id >= 9 && mpc_mem_id <= 12) return 128;
    if (mpc_mem_id >= 13 && mpc_mem_id <= 14) return 256;
    return 0;
}

inline void check_mpc_mem_addr(int mpc_mem_id, int word_addr) {
    const int depth = mpc_mem_depth(mpc_mem_id);
    if (depth == 0) {
        throw std::runtime_error("invalid TopChip physical memory id " + std::to_string(mpc_mem_id));
    }
    if (word_addr < 0 || word_addr >= depth) {
        throw std::runtime_error("TopChip physical memory address overflow, mem="
                                 + std::to_string(mpc_mem_id)
                                 + " addr=" + std::to_string(word_addr));
    }
}

constexpr std::uint8_t kD2dWrIdLo = 0x0c;
constexpr std::uint8_t kD2dWrIdHi = 0x0d;
constexpr std::uint8_t kD2dRdIdLo = 0x2a;
constexpr std::uint8_t kD2dRdIdHi = 0x2b;

inline std::uint32_t mpc_cfg_addr(int reg_idx) {
    return kBaseDexmpcAddr + (static_cast<std::uint32_t>(reg_idx) << 3);
}

inline std::uint32_t mpc_sram_addr(int mpc_mem_id, int word_addr) {
    return kBaseDexmpcAddr
        + ((0x00008000u + (static_cast<std::uint32_t>(mpc_mem_id) << 11)
            + static_cast<std::uint32_t>(word_addr)) << 3);
}

inline int core_mem_to_mpc_mem(int mem_id) {
    switch (mem_id) {
    case kMemGlobal:
        return 0;
    case kMemLocal0:
        return 1;
    case kMemTemp0:
        return 5;
    case kMemTrigSinEven:
    case kMemTrigSinOdd:
    case kMemTrigCosEven:
    case kMemTrigCosOdd:
    case kMemSoftEven:
    case kMemSoftOdd:
        return mem_id;
    default:
        throw std::runtime_error("unsupported TopChip memory id " + std::to_string(mem_id));
    }
}

inline std::uint64_t make64(std::uint32_t hi, std::uint32_t lo) {
    return (std::uint64_t(hi) << 32) | lo;
}

inline Cmd96 cmd_with_group_end(Cmd96 cmd, bool group_end) {
    const Cmd96 mask = Cmd96(1) << 76;
    return group_end ? (cmd | mask) : (cmd & ~mask);
}

struct CoreDutView {
    std::uint8_t reset = 1;
    std::uint32_t io_cmdStatus_0 = 0;
    std::uint32_t io_doneCount_0 = 0;
    std::uint32_t io_lastDone_0 = 0;
    std::uint32_t io_addReduceReg_0 = 0;
    std::uint32_t io_cmpReduceReg0_0 = 0;
    std::uint32_t io_cmpReduceReg1_0 = 0;
    std::uint32_t io_engineStatus = 0;
    std::uint32_t io_allDoneReg = 0;

    void eval() {}
};

class Sim {
public:
#if defined(DEX_TOPCHIP_TRANSPORT_SPI)
    using Model = VTopChipTop;
#else
    using Model = VTopChipTopD2dHarness;
#endif

    Sim(int argc, char** argv)
        : context_(std::make_unique<VerilatedContext>()),
          dut_(std::make_unique<Model>(context_.get())) {
        context_->commandArgs(argc, argv);
        drive_defaults();
        dut_->eval();
    }

    ~Sim() {
        dut_->final();
    }

    Model* model() { return dut_.get(); }
    CoreDutView* dut() { return &view_; }
    std::uint64_t cycle() const { return cycle_; }
    std::uint64_t done_pulses() const { return done_pulses_; }
    std::uint64_t transport_read_bytes() const { return transport_read_bytes_; }
    std::uint64_t transport_write_bytes() const { return transport_write_bytes_; }

    void clear_transport_counters() {
        transport_read_bytes_ = 0;
        transport_write_bytes_ = 0;
    }

    void reset() {
        view_ = CoreDutView{};
        view_.reset = 1;
        drive_reset(true);
        run_core_cycles(24);
        view_.reset = 0;
        drive_reset(false);
        run_core_cycles(160);
        done_pulses_ = 0;
        prev_dex_done_ = false;
        refresh_status_regs();
    }

    void tick() {
        apply_view_reset();
        run_core_cycles(1);
    }

    void run_core_cycles(int cycles) {
        for (int i = 0; i < cycles; ++i) {
#if defined(DEX_TOPCHIP_TRANSPORT_SPI)
            tick_half();
            tick_half();
#else
            wait_core_posedge();
#endif
        }
    }

    void run_until_done_pulses(std::uint64_t target, int timeout_cycles) {
        for (int cycles = 0; done_pulses_ < target && cycles < timeout_cycles; ++cycles) {
            tick();
        }
        if (done_pulses_ < target) {
            throw std::runtime_error("TopChip timeout waiting for dexmpc complete pulses: target="
                                     + std::to_string(target)
                                     + " got=" + std::to_string(done_pulses_));
        }
    }

    void write_reg(int reg_idx, std::uint32_t value) {
        bus_write32(mpc_cfg_addr(reg_idx), value);
        transport_write_bytes_ += sizeof(value);
        update_cached_reg(reg_idx, value);
    }

    std::uint32_t read_reg(int reg_idx) {
        const auto value = bus_read32(mpc_cfg_addr(reg_idx));
        transport_read_bytes_ += sizeof(value);
        update_cached_reg(reg_idx, value);
        return value;
    }

    void refresh_status_regs() {
        view_.io_cmdStatus_0 = bus_read32(mpc_cfg_addr(kCfgCmdStatus0));
        view_.io_doneCount_0 = bus_read32(mpc_cfg_addr(kCfgDoneCount0));
        view_.io_lastDone_0 = bus_read32(mpc_cfg_addr(kCfgLastDone0));
        view_.io_addReduceReg_0 = bus_read32(mpc_cfg_addr(kCfgAddReduceReg0));
        view_.io_cmpReduceReg0_0 = bus_read32(mpc_cfg_addr(kCfgCmpReduceReg00));
        view_.io_cmpReduceReg1_0 = bus_read32(mpc_cfg_addr(kCfgCmpReduceReg10));
        view_.io_engineStatus = bus_read32(mpc_cfg_addr(kCfgEngineStatus));
        view_.io_allDoneReg = bus_read32(mpc_cfg_addr(kCfgAllDoneReg));
    }

    void write_mem_word(int mem_id, int word_addr, const Word128& data) {
        const int mpc_mem = core_mem_to_mpc_mem(mem_id);
        write_mpc_mem_word(mpc_mem, word_addr, data);
    }

    Word128 read_mem_word(int mem_id, int word_addr) {
        const int mpc_mem = core_mem_to_mpc_mem(mem_id);
        return read_mpc_mem_word(mpc_mem, word_addr);
    }

    void write_mpc_mem_word(int mpc_mem_id, int word_addr, const Word128& data) {
        check_mpc_mem_addr(mpc_mem_id, word_addr);
        bus_write128_sameaddr(mpc_sram_addr(mpc_mem_id, word_addr), data);
        transport_write_bytes_ += sizeof(Word128);
    }

    Word128 read_mpc_mem_word(int mpc_mem_id, int word_addr) {
        check_mpc_mem_addr(mpc_mem_id, word_addr);
        const auto data = bus_read128_sameaddr(mpc_sram_addr(mpc_mem_id, word_addr));
        transport_read_bytes_ += sizeof(Word128);
        return data;
    }

    void write_mem_words(int mem_id, int word_addr, const std::vector<Word128>& words) {
        write_mpc_mem_words(core_mem_to_mpc_mem(mem_id), word_addr, words);
    }

    void write_mpc_mem_words(int mpc_mem_id, int word_addr, const std::vector<Word128>& words) {
        if (!words.empty()) {
            check_mpc_mem_addr(mpc_mem_id, word_addr);
            check_mpc_mem_addr(mpc_mem_id, word_addr + static_cast<int>(words.size()) - 1);
        }
#if defined(DEX_TOPCHIP_TRANSPORT_D2D)
        transport_write_bytes_ += sizeof(Word128) * words.size();
        for (std::size_t base = 0; base < words.size(); base += kD2dMaxBurstBeats) {
            const auto beats = std::min<std::size_t>(kD2dMaxBurstBeats, words.size() - base);
            std::vector<std::uint64_t> lo(beats);
            std::vector<std::uint64_t> hi(beats);
            for (std::size_t i = 0; i < beats; ++i) {
                const auto& word = words[base + i];
                lo[i] = make64(word[1], word[0]);
                hi[i] = make64(word[3], word[2]);
            }
            const auto addr = mpc_sram_addr(mpc_mem_id, word_addr + static_cast<int>(base));
            d2d_write(addr, kD2dWrIdLo, static_cast<std::uint8_t>(beats - 1), lo);
            d2d_write(addr, kD2dWrIdHi, static_cast<std::uint8_t>(beats - 1), hi);
        }
#else
        for (std::size_t i = 0; i < words.size(); ++i) {
            write_mpc_mem_word(mpc_mem_id, word_addr + static_cast<int>(i), words[i]);
        }
#endif
    }

    std::vector<Word128> read_mem_words(int mem_id, int word_addr, int word_count) {
        return read_mpc_mem_words(core_mem_to_mpc_mem(mem_id), word_addr, word_count);
    }

    std::vector<Word128> read_mpc_mem_words(int mpc_mem_id, int word_addr, int word_count) {
        if (word_count < 0) throw std::runtime_error("negative TopChip memory word count");
        if (word_count > 0) {
            check_mpc_mem_addr(mpc_mem_id, word_addr);
            check_mpc_mem_addr(mpc_mem_id, word_addr + word_count - 1);
        }
        std::vector<Word128> words(static_cast<std::size_t>(word_count), zero_word());
#if defined(DEX_TOPCHIP_TRANSPORT_D2D)
        transport_read_bytes_ += sizeof(Word128) * static_cast<std::size_t>(word_count);
        for (int base = 0; base < word_count; base += static_cast<int>(kD2dMaxBurstBeats)) {
            const auto beats = std::min<int>(static_cast<int>(kD2dMaxBurstBeats), word_count - base);
            const auto addr = mpc_sram_addr(mpc_mem_id, word_addr + base);
            const auto lo = d2d_read(addr, kD2dRdIdLo, static_cast<std::uint8_t>(beats - 1));
            const auto hi = d2d_read(addr, kD2dRdIdHi, static_cast<std::uint8_t>(beats - 1));
            if (lo.size() != static_cast<std::size_t>(beats) ||
                hi.size() != static_cast<std::size_t>(beats)) {
                throw std::runtime_error("D2D SRAM burst read returned unexpected beat count");
            }
            for (int i = 0; i < beats; ++i) {
                words[static_cast<std::size_t>(base + i)] = Word128{
                    static_cast<std::uint32_t>(lo[static_cast<std::size_t>(i)]),
                    static_cast<std::uint32_t>(lo[static_cast<std::size_t>(i)] >> 32),
                    static_cast<std::uint32_t>(hi[static_cast<std::size_t>(i)]),
                    static_cast<std::uint32_t>(hi[static_cast<std::size_t>(i)] >> 32),
                };
            }
        }
#else
        for (int i = 0; i < word_count; ++i) {
            words[static_cast<std::size_t>(i)] = read_mpc_mem_word(mpc_mem_id, word_addr + i);
        }
#endif
        return words;
    }

    std::uint32_t done_count(int core) { return read_reg(cfg_done_count(core)); }
    std::uint32_t command_status(int core) { return read_reg(cfg_cmd_status(core)); }
    std::uint32_t last_done(int core) { return read_reg(cfg_last_done(core)); }

    void stage_cmd(int core, Cmd96 cmd) {
        for (int word = 0; word < 3; ++word) {
            write_reg(cfg_cmd_word(core, word), cmd_word(cmd, word));
        }
    }

    void set_cmd_push(int core, bool value) {
        write_reg(cfg_cmd_ctrl(core), value ? 1u : 0u);
    }

    void push_cmd(int core, Cmd96 cmd) {
        for (int guard = 0; guard < 10000; ++guard) {
            if ((command_status(core) & 0x1u) == 0) {
                stage_cmd(core, cmd);
                set_cmd_push(core, true);
                set_cmd_push(core, false);
                return;
            }
            run_core_cycles(1);
        }
        throw std::runtime_error("timeout waiting for TopChip core command FIFO space");
    }

    void wait_for_done_count(int core, std::uint32_t target, int timeout_cycles,
                             int poll_cycles = 32) {
        for (int cycles = 0; cycles < timeout_cycles; cycles += poll_cycles) {
            run_core_cycles(poll_cycles);
            const auto observed = done_count(core);
            if (observed >= target) {
                if (observed != target) {
                    throw std::runtime_error("TopChip doneCount jump on core "
                                             + std::to_string(core)
                                             + ": expected=" + std::to_string(target)
                                             + " got=" + std::to_string(observed));
                }
                return;
            }
        }
        throw std::runtime_error("TopChip timeout waiting for core " + std::to_string(core)
                                 + " doneCount=" + std::to_string(target));
    }

private:
    static constexpr int kSpiHalfCyclesPerPhase = 4;
    // The tapeout D2D SRAM path is validated with one AXI beat per 64-bit half-word.
    static constexpr std::size_t kD2dMaxBurstBeats = 1;
    static constexpr int kTransactionTimeoutCycles = 100000;

    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<Model> dut_;
    CoreDutView view_{};
    bool clock_ = false;
    bool d2d_ref_clock_ = true;
    std::uint64_t time_ = 0;
    std::uint64_t cycle_ = 0;
    std::uint64_t done_pulses_ = 0;
    std::uint64_t transport_read_bytes_ = 0;
    std::uint64_t transport_write_bytes_ = 0;
    bool prev_dex_done_ = false;

    void update_cached_reg(int reg_idx, std::uint32_t value) {
        switch (reg_idx) {
        case kCfgCmdStatus0:
            view_.io_cmdStatus_0 = value;
            break;
        case kCfgDoneCount0:
            view_.io_doneCount_0 = value;
            break;
        case kCfgLastDone0:
            view_.io_lastDone_0 = value;
            break;
        case kCfgAddReduceReg0:
            view_.io_addReduceReg_0 = value;
            break;
        case kCfgCmpReduceReg00:
            view_.io_cmpReduceReg0_0 = value;
            break;
        case kCfgCmpReduceReg10:
            view_.io_cmpReduceReg1_0 = value;
            break;
        case kCfgEngineStatus:
            view_.io_engineStatus = value;
            break;
        case kCfgAllDoneReg:
            view_.io_allDoneReg = value;
            break;
        default:
            break;
        }
    }

    void apply_view_reset() {
        drive_reset(view_.reset != 0);
    }

#if defined(DEX_TOPCHIP_TRANSPORT_SPI)
    void drive_defaults() {
        auto* d = dut_.get();
        d->pad_clock = 0;
        d->pad_reset = 1;
        d->pad_clock_sel = 0;
        d->pad_spi_sck = 0;
        d->pad_spi_ssn = 1;
        d->pad_spi_mosi = 0;
        d->pad_d2d_rx_clock = 0;
        d->pad_d2d_rx_flit_valid = 0;
        d->pad_d2d_rx_flit_0 = 0;
        d->pad_d2d_rx_flit_1 = 0;
        d->pad_d2d_rx_flit_2 = 0;
        d->pad_d2d_rx_flit_3 = 0;
        d->pad_d2d_rx_flit_4 = 0;
        d->pad_d2d_rx_flit_5 = 0;
        d->pad_d2d_rx_flit_6 = 0;
        d->pad_d2d_rx_flit_7 = 0;
        d->pad_d2d_rx_flit_8 = 0;
        d->pad_d2d_rx_flit_9 = 0;
        d->pad_d2d_rx_flit_10 = 0;
        d->pad_d2d_rx_flit_11 = 0;
        d->pad_d2d_rx_flit_12 = 0;
        d->pad_d2d_rx_flit_13 = 0;
        d->pad_d2d_rx_flit_14 = 0;
        d->pad_d2d_rx_flit_15 = 0;
        d->pad_d2d_rx_creditFree = 0;
        d->pad_d2d_rx_replayPkgID = 0;
        d->pad_d2d_mux = 0;
    }

    void drive_reset(bool value) {
        dut_->pad_clock_sel = 0;
        dut_->pad_reset = value ? 1 : 0;
    }

    bool dex_done_pin() const {
        return (dut_->pad_dexmpc_complete & 1u) != 0;
    }

    void tick_half() {
        clock_ = !clock_;
        dut_->pad_clock = clock_ ? 1 : 0;
        dut_->eval();
        context_->timeInc(2);
        if (clock_) {
            ++cycle_;
            sample_done_pin();
        }
    }

    void settle_spi() {
        run_core_cycles(kSpiHalfCyclesPerPhase);
    }

    std::uint32_t spi_transfer(std::uint8_t cmd, std::uint32_t addr, std::uint32_t data) {
        std::array<int, 80> bits{};
        for (int i = 0; i < 8; ++i) bits[static_cast<std::size_t>(i)] = (cmd >> (7 - i)) & 1u;
        for (int i = 0; i < 32; ++i) bits[static_cast<std::size_t>(8 + i)] = (addr >> (31 - i)) & 1u;
        for (int i = 0; i < 32; ++i) bits[static_cast<std::size_t>(40 + i)] = (data >> (31 - i)) & 1u;
        for (int i = 0; i < 8; ++i) bits[static_cast<std::size_t>(72 + i)] = 0;

        auto* d = dut_.get();
        d->pad_spi_sck = 0;
        d->pad_spi_mosi = 0;
        d->pad_spi_ssn = 1;
        settle_spi();
        d->pad_spi_ssn = 0;
        d->pad_spi_mosi = bits[0];
        settle_spi();

        std::uint32_t rx = 0;
        for (std::size_t i = 0; i < bits.size(); ++i) {
            rx = (rx << 1) | (d->pad_spi_miso & 1u);
            d->pad_spi_sck = 1;
            settle_spi();
            d->pad_spi_sck = 0;
            if (i + 1 < bits.size()) {
                d->pad_spi_mosi = bits[i + 1];
            }
            settle_spi();
        }

        d->pad_spi_ssn = 1;
        d->pad_spi_mosi = 0;
        d->pad_spi_sck = 0;
        settle_spi();
        return rx;
    }

    void bus_write32(std::uint32_t addr, std::uint32_t data) {
        spi_transfer(0x80u, addr, data);
    }

    std::uint32_t bus_read32(std::uint32_t addr) {
        return spi_transfer(0xc0u, addr, 0);
    }

    void bus_write64(std::uint32_t addr, std::uint64_t data) {
        bus_write32(addr, static_cast<std::uint32_t>(data));
        bus_write32(addr + 4, static_cast<std::uint32_t>(data >> 32));
    }

    std::uint64_t bus_read64(std::uint32_t addr) {
        const auto lo = bus_read32(addr);
        const auto hi = bus_read32(addr + 4);
        return (std::uint64_t(hi) << 32) | lo;
    }

#else
    void drive_defaults() {
        auto* d = dut_.get();
        d->clock = 0;
        d->d2d_ref_clock = 1;
        d->reset = 1;
        d->clock_sel = 0;
        d->d2dm_ar_valid = 0;
        d->d2dm_ar_addr = 0;
        d->d2dm_ar_id = 0;
        d->d2dm_ar_len = 0;
        d->d2dm_r_ready = 0;
        d->d2dm_aw_valid = 0;
        d->d2dm_aw_addr = 0;
        d->d2dm_aw_id = 0;
        d->d2dm_aw_len = 0;
        d->d2dm_w_valid = 0;
        d->d2dm_w_data = 0;
        d->d2dm_w_last = 0;
        d->d2dm_w_strb = 0;
        d->d2dm_b_ready = 0;
    }

    void drive_reset(bool value) {
        dut_->clock_sel = 0;
        dut_->reset = value ? 1 : 0;
    }

    bool dex_done_pin() const {
        return (dut_->dexmpc_complete & 1u) != 0;
    }

    void step_time() {
        const bool prev_clock = clock_;
        if ((time_ & 1u) == 0) {
            clock_ = !clock_;
            dut_->clock = clock_ ? 1 : 0;
        } else {
            d2d_ref_clock_ = !clock_;
            dut_->d2d_ref_clock = d2d_ref_clock_ ? 1 : 0;
        }

        dut_->eval();
        if (!prev_clock && clock_) {
            ++cycle_;
            sample_done_pin();
        }
        context_->timeInc(1);
        ++time_;
    }

    void wait_core_posedge() {
        while (true) {
            const bool prev_clock = clock_;
            step_time();
            if (!prev_clock && clock_) return;
        }
    }

    void clear_write_inputs() {
        auto* d = dut_.get();
        d->d2dm_aw_valid = 0;
        d->d2dm_w_valid = 0;
        d->d2dm_w_last = 0;
        d->d2dm_w_strb = 0;
        d->d2dm_b_ready = 0;
    }

    void clear_read_inputs() {
        auto* d = dut_.get();
        d->d2dm_ar_valid = 0;
        d->d2dm_r_ready = 0;
    }

    void d2d_write(std::uint32_t addr, std::uint8_t id, std::uint8_t len,
                   const std::vector<std::uint64_t>& data) {
        if (data.size() < static_cast<std::size_t>(len) + 1) {
            throw std::runtime_error("D2D write data shorter than burst length");
        }

        auto* d = dut_.get();
        d->d2dm_aw_valid = 1;
        d->d2dm_aw_addr = addr & 0x1fffffu;
        d->d2dm_aw_id = id;
        d->d2dm_aw_len = len;
        d->d2dm_w_valid = 1;
        d->d2dm_w_data = data[0];
        d->d2dm_w_last = (len == 0) ? 1 : 0;
        d->d2dm_w_strb = 0xff;
        d->d2dm_b_ready = 1;

        bool aw_done = false;
        bool w_done = false;
        int beat = 0;
        for (int timeout = 0; timeout < kTransactionTimeoutCycles; ++timeout) {
            wait_core_posedge();

            if (!aw_done && d->d2dm_aw_valid && d->d2dm_aw_ready) {
                aw_done = true;
                d->d2dm_aw_valid = 0;
            }
            if (!w_done && d->d2dm_w_valid && d->d2dm_w_ready) {
                if (beat == len) {
                    w_done = true;
                    d->d2dm_w_valid = 0;
                    d->d2dm_w_last = 0;
                    d->d2dm_w_strb = 0;
                } else {
                    ++beat;
                    d->d2dm_w_data = data[static_cast<std::size_t>(beat)];
                    d->d2dm_w_last = (beat == len) ? 1 : 0;
                }
            }
            if (d->d2dm_b_valid && d->d2dm_b_ready) {
                const auto got_id = static_cast<std::uint8_t>(d->d2dm_b_id);
                const auto resp = static_cast<std::uint8_t>(d->d2dm_b_resp);
                clear_write_inputs();
                if (resp != 0 || got_id != id) {
                    throw std::runtime_error("D2D write response mismatch addr=0x"
                                             + std::to_string(addr));
                }
                return;
            }
        }

        clear_write_inputs();
        throw std::runtime_error("D2D write timeout addr=0x" + std::to_string(addr)
                                 + " aw_done=" + std::to_string(aw_done)
                                 + " w_done=" + std::to_string(w_done));
    }

    std::vector<std::uint64_t> d2d_read(std::uint32_t addr, std::uint8_t id, std::uint8_t len) {
        auto* d = dut_.get();
        d->d2dm_ar_valid = 1;
        d->d2dm_ar_addr = addr & 0x1fffffu;
        d->d2dm_ar_id = id;
        d->d2dm_ar_len = len;
        d->d2dm_r_ready = 1;

        bool ar_done = false;
        std::vector<std::uint64_t> data;
        data.reserve(static_cast<std::size_t>(len) + 1);

        for (int timeout = 0; timeout < kTransactionTimeoutCycles; ++timeout) {
            wait_core_posedge();

            if (!ar_done && d->d2dm_ar_valid && d->d2dm_ar_ready) {
                ar_done = true;
                d->d2dm_ar_valid = 0;
            }
            if (d->d2dm_r_valid && d->d2dm_r_ready) {
                const auto got_id = static_cast<std::uint8_t>(d->d2dm_r_id);
                const auto resp = static_cast<std::uint8_t>(d->d2dm_r_resp);
                const bool last = d->d2dm_r_last != 0;
                data.push_back(d->d2dm_r_data);
                if (resp != 0 || got_id != id) {
                    clear_read_inputs();
                    throw std::runtime_error("D2D read response mismatch addr=0x"
                                             + std::to_string(addr));
                }
                if (last || data.size() == static_cast<std::size_t>(len) + 1) {
                    clear_read_inputs();
                    return data;
                }
            }
        }

        clear_read_inputs();
        throw std::runtime_error("D2D read timeout addr=0x" + std::to_string(addr)
                                 + " ar_done=" + std::to_string(ar_done));
    }

    void bus_write64_id(std::uint32_t addr, std::uint8_t id, std::uint64_t data) {
        d2d_write(addr, id, 0, std::vector<std::uint64_t>{data});
    }

    std::uint64_t bus_read64_id(std::uint32_t addr, std::uint8_t id) {
        const auto data = d2d_read(addr, id, 0);
        if (data.empty()) throw std::runtime_error("D2D read returned no data");
        return data[0];
    }

    void bus_write32(std::uint32_t addr, std::uint32_t data) {
        bus_write64_id(addr, kD2dWrIdLo, make64(0, data));
    }

    std::uint32_t bus_read32(std::uint32_t addr) {
        return static_cast<std::uint32_t>(bus_read64_id(addr, kD2dRdIdLo));
    }
#endif

    void sample_done_pin() {
        const bool done = !view_.reset && dex_done_pin();
        if (done && !prev_dex_done_) {
            ++done_pulses_;
        }
        prev_dex_done_ = done;
    }

    void bus_write128_sameaddr(std::uint32_t addr, const Word128& data) {
#if defined(DEX_TOPCHIP_TRANSPORT_SPI)
        bus_write64(addr, make64(data[1], data[0]));
        bus_write64(addr, make64(data[3], data[2]));
#else
        bus_write64_id(addr, kD2dWrIdLo, make64(data[1], data[0]));
        bus_write64_id(addr, kD2dWrIdHi, make64(data[3], data[2]));
#endif
    }

    Word128 bus_read128_sameaddr(std::uint32_t addr) {
#if defined(DEX_TOPCHIP_TRANSPORT_SPI)
        const auto lo = bus_read64(addr);
        const auto hi = bus_read64(addr);
#else
        const auto lo = bus_read64_id(addr, kD2dRdIdLo);
        const auto hi = bus_read64_id(addr, kD2dRdIdHi);
#endif
        return Word128{
            static_cast<std::uint32_t>(lo),
            static_cast<std::uint32_t>(lo >> 32),
            static_cast<std::uint32_t>(hi),
            static_cast<std::uint32_t>(hi >> 32),
        };
    }
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
        (void)cycles;
        sim_.reset();
        sim_.write_reg(kCfgIsLoop, 0);
    }

    void release_reset(int pre_cycles = 4, int post_cycles = 2) {
        sim_.dut()->reset = 0;
        for (int i = 0; i < pre_cycles + post_cycles; ++i) tick_raw();
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
        sim_.write_mem_word(mem_id, addr, data);
    }

    Word128 mem_read_word_1cycle(int mem_id, int addr) {
        check_mem_addr(mem_id, addr);
        return sim_.read_mem_word(mem_id, addr);
    }

    void write_words_to_mem(int mem_id, int base, const std::vector<Word128>& words) {
        for (std::size_t w = 0; w < words.size(); ++w) check_mem_addr(mem_id, base + static_cast<int>(w));
        sim_.write_mem_words(mem_id, base, words);
    }

    std::vector<Word128> read_words_from_mem(int mem_id, int base, int word_count) {
        for (int w = 0; w < word_count; ++w) check_mem_addr(mem_id, base + w);
        return sim_.read_mem_words(mem_id, base, word_count);
    }

    void clear_mem_range(int mem_id, int base, int elem_count) {
        const int words = ceil_div(elem_count, kFp16PerWord);
        write_words_to_mem(mem_id, base, std::vector<Word128>(static_cast<std::size_t>(words), zero_word()));
    }

    void wait_fifo_space() {
        for (int guard = 0; guard < 10000; ++guard) {
            if ((sim_.read_reg(kCfgCmdStatus0) & 0x1u) == 0) return;
            tick_raw();
        }
        throw std::runtime_error("timeout waiting for TopChip command FIFO space");
    }

    void push_cmd_raw(Cmd96 cmd) {
        sim_.write_reg(kCfgCmdWord00, cmd_word(cmd, 0));
        sim_.write_reg(kCfgCmdWord01, cmd_word(cmd, 1));
        sim_.write_reg(kCfgCmdWord02, cmd_word(cmd, 2));
        sim_.write_reg(kCfgCmdCtrl0, 1);
        sim_.write_reg(kCfgCmdCtrl0, 0);
    }

    void push_cmd(Cmd96 cmd) {
        wait_fifo_space();
        push_cmd_raw(cmd);
    }

    void topchip_wait_for_next_done(int timeout_cycles) {
        constexpr int kPollCycles = 128;
        const auto target = sim_.dut()->io_doneCount_0 + 1;
        for (int cycles = 0; cycles < timeout_cycles; cycles += kPollCycles) {
            sim_.run_core_cycles(kPollCycles);
            if (sim_.read_reg(kCfgDoneCount0) >= target) {
                sim_.refresh_status_regs();
                return;
            }
        }
        sim_.refresh_status_regs();
        throw std::runtime_error("TopChip timeout waiting for next doneCount: target="
                                 + std::to_string(target)
                                 + " got=" + std::to_string(sim_.dut()->io_doneCount_0));
    }

    void topchip_wait_for_done_count(int target_done_count, int timeout_cycles) {
        constexpr int kPollCycles = 128;
        for (int cycles = 0; cycles < timeout_cycles; cycles += kPollCycles) {
            sim_.run_core_cycles(kPollCycles);
            if (sim_.read_reg(kCfgDoneCount0) >= static_cast<std::uint32_t>(target_done_count)) {
                sim_.refresh_status_regs();
                if (sim_.dut()->io_doneCount_0 != static_cast<std::uint32_t>(target_done_count)) {
                    throw std::runtime_error("TopChip doneCount mismatch: expected="
                                             + std::to_string(target_done_count)
                                             + " got=" + std::to_string(sim_.dut()->io_doneCount_0));
                }
                return;
            }
        }
        sim_.refresh_status_regs();
        throw std::runtime_error("TopChip timeout waiting for doneCount: expected="
                                 + std::to_string(target_done_count)
                                 + " got=" + std::to_string(sim_.dut()->io_doneCount_0));
    }

    void topchip_refresh_status() {
        sim_.refresh_status_regs();
    }

    Sim& sim_;
};

} // namespace dexsim::topchip
