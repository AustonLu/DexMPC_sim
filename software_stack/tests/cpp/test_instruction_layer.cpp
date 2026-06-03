#include "dexmpc/runtime/instruction.hpp"

#include <cstdint>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {

void expect(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}

void expect_eq_u32(std::uint32_t got, std::uint32_t expected, const char* message) {
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

        VariableAllocator allocator;
        const auto a = allocator.allocate_matrix("A", dexsim::kMemGlobal, 4, 4);
        const auto b = allocator.allocate_matrix("B", dexsim::kMemGlobal, 4, 3);
        const auto c = allocator.allocate_matrix("C", dexsim::kMemLocal0, 4, 3);
        const auto tmp = allocator.allocate_vector("tmp_reduce", dexsim::kMemTemp0, 8);

        expect_eq_u32(static_cast<std::uint32_t>(a.word_addr), 0, "A base");
        expect_eq_u32(static_cast<std::uint32_t>(a.word_count), 2, "A words");
        expect_eq_u32(static_cast<std::uint32_t>(b.word_addr), 3, "B base");
        expect_eq_u32(static_cast<std::uint32_t>(c.word_addr), 0, "C base");
        expect_eq_u32(static_cast<std::uint32_t>(tmp.mem_id), dexsim::kMemTemp0, "tmp mem");
        expect(allocator.get("A").packed_addr() == dexsim::pack_addr(dexsim::kMemGlobal, 0),
               "variable lookup or packed address mismatch");

        bool duplicate_rejected = false;
        try {
            (void)allocator.allocate_words("A", dexsim::kMemGlobal, 1);
        } catch (const std::runtime_error&) {
            duplicate_rejected = true;
        }
        expect(duplicate_rejected, "duplicate variable name was not rejected");

        const auto preloaded = allocator.bind_existing("preloaded", dexsim::kMemGlobal, 10, 8, 1, 8);
        expect_eq_u32(static_cast<std::uint32_t>(preloaded.word_addr), 10, "preloaded base");
        const auto after_preload = allocator.allocate_words("after_preload", dexsim::kMemGlobal, 1);
        expect_eq_u32(static_cast<std::uint32_t>(after_preload.word_addr), 12,
                      "bind_existing did not advance allocation cursor");

        VariableAllocator manual_allocator;
        const auto fixed = manual_allocator.bind_existing_words("fixed_words", dexsim::kMemGlobal, 4, 2);
        expect_eq_u32(static_cast<std::uint32_t>(fixed.word_addr), 4, "fixed base");
        bool overlap_rejected = false;
        try {
            (void)manual_allocator.bind_existing_words("overlap", dexsim::kMemGlobal, 5, 1);
        } catch (const std::runtime_error&) {
            overlap_rejected = true;
        }
        expect(overlap_rejected, "overlapping variable address range was not rejected");

        VariableAllocator lifecycle_allocator;
        const auto live0 = lifecycle_allocator.allocate_words("live0", dexsim::kMemGlobal, 2);
        const auto live1 = lifecycle_allocator.allocate_words("live1", dexsim::kMemGlobal, 3);
        expect_eq_u32(static_cast<std::uint32_t>(live0.word_addr), 0, "live0 base");
        expect_eq_u32(static_cast<std::uint32_t>(live1.word_addr), 3, "live1 base");

        lifecycle_allocator.release("live0");
        expect(!lifecycle_allocator.contains("live0"), "released variable is still live");
        bool released_lookup_rejected = false;
        try {
            (void)lifecycle_allocator.get("live0");
        } catch (const std::runtime_error&) {
            released_lookup_rejected = true;
        }
        expect(released_lookup_rejected, "released variable lookup was not rejected");

        const auto reuse0 = lifecycle_allocator.allocate_words("reuse0", dexsim::kMemGlobal, 1);
        const auto reuse1 = lifecycle_allocator.allocate_words("reuse1", dexsim::kMemGlobal, 1);
        expect_eq_u32(static_cast<std::uint32_t>(reuse0.word_addr), 0, "first free-list reuse base");
        expect_eq_u32(static_cast<std::uint32_t>(reuse1.word_addr), 1, "free-list remainder reuse base");

        bool double_release_rejected = false;
        try {
            lifecycle_allocator.release("live0");
        } catch (const std::runtime_error&) {
            double_release_rejected = true;
        }
        expect(double_release_rejected, "double release was not rejected");

        lifecycle_allocator.release("reuse0");
        lifecycle_allocator.release("reuse1");
        const auto merged_reuse = lifecycle_allocator.allocate_words("merged_reuse", dexsim::kMemGlobal, 2);
        expect_eq_u32(static_cast<std::uint32_t>(merged_reuse.word_addr), 0,
                      "adjacent free ranges were not coalesced");

        bool unknown_release_rejected = false;
        try {
            lifecycle_allocator.release("missing");
        } catch (const std::runtime_error&) {
            unknown_release_rejected = true;
        }
        expect(unknown_release_rejected, "unknown variable release was not rejected");

        VariableAllocator bind_after_free_allocator;
        const auto free_target = bind_after_free_allocator.allocate_words("free_target", dexsim::kMemGlobal, 2);
        bind_after_free_allocator.release(free_target.name);
        const auto rebound = bind_after_free_allocator.bind_existing_words(
            "rebound", dexsim::kMemGlobal, free_target.word_addr, 1);
        expect_eq_u32(static_cast<std::uint32_t>(rebound.word_addr), 0, "rebound base");
        const auto free_tail = bind_after_free_allocator.allocate_words("free_tail", dexsim::kMemGlobal, 1);
        expect_eq_u32(static_cast<std::uint32_t>(free_tail.word_addr), 1,
                      "bind_existing_words did not reserve the rebound free range");

        VariableAllocator bind_matrix_after_free_allocator;
        const auto free_matrix = bind_matrix_after_free_allocator.allocate_matrix(
            "free_matrix", dexsim::kMemGlobal, 1, 16);
        bind_matrix_after_free_allocator.release(free_matrix.name);
        const auto rebound_matrix = bind_matrix_after_free_allocator.bind_existing(
            "rebound_matrix", dexsim::kMemGlobal, free_matrix.word_addr, 8, 1, 8);
        expect_eq_u32(static_cast<std::uint32_t>(rebound_matrix.word_addr), 0, "rebound matrix base");
        const auto matrix_tail = bind_matrix_after_free_allocator.allocate_words(
            "matrix_tail", dexsim::kMemGlobal, 1);
        expect_eq_u32(static_cast<std::uint32_t>(matrix_tail.word_addr), 1,
                      "bind_existing did not reserve the rebound free range");

        const auto wrong_c = allocator.allocate_matrix("wrong_C", dexsim::kMemLocal0, 3, 4);
        bool shape_rejected = false;
        try {
            InstructionBuilder shape_builder;
            (void)shape_builder.gemm(a, b, wrong_c);
        } catch (const std::runtime_error&) {
            shape_rejected = true;
        }
        expect(shape_rejected, "gemm output shape mismatch was not rejected");

        InstructionBuilder builder;
        const auto gemm = builder.gemm(a, b, c, true);
        expect_eq_u32(gemm.cmd_id, 0, "gemm cmd_id");
        expect_eq_u32(gemm.opcode, dexsim::kOpLa, "gemm opcode");
        expect_eq_u32(gemm.subop, dexsim::kSubGemm, "gemm subop");
        expect(gemm.group_end, "gemm group_end");

        const auto expected = dexsim::make_cmd(
            0,
            dexsim::kOpLa,
            dexsim::kSubGemm,
            true,
            a.packed_addr(),
            b.packed_addr(),
            c.packed_addr(),
            3,
            4,
            4);
        expect(gemm.raw == expected, "gemm raw command mismatch");

        const auto writes = gemm.register_writes();
        expect(writes.size() == 5, "register write sequence size");
        expect_eq_u32(static_cast<std::uint32_t>(writes[0].reg_idx), 0, "cmdWord0 register");
        expect_eq_u32(writes[0].value, dexsim::cmd_word(expected, 0), "cmdWord0 value");
        expect_eq_u32(static_cast<std::uint32_t>(writes[1].reg_idx), 1, "cmdWord1 register");
        expect_eq_u32(writes[1].value, dexsim::cmd_word(expected, 1), "cmdWord1 value");
        expect_eq_u32(static_cast<std::uint32_t>(writes[2].reg_idx), 2, "cmdWord2 register");
        expect_eq_u32(writes[2].value, dexsim::cmd_word(expected, 2), "cmdWord2 value");
        expect_eq_u32(static_cast<std::uint32_t>(writes[3].reg_idx), 12, "cmdCtrl high register");
        expect_eq_u32(writes[3].value, 1, "cmdCtrl high value");
        expect_eq_u32(static_cast<std::uint32_t>(writes[4].reg_idx), 12, "cmdCtrl low register");
        expect_eq_u32(writes[4].value, 0, "cmdCtrl low value");

        const auto reduce = builder.reduce_add(tmp);
        expect_eq_u32(reduce.cmd_id, 1, "reduce cmd_id");
        expect_eq_u32(reduce.opcode, dexsim::kOpReduce, "reduce opcode");
        expect_eq_u32(reduce.subop, dexsim::kSubAddTree, "reduce subop");

        std::cout << "Instruction layer unit test passed\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Instruction layer unit test failed: " << e.what() << "\n";
        return 1;
    }
}
