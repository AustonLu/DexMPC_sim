#include "dexmpc/runtime/operator.hpp"

#include <cstdint>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

class FakeBackend final : public dexmpc::runtime::IDeviceBackend {
public:
    dexmpc::runtime::BackendKind backend_kind() const override {
        return dexmpc::runtime::BackendKind::SimModel;
    }
    dexmpc::runtime::Transport transport() const override {
        return dexmpc::runtime::Transport::D2D;
    }
    std::uint64_t cycle() const override { return 0; }
    void reset() override {}
    void write_register(int reg_idx, std::uint32_t value) override {
        registers_[reg_idx] = value;
    }
    std::uint32_t read_register(int reg_idx) override {
        const auto it = registers_.find(reg_idx);
        return it == registers_.end() ? 0 : it->second;
    }
    void write_memory(int mem_id, int word_addr, const std::vector<dexmpc::runtime::Word128>& words) override {
        for (std::size_t i = 0; i < words.size(); ++i) {
            memory_[memory_key(mem_id, word_addr + static_cast<int>(i))] = words[i];
        }
    }
    std::vector<dexmpc::runtime::Word128> read_memory(int mem_id, int word_addr, int word_count) override {
        std::vector<dexmpc::runtime::Word128> out;
        out.reserve(static_cast<std::size_t>(word_count));
        for (int i = 0; i < word_count; ++i) {
            const auto it = memory_.find(memory_key(mem_id, word_addr + i));
            out.push_back(it == memory_.end() ? dexsim::zero_word() : it->second);
        }
        return out;
    }
    void send_instruction(dexmpc::runtime::Cmd96) override {}
    dexmpc::runtime::StatusRegisters wait_done_count(std::uint32_t, int) override { return {}; }
    dexmpc::runtime::StatusRegisters wait_next_done(int) override { return {}; }
    dexmpc::runtime::StatusRegisters read_status() override { return {}; }

private:
    static std::int64_t memory_key(int mem_id, int word_addr) {
        return (static_cast<std::int64_t>(mem_id) << 32) | static_cast<std::uint32_t>(word_addr);
    }

    std::unordered_map<int, std::uint32_t> registers_;
    std::unordered_map<std::int64_t, dexmpc::runtime::Word128> memory_;
};

void expect(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}

void expect_eq_int(int got, int expected, const char* message) {
    if (got != expected) {
        throw std::runtime_error(
            std::string(message) + ": got=" + std::to_string(got)
            + " expected=" + std::to_string(expected));
    }
}

} // namespace

int main() {
    try {
        using namespace dexmpc::runtime;

        Device device(std::make_unique<FakeBackend>());
        OperatorRuntime runtime(device);
        runtime.reset_program();

        runtime.write_register(0, 0x1234);
        expect_eq_int(static_cast<int>(runtime.read_register(0)), 0x1234,
                      "operator register pass-through did not reach backend");
        const Word128 raw_word{1, 2, 3, 4};
        runtime.write_memory(dexsim::kMemTemp0, 0, std::vector<Word128>{raw_word});
        const auto raw_readback = runtime.read_memory(dexsim::kMemTemp0, 0, 1);
        expect_eq_int(static_cast<int>(raw_readback.size()), 1,
                      "operator memory pass-through readback size mismatch");
        expect(raw_readback[0] == raw_word, "operator memory pass-through did not reach backend");

        {
            auto tensor = runtime.empty_words(dexsim::kMemGlobal, 2, "scoped_words");
            expect_eq_int(tensor.word_addr(), 0, "initial operator tensor base");
            expect(runtime.instruction_runtime().allocator().contains(tensor.name()),
                   "operator tensor was not allocated");
        }
        expect(!runtime.instruction_runtime().allocator().contains("scoped_words"),
               "operator tensor was not auto released at scope exit");

        {
            auto bound = runtime.bind_existing_words(dexsim::kMemTemp0, 4, 2, "bound_words");
            expect_eq_int(bound.word_addr(), 4, "bound operator tensor base");
            expect(runtime.instruction_runtime().allocator().contains(bound.name()),
                   "bound operator tensor was not tracked by allocator");
        }
        auto rebound = runtime.empty_words(dexsim::kMemTemp0, 2, "rebound_words");
        expect_eq_int(rebound.word_addr(), 4, "bound operator tensor memory was not reused");

        auto reused = runtime.empty_words(dexsim::kMemGlobal, 2, "reused_words");
        expect_eq_int(reused.word_addr(), 0, "operator tensor memory was not reused");

        {
            auto move_src = runtime.empty_words(dexsim::kMemGlobal, 1, "move_src");
            const int move_base = move_src.word_addr();
            auto move_dst = std::move(move_src);
            expect(!move_src.valid(), "moved-from operator tensor is still valid");
            expect(move_dst.valid(), "moved-to operator tensor is not valid");
            expect_eq_int(move_dst.word_addr(), move_base, "moved tensor base changed");
        }

        auto after_move = runtime.empty_words(dexsim::kMemGlobal, 1, "after_move");
        expect_eq_int(after_move.word_addr(), 3, "moved tensor memory was not released once");

        auto before_reset = runtime.empty_words(dexsim::kMemGlobal, 1, "before_reset");
        runtime.reset_program();
        expect(!before_reset.valid(), "operator tensor remained valid after runtime reset_program");
        expect(!runtime.instruction_runtime().allocator().contains(before_reset.name()),
               "runtime reset_program did not clear operator tensor allocation");

        std::cout << "Operator layer unit test passed\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Operator layer unit test failed: " << e.what() << "\n";
        return 1;
    }
}
