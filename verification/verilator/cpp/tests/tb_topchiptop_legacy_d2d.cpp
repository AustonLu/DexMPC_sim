#include "VTopChipTopD2dHarness.h"
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

std::uint64_t make64(std::uint32_t hi, std::uint32_t lo) {
    return (std::uint64_t(hi) << 32) | lo;
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

std::string hex64(std::uint64_t value) {
    return "0x" + hex32(static_cast<std::uint32_t>(value >> 32))
        + hex32(static_cast<std::uint32_t>(value));
}

std::string hex128(const Word128& value) {
    return "0x" + hex32(value[3]) + hex32(value[2]) + hex32(value[1]) + hex32(value[0]);
}

class TopChipTopD2dSim {
public:
    TopChipTopD2dSim(int argc, char** argv)
        : context_(std::make_unique<VerilatedContext>()),
          dut_(std::make_unique<VTopChipTopD2dHarness>(context_.get())) {
        context_->commandArgs(argc, argv);
        drive_defaults();
        dut_->eval();
    }

    std::uint64_t cycle() const { return cycle_; }

    void reset() {
        auto* d = dut();
        d->clock_sel = 0;
        d->reset = 1;
        run_core_cycles(20);
        d->reset = 0;
        run_core_cycles(120);
    }

    void run_core_cycles(int cycles) {
        for (int i = 0; i < cycles; ++i) {
            wait_core_posedge();
        }
    }

    void d2d_write(std::uint32_t addr, std::uint8_t id, std::uint8_t len,
                   const std::vector<std::uint64_t>& data) {
        if (data.size() < static_cast<std::size_t>(len) + 1) {
            throw std::runtime_error("D2D write data shorter than burst length");
        }

        auto* d = dut();
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
                if (resp != 0) {
                    throw std::runtime_error("D2D write response error addr=0x" + hex32(addr)
                                             + " id=" + std::to_string(id)
                                             + " resp=" + std::to_string(resp));
                }
                if (got_id != id) {
                    throw std::runtime_error("D2D write response id mismatch addr=0x" + hex32(addr)
                                             + " expected=" + std::to_string(id)
                                             + " got=" + std::to_string(got_id));
                }
                return;
            }
        }

        clear_write_inputs();
        throw std::runtime_error("D2D write timeout addr=0x" + hex32(addr)
                                 + " id=" + std::to_string(id)
                                 + " aw_done=" + std::to_string(aw_done)
                                 + " w_done=" + std::to_string(w_done));
    }

    std::vector<std::uint64_t> d2d_read(std::uint32_t addr, std::uint8_t id, std::uint8_t len) {
        auto* d = dut();
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

                if (resp != 0) {
                    clear_read_inputs();
                    throw std::runtime_error("D2D read response error addr=0x" + hex32(addr)
                                             + " id=" + std::to_string(id)
                                             + " resp=" + std::to_string(resp));
                }
                if (got_id != id) {
                    clear_read_inputs();
                    throw std::runtime_error("D2D read response id mismatch addr=0x" + hex32(addr)
                                             + " expected=" + std::to_string(id)
                                             + " got=" + std::to_string(got_id));
                }
                if (last || data.size() == static_cast<std::size_t>(len) + 1) {
                    clear_read_inputs();
                    return data;
                }
            }
        }

        clear_read_inputs();
        throw std::runtime_error("D2D read timeout addr=0x" + hex32(addr)
                                 + " id=" + std::to_string(id)
                                 + " ar_done=" + std::to_string(ar_done)
                                 + " beats=" + std::to_string(data.size()));
    }

    void d2d_write64(std::uint32_t addr, std::uint8_t id, std::uint64_t data) {
        d2d_write(addr, id, 0, std::vector<std::uint64_t>{data});
    }

    std::uint64_t d2d_read64(std::uint32_t addr, std::uint8_t id) {
        const auto data = d2d_read(addr, id, 0);
        if (data.empty()) {
            throw std::runtime_error("D2D read returned no data addr=0x" + hex32(addr));
        }
        return data[0];
    }

