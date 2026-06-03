#pragma once

#include "dexmpc/runtime/instruction.hpp"

#include <cstdint>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace dexmpc::runtime {

namespace detail {

struct OperatorRuntimeState {
    InstructionRuntime* instruction = nullptr;
    bool active = true;
    std::uint64_t generation = 0;
};

} // namespace detail

struct ReduceResult {
    std::uint16_t value = 0;
    std::uint16_t index = 0;
    StatusRegisters status{};
};

class OperatorTensor {
public:
    OperatorTensor() = default;

    OperatorTensor(std::shared_ptr<detail::OperatorRuntimeState> state, VariableRef ref)
        : state_(std::move(state)), ref_(std::move(ref)), generation_(state_ ? state_->generation : 0),
          owning_(true) {}

    ~OperatorTensor() {
        release_noexcept();
    }

    OperatorTensor(const OperatorTensor&) = delete;
    OperatorTensor& operator=(const OperatorTensor&) = delete;

    OperatorTensor(OperatorTensor&& other) noexcept
        : state_(std::move(other.state_)), ref_(std::move(other.ref_)),
          generation_(other.generation_), owning_(other.owning_) {
        other.owning_ = false;
    }

    OperatorTensor& operator=(OperatorTensor&& other) noexcept {
        if (this == &other) return *this;
        release_noexcept();
        state_ = std::move(other.state_);
        ref_ = std::move(other.ref_);
        generation_ = other.generation_;
        owning_ = other.owning_;
        other.owning_ = false;
        return *this;
    }

    bool valid() const {
        return owning_ && state_ != nullptr && state_->active && generation_ == state_->generation;
    }
    const VariableRef& ref() const { return ref_; }
    const std::string& name() const { return ref_.name; }
    int mem_id() const { return ref_.mem_id; }
    int word_addr() const { return ref_.word_addr; }
    int word_count() const { return ref_.word_count; }
    int elem_count() const { return ref_.elem_count; }
    int rows() const { return ref_.rows; }
    int cols() const { return ref_.cols; }
    bool is_matrix() const { return ref_.is_matrix(); }

private:
    void release_noexcept() noexcept {
        if (!owning_) return;
        owning_ = false;
        if (!state_ || !state_->active || generation_ != state_->generation ||
            state_->instruction == nullptr || ref_.name.empty()) {
            return;
        }
        try {
            state_->instruction->release_variable(ref_.name);
        } catch (...) {
        }
    }

    std::shared_ptr<detail::OperatorRuntimeState> state_;
    VariableRef ref_{};
    std::uint64_t generation_ = 0;
    bool owning_ = false;
};

class OperatorRuntime {
public:
    explicit OperatorRuntime(Device& device, int timeout_cycles = 1200000)
        : instruction_(device), timeout_cycles_(timeout_cycles),
          state_(std::make_shared<detail::OperatorRuntimeState>()) {
        state_->instruction = &instruction_;
    }

    ~OperatorRuntime() {
        state_->active = false;
        state_->instruction = nullptr;
    }

    OperatorRuntime(const OperatorRuntime&) = delete;
    OperatorRuntime& operator=(const OperatorRuntime&) = delete;
    OperatorRuntime(OperatorRuntime&&) = delete;
    OperatorRuntime& operator=(OperatorRuntime&&) = delete;

    InstructionRuntime& instruction_runtime() { return instruction_; }
    Device& device() { return instruction_.device(); }

    void reset_program(std::uint32_t first_cmd_id = 0) {
        instruction_.reset_program(first_cmd_id);
        ++state_->generation;
        next_auto_id_ = 0;
    }

    void reset_device() { instruction_.reset_device(); }
    void write_register(int reg_idx, std::uint32_t value) { instruction_.write_register(reg_idx, value); }
    std::uint32_t read_register(int reg_idx) { return instruction_.read_register(reg_idx); }
    void write_memory(int mem_id, int word_addr, const std::vector<Word128>& words) {
        instruction_.write_memory(mem_id, word_addr, words);
    }
    std::vector<Word128> read_memory(int mem_id, int word_addr, int word_count) {
        return instruction_.read_memory(mem_id, word_addr, word_count);
    }

    OperatorTensor empty_matrix(int mem_id, int rows, int cols, std::string name = {}) {
        auto ref = instruction_.allocate_matrix(resolve_name(std::move(name), "matrix"), mem_id, rows, cols);
        return OperatorTensor(state_, std::move(ref));
    }

    OperatorTensor empty_vector(int mem_id, int elem_count, std::string name = {}) {
        auto ref = instruction_.allocate_vector(resolve_name(std::move(name), "vector"), mem_id, elem_count);
        return OperatorTensor(state_, std::move(ref));
    }

    OperatorTensor empty_words(int mem_id, int word_count, std::string name = {}) {
        auto ref = instruction_.allocate_words(resolve_name(std::move(name), "words"), mem_id, word_count);
        return OperatorTensor(state_, std::move(ref));
    }

