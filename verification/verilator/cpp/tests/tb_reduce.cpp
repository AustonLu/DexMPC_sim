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
#define DEXMPC_RESULT_DIR "verification/results/core_top/reduce"
#endif

namespace {

struct ReduceCase {
    int elem_count = 0;
    int word_count = 0;
    int seq = 0;
    int mem_id = 0;
    bool cmp_mode = false;
    uint32_t req_id = 0;
    uint32_t cmd_id = 0;
    int base_addr = 0;
    Cmd96 cmd = 0;
    std::array<uint16_t, 48> data{};
    uint16_t result_value = 0;
    uint16_t result_index = 0;
    bool done_seen = false;
    bool result_seen = false;
};

class ReduceTest : public TestBase {
public:
    ReduceTest(Sim& sim, std::filesystem::path out_dir)
        : TestBase(sim), out_dir_(std::move(out_dir)) {}

    void run() {
        std::filesystem::create_directories(out_dir_);
        build_cases();
        write_input_csv();

        reset_sequence();
        preload_cases();
        release_reset();

#ifdef DEXMPC_USE_TOPCHIP_SIM
        for (const auto& c : cases_) {
            push_cmd(c.cmd);
            topchip_wait_for_next_done(kTimeoutCycles);
            monitor_done();
        }
#else
        for (const auto& c : cases_) {
            push_cmd(c.cmd);
        }
        int cycles = 0;
        while (done_count_ < static_cast<int>(cases_.size()) && cycles < kTimeoutCycles) {
            tick();
            ++cycles;
        }
        if (done_count_ < static_cast<int>(cases_.size())) {
            throw std::runtime_error("reduce timeout waiting for done_count");
        }
#endif

        write_output_csv();
        std::cout << "Reduce C++ test passed at cycle " << sim_.cycle()
                  << ", cases=" << cases_.size() << "\n";
    }

protected:
    void monitor_done() override {
        auto* d = sim_.dut();
        if (d->reset) return;
        if ((d->io_cmdStatus_0 & (1u << 5)) != 0) {
            throw std::runtime_error("reduce cmdStatus overflow set");
        }
        if (d->io_doneCount_0 == last_done_count_) return;
        if (d->io_doneCount_0 != last_done_count_ + 1) {
            throw std::runtime_error("reduce doneCount jump");
        }

        const uint32_t last = d->io_lastDone_0;
        const uint32_t done_cmd_id = last & 0xfffu;
        const uint32_t done_opcode = (last >> 12) & 0x7u;
        const uint32_t done_subop = (last >> 15) & 0xfu;
        const bool group_end = ((last >> 19) & 1u) != 0;
        const bool illegal = ((last >> 20) & 1u) != 0;

        if (illegal) throw std::runtime_error("reduce illegal command reported");
        if (done_cmd_id != static_cast<uint32_t>(expected_done_)) {
            throw std::runtime_error("reduce doneCmdId out of order");
        }
        if (done_opcode != kOpReduce) throw std::runtime_error("reduce done opcode mismatch");

        auto& c = cases_.at(done_cmd_id);
        if (c.cmp_mode && done_subop != kSubCmpReduce) throw std::runtime_error("reduce cmp subop mismatch");
        if (!c.cmp_mode && done_subop != kSubAddTree) throw std::runtime_error("reduce add subop mismatch");
        if (group_end != (expected_done_ == static_cast<int>(cases_.size()) - 1)) {
            throw std::runtime_error("reduce group_end mismatch");
        }
        if (c.result_seen) throw std::runtime_error("duplicate reduce result");

        if (c.cmp_mode) {
            const uint32_t reg0 = d->io_cmpReduceReg0_0;
            const uint32_t reg1 = d->io_cmpReduceReg1_0;
            const uint16_t val = static_cast<uint16_t>(reg0 & 0xffffu);
            const uint32_t cmd = (reg0 >> 16) & 0xfffu;
            const bool valid = ((reg0 >> 28) & 1u) != 0;
            const uint16_t idx = static_cast<uint16_t>(reg1 & 0xfffu);
            if (!valid) throw std::runtime_error("cmpReduce valid not set");
            if (cmd != done_cmd_id) throw std::runtime_error("cmpReduce cmd id mismatch");
            c.result_value = val;
            c.result_index = idx;
        } else {
            const uint32_t reg = d->io_addReduceReg_0;
            const uint16_t val = static_cast<uint16_t>(reg & 0xffffu);
            const uint32_t cmd = (reg >> 16) & 0xfffu;
            const bool valid = ((reg >> 28) & 1u) != 0;
            if (!valid) throw std::runtime_error("addReduce valid not set");
            if (cmd != done_cmd_id) throw std::runtime_error("addReduce cmd id mismatch");
            c.result_value = val;
            c.result_index = 0;
        }

        c.result_seen = true;
        c.done_seen = true;
        ++done_count_;
        ++expected_done_;
        last_done_count_ = d->io_doneCount_0;
    }

private:
    static constexpr int kCases = 36;
    static constexpr int kMaxElems = 48;
    static constexpr int kTimeoutCycles = 300000;

