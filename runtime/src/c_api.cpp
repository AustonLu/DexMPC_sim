#include "dexsim/c_api.h"
#include "dexsim/session.hpp"

#include <exception>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

thread_local std::string last_error;

dexsim::runtime::Session& session(void* handle) {
    if (handle == nullptr) {
        throw std::runtime_error("dexsim session handle is null");
    }
    return *static_cast<dexsim::runtime::Session*>(handle);
}

template <typename Callable>
int guard(Callable&& callable) {
    try {
        callable();
        last_error.clear();
        return 0;
    } catch (const std::exception& error) {
        last_error = error.what();
        return -1;
    } catch (...) {
        last_error = "unknown dexsim runtime error";
        return -1;
    }
}

} // namespace

extern "C" {

void* dexsim_session_create(void) {
    try {
        auto value = std::make_unique<dexsim::runtime::Session>();
        last_error.clear();
        return value.release();
    } catch (const std::exception& error) {
        last_error = error.what();
        return nullptr;
    } catch (...) {
        last_error = "unknown dexsim runtime construction error";
        return nullptr;
    }
}

void dexsim_session_destroy(void* handle) {
    delete static_cast<dexsim::runtime::Session*>(handle);
}

const char* dexsim_last_error(void) {
    return last_error.c_str();
}

int dexsim_write_words(void* handle, int physical_memory_id, int word_offset,
                       const uint32_t* words, size_t word_count) {
    return guard([&] {
        session(handle).write_words(physical_memory_id, word_offset, words, word_count);
    });
}

int dexsim_read_words(void* handle, int physical_memory_id, int word_offset,
                      uint32_t* words, size_t word_count) {
    return guard([&] {
        session(handle).read_words(physical_memory_id, word_offset, words, word_count);
    });
}

int dexsim_run(void* handle, const dexsim_command* commands, size_t command_count,
               int timeout_cycles, dexsim_run_stats* stats) {
    return guard([&] {
        if (command_count != 0 && commands == nullptr) {
            throw std::runtime_error("dexsim_run received a null command pointer");
        }
        if (stats == nullptr) {
            throw std::runtime_error("dexsim_run received a null stats pointer");
        }
        std::vector<dexsim::runtime::Command> batch(command_count);
        for (size_t index = 0; index < command_count; ++index) {
            for (int word = 0; word < 3; ++word) {
                batch[index].words[static_cast<std::size_t>(word)] = commands[index].words[word];
            }
        }
        const auto value = session(handle).run(batch, timeout_cycles);
        stats->cycles = value.cycles;
        stats->read_bytes = value.read_bytes;
        stats->write_bytes = value.write_bytes;
        stats->command_count = value.command_count;
        stats->done_count_before = value.done_count_before;
        stats->done_count_after = value.done_count_after;
        stats->last_done = value.last_done;
        stats->reset_count = value.reset_count;
    });
}

int dexsim_read_register(void* handle, int register_index, uint32_t* value) {
    return guard([&] {
        if (value == nullptr) {
            throw std::runtime_error("dexsim_read_register received a null output pointer");
        }
        *value = session(handle).read_register(register_index);
    });
}

int dexsim_get_snapshot(void* handle, dexsim_snapshot* snapshot) {
    return guard([&] {
        if (snapshot == nullptr) {
            throw std::runtime_error("dexsim_get_snapshot received a null output pointer");
        }
        const auto value = session(handle).snapshot();
        snapshot->cycle = value.cycle;
        snapshot->read_bytes = value.read_bytes;
        snapshot->write_bytes = value.write_bytes;
        snapshot->done_count = value.done_count;
        snapshot->reset_count = value.reset_count;
    });
}

} // extern "C"
