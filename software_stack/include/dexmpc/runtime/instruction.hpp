#pragma once

#include "dexmpc/runtime/device.hpp"

#include <cstdint>
#include <stdexcept>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

namespace dexmpc::runtime {

enum class InstructionKind {
    Abs,
    LayoutTranspose,
    LayoutAssemble,
    ReduceAdd,
    ReduceCmp,
    Gemm,
    Mul,
    Add,
    LutSin,
    LutCos,
    LutSoftplus,
    Raw,
};

inline std::string_view to_string(InstructionKind kind) {
    switch (kind) {
    case InstructionKind::Abs:
        return "abs";
    case InstructionKind::LayoutTranspose:
        return "layout_transpose";
    case InstructionKind::LayoutAssemble:
        return "layout_assemble";
    case InstructionKind::ReduceAdd:
        return "reduce_add";
    case InstructionKind::ReduceCmp:
        return "reduce_cmp";
    case InstructionKind::Gemm:
        return "gemm";
    case InstructionKind::Mul:
        return "mul";
    case InstructionKind::Add:
        return "add";
    case InstructionKind::LutSin:
        return "lut_sin";
    case InstructionKind::LutCos:
        return "lut_cos";
    case InstructionKind::LutSoftplus:
        return "lut_softplus";
    case InstructionKind::Raw:
        return "raw";
    }
    return "unknown";
}

struct VariableRef {
    std::string name;
    int mem_id = dexsim::kMemGlobal;
    int word_addr = 0;
    int elem_count = 0;
    int word_count = 0;
    int rows = 0;
    int cols = 0;

    std::uint16_t packed_addr() const {
        return dexsim::pack_addr(mem_id, word_addr);
    }

    bool is_matrix() const {
        return rows > 0 && cols > 0;
    }
};

struct RegisterWrite {
    int reg_idx = 0;
    std::uint32_t value = 0;
};

struct Instruction {
    InstructionKind kind = InstructionKind::Raw;
    std::uint32_t cmd_id = 0;
    std::uint32_t opcode = 0;
    std::uint32_t subop = 0;
    bool group_end = false;
    Cmd96 raw = 0;

    std::uint32_t command_word(int word_idx) const {
        if (word_idx < 0 || word_idx > 2) {
            throw std::runtime_error("command_word index must be 0..2");
        }
        return dexsim::cmd_word(raw, word_idx);
    }

    std::vector<RegisterWrite> register_writes(int core = 0) const {
        if (core < 0 || core > 3) throw std::runtime_error("core index must be 0..3");
        const int word_base = core * 3;
        const int ctrl_reg = 12 + core;
        return std::vector<RegisterWrite>{
            {word_base + 0, command_word(0)},
            {word_base + 1, command_word(1)},
            {word_base + 2, command_word(2)},
            {ctrl_reg, 1},
            {ctrl_reg, 0},
        };
    }
};

class VariableAllocator {
public:
    void reset() {
        variables_.clear();
        next_word_.clear();
    }

    bool contains(std::string_view name) const {
        return variables_.find(std::string(name)) != variables_.end();
    }

    const VariableRef& get(std::string_view name) const {
        const auto it = variables_.find(std::string(name));
        if (it == variables_.end()) {
            throw std::runtime_error("unknown DexMPC variable: " + std::string(name));
        }
        return it->second;
    }

    VariableRef allocate_matrix(std::string name, int mem_id, int rows, int cols) {
        if (rows <= 0 || cols <= 0) {
            throw std::runtime_error("matrix allocation requires positive rows and cols");
        }
        return allocate_elements(std::move(name), mem_id, rows * cols, rows, cols);
    }

    VariableRef allocate_vector(std::string name, int mem_id, int elem_count) {
        if (elem_count <= 0) {
            throw std::runtime_error("vector allocation requires positive element count");
        }
        return allocate_elements(std::move(name), mem_id, elem_count, 1, elem_count);
    }