    OperatorTensor bind_existing_matrix(int mem_id, int word_addr, int rows, int cols, std::string name = {}) {
        auto ref = instruction_.bind_existing(resolve_name(std::move(name), "bound_matrix"),
                                              mem_id, word_addr, rows * cols, rows, cols);
        return OperatorTensor(state_, std::move(ref));
    }

    OperatorTensor bind_existing_vector(int mem_id, int word_addr, int elem_count, std::string name = {}) {
        auto ref = instruction_.bind_existing(resolve_name(std::move(name), "bound_vector"),
                                              mem_id, word_addr, elem_count, 1, elem_count);
        return OperatorTensor(state_, std::move(ref));
    }

    OperatorTensor bind_existing_words(int mem_id, int word_addr, int word_count, std::string name = {}) {
        auto ref = instruction_.bind_existing_words(resolve_name(std::move(name), "bound_words"),
                                                    mem_id, word_addr, word_count);
        return OperatorTensor(state_, std::move(ref));
    }

    OperatorTensor upload_matrix(const dexsim::Matrix& matrix, int mem_id, std::string name = {}) {
        const int rows = checked_rows(matrix);
        const int cols = checked_cols(matrix);
        auto tensor = empty_matrix(mem_id, rows, cols, std::move(name));
        instruction_.write_variable_words(tensor.name(), dexsim::matrix_to_words(matrix, rows, cols));
        return tensor;
    }

    OperatorTensor upload_vector(const std::vector<std::uint16_t>& values, int mem_id, std::string name = {}) {
        if (values.empty()) throw std::runtime_error("operator upload_vector requires non-empty data");
        auto tensor = empty_vector(mem_id, static_cast<int>(values.size()), std::move(name));
        instruction_.write_variable_words(tensor.name(), dexsim::pack_elements(values));
        return tensor;
    }

    OperatorTensor upload_words(const std::vector<Word128>& words, int mem_id, std::string name = {}) {
        if (words.empty()) throw std::runtime_error("operator upload_words requires non-empty data");
        auto tensor = empty_words(mem_id, static_cast<int>(words.size()), std::move(name));
        instruction_.write_variable_words(tensor.name(), words);
        return tensor;
    }

    void write_words(const OperatorTensor& tensor, const std::vector<Word128>& words) {
        require_live(tensor);
        instruction_.write_variable_words(tensor.name(), words);
    }

    std::vector<Word128> download_words(const OperatorTensor& tensor) {
        require_live(tensor);
        return instruction_.read_variable_words(tensor.name());
    }

    dexsim::Matrix download_matrix(const OperatorTensor& tensor) {
        require_matrix(tensor, "download_matrix tensor");
        return dexsim::words_to_matrix(download_words(tensor), tensor.rows(), tensor.cols());
    }

    std::vector<std::uint16_t> download_vector(const OperatorTensor& tensor) {
        require_live(tensor);
        return dexsim::unpack_elements(download_words(tensor), tensor.elem_count());
    }

    OperatorTensor abs(const OperatorTensor& src, int dst_mem, std::string name = {}) {
        require_matrix(src, "abs src");
        auto dst = empty_matrix(dst_mem, src.rows(), src.cols(), std::move(name));
        execute(instruction_.abs(src.name(), dst.name(), true));
        return dst;
    }

    OperatorTensor layout_transpose(const OperatorTensor& src, int dst_mem, std::string name = {}) {
        require_matrix(src, "transpose src");
        auto dst = empty_matrix(dst_mem, src.cols(), src.rows(), std::move(name));
        execute(instruction_.layout_transpose(src.name(), dst.name(), true));
        return dst;
    }

    OperatorTensor layout_assemble(const OperatorTensor& src, int dst_mem,
                                   int dst_rows, int dst_cols,
                                   int offset_row, int offset_col,
                                   std::string name = {}) {
        auto dst = empty_matrix(dst_mem, dst_rows, dst_cols, std::move(name));
        layout_assemble_into(src, dst, offset_row, offset_col);
        return dst;
    }

    void layout_assemble_into(const OperatorTensor& src, const OperatorTensor& dst,
                              int offset_row, int offset_col) {
        require_matrix(src, "assemble src");
        require_matrix(dst, "assemble dst");
        execute(instruction_.layout_assemble(src.name(), dst.name(), offset_row, offset_col, true));
    }

    ReduceResult reduce_add(const OperatorTensor& src) {
        require_live(src);
        const auto status = execute(instruction_.reduce_add(src.name(), true));
        const auto reg = status.add_reduce;
        const bool valid = ((reg >> 28) & 1u) != 0;
        const auto cmd = (reg >> 16) & 0xfffu;
        if (!valid) throw std::runtime_error("operator reduce_add result valid bit was not set");
        if (cmd != status_cmd_id(status)) throw std::runtime_error("operator reduce_add cmd id mismatch");
        return ReduceResult{static_cast<std::uint16_t>(reg & 0xffffu), 0, status};
    }

