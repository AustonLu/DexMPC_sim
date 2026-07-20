#if defined(DEX_CORE_PROBE_SPI)
#define DEX_TOPCHIP_TRANSPORT_SPI
#else
#define DEX_TOPCHIP_TRANSPORT_D2D
#endif

#ifndef DEXMPC_RESULT_DIR
#if defined(DEX_CORE_PROBE_SPI)
#define DEXMPC_RESULT_DIR "verification/results/full_chip/spi/core_probe"
#else
#define DEXMPC_RESULT_DIR "verification/results/full_chip/d2d/core_probe"
#endif
#endif

#include "../../common/topchip_sim.hpp"

#include <array>
#include <filesystem>
#include <fstream>
#include <functional>
#include <initializer_list>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

using namespace dexsim;
using namespace dexsim::topchip;

namespace {

struct TestRecord {
    std::string name;
    bool passed = false;
    std::string detail;
};

std::string json_escape(const std::string& text) {
    std::ostringstream out;
    for (const char ch : text) {
        switch (ch) {
        case '\\': out << "\\\\"; break;
        case '"': out << "\\\""; break;
        case '\n': out << "\\n"; break;
        case '\r': out << "\\r"; break;
        case '\t': out << "\\t"; break;
        default: out << ch; break;
        }
    }
    return out.str();
}

std::string hex16(std::uint16_t value) {
    const char* digits = "0123456789abcdef";
    std::string out = "0x0000";
    for (int nibble = 0; nibble < 4; ++nibble) {
        out[5 - nibble] = digits[(value >> (nibble * 4)) & 0xfu];
    }
    return out;
}

void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

Word128 fp16_word(std::initializer_list<std::uint16_t> values) {
    Word128 word = zero_word();
    int lane = 0;
    for (const auto value : values) {
        if (lane >= kFp16PerWord) break;
        set_fp16_lane(word, lane++, value);
    }
    return word;
}

std::vector<Word128> filled_matrix_words(int rows, int cols, std::uint16_t value) {
    Matrix matrix = make_matrix(rows, cols, value);
    return matrix_to_words(matrix, rows, cols);
}

class CoreProbe {
public:
    CoreProbe(Sim& sim, std::filesystem::path out_dir)
        : sim_(sim), out_dir_(std::move(out_dir)) {}

    int run() {
        std::filesystem::create_directories(out_dir_);
        sim_.reset();
        sim_.write_reg(kCfgIsLoop, 0);

#if defined(DEX_CORE_PROBE_SPI)
        run_case("spi_command_contexts_and_gemm", [this] { test_per_core_gemm(); });
#else
        run_case("d2d_local_temp_external_isolation", [this] { test_memory_isolation(); });
        run_case("d2d_command_contexts_and_per_core_gemm", [this] { test_per_core_gemm(); });
        run_case("d2d_core0_core1_concurrent_gemm", [this] { test_concurrent_gemm(); });
        run_case("d2d_core1_reduce_storage_owner", [this] { test_reduce_owner(); });
        run_case("d2d_core1_lut_storage_owner", [this] { test_lut_owner(); });
#endif

        write_json();
        write_text_summary();

        const bool passed = all_passed();
        std::cout << "CORE_PROBE_RESULT transport=" << transport_name()
                  << " pass=" << (passed ? "true" : "false")
                  << " cycle=" << sim_.cycle()
                  << " output=" << (out_dir_ / "runtime_capabilities.json").string()
                  << "\n";
        return passed ? 0 : 1;
    }

private:
    static constexpr int kTimeoutCycles = 500000;

    std::string transport_name() const {
#if defined(DEX_CORE_PROBE_SPI)
        return "spi";
#else
        return "d2d";
#endif
    }

    void run_case(const std::string& name, const std::function<void()>& fn) {
        TestRecord record;
        record.name = name;
        try {
            fn();
            record.passed = true;
            record.detail = last_detail_;
            std::cout << "[PASS] " << name << ": " << record.detail << "\n";
        } catch (const std::exception& e) {
            record.passed = false;
            record.detail = e.what();
            std::cout << "[FAIL] " << name << ": " << record.detail << "\n";
        }
        records_.push_back(std::move(record));
        last_detail_.clear();
    }

