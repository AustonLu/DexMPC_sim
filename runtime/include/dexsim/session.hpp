#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <vector>

namespace dexsim::runtime {

struct Command {
    std::array<std::uint32_t, 3> words{};
};

struct CommandResult {
    std::uint32_t command_id = 0;
    std::uint32_t opcode = 0;
    std::uint32_t subop = 0;
    std::uint32_t group_end = 0;
    std::uint32_t done_cycle = 0;
    std::uint32_t reduce_value_bits = 0;
    std::uint32_t reduce_index = 0;
    std::uint32_t reduce_valid = 0;
};

struct RunStats {
    std::uint64_t cycles = 0;
    std::uint64_t read_bytes = 0;
    std::uint64_t write_bytes = 0;
    std::uint32_t command_count = 0;
    std::uint32_t done_count_before = 0;
    std::uint32_t done_count_after = 0;
    std::uint32_t last_done = 0;
    std::uint32_t reset_count = 0;
    std::vector<CommandResult> command_results;
};

struct Snapshot {
    std::uint64_t cycle = 0;
    std::uint64_t read_bytes = 0;
    std::uint64_t write_bytes = 0;
    std::uint32_t done_count = 0;
    std::uint32_t reset_count = 0;
};

struct Counters {
    std::uint64_t cycle = 0;
    std::uint64_t read_bytes = 0;
    std::uint64_t write_bytes = 0;
};

class Session {
public:
    Session();
    ~Session();

    Session(const Session&) = delete;
    Session& operator=(const Session&) = delete;
    Session(Session&&) noexcept;
    Session& operator=(Session&&) noexcept;

    void write_words(int physical_memory_id, int word_offset,
                     const std::uint32_t* words, std::size_t word_count);
    void read_words(int physical_memory_id, int word_offset,
                    std::uint32_t* words, std::size_t word_count);
    RunStats run(const std::vector<Command>& commands, int timeout_cycles);
    std::uint32_t read_register(int register_index);
    Snapshot snapshot();
    Counters counters() const;

private:
    class Impl;
    std::unique_ptr<Impl> impl_;
};

} // namespace dexsim::runtime
