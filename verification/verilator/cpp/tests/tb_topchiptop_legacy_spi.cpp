#include "VTopChipTop.h"
#include "verilated.h"

#include <array>
#include <cstdint>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

using Word128 = std::array<std::uint32_t, 4>;

constexpr std::uint32_t kBaseDexmpcAddr = 0x00000000u;
constexpr int kMpcCfgRwTestRegCount = 22;

std::uint32_t mpc_cfg_addr(int reg_idx) {
    return kBaseDexmpcAddr + (static_cast<std::uint32_t>(reg_idx) << 3);
}

std::uint32_t mpc_sram_addr(int mem_id, int word_addr) {
    return kBaseDexmpcAddr
        + ((0x00008000u + (static_cast<std::uint32_t>(mem_id) << 11)
            + static_cast<std::uint32_t>(word_addr)) << 3);
}

std::uint32_t cfg_test_pattern(int reg_idx, int phase) {
    const auto r = static_cast<std::uint32_t>(reg_idx);
    std::uint32_t value = 0;
    switch (phase & 3) {
    case 0:
        value = 0xa5a55a5au ^ (r * 0x01010001u);
        break;
    case 1:
        value = 0x3c3cc3c3u ^ ((r & 0xffu) << 24) ^ (((~r) & 0xffu) << 16)
              ^ 0x00009669u;
        break;
    case 2:
        value = 0x13579bdfu ^ 0x5a00a500u ^ ((r & 0xffu) << 16) ^ ((~r) & 0xffu);
        break;
    default:
        value = 0xfeed1234u ^ (r * 0x10210011u);
        break;
    }
    return value == 0 ? 1 : value;
}

int sram_depth(int mem_id) {
    switch (mem_id) {
    case 0:
        return 2048;
    case 1:
    case 2:
    case 3:
    case 4:
        return 512;
    case 5:
    case 6:
    case 7:
    case 8:
        return 896;
    case 9:
    case 10:
    case 11:
    case 12:
        return 128;
    case 13:
    case 14:
        return 256;
    default:
        return 1;
    }
}

int sram_data_width(int mem_id) {
    switch (mem_id) {
    case 9:
    case 10:
    case 11:
    case 12:
        return 16;
    case 13:
    case 14:
        return 32;
    default:
        return 128;
    }
}

int sram_test_addr(int mem_id, int slot) {
    const int depth = sram_depth(mem_id);
    if (slot == 0) return 0;
    if (slot == 1) return depth > 1 ? depth - 1 : 0;
    return depth > 2 ? depth >> 1 : 0;
}