    bool all_passed() const {
        for (const auto& record : records_) {
            if (!record.passed) return false;
        }
        return true;
    }

    void test_memory_isolation() {
        constexpr int kProbeAddr = 31;
        std::array<Word128, 8> patterns{};
        for (int slot = 0; slot < 8; ++slot) {
            patterns[static_cast<std::size_t>(slot)] = Word128{
                0x10000000u + static_cast<std::uint32_t>(slot),
                0x20000000u + static_cast<std::uint32_t>(slot),
                0x30000000u + static_cast<std::uint32_t>(slot),
                0x40000000u + static_cast<std::uint32_t>(slot),
            };
            const int mpc_mem = slot < 4 ? mpc_local_mem(slot) : mpc_temp_mem(slot - 4);
            sim_.write_mpc_mem_word(mpc_mem, kProbeAddr, patterns[static_cast<std::size_t>(slot)]);
        }

        for (int slot = 0; slot < 8; ++slot) {
            const int mpc_mem = slot < 4 ? mpc_local_mem(slot) : mpc_temp_mem(slot - 4);
            const auto observed = sim_.read_mpc_mem_word(mpc_mem, kProbeAddr);
            require(observed == patterns[static_cast<std::size_t>(slot)],
                    "external SRAM alias/readback mismatch at physical mem "
                    + std::to_string(mpc_mem));
        }
        memory_isolation_passed_ = true;
        last_detail_ = "Local0-3 and Temp0-3 accepted distinct values at the same word address";
    }

    void test_per_core_gemm() {
        static constexpr std::array<std::uint16_t, 4> kB{{
            0x4000, // 2
            0x4200, // 3
            0x4400, // 4
            0x4500, // 5
        }};

        std::array<std::uint32_t, kNumCommandContexts> counts{};
        for (int core = 0; core < kNumCommandContexts; ++core) counts[core] = sim_.done_count(core);

        for (int core = 0; core < kNumCommandContexts; ++core) {
            const int mem = mpc_local_mem(core);
            sim_.write_mpc_mem_word(mem, 0, fp16_word({0x3c00})); // 1
            sim_.write_mpc_mem_word(mem, 1, fp16_word({kB[static_cast<std::size_t>(core)]}));
            sim_.write_mpc_mem_word(mem, 2, zero_word());

            const auto cmd = make_cmd(
                static_cast<std::uint32_t>(0x10 + core),
                kOpLa,
                kSubGemm,
                true,
                pack_addr(kMemLocal0, 0),
                pack_addr(kMemLocal0, 1),
                pack_addr(kMemLocal0, 2),
                1,
                1,
                1);

            const auto before = counts;
            sim_.push_cmd(core, cmd);
            sim_.wait_for_done_count(core, before[static_cast<std::size_t>(core)] + 1,
                                     kTimeoutCycles);
            for (int observed_core = 0; observed_core < kNumCommandContexts; ++observed_core) {
                counts[static_cast<std::size_t>(observed_core)] = sim_.done_count(observed_core);
                const auto expected = before[static_cast<std::size_t>(observed_core)]
                    + (observed_core == core ? 1u : 0u);
                require(counts[static_cast<std::size_t>(observed_core)] == expected,
                        "command submitted to core " + std::to_string(core)
                        + " changed doneCount of core " + std::to_string(observed_core));
            }

            const auto last = sim_.last_done(core);
            require(((last >> 20) & 1u) == 0, "core " + std::to_string(core) + " reported illegal GEMM");
            require(((last >> 12) & 0x7u) == kOpLa,
                    "core " + std::to_string(core) + " lastDone opcode mismatch");
            require(((last >> 15) & 0xfu) == kSubGemm,
                    "core " + std::to_string(core) + " lastDone subop mismatch");

            const auto output = sim_.read_mpc_mem_word(mem, 2);
            const auto value = get_fp16_lane(output, 0);
            require(value == kB[static_cast<std::size_t>(core)],
                    "core " + std::to_string(core) + " GEMM result mismatch: expected "
                    + hex16(kB[static_cast<std::size_t>(core)]) + " got " + hex16(value));
            gemm_validated_[static_cast<std::size_t>(core)] = true;
        }

        last_detail_ = "all four command contexts completed isolated 1x1 local GEMMs with exact FP16 results";
    }