    VariableRef allocate_words(std::string name, int mem_id, int word_count) {
        if (word_count <= 0) {
            throw std::runtime_error("word allocation requires positive word count");
        }
        return allocate(std::move(name), mem_id, word_count, word_count * dexsim::kFp16PerWord, 0, 0);
    }

    VariableRef bind_existing(std::string name, int mem_id, int word_addr,
                              int elem_count, int rows = 0, int cols = 0) {
        if (name.empty()) throw std::runtime_error("variable name must not be empty");
        if (variables_.find(name) != variables_.end()) {
            throw std::runtime_error("duplicate DexMPC variable: " + name);
        }
        if (elem_count <= 0) throw std::runtime_error("bind_existing elem_count must be positive");
        if ((rows == 0 && cols != 0) || (rows != 0 && cols == 0)) {
            throw std::runtime_error("bind_existing matrix shape must provide both rows and cols");
        }
        if (rows < 0 || cols < 0) {
            throw std::runtime_error("bind_existing matrix shape must be non-negative");
        }
        if (rows > 0 && rows * cols != elem_count) {
            throw std::runtime_error("bind_existing matrix shape does not match elem_count");
        }
        const int words = dexsim::ceil_div(elem_count, dexsim::kFp16PerWord);
        check_range(mem_id, word_addr, words);
        check_no_overlap(mem_id, word_addr, words, name);
        VariableRef ref{std::move(name), mem_id, word_addr, elem_count, words, rows, cols};
        insert(ref);
        bump_next_word(ref);
        return ref;
    }

    VariableRef bind_existing_words(std::string name, int mem_id, int word_addr, int word_count) {
        if (name.empty()) throw std::runtime_error("variable name must not be empty");
        if (variables_.find(name) != variables_.end()) {
            throw std::runtime_error("duplicate DexMPC variable: " + name);
        }
        if (word_count <= 0) throw std::runtime_error("bind_existing_words word_count must be positive");
        check_range(mem_id, word_addr, word_count);
        check_no_overlap(mem_id, word_addr, word_count, name);
        VariableRef ref{std::move(name), mem_id, word_addr,
                        word_count * dexsim::kFp16PerWord, word_count, 0, 0};
        insert(ref);
        bump_next_word(ref);
        return ref;
    }

private:
    VariableRef allocate_elements(std::string name, int mem_id, int elem_count, int rows, int cols) {
        const int words = dexsim::ceil_div(elem_count, dexsim::kFp16PerWord);
        return allocate(std::move(name), mem_id, words, elem_count, rows, cols);
    }

    VariableRef allocate(std::string name, int mem_id, int word_count,
                         int elem_count, int rows, int cols) {
        if (name.empty()) throw std::runtime_error("variable name must not be empty");
        if (variables_.find(name) != variables_.end()) {
            throw std::runtime_error("duplicate DexMPC variable: " + name);
        }
        if (word_count <= 0) throw std::runtime_error("variable word_count must be positive");

        const int base = next_word_[mem_id];
        check_range(mem_id, base, word_count);
        check_no_overlap(mem_id, base, word_count, name);
        next_word_[mem_id] = base + word_count + 1;

        VariableRef ref{std::move(name), mem_id, base, elem_count, word_count, rows, cols};
        insert(ref);
        return ref;
    }

    void insert(const VariableRef& ref) {
        variables_.emplace(ref.name, ref);
    }

    static void check_range(int mem_id, int word_addr, int word_count) {
        const int depth = dexsim::sram_depth(mem_id);
        if (depth <= 0) {
            throw std::runtime_error("unsupported DexMPC SRAM id " + std::to_string(mem_id));
        }
        if (word_addr < 0 || word_count <= 0 || word_addr > depth - word_count) {
            throw std::runtime_error(
                "DexMPC variable SRAM range overflow, mem=" + std::to_string(mem_id)
                + " base=" + std::to_string(word_addr)
                + " words=" + std::to_string(word_count)
                + " depth=" + std::to_string(depth));
        }
    }

