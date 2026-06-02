#pragma once

#ifdef DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
#include "topchip_sim.hpp"
#else
#define DEXMPC_SIM_COMMON_ONLY
#include "dexmpc_sim.hpp"
#undef DEXMPC_SIM_COMMON_ONLY
#endif

#include <cstdint>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace dexmpc::runtime {

using Cmd96 = dexsim::Cmd96;
using Word128 = dexsim::Word128;

enum class BackendKind {
    SimModel,
    FpgaChip,
};

enum class Transport {
    D2D,
    SPI,
};

inline std::string_view to_string(BackendKind kind) {
    switch (kind) {
    case BackendKind::SimModel:
        return "sim_model";
    case BackendKind::FpgaChip:
        return "fpga_chip";
    }
    return "unknown";
}

inline std::string_view to_string(Transport transport) {
    switch (transport) {
    case Transport::D2D:
        return "d2d";
    case Transport::SPI:
        return "spi";
    }
    return "unknown";
}

struct DeviceOptions {
    BackendKind backend = BackendKind::SimModel;
    Transport transport = Transport::D2D;
    int wait_timeout_cycles = 400000;
};

struct StatusRegisters {
    std::uint32_t cmd_status = 0;
    std::uint32_t done_count = 0;
    std::uint32_t last_done = 0;
    std::uint32_t add_reduce = 0;
    std::uint32_t cmp_reduce0 = 0;
    std::uint32_t cmp_reduce1 = 0;
    std::uint32_t engine_status = 0;
    std::uint32_t all_done = 0;
};

class IDeviceBackend {
public:
    virtual ~IDeviceBackend() = default;

    virtual BackendKind backend_kind() const = 0;
    virtual Transport transport() const = 0;
    virtual std::uint64_t cycle() const = 0;

    virtual void reset() = 0;
    virtual void write_register(int reg_idx, std::uint32_t value) = 0;
    virtual std::uint32_t read_register(int reg_idx) = 0;
    virtual void write_memory(int mem_id, int word_addr, const std::vector<Word128>& words) = 0;
    virtual std::vector<Word128> read_memory(int mem_id, int word_addr, int word_count) = 0;
    virtual void send_instruction(Cmd96 command) = 0;
    virtual StatusRegisters wait_done_count(std::uint32_t target_done_count, int timeout_cycles) = 0;
    virtual StatusRegisters wait_next_done(int timeout_cycles) = 0;
    virtual StatusRegisters read_status() = 0;
};

class Device {
public:
    static Device open(const DeviceOptions& options, int argc, char** argv);

    static Device open_sim(int argc, char** argv, Transport transport = Transport::D2D) {
        DeviceOptions options;
        options.backend = BackendKind::SimModel;
        options.transport = transport;
        return open(options, argc, argv);
    }

    explicit Device(std::unique_ptr<IDeviceBackend> backend)
        : backend_(std::move(backend)) {
        if (!backend_) throw std::runtime_error("Device backend must not be null");
    }

    Device(Device&&) noexcept = default;
    Device& operator=(Device&&) noexcept = default;
    Device(const Device&) = delete;
    Device& operator=(const Device&) = delete;

    BackendKind backend_kind() const { return backend_->backend_kind(); }
    Transport transport() const { return backend_->transport(); }
    std::uint64_t cycle() const { return backend_->cycle(); }

    void reset() { backend_->reset(); }
    void write_register(int reg_idx, std::uint32_t value) { backend_->write_register(reg_idx, value); }
    std::uint32_t read_register(int reg_idx) { return backend_->read_register(reg_idx); }

    void write_memory(int mem_id, int word_addr, const std::vector<Word128>& words) {
        backend_->write_memory(mem_id, word_addr, words);
    }

    void write_memory_word(int mem_id, int word_addr, const Word128& word) {
        backend_->write_memory(mem_id, word_addr, std::vector<Word128>{word});
    }

    std::vector<Word128> read_memory(int mem_id, int word_addr, int word_count) {
        return backend_->read_memory(mem_id, word_addr, word_count);
    }

    Word128 read_memory_word(int mem_id, int word_addr) {
        auto words = backend_->read_memory(mem_id, word_addr, 1);
        if (words.size() != 1) throw std::runtime_error("read_memory_word returned invalid size");
        return words[0];
    }

    void send_instruction(Cmd96 command) { backend_->send_instruction(command); }
    StatusRegisters wait_done_count(std::uint32_t target_done_count, int timeout_cycles) {
        return backend_->wait_done_count(target_done_count, timeout_cycles);
    }
    StatusRegisters wait_next_done(int timeout_cycles) { return backend_->wait_next_done(timeout_cycles); }
    StatusRegisters read_status() { return backend_->read_status(); }

private:
    std::unique_ptr<IDeviceBackend> backend_;
};

#ifdef DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
inline Transport compiled_sim_transport() {
#if defined(DEX_TOPCHIP_TRANSPORT_D2D)
    return Transport::D2D;
#elif defined(DEX_TOPCHIP_TRANSPORT_SPI)
    return Transport::SPI;
#else
    throw std::runtime_error("SimBackend requires DEX_TOPCHIP_TRANSPORT_D2D or DEX_TOPCHIP_TRANSPORT_SPI");
#endif
}

class SimBackend final : public IDeviceBackend {
public:
    SimBackend(DeviceOptions options, int argc, char** argv)
        : options_(options), sim_(argc, argv) {
        if (options_.transport != compiled_sim_transport()) {
            throw std::runtime_error(
                "Selected transport " + std::string(to_string(options_.transport))
                + " does not match compiled SimBackend transport "
                + std::string(to_string(compiled_sim_transport())));
        }
    }