    void test_concurrent_gemm() {
        constexpr int kRows = 16;
        constexpr int kCols = 16;
        constexpr int kDim = 16;
        constexpr int kBaseA = 64;
        constexpr int kBaseB = 96;
        constexpr int kBaseC = 128;
        constexpr std::uint16_t kExpected = 0x4c00; // 16

        const auto matrix = filled_matrix_words(kRows, kDim, 0x3c00);
        const auto output_zeros = filled_matrix_words(kRows, kCols, 0);
        for (const int core : {0, 1}) {
            const int mem = mpc_local_mem(core);
            sim_.write_mpc_mem_words(mem, kBaseA, matrix);
            sim_.write_mpc_mem_words(mem, kBaseB, matrix);
            sim_.write_mpc_mem_words(mem, kBaseC, output_zeros);
        }

        const auto count0 = sim_.done_count(0);
        const auto count1 = sim_.done_count(1);
        const auto cmd0 = make_cmd(0x80, kOpLa, kSubGemm, true,
                                   pack_addr(kMemLocal0, kBaseA),
                                   pack_addr(kMemLocal0, kBaseB),
                                   pack_addr(kMemLocal0, kBaseC),
                                   kCols, kRows, kDim);
        const auto cmd1 = make_cmd(0x81, kOpLa, kSubGemm, true,
                                   pack_addr(kMemLocal0, kBaseA),
                                   pack_addr(kMemLocal0, kBaseB),
                                   pack_addr(kMemLocal0, kBaseC),
                                   kCols, kRows, kDim);

        sim_.stage_cmd(0, cmd0);
        sim_.stage_cmd(1, cmd1);
        const auto start_cycle = sim_.cycle();
        sim_.set_cmd_push(0, true);
        sim_.set_cmd_push(1, true);

        bool both_busy = false;
        bool finished = false;
        for (int guard = 0; guard < kTimeoutCycles; guard += 8) {
            const auto status0 = sim_.command_status(0);
            const auto status1 = sim_.command_status(1);
            both_busy = both_busy || (((status0 >> 2) & 1u) != 0 && ((status1 >> 2) & 1u) != 0);
            if (sim_.done_count(0) == count0 + 1 && sim_.done_count(1) == count1 + 1) {
                finished = true;
                break;
            }
            sim_.run_core_cycles(8);
        }
        const auto elapsed = sim_.cycle() - start_cycle;
        sim_.set_cmd_push(0, false);
        sim_.set_cmd_push(1, false);

        require(finished, "concurrent core0/core1 GEMMs did not both complete");
        require(both_busy, "core0/core1 busy windows were never observed to overlap");

        for (const int core : {0, 1}) {
            const auto words = sim_.read_mpc_mem_words(mpc_local_mem(core), kBaseC,
                                                       static_cast<int>(output_zeros.size()));
            const auto values = unpack_elements(words, kRows * kCols);
            for (std::size_t i = 0; i < values.size(); ++i) {
                require(values[i] == kExpected,
                        "concurrent GEMM result mismatch on core " + std::to_string(core)
                        + " element " + std::to_string(i));
            }
        }

        concurrent_core01_passed_ = true;
        last_detail_ = "core0/core1 busy windows overlapped; both 16x16x16 GEMMs were exact, elapsed_cycles="
            + std::to_string(elapsed);
    }