private:
    static constexpr int kTransactionTimeoutCycles = 100000;

    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<VTopChipTopD2dHarness> dut_;
    bool clock_ = false;
    bool d2d_ref_clock_ = true;
    std::uint64_t time_ = 0;
    std::uint64_t cycle_ = 0;

    VTopChipTopD2dHarness* dut() { return dut_.get(); }

    void drive_defaults() {
        auto* d = dut();
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
        }
        context_->timeInc(1);
        ++time_;
    }

    void wait_core_posedge() {
        while (true) {
            const bool prev_clock = clock_;
            step_time();
            if (!prev_clock && clock_) {
                return;
            }
        }
    }

    void clear_write_inputs() {
        auto* d = dut();
        d->d2dm_aw_valid = 0;
        d->d2dm_w_valid = 0;
        d->d2dm_w_last = 0;
        d->d2dm_w_strb = 0;
        d->d2dm_b_ready = 0;
    }

    void clear_read_inputs() {
        auto* d = dut();
        d->d2dm_ar_valid = 0;
        d->d2dm_r_ready = 0;
    }
};

void test_config_d2d(TopChipTopD2dSim& sim) {
    int pass = 0;
    for (int phase = 0; phase < 2; ++phase) {
        for (int idx = 0; idx < kMpcCfgRwTestRegCount; ++idx) {
            const int reg_idx = phase == 0 ? idx : (kMpcCfgRwTestRegCount - 1 - idx);
            const auto addr = mpc_cfg_addr(reg_idx);
            const auto expected = cfg_test_pattern(reg_idx, phase + 2);
            const auto wr_id = static_cast<std::uint8_t>(phase == 0 ? 0x0c : 0x0d);
            const auto rd_id = static_cast<std::uint8_t>(phase == 0 ? 0x2a : 0x2b);

            sim.d2d_write64(addr, wr_id, make64(0, expected));
            const auto got = static_cast<std::uint32_t>(sim.d2d_read64(addr, rd_id));
            if (got != expected) {
                throw std::runtime_error(
                    "D2D config mismatch reg=" + std::to_string(reg_idx)
                    + " addr=0x" + hex32(addr)
                    + " expected=0x" + hex32(expected)
                    + " got=0x" + hex32(got));
            }
            ++pass;
        }
    }
    std::cout << "D2D config register smoke passed, cases=" << pass << "\n";
}

void test_sram_d2d(TopChipTopD2dSim& sim, bool full) {
    const std::vector<int> mem_ids = full
        ? std::vector<int>{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}
        : std::vector<int>{0, 1, 5, 9, 13};
    int pass = 0;
    for (int mem_id : mem_ids) {
        for (int slot = 0; slot < 3; ++slot) {
            const int word_addr = sram_test_addr(mem_id, slot);
            const auto addr = mpc_sram_addr(mem_id, word_addr);
            const auto data = sram_test_pattern(mem_id, word_addr, slot + 2);
            const auto mask = sram_valid_mask(mem_id);

            sim.d2d_write64(addr, 0x0c, make64(data[1], data[0]));
            sim.d2d_write64(addr, 0x0d, make64(data[3], data[2]));
            const auto lo = sim.d2d_read64(addr, 0x2a);
            const auto hi = sim.d2d_read64(addr, 0x2b);
            const Word128 got{
                static_cast<std::uint32_t>(lo),
                static_cast<std::uint32_t>(lo >> 32),
                static_cast<std::uint32_t>(hi),
                static_cast<std::uint32_t>(hi >> 32),
            };
            const auto expected_masked = mask_word(data, mask);
            const auto got_masked = mask_word(got, mask);
            if (!word_equal(got_masked, expected_masked)) {
                throw std::runtime_error(
                    "D2D SRAM mismatch mem=" + std::to_string(mem_id)
                    + " word=" + std::to_string(word_addr)
                    + " addr=0x" + hex32(addr)
                    + " expected=" + hex128(expected_masked)
                    + " got=" + hex128(got_masked)
                    + " lo=" + hex64(lo)
                    + " hi=" + hex64(hi));
            }
            ++pass;
        }
    }
    std::cout << "D2D SRAM smoke passed, cases=" << pass
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

        TopChipTopD2dSim sim(argc, argv);
        sim.reset();
        test_config_d2d(sim);
        test_sram_d2d(sim, full_sram);

        std::cout << "TopChipTop legacy D2D C++ test passed at core cycle "
                  << sim.cycle() << "\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "TopChipTop legacy D2D C++ test failed: " << e.what() << "\n";
        return 1;
    }
}