    const std::array<int, kCases> size_plan_{{
        5, 12, 16, 17, 33, 20, 31, 48, 9, 24, 15, 40,
        5, 12, 16, 17, 33, 20, 31, 48, 9, 24, 15, 40,
        5, 12, 16, 17, 33, 20, 31, 48, 9, 24, 15, 40,
    }};
    const std::array<int, kCases> mode_plan_{{
        0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1,
        0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1,
        0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1,
    }};
    const std::array<int, kCases> seq_plan_{{
        0, 1, 2, 3, 0, 1, 2, 3, 0, 2, 1, 3,
        0, 1, 2, 3, 0, 1, 2, 3, 0, 2, 1, 3,
        0, 1, 2, 3, 0, 1, 2, 3, 0, 2, 1, 3,
    }};

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
            throw std::runtime_error("unknown reduce mem id");
        }
        check_mem_addr(mem_id, base + words - 1);
    }

    void build_cases() {
        std::mt19937 rng(0x20260309u);
        cases_.assign(kCases, {});
        next_global_ = 0;
        next_local_ = 0;
        next_temp_ = 0;

        for (int cid = 0; cid < kCases; ++cid) {
            auto& c = cases_[static_cast<size_t>(cid)];
            c.elem_count = size_plan_[static_cast<size_t>(cid)];
            c.cmp_mode = mode_plan_[static_cast<size_t>(cid)] != 0;
            c.seq = seq_plan_[static_cast<size_t>(cid)];
            c.mem_id = cid / 12;
            c.req_id = static_cast<uint32_t>(cid & 0xff);
            c.cmd_id = static_cast<uint32_t>(cid);
            c.word_count = ceil_div(c.elem_count, kFp16PerWord);
            reserve_base(c.mem_id, c.word_count, c.base_addr);

            for (int i = 0; i < kMaxElems; ++i) {
                c.data[static_cast<size_t>(i)] = (i < c.elem_count) ? rand_fp16_non_extreme(rng) : 0;
            }

            c.cmd = make_cmd(
                c.cmd_id,
                kOpReduce,
                c.cmp_mode ? kSubCmpReduce : kSubAddTree,
                cid == kCases - 1,
                pack_addr(c.mem_id, c.base_addr),
                0,
                0,
                c.elem_count,
                0,
                0);
        }
    }

    Word128 pack_case_word(const ReduceCase& c, int word_idx) const {
        Word128 word = zero_word();
        for (int lane = 0; lane < kFp16PerWord; ++lane) {
            const int elem_idx = word_idx * kFp16PerWord + lane;
            if (elem_idx < c.elem_count) {
                set_fp16_lane(word, lane, c.data[static_cast<size_t>(elem_idx)]);
            }
        }
        return word;
    }

    void preload_cases() {
        for (const auto& c : cases_) {
            for (int w = 0; w < c.word_count; ++w) {
                mem_write_word(c.mem_id, c.base_addr + w, pack_case_word(c, w));
            }
        }
    }

    void write_input_csv() const {
        std::ofstream f(out_dir_ / "tb_core_top_reduce_input.csv");
        if (!f) throw std::runtime_error("failed to open reduce input CSV");
        f << "case_id,seq_id_bin,req_id_bin,mode_bin,elem_count_bin,base_addr_bin";
        for (int col = 0; col < kMaxElems; ++col) f << ",in_" << col << "_bin";
        f << "\n";
        for (size_t cid = 0; cid < cases_.size(); ++cid) {
            const auto& c = cases_[cid];
            f << cid
              << "," << bin_value(c.seq, 2)
              << "," << bin_value(c.req_id, 8)
              << "," << bin_value(c.cmp_mode ? 1 : 0, 1)
              << "," << bin_value(c.elem_count, 16)
              << "," << bin_value(c.base_addr, kAddrW);
            for (int col = 0; col < kMaxElems; ++col) {
                f << "," << bin_value(c.data[static_cast<size_t>(col)], 16);
            }
            f << "\n";
        }
    }

    void write_output_csv() const {
        std::ofstream f(out_dir_ / "tb_core_top_reduce_output.csv");
        if (!f) throw std::runtime_error("failed to open reduce output CSV");
        f << "case_id,seq_id_bin,req_id_bin,mode_bin,elem_count_bin,base_addr_bin,"
             "result_value_bin,result_index_bin\n";
        for (size_t cid = 0; cid < cases_.size(); ++cid) {
            const auto& c = cases_[cid];
            if (!c.done_seen || !c.result_seen) throw std::runtime_error("missing reduce result");
            f << cid
              << "," << bin_value(c.seq, 2)
              << "," << bin_value(c.req_id, 8)
              << "," << bin_value(c.cmp_mode ? 1 : 0, 1)
              << "," << bin_value(c.elem_count, 16)
              << "," << bin_value(c.base_addr, kAddrW)
              << "," << bin_value(c.result_value, 16)
              << "," << bin_value(c.result_index, 16)
              << "\n";
        }
    }

    std::filesystem::path out_dir_;
    std::vector<ReduceCase> cases_;
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
        ReduceTest test(sim, DEXMPC_RESULT_DIR);
        test.run();
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Reduce simulation failed: " << e.what() << "\n";
        return 1;
    }
}