    void check_no_overlap(int mem_id, int word_addr, int word_count, std::string_view name) const {
        const int end = word_addr + word_count;
        for (const auto& entry : variables_) {
            const auto& existing = entry.second;
            if (existing.mem_id != mem_id) continue;
            const int existing_end = existing.word_addr + existing.word_count;
            if (word_addr < existing_end && existing.word_addr < end) {
                throw std::runtime_error(
                    "DexMPC variable SRAM range overlaps, name=" + std::string(name)
                    + " existing=" + existing.name
                    + " mem=" + std::to_string(mem_id));
            }
        }
    }

    void bump_next_word(const VariableRef& ref) {
        const int after = ref.word_addr + ref.word_count + 1;
        auto& next = next_word_[ref.mem_id];
        if (next < after) next = after;
    }

    std::unordered_map<std::string, VariableRef> variables_;
    std::unordered_map<int, int> next_word_;
};

class InstructionBuilder {
public:
    void reset(std::uint32_t first_cmd_id = 0) {
        next_cmd_id_ = first_cmd_id;
    }

    std::uint32_t next_cmd_id() const { return next_cmd_id_; }

    Instruction raw(std::uint32_t opcode, std::uint32_t subop, bool group_end,
                    std::uint32_t addr0, std::uint32_t addr1, std::uint32_t addr2,
                    std::uint32_t dim0, std::uint32_t dim1, std::uint32_t dim2,
                    InstructionKind kind = InstructionKind::Raw) {
        const auto cmd_id = next_cmd_id_++;
        return make(kind, cmd_id, opcode, subop, group_end, addr0, addr1, addr2, dim0, dim1, dim2);
    }

    Instruction abs(const VariableRef& src, const VariableRef& dst, bool group_end = false) {
        require_matrix(src, "abs src");
        require_same_shape(dst, src.rows, src.cols, "abs dst");
        require_capacity(dst, src.elem_count, "abs dst");
        return raw(dexsim::kOpAbs, dexsim::kSubAbs, group_end,
                   src.packed_addr(), dst.packed_addr(), 0,
                   checked_dim(src.rows, "abs rows"), checked_dim(src.cols, "abs cols"), 0,
                   InstructionKind::Abs);
    }

    Instruction layout_transpose(const VariableRef& src, const VariableRef& dst, bool group_end = false) {
        require_matrix(src, "transpose src");
        require_same_shape(dst, src.cols, src.rows, "transpose dst");
        require_capacity(dst, src.elem_count, "transpose dst");
        return raw(dexsim::kOpDataLayout, dexsim::kSubTranspose, group_end,
                   src.packed_addr(), dst.packed_addr(), 0,
                   checked_dim(src.rows, "transpose rows"), checked_dim(src.cols, "transpose cols"), 0,
                   InstructionKind::LayoutTranspose);
    }

    Instruction layout_assemble(const VariableRef& src, const VariableRef& dst,
                                int offset_row, int offset_col, bool group_end = false) {
        require_matrix(src, "assemble src");
        require_matrix(dst, "assemble dst");
        if (offset_row < 0 || offset_col < 0) {
            throw std::runtime_error("assemble offsets must be non-negative");
        }
        if (offset_row + src.rows > dst.rows || offset_col + src.cols > dst.cols) {
            throw std::runtime_error("assemble source region exceeds destination shape");
        }
        require_capacity(dst, dst.elem_count, "assemble dst");
        return raw(dexsim::kOpDataLayout, dexsim::kSubAssemble, group_end,
                   src.packed_addr(), dst.packed_addr(), checked_dim(offset_col, "assemble offset_col"),
                   checked_dim(src.rows, "assemble rows"), checked_dim(src.cols, "assemble cols"),
                   checked_dim(offset_row, "assemble offset_row"),
                   InstructionKind::LayoutAssemble);
    }

