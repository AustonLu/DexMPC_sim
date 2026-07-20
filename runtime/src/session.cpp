#include "verification/verilator/cpp/common/topchip_sim.hpp"

#include "dexsim/session.hpp"

#include <stdexcept>
#include <string>
#include <utility>

namespace dexsim::runtime {

namespace {

std::unique_ptr<topchip::Sim> make_simulator() {
    char program[] = "dexsim";
    char* argv[] = {program, nullptr};
    return std::make_unique<topchip::Sim>(1, argv);
}

Cmd96 command_value(const Command& command) {
    Cmd96 value = command.words[0];
    value |= Cmd96(command.words[1]) << 32;
    value |= Cmd96(command.words[2]) << 64;
    return value;
}

std::uint32_t command_id(const Command& command) {
    return (command.words[2] >> 20) & 0xfffu;
}

std::uint32_t command_opcode(const Command& command) {
    return (command.words[2] >> 17) & 0x7u;
}

std::uint32_t command_subop(const Command& command) {
    return (command.words[2] >> 13) & 0xfu;
}

std::uint32_t command_group_end(const Command& command) {
    return (command.words[2] >> 12) & 0x1u;
}

} // namespace

class Session::Impl {
public:
    Impl() : sim(make_simulator()) {
        sim->reset();
        sim->write_reg(topchip::kCfgIsLoop, 0);
        sim->clear_transport_counters();
        reset_count = 1;
    }

    std::unique_ptr<topchip::Sim> sim;
    std::uint32_t reset_count = 0;
};

Session::Session() : impl_(std::make_unique<Impl>()) {}
Session::~Session() = default;
Session::Session(Session&&) noexcept = default;
Session& Session::operator=(Session&&) noexcept = default;

void Session::write_words(int physical_memory_id, int word_offset,
                          const std::uint32_t* words, std::size_t word_count) {
    if (word_count != 0 && words == nullptr) {
        throw std::runtime_error("write_words received a null data pointer");
    }
    std::vector<Word128> packed(word_count, zero_word());
    for (std::size_t index = 0; index < word_count; ++index) {
        for (int lane = 0; lane < 4; ++lane) {
            packed[index][static_cast<std::size_t>(lane)] = words[index * 4 + lane];
        }
    }
    impl_->sim->write_mpc_mem_words(physical_memory_id, word_offset, packed);
}

void Session::read_words(int physical_memory_id, int word_offset,
                         std::uint32_t* words, std::size_t word_count) {
    if (word_count != 0 && words == nullptr) {
        throw std::runtime_error("read_words received a null output pointer");
    }
    const auto packed = impl_->sim->read_mpc_mem_words(
        physical_memory_id, word_offset, static_cast<int>(word_count));
    for (std::size_t index = 0; index < packed.size(); ++index) {
        for (int lane = 0; lane < 4; ++lane) {
            words[index * 4 + lane] = packed[index][static_cast<std::size_t>(lane)];
        }
    }
}

RunStats Session::run(const std::vector<Command>& commands, int timeout_cycles) {
    if (timeout_cycles <= 0) {
        throw std::runtime_error("timeout_cycles must be positive");
    }

    RunStats stats{};
    const auto cycle_before = impl_->sim->cycle();
    const auto read_before = impl_->sim->transport_read_bytes();
    const auto write_before = impl_->sim->transport_write_bytes();
    stats.done_count_before = impl_->sim->done_count(0);
    stats.command_results.reserve(commands.size());

    std::uint32_t expected_done = stats.done_count_before;
    for (const auto& command : commands) {
        ++expected_done;
        impl_->sim->push_cmd(0, command_value(command));
        impl_->sim->wait_for_done_count(0, expected_done, timeout_cycles);

        const auto last_done = impl_->sim->last_done(0);
        const auto observed_id = last_done & 0xfffu;
        if (observed_id != command_id(command)) {
            throw std::runtime_error(
                "TopChip lastDone command ID mismatch: expected="
                + std::to_string(command_id(command))
                + " got=" + std::to_string(observed_id));
        }
        if (((last_done >> 20) & 1u) != 0) {
            throw std::runtime_error(
                "TopChip reported illegal command id=" + std::to_string(observed_id));
        }
        stats.last_done = last_done;

        CommandResult result{};
        result.command_id = observed_id;
        result.opcode = (last_done >> 12) & 0x7u;
        result.subop = (last_done >> 15) & 0xfu;
        result.group_end = (last_done >> 19) & 0x1u;
        result.done_cycle = impl_->sim->read_reg(topchip::cfg_last_done_cycle(0));

        if (result.opcode != command_opcode(command)
            || result.subop != command_subop(command)
            || result.group_end != command_group_end(command)) {
            throw std::runtime_error(
                "TopChip lastDone metadata mismatch for command id="
                + std::to_string(observed_id));
        }

        constexpr std::uint32_t kOpReduce = 0b010u;
        constexpr std::uint32_t kSubCompareReduce = 0u;
        constexpr std::uint32_t kSubAddReduce = 1u;
        if (result.opcode == kOpReduce && result.subop == kSubAddReduce) {
            const auto reg = impl_->sim->read_reg(topchip::cfg_add_reduce(0));
            result.reduce_value_bits = reg & 0xffffu;
            result.reduce_valid = (reg >> 28) & 0x1u;
            const auto result_id = (reg >> 16) & 0xfffu;
            if (!result.reduce_valid || result_id != observed_id) {
                throw std::runtime_error(
                    "TopChip add-reduce result mismatch for command id="
                    + std::to_string(observed_id));
            }
        } else if (result.opcode == kOpReduce && result.subop == kSubCompareReduce) {
            const auto reg0 = impl_->sim->read_reg(topchip::cfg_cmp_reduce0(0));
            const auto reg1 = impl_->sim->read_reg(topchip::cfg_cmp_reduce1(0));
            result.reduce_value_bits = reg0 & 0xffffu;
            result.reduce_index = reg1 & 0xfffu;
            result.reduce_valid = (reg0 >> 28) & 0x1u;
            const auto result_id = (reg0 >> 16) & 0xfffu;
            if (!result.reduce_valid || result_id != observed_id) {
                throw std::runtime_error(
                    "TopChip compare-reduce result mismatch for command id="
                    + std::to_string(observed_id));
            }
        }
        stats.command_results.push_back(result);
    }

    stats.done_count_after = commands.empty()
        ? stats.done_count_before
        : expected_done;
    stats.cycles = impl_->sim->cycle() - cycle_before;
    stats.read_bytes = impl_->sim->transport_read_bytes() - read_before;
    stats.write_bytes = impl_->sim->transport_write_bytes() - write_before;
    stats.command_count = static_cast<std::uint32_t>(commands.size());
    stats.reset_count = impl_->reset_count;
    return stats;
}

std::uint32_t Session::read_register(int register_index) {
    return impl_->sim->read_reg(register_index);
}

Snapshot Session::snapshot() {
    Snapshot value{};
    value.cycle = impl_->sim->cycle();
    value.done_count = impl_->sim->done_count(0);
    value.read_bytes = impl_->sim->transport_read_bytes();
    value.write_bytes = impl_->sim->transport_write_bytes();
    value.reset_count = impl_->reset_count;
    return value;
}

Counters Session::counters() const {
    Counters value{};
    value.cycle = impl_->sim->cycle();
    value.read_bytes = impl_->sim->transport_read_bytes();
    value.write_bytes = impl_->sim->transport_write_bytes();
    return value;
}

} // namespace dexsim::runtime
