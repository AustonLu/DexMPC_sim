#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct dexsim_command {
    uint32_t words[3];
} dexsim_command;

typedef struct dexsim_command_result {
    uint32_t command_id;
    uint32_t opcode;
    uint32_t subop;
    uint32_t group_end;
    uint32_t done_cycle;
    uint32_t reduce_value_bits;
    uint32_t reduce_index;
    uint32_t reduce_valid;
} dexsim_command_result;

typedef struct dexsim_scheduled_command {
    uint32_t core;
    uint32_t words[3];
} dexsim_scheduled_command;

typedef struct dexsim_scheduled_command_result {
    uint32_t core;
    uint32_t command_id;
    uint32_t opcode;
    uint32_t subop;
    uint32_t group_end;
    uint32_t done_cycle;
    uint32_t reduce_value_bits;
    uint32_t reduce_index;
    uint32_t reduce_valid;
} dexsim_scheduled_command_result;

typedef struct dexsim_run_stats {
    uint64_t cycles;
    uint64_t read_bytes;
    uint64_t write_bytes;
    uint32_t command_count;
    uint32_t done_count_before;
    uint32_t done_count_after;
    uint32_t last_done;
    uint32_t reset_count;
} dexsim_run_stats;

typedef struct dexsim_snapshot {
    uint64_t cycle;
    uint64_t read_bytes;
    uint64_t write_bytes;
    uint32_t done_count;
    uint32_t reset_count;
} dexsim_snapshot;

typedef struct dexsim_counters {
    uint64_t cycle;
    uint64_t read_bytes;
    uint64_t write_bytes;
} dexsim_counters;

void* dexsim_session_create(void);
void dexsim_session_destroy(void* handle);
const char* dexsim_last_error(void);

int dexsim_write_words(void* handle, int physical_memory_id, int word_offset,
                       const uint32_t* words, size_t word_count);
int dexsim_read_words(void* handle, int physical_memory_id, int word_offset,
                      uint32_t* words, size_t word_count);
int dexsim_run(void* handle, const dexsim_command* commands, size_t command_count,
               int timeout_cycles, dexsim_run_stats* stats);
int dexsim_run_detailed(void* handle, const dexsim_command* commands, size_t command_count,
                        int timeout_cycles, dexsim_run_stats* stats,
                        dexsim_command_result* results, size_t result_count);
int dexsim_run_scheduled_detailed(
    void* handle, const dexsim_scheduled_command* commands, size_t command_count,
    int timeout_cycles, dexsim_run_stats* stats,
    dexsim_scheduled_command_result* results, size_t result_count);
int dexsim_read_register(void* handle, int register_index, uint32_t* value);
int dexsim_get_snapshot(void* handle, dexsim_snapshot* snapshot);
int dexsim_get_counters(void* handle, dexsim_counters* counters);

#ifdef __cplusplus
}
#endif