    Instruction reduce_add(const VariableRef& src, bool group_end = false) {
        require_capacity(src, src.elem_count, "reduce_add src");
        return raw(dexsim::kOpReduce, dexsim::kSubAddTree, group_end,
                   src.packed_addr(), 0, 0, checked_dim(src.elem_count, "reduce_add length"), 0, 0,
                   InstructionKind::ReduceAdd);
    }

    Instruction reduce_cmp(const VariableRef& src, bool group_end = false) {
        require_capacity(src, src.elem_count, "reduce_cmp src");
        return raw(dexsim::kOpReduce, dexsim::kSubCmpReduce, group_end,
                   src.packed_addr(), 0, 0, checked_dim(src.elem_count, "reduce_cmp length"), 0, 0,
                   InstructionKind::ReduceCmp);
    }

    Instruction gemm(const VariableRef& a, const VariableRef& b, const VariableRef& c,
                     bool group_end = false) {
        require_matrix(a, "gemm A");
        require_matrix(b, "gemm B");
        if (a.cols != b.rows) throw std::runtime_error("gemm dimension mismatch");
        require_same_shape(c, a.rows, b.cols, "gemm C");
        require_capacity(c, a.rows * b.cols, "gemm C");
        return raw(dexsim::kOpLa, dexsim::kSubGemm, group_end,
                   a.packed_addr(), b.packed_addr(), c.packed_addr(),
                   checked_dim(b.cols, "gemm m_cols"), checked_dim(a.rows, "gemm n_rows"),
                   checked_dim(a.cols, "gemm k_dim"),
                   InstructionKind::Gemm);
    }

    Instruction mul(const VariableRef& a, const VariableRef& c,
                    std::uint16_t alpha, bool group_end = false) {
        require_matrix(a, "mul A");
        require_same_shape(c, a.rows, a.cols, "mul C");
        require_capacity(c, a.elem_count, "mul C");
        return raw(dexsim::kOpLa, dexsim::kSubMul, group_end,
                   a.packed_addr(), c.packed_addr(), alpha & 0x1fffu,
                   checked_dim(a.rows, "mul rows"), checked_dim(a.cols, "mul cols"),
                   (alpha >> 13) & 0x7u,
                   InstructionKind::Mul);
    }

    Instruction add(const VariableRef& a, const VariableRef& b, const VariableRef& c,
                    bool group_end = false) {
        require_matrix(a, "add A");
        require_matrix(b, "add B");
        if (a.rows != b.rows || a.cols != b.cols) throw std::runtime_error("add dimension mismatch");
        require_same_shape(c, a.rows, a.cols, "add C");
        require_capacity(c, a.elem_count, "add C");
        return raw(dexsim::kOpLa, dexsim::kSubAdd, group_end,
                   a.packed_addr(), b.packed_addr(), c.packed_addr(),
                   checked_dim(a.rows, "add rows"), checked_dim(a.cols, "add cols"), 0,
                   InstructionKind::Add);
    }

    Instruction lut_sin(const VariableRef& src, const VariableRef& dst, bool group_end = false) {
        return lut(src, dst, dexsim::kSubSin, group_end, InstructionKind::LutSin);
    }

    Instruction lut_cos(const VariableRef& src, const VariableRef& dst, bool group_end = false) {
        return lut(src, dst, dexsim::kSubCos, group_end, InstructionKind::LutCos);
    }

    Instruction lut_softplus(const VariableRef& src, const VariableRef& dst, bool group_end = false) {
        return lut(src, dst, dexsim::kSubSoftplus, group_end, InstructionKind::LutSoftplus);
    }