    BackendKind backend_kind() const override { return BackendKind::SimModel; }
    Transport transport() const override { return options_.transport; }
    std::uint64_t cycle() const override { return sim_.cycle(); }

    void reset() override {
        sim_.reset();
        sim_.write_reg(dexsim::topchip::kCfgIsLoop, 0);
        observed_done_count_ = 0;
    }

    void write_register(int reg_idx, std::uint32_t value) override { sim_.write_reg(reg_idx, value); }
    std::uint32_t read_register(int reg_idx) override {
        const auto value = sim_.read_reg(reg_idx);
        if (reg_idx == dexsim::topchip::kCfgDoneCount0) {
            observed_done_count_ = value;
        }
        return value;
    }
    void write_memory(int mem_id, int word_addr, const std::vector<Word128>& words) override {
        sim_.write_mem_words(mem_id, word_addr, words);
    }
    std::vector<Word128> read_memory(int mem_id, int word_addr, int word_count) override {
        return sim_.read_mem_words(mem_id, word_addr, word_count);
    }

    void send_instruction(Cmd96 command) override {
        wait_fifo_space();
        (void)read_status();
        sim_.write_reg(dexsim::topchip::kCfgCmdWord00, dexsim::cmd_word(command, 0));
        sim_.write_reg(dexsim::topchip::kCfgCmdWord01, dexsim::cmd_word(command, 1));
        sim_.write_reg(dexsim::topchip::kCfgCmdWord02, dexsim::cmd_word(command, 2));
        sim_.write_reg(dexsim::topchip::kCfgCmdCtrl0, 1);
        sim_.write_reg(dexsim::topchip::kCfgCmdCtrl0, 0);
    }

    StatusRegisters wait_done_count(std::uint32_t target_done_count, int timeout_cycles) override {
        auto status = read_status();
        if (status.done_count >= target_done_count) {
            return status;
        }

        constexpr int kPollCycles = 128;
        for (int cycles = 0; cycles < timeout_cycles; cycles += kPollCycles) {
            sim_.run_core_cycles(kPollCycles);
            if (sim_.read_reg(dexsim::topchip::kCfgDoneCount0) >= target_done_count) {
                return read_status();
            }
        }

        const auto final_status = read_status();
        throw std::runtime_error(
            "timeout waiting for doneCount target=" + std::to_string(target_done_count)
            + " got=" + std::to_string(final_status.done_count));
    }

    StatusRegisters wait_next_done(int timeout_cycles) override {
        return wait_done_count(observed_done_count_ + 1, timeout_cycles);
    }

    StatusRegisters read_status() override {
        sim_.refresh_status_regs();
        const auto* view = sim_.dut();
        observed_done_count_ = view->io_doneCount_0;
        return StatusRegisters{
            view->io_cmdStatus_0,
            view->io_doneCount_0,
            view->io_lastDone_0,
            view->io_addReduceReg_0,
            view->io_cmpReduceReg0_0,
            view->io_cmpReduceReg1_0,
            view->io_engineStatus,
            view->io_allDoneReg,
        };
    }

private:
    void wait_fifo_space() {
        for (int guard = 0; guard < 10000; ++guard) {
            if ((sim_.read_reg(dexsim::topchip::kCfgCmdStatus0) & 0x1u) == 0) return;
            sim_.run_core_cycles(1);
        }
        throw std::runtime_error("timeout waiting for TopChip command FIFO space");
    }

    DeviceOptions options_;
    dexsim::topchip::Sim sim_;
    std::uint32_t observed_done_count_ = 0;
};
#endif

class FpgaChipBackend final : public IDeviceBackend {
public:
    explicit FpgaChipBackend(DeviceOptions options) : options_(options) {}

    BackendKind backend_kind() const override { return BackendKind::FpgaChip; }
    Transport transport() const override { return options_.transport; }
    std::uint64_t cycle() const override { return 0; }

    void reset() override { not_implemented("reset"); }
    void write_register(int, std::uint32_t) override { not_implemented("write_register"); }
    std::uint32_t read_register(int) override {
        not_implemented("read_register");
        return 0;
    }
    void write_memory(int, int, const std::vector<Word128>&) override { not_implemented("write_memory"); }
    std::vector<Word128> read_memory(int, int, int) override {
        not_implemented("read_memory");
        return {};
    }
    void send_instruction(Cmd96) override { not_implemented("send_instruction"); }
    StatusRegisters wait_done_count(std::uint32_t, int) override {
        not_implemented("wait_done_count");
        return {};
    }
    StatusRegisters wait_next_done(int) override {
        not_implemented("wait_next_done");
        return {};
    }
    StatusRegisters read_status() override {
        not_implemented("read_status");
        return {};
    }

private:
    [[noreturn]] void not_implemented(std::string_view operation) const {
        throw std::runtime_error(
            "FpgaChipBackend::" + std::string(operation)
            + " is reserved but not implemented yet for transport "
            + std::string(to_string(options_.transport)));
    }

    DeviceOptions options_;
};

inline Device Device::open(const DeviceOptions& options, int argc, char** argv) {
    switch (options.backend) {
    case BackendKind::SimModel:
#ifdef DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
        return Device(std::make_unique<SimBackend>(options, argc, argv));
#else
        (void)argc;
        (void)argv;
        throw std::runtime_error("SimModel backend was not enabled at compile time");
#endif
    case BackendKind::FpgaChip:
        (void)argc;
        (void)argv;
        return Device(std::make_unique<FpgaChipBackend>(options));
    }
    throw std::runtime_error("unsupported backend kind");
}

} // namespace dexmpc::runtime