    int detect_reduce_owner(int command_mem_id, int core0_mpc_mem, int core1_mpc_mem,
                            int base, std::uint32_t cmd_id) {
        sim_.write_mpc_mem_word(core0_mpc_mem, base, fp16_word({0x3c00, 0x3c00})); // 1+1=2
        sim_.write_mpc_mem_word(core1_mpc_mem, base, fp16_word({0x4000, 0x4000})); // 2+2=4

        const auto before = sim_.done_count(1);
        const auto cmd = make_cmd(cmd_id, kOpReduce, kSubAddTree, true,
                                  pack_addr(command_mem_id, base), 0, 0, 2, 0, 0);
        sim_.push_cmd(1, cmd);
        sim_.wait_for_done_count(1, before + 1, kTimeoutCycles);

        const auto result_reg = sim_.read_reg(cfg_add_reduce(1));
        require(((result_reg >> 28) & 1u) != 0, "core1 add-reduce result valid bit was not set");
        require(((result_reg >> 16) & 0xfffu) == cmd_id,
                "core1 add-reduce result command id mismatch");
        const auto value = static_cast<std::uint16_t>(result_reg & 0xffffu);
        if (value == 0x4000) return 0;
        if (value == 0x4400) return 1;
        throw std::runtime_error("core1 reduce read neither core0 nor core1 test data; value="
                                 + hex16(value));
    }

    void test_reduce_owner() {
        shared_local_owner_ = detect_reduce_owner(kMemLocal0, mpc_local_mem(0), mpc_local_mem(1),
                                                  200, 0x120);
        shared_temp_owner_ = detect_reduce_owner(kMemTemp0, mpc_temp_mem(0), mpc_temp_mem(1),
                                                 200, 0x121);
        require(shared_local_owner_ == 0,
                "core1 Reduce local access resolved to core" + std::to_string(shared_local_owner_));
        require(shared_temp_owner_ == 0,
                "core1 Reduce temp access resolved to core" + std::to_string(shared_temp_owner_));
        last_detail_ = "Reduce submitted through cmd context 1 read Local0 and Temp0, not Local1/Temp1";
    }

    void load_softplus_lut() {
        const auto data = load_hex_u32("rtl/chisel/top_connect/src/lut/tools/softplus_data.hex");
        require(data.size() == 512, "unexpected softplus LUT image size");
        for (int bank = 0; bank < 2; ++bank) {
            std::vector<Word128> words(256, zero_word());
            for (int i = 0; i < 256; ++i) {
                words[static_cast<std::size_t>(i)][0] =
                    data[static_cast<std::size_t>(bank * 256 + i)];
            }
            sim_.write_mpc_mem_words(13 + bank, 0, words);
        }
    }

    void test_lut_owner() {
        constexpr int kSrc = 220;
        constexpr int kDst = 221;
        constexpr std::uint16_t kCore0Sentinel = 0x7e00;
        constexpr std::uint16_t kCore1Sentinel = 0x7d00;
        load_softplus_lut();

        sim_.write_mpc_mem_word(mpc_local_mem(0), kSrc, fp16_word({0x0000}));
        sim_.write_mpc_mem_word(mpc_local_mem(1), kSrc, fp16_word({0x3c00}));
        sim_.write_mpc_mem_word(mpc_local_mem(0), kDst, fp16_word({kCore0Sentinel}));
        sim_.write_mpc_mem_word(mpc_local_mem(1), kDst, fp16_word({kCore1Sentinel}));

        const auto before = sim_.done_count(1);
        const auto cmd = make_cmd(0x130, kOpLut, kSubSoftplus, true,
                                  pack_addr(kMemLocal0, kSrc),
                                  pack_addr(kMemLocal0, kDst),
                                  0, 1, 1, 0);
        sim_.push_cmd(1, cmd);
        sim_.wait_for_done_count(1, before + 1, kTimeoutCycles);

        const auto local0 = get_fp16_lane(sim_.read_mpc_mem_word(mpc_local_mem(0), kDst), 0);
        const auto local1 = get_fp16_lane(sim_.read_mpc_mem_word(mpc_local_mem(1), kDst), 0);
        const bool wrote_local0 = local0 != kCore0Sentinel;
        const bool wrote_local1 = local1 != kCore1Sentinel;
        require(wrote_local0 && !wrote_local1,
                "core1 LUT destination ownership ambiguous: local0=" + hex16(local0)
                + " local1=" + hex16(local1));
        shared_lut_local_owner_ = 0;
        last_detail_ = "Softplus submitted through cmd context 1 wrote Local0 and left Local1 unchanged";
    }