    static Instruction with_group_end(Instruction instruction, bool group_end) {
        instruction.group_end = group_end;
        const Cmd96 mask = Cmd96(1) << 76;
        instruction.raw = group_end ? (instruction.raw | mask) : (instruction.raw & ~mask);
        return instruction;
    }

private:
    static Instruction make(InstructionKind kind, std::uint32_t cmd_id,
                            std::uint32_t opcode, std::uint32_t subop, bool group_end,
                            std::uint32_t addr0, std::uint32_t addr1, std::uint32_t addr2,
                            std::uint32_t dim0, std::uint32_t dim1, std::uint32_t dim2) {
        Instruction instruction;
        instruction.kind = kind;
        instruction.cmd_id = cmd_id;
        instruction.opcode = opcode;
        instruction.subop = subop;
        instruction.group_end = group_end;
        instruction.raw = dexsim::make_cmd(cmd_id, opcode, subop, group_end,
                                           addr0, addr1, addr2, dim0, dim1, dim2);
        return instruction;
    }

    Instruction lut(const VariableRef& src, const VariableRef& dst,
                    std::uint32_t subop, bool group_end, InstructionKind kind) {
        require_matrix(src, "lut src");
        require_capacity(dst, src.elem_count, "lut dst");
        return raw(dexsim::kOpLut, subop, group_end,
                   src.packed_addr(), dst.packed_addr(), 0,
                   checked_dim(src.rows, "lut rows"), checked_dim(src.cols, "lut cols"), 0,
                   kind);
    }

    static void require_matrix(const VariableRef& ref, std::string_view label) {
        if (!ref.is_matrix()) {
            throw std::runtime_error(std::string(label) + " must have matrix shape metadata");
        }
    }

    static void require_same_shape(const VariableRef& ref, int rows, int cols, std::string_view label) {
        require_matrix(ref, label);
        if (ref.rows != rows || ref.cols != cols) {
            throw std::runtime_error(std::string(label) + " matrix shape mismatch");
        }
    }

    static void require_capacity(const VariableRef& ref, int elem_count, std::string_view label) {
        if (elem_count <= 0) {
            throw std::runtime_error(std::string(label) + " element count must be positive");
        }
        const int required_words = dexsim::ceil_div(elem_count, dexsim::kFp16PerWord);
        if (ref.word_count < required_words) {
            throw std::runtime_error(std::string(label) + " variable capacity is too small");
        }
    }

    static std::uint32_t checked_dim(int value, std::string_view label) {
        if (value < 0 || value > 0xfff) {
            throw std::runtime_error(std::string(label) + " exceeds 12-bit command field");
        }
        return static_cast<std::uint32_t>(value);
    }

    std::uint32_t next_cmd_id_ = 0;
};

class InstructionRuntime {
public:
    explicit InstructionRuntime(Device& device) : device_(device) {}

    Device& device() { return device_; }
    VariableAllocator& allocator() { return allocator_; }
    InstructionBuilder& builder() { return builder_; }

    void reset_program(std::uint32_t first_cmd_id = 0) {
        allocator_.reset();
        builder_.reset(first_cmd_id);
    }

    VariableRef allocate_matrix(std::string name, int mem_id, int rows, int cols) {
        return allocator_.allocate_matrix(std::move(name), mem_id, rows, cols);
    }

    VariableRef allocate_vector(std::string name, int mem_id, int elem_count) {
        return allocator_.allocate_vector(std::move(name), mem_id, elem_count);
    }

    VariableRef allocate_words(std::string name, int mem_id, int word_count) {
        return allocator_.allocate_words(std::move(name), mem_id, word_count);
    }

    VariableRef bind_existing(std::string name, int mem_id, int word_addr,
                              int elem_count, int rows = 0, int cols = 0) {
        return allocator_.bind_existing(std::move(name), mem_id, word_addr, elem_count, rows, cols);
    }

    VariableRef bind_existing_words(std::string name, int mem_id, int word_addr, int word_count) {
        return allocator_.bind_existing_words(std::move(name), mem_id, word_addr, word_count);
    }

    const VariableRef& variable(std::string_view name) const { return allocator_.get(name); }