Word128 sram_valid_mask(int mem_id) {
    switch (sram_data_width(mem_id)) {
    case 16:
        return Word128{0x0000ffffu, 0, 0, 0};
    case 32:
        return Word128{0xffffffffu, 0, 0, 0};
    default:
        return Word128{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
    }
}

Word128 sram_test_pattern(int mem_id, int word_addr, int phase) {
    const std::uint32_t mix =
        (static_cast<std::uint32_t>(mem_id) * 0x01010011u)
        ^ (static_cast<std::uint32_t>(word_addr) * 0x00101101u)
        ^ (static_cast<std::uint32_t>(phase) * 0x10210001u);
    return Word128{
        0x01234567u ^ mix,
        0x89abcdefu ^ ((mix << 16) | (mix >> 16)),
        0x13579bdfu ^ (((~mix) & 0xffu) << 24) ^ (mix >> 8),
        0xfedcba98u ^ ((mix << 8) | (mix >> 24)),
    };
}

Word128 mask_word(const Word128& value, const Word128& mask) {
    return Word128{
        value[0] & mask[0],
        value[1] & mask[1],
        value[2] & mask[2],
        value[3] & mask[3],
    };
}

bool word_equal(const Word128& lhs, const Word128& rhs) {
    return lhs[0] == rhs[0] && lhs[1] == rhs[1] && lhs[2] == rhs[2] && lhs[3] == rhs[3];
}

std::string hex32(std::uint32_t value) {
    constexpr char digits[] = "0123456789abcdef";
    std::string out(8, '0');
    for (int i = 7; i >= 0; --i) {
        out[static_cast<std::size_t>(i)] = digits[value & 0xfu];
        value >>= 4;
    }
    return out;
}

std::string hex128(const Word128& value) {
    return "0x" + hex32(value[3]) + hex32(value[2]) + hex32(value[1]) + hex32(value[0]);
}

class TopChipTopSim {
public:
    TopChipTopSim(int argc, char** argv)
        : context_(std::make_unique<VerilatedContext>()),
          dut_(std::make_unique<VTopChipTop>(context_.get())) {
        context_->commandArgs(argc, argv);
        drive_defaults();
        dut_->eval();
    }

    VTopChipTop* dut() { return dut_.get(); }

    std::uint64_t cycle() const { return cycle_; }

    void reset() {
        auto* d = dut();
        d->pad_clock_sel = 0;
        d->pad_reset = 1;
        run_core_cycles(20);
        d->pad_reset = 0;
        run_core_cycles(40);
    }

    void run_core_cycles(int cycles) {
        for (int i = 0; i < cycles; ++i) {
            tick_half();
            tick_half();
        }
    }

    std::uint32_t spi_write(std::uint32_t addr, std::uint32_t data) {
        return spi_transfer(0x80u, addr, data);
    }

    std::uint32_t spi_read(std::uint32_t addr) {
        return spi_transfer(0xc0u, addr, 0);
    }

    void spi_write64(std::uint32_t addr, std::uint64_t data) {
        spi_write(addr, static_cast<std::uint32_t>(data));
        spi_write(addr + 4, static_cast<std::uint32_t>(data >> 32));
    }

    std::uint64_t spi_read64(std::uint32_t addr) {
        const auto lo = spi_read(addr);
        const auto hi = spi_read(addr + 4);
        return (std::uint64_t(hi) << 32) | lo;
    }

    void spi_write128_sameaddr(std::uint32_t addr, const Word128& data) {
        spi_write64(addr, (std::uint64_t(data[1]) << 32) | data[0]);
        spi_write64(addr, (std::uint64_t(data[3]) << 32) | data[2]);
    }

    Word128 spi_read128_sameaddr(std::uint32_t addr) {
        const auto lo = spi_read64(addr);
        const auto hi = spi_read64(addr);
        return Word128{
            static_cast<std::uint32_t>(lo),
            static_cast<std::uint32_t>(lo >> 32),
            static_cast<std::uint32_t>(hi),
            static_cast<std::uint32_t>(hi >> 32),
        };
    }

private:
    static constexpr int kHalfCyclesPerSpiPhase = 4;

    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<VTopChipTop> dut_;
    bool clock_ = false;
    std::uint64_t cycle_ = 0;

    void drive_defaults() {
        auto* d = dut();
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

    void tick_half() {
        clock_ = !clock_;
        dut_->pad_clock = clock_ ? 1 : 0;
        dut_->eval();
        context_->timeInc(2);
        if (clock_) ++cycle_;
    }

    void settle_spi() {
        run_core_cycles(kHalfCyclesPerSpiPhase);
    }

    std::uint32_t spi_transfer(std::uint8_t cmd, std::uint32_t addr, std::uint32_t data) {
        std::array<int, 80> bits{};
        for (int i = 0; i < 8; ++i) bits[static_cast<std::size_t>(i)] = (cmd >> (7 - i)) & 1u;
        for (int i = 0; i < 32; ++i) bits[static_cast<std::size_t>(8 + i)] = (addr >> (31 - i)) & 1u;
        for (int i = 0; i < 32; ++i) bits[static_cast<std::size_t>(40 + i)] = (data >> (31 - i)) & 1u;
        for (int i = 0; i < 8; ++i) bits[static_cast<std::size_t>(72 + i)] = 0;

        auto* d = dut();
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
};

void test_config_spi(TopChipTopSim& sim) {
    int pass = 0;
    for (int phase = 0; phase < 2; ++phase) {
        for (int idx = 0; idx < kMpcCfgRwTestRegCount; ++idx) {
            const int reg_idx = phase == 0 ? idx : (kMpcCfgRwTestRegCount - 1 - idx);
            const auto addr = mpc_cfg_addr(reg_idx);
            const auto expected = cfg_test_pattern(reg_idx, phase);
            sim.spi_write(addr, expected);
            const auto got = sim.spi_read(addr);
            if (got != expected) {
                throw std::runtime_error(
                    "SPI config mismatch reg=" + std::to_string(reg_idx)
                    + " addr=0x" + hex32(addr)
                    + " expected=0x" + hex32(expected)
                    + " got=0x" + hex32(got));
            }
            ++pass;
        }
    }
    std::cout << "SPI config register smoke passed, cases=" << pass << "\n";
}

void test_sram_spi(TopChipTopSim& sim, bool full) {
    const std::vector<int> mem_ids = full
        ? std::vector<int>{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}
        : std::vector<int>{0, 1, 5, 9, 13};
    int pass = 0;
    for (int mem_id : mem_ids) {
        for (int slot = 0; slot < 3; ++slot) {
            const int word_addr = sram_test_addr(mem_id, slot);
            const auto addr = mpc_sram_addr(mem_id, word_addr);
            const auto data = sram_test_pattern(mem_id, word_addr, slot);
            const auto mask = sram_valid_mask(mem_id);
            sim.spi_write128_sameaddr(addr, data);
            const auto got = sim.spi_read128_sameaddr(addr);
            const auto expected_masked = mask_word(data, mask);
            const auto got_masked = mask_word(got, mask);
            if (!word_equal(got_masked, expected_masked)) {
                throw std::runtime_error(
                    "SPI SRAM mismatch mem=" + std::to_string(mem_id)
                    + " word=" + std::to_string(word_addr)
                    + " addr=0x" + hex32(addr)
                    + " expected=" + hex128(expected_masked)
                    + " got=" + hex128(got_masked));
            }
            ++pass;
        }
    }
    std::cout << "SPI SRAM smoke passed, cases=" << pass
              << (full ? " (full memory-id sweep)" : " (representative memory-id sweep)")
              << "\n";
}

} // namespace

int main(int argc, char** argv) {
    try {
        bool full_sram = false;
        for (int i = 1; i < argc; ++i) {
            if (std::string(argv[i]) == "--full-sram") full_sram = true;
        }

        TopChipTopSim sim(argc, argv);
        sim.reset();
        test_config_spi(sim);
        test_sram_spi(sim, full_sram);

        std::cout << "TopChipTop legacy SPI C++ test passed at core cycle "
                  << sim.cycle() << "\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "TopChipTop legacy SPI C++ test failed: " << e.what() << "\n";
        return 1;
    }
}