    ReduceResult reduce_cmp(const OperatorTensor& src) {
        require_live(src);
        const auto status = execute(instruction_.reduce_cmp(src.name(), true));
        const auto reg0 = status.cmp_reduce0;
        const auto reg1 = status.cmp_reduce1;
        const bool valid = ((reg0 >> 28) & 1u) != 0;
        const auto cmd = (reg0 >> 16) & 0xfffu;
        if (!valid) throw std::runtime_error("operator reduce_cmp result valid bit was not set");
        if (cmd != status_cmd_id(status)) throw std::runtime_error("operator reduce_cmp cmd id mismatch");
        return ReduceResult{
            static_cast<std::uint16_t>(reg0 & 0xffffu),
            static_cast<std::uint16_t>(reg1 & 0xfffu),
            status,
        };
    }

    OperatorTensor gemm(const OperatorTensor& a, const OperatorTensor& b, int dst_mem, std::string name = {}) {
        require_matrix(a, "gemm A");
        require_matrix(b, "gemm B");
        auto c = empty_matrix(dst_mem, a.rows(), b.cols(), std::move(name));
        execute(instruction_.gemm(a.name(), b.name(), c.name(), true));
        return c;
    }

    void gemm_into(const OperatorTensor& a, const OperatorTensor& b, const OperatorTensor& c) {
        require_matrix(a, "gemm A");
        require_matrix(b, "gemm B");
        require_matrix(c, "gemm C");
        execute(instruction_.gemm(a.name(), b.name(), c.name(), true));
    }

    OperatorTensor mul(const OperatorTensor& a, std::uint16_t alpha, int dst_mem, std::string name = {}) {
        require_matrix(a, "mul A");
        auto c = empty_matrix(dst_mem, a.rows(), a.cols(), std::move(name));
        execute(instruction_.mul(a.name(), c.name(), alpha, true));
        return c;
    }

    OperatorTensor add(const OperatorTensor& a, const OperatorTensor& b, int dst_mem, std::string name = {}) {
        require_matrix(a, "add A");
        require_matrix(b, "add B");
        auto c = empty_matrix(dst_mem, a.rows(), a.cols(), std::move(name));
        execute(instruction_.add(a.name(), b.name(), c.name(), true));
        return c;
    }

    OperatorTensor lut_sin(const OperatorTensor& src, int dst_mem, std::string name = {}) {
        return lut(src, dst_mem, std::move(name), LutKind::Sin);
    }

    OperatorTensor lut_cos(const OperatorTensor& src, int dst_mem, std::string name = {}) {
        return lut(src, dst_mem, std::move(name), LutKind::Cos);
    }

    OperatorTensor lut_softplus(const OperatorTensor& src, int dst_mem, std::string name = {}) {
        return lut(src, dst_mem, std::move(name), LutKind::Softplus);
    }

private:
    enum class LutKind { Sin, Cos, Softplus };

    static void require_live(const OperatorTensor& tensor) {
        if (!tensor.valid()) throw std::runtime_error("operator tensor is not live");
    }

    static void require_matrix(const OperatorTensor& tensor, std::string_view label) {
        require_live(tensor);
        if (!tensor.is_matrix()) {
            throw std::runtime_error(std::string(label) + " must be a matrix tensor");
        }
    }

    static int checked_rows(const dexsim::Matrix& matrix) {
        if (matrix.empty()) throw std::runtime_error("operator matrix must not be empty");
        return static_cast<int>(matrix.size());
    }

    static int checked_cols(const dexsim::Matrix& matrix) {
        if (matrix.empty() || matrix[0].empty()) {
            throw std::runtime_error("operator matrix must not be empty");
        }
        const auto cols = matrix[0].size();
        for (const auto& row : matrix) {
            if (row.size() != cols) throw std::runtime_error("operator matrix rows must be rectangular");
        }
        return static_cast<int>(cols);
    }

    static std::uint32_t status_cmd_id(const StatusRegisters& status) {
        return status.last_done & 0xfffu;
    }

    std::string resolve_name(std::string name, std::string_view prefix) {
        if (!name.empty()) return name;
        return "op_" + std::string(prefix) + "_" + std::to_string(next_auto_id_++);
    }

    StatusRegisters execute(const Instruction& instruction) {
        return instruction_.send_and_wait_next(instruction, timeout_cycles_);
    }

    OperatorTensor lut(const OperatorTensor& src, int dst_mem, std::string name, LutKind kind) {
        require_matrix(src, "lut src");
        auto dst = empty_matrix(dst_mem, src.rows(), src.cols(), std::move(name));
        switch (kind) {
        case LutKind::Sin:
            execute(instruction_.lut_sin(src.name(), dst.name(), true));
            break;
        case LutKind::Cos:
            execute(instruction_.lut_cos(src.name(), dst.name(), true));
            break;
        case LutKind::Softplus:
            execute(instruction_.lut_softplus(src.name(), dst.name(), true));
            break;
        }
        return dst;
    }

    InstructionRuntime instruction_;
    int timeout_cycles_ = 1200000;
    std::shared_ptr<detail::OperatorRuntimeState> state_;
    std::uint64_t next_auto_id_ = 0;
};

} // namespace dexmpc::runtime