    void reset_device() { device_.reset(); }
    void write_register(int reg_idx, std::uint32_t value) { device_.write_register(reg_idx, value); }
    std::uint32_t read_register(int reg_idx) { return device_.read_register(reg_idx); }
    void write_memory(int mem_id, int word_addr, const std::vector<Word128>& words) {
        device_.write_memory(mem_id, word_addr, words);
    }
    std::vector<Word128> read_memory(int mem_id, int word_addr, int word_count) {
        return device_.read_memory(mem_id, word_addr, word_count);
    }

    void write_variable_words(std::string_view name, const std::vector<Word128>& words) {
        const auto& ref = variable(name);
        if (static_cast<int>(words.size()) > ref.word_count) {
            throw std::runtime_error("write_variable_words exceeds variable capacity: " + ref.name);
        }
        device_.write_memory(ref.mem_id, ref.word_addr, words);
    }

    std::vector<Word128> read_variable_words(std::string_view name) {
        const auto& ref = variable(name);
        return device_.read_memory(ref.mem_id, ref.word_addr, ref.word_count);
    }

    Instruction abs(std::string_view src, std::string_view dst, bool group_end = false) {
        return builder_.abs(variable(src), variable(dst), group_end);
    }

    Instruction layout_transpose(std::string_view src, std::string_view dst, bool group_end = false) {
        return builder_.layout_transpose(variable(src), variable(dst), group_end);
    }

    Instruction layout_assemble(std::string_view src, std::string_view dst,
                                int offset_row, int offset_col, bool group_end = false) {
        return builder_.layout_assemble(variable(src), variable(dst), offset_row, offset_col, group_end);
    }

    Instruction reduce_add(std::string_view src, bool group_end = false) {
        return builder_.reduce_add(variable(src), group_end);
    }

    Instruction reduce_cmp(std::string_view src, bool group_end = false) {
        return builder_.reduce_cmp(variable(src), group_end);
    }

    Instruction gemm(std::string_view a, std::string_view b, std::string_view c, bool group_end = false) {
        return builder_.gemm(variable(a), variable(b), variable(c), group_end);
    }

    Instruction mul(std::string_view a, std::string_view c, std::uint16_t alpha, bool group_end = false) {
        return builder_.mul(variable(a), variable(c), alpha, group_end);
    }

    Instruction add(std::string_view a, std::string_view b, std::string_view c, bool group_end = false) {
        return builder_.add(variable(a), variable(b), variable(c), group_end);
    }

    Instruction lut_sin(std::string_view src, std::string_view dst, bool group_end = false) {
        return builder_.lut_sin(variable(src), variable(dst), group_end);
    }

    Instruction lut_cos(std::string_view src, std::string_view dst, bool group_end = false) {
        return builder_.lut_cos(variable(src), variable(dst), group_end);
    }

    Instruction lut_softplus(std::string_view src, std::string_view dst, bool group_end = false) {
        return builder_.lut_softplus(variable(src), variable(dst), group_end);
    }

    Instruction with_group_end(Instruction instruction, bool group_end) {
        return InstructionBuilder::with_group_end(instruction, group_end);
    }

    void send_instruction(const Instruction& instruction) {
        device_.send_instruction(instruction.raw);
    }

    std::vector<RegisterWrite> register_writes(const Instruction& instruction, int core = 0) const {
        return instruction.register_writes(core);
    }

    StatusRegisters send_and_wait_next(const Instruction& instruction, int timeout_cycles) {
        send_instruction(instruction);
        return device_.wait_next_done(timeout_cycles);
    }

    StatusRegisters wait_done_count(std::uint32_t target_done_count, int timeout_cycles) {
        return device_.wait_done_count(target_done_count, timeout_cycles);
    }

    StatusRegisters wait_next_done(int timeout_cycles) {
        return device_.wait_next_done(timeout_cycles);
    }

    StatusRegisters read_status() {
        return device_.read_status();
    }

private:
    Device& device_;
    VariableAllocator allocator_;
    InstructionBuilder builder_;
};

} // namespace dexmpc::runtime