    void write_json() const {
        std::ofstream out(out_dir_ / "runtime_capabilities.json");
        if (!out) throw std::runtime_error("failed to create runtime_capabilities.json");
        out << "{\n";
        out << "  \"schema_version\": 1,\n";
        out << "  \"transport\": \"" << transport_name() << "\",\n";
        out << "  \"overall_pass\": " << (all_passed() ? "true" : "false") << ",\n";
        out << "  \"simulated_core_cycles\": " << sim_.cycle() << ",\n";
        out << "  \"tests\": [\n";
        for (std::size_t i = 0; i < records_.size(); ++i) {
            const auto& record = records_[i];
            out << "    {\"name\": \"" << json_escape(record.name)
                << "\", \"passed\": " << (record.passed ? "true" : "false")
                << ", \"detail\": \"" << json_escape(record.detail) << "\"}"
                << (i + 1 == records_.size() ? "\n" : ",\n");
        }
        out << "  ],\n";
        out << "  \"capabilities\": {\n";
        out << "    \"external_device_ports\": 1,\n";
        out << "    \"rtl_command_contexts\": 4,\n";
        out << "    \"external_local_temp_isolation_validated\": "
            << (memory_isolation_passed_ ? "true" : "false") << ",\n";
        out << "    \"gemm_validated_cores\": [";
        bool first = true;
        for (int core = 0; core < kNumCommandContexts; ++core) {
            if (!gemm_validated_[static_cast<std::size_t>(core)]) continue;
            if (!first) out << ", ";
            out << core;
            first = false;
        }
        out << "],\n";
        out << "    \"concurrent_gemm_pairs\": "
            << (concurrent_core01_passed_ ? "[[0, 1]]" : "[]") << ",\n";
        out << "    \"shared_engine_local_owner\": " << shared_local_owner_ << ",\n";
        out << "    \"shared_engine_temp_owner\": " << shared_temp_owner_ << ",\n";
        out << "    \"lut_local_owner\": " << shared_lut_local_owner_ << "\n";
        out << "  }\n";
        out << "}\n";
    }

    void write_text_summary() const {
        std::ofstream out(out_dir_ / "core_probe_summary.txt");
        if (!out) throw std::runtime_error("failed to create core_probe_summary.txt");
        out << "transport=" << transport_name() << "\n";
        out << "overall_pass=" << (all_passed() ? "true" : "false") << "\n";
        out << "simulated_core_cycles=" << sim_.cycle() << "\n";
        for (const auto& record : records_) {
            out << (record.passed ? "PASS" : "FAIL") << " " << record.name
                << " " << record.detail << "\n";
        }
    }

    Sim& sim_;
    std::filesystem::path out_dir_;
    std::vector<TestRecord> records_;
    std::string last_detail_;
    bool memory_isolation_passed_ = false;
    std::array<bool, kNumCommandContexts> gemm_validated_{{false, false, false, false}};
    bool concurrent_core01_passed_ = false;
    int shared_local_owner_ = -1;
    int shared_temp_owner_ = -1;
    int shared_lut_local_owner_ = -1;
};

} // namespace

int main(int argc, char** argv) {
    try {
        Sim sim(argc, argv);
        CoreProbe probe(sim, DEXMPC_RESULT_DIR);
        return probe.run();
    } catch (const std::exception& e) {
        std::cerr << "Core capability probe failed before report generation: " << e.what() << "\n";
        return 2;
    }
}
