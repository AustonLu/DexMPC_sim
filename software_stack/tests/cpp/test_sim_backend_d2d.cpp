#define DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
#define DEX_TOPCHIP_TRANSPORT_D2D

#include "dexmpc/runtime/device.hpp"

#include <cstddef>
#include <cstdint>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {

void expect_word_eq(const dexmpc::runtime::Word128& got,
                    const dexmpc::runtime::Word128& expected,
                    const char* label) {
    for (int i = 0; i < 4; ++i) {
        if (got[static_cast<std::size_t>(i)] != expected[static_cast<std::size_t>(i)]) {
            throw std::runtime_error(std::string(label) + " word mismatch");
        }
    }
}

} // namespace

int main(int argc, char** argv) {
    try {
        using namespace dexmpc::runtime;

        DeviceOptions defaults;
        if (defaults.transport != Transport::D2D) {
            throw std::runtime_error("DeviceOptions default transport must be D2D");
        }

        auto device = Device::open_sim(argc, argv);
        if (device.backend_kind() != BackendKind::SimModel) {
            throw std::runtime_error("expected SimModel backend");
        }
        if (device.transport() != Transport::D2D) {
            throw std::runtime_error("expected D2D transport");
        }

        device.reset();

        constexpr std::uint32_t kRegPattern = 0x12345678u;
        device.write_register(dexsim::topchip::kCfgCmdWord00, kRegPattern);
        const auto reg_value = device.read_register(dexsim::topchip::kCfgCmdWord00);
        if (reg_value != kRegPattern) {
            throw std::runtime_error("register readback mismatch");
        }

        const Word128 global_word{0x01234567u, 0x89abcdefu, 0x13579bdfu, 0xfedcba98u};
        device.write_memory_word(dexsim::kMemGlobal, 0, global_word);
        expect_word_eq(device.read_memory_word(dexsim::kMemGlobal, 0), global_word, "global");

        const Word128 local_word{0x10203040u, 0x50607080u, 0x90a0b0c0u, 0xd0e0f001u};
        device.write_memory_word(dexsim::kMemLocal0, 3, local_word);
        expect_word_eq(device.read_memory_word(dexsim::kMemLocal0, 3), local_word, "local");

        const Word128 temp_word{0x0badcafeu, 0x55aa55aau, 0xa5a5f00du, 0x11223344u};
        device.write_memory_word(dexsim::kMemTemp0, 5, temp_word);
        expect_word_eq(device.read_memory_word(dexsim::kMemTemp0, 5), temp_word, "temp");

        const auto status = device.read_status();
        std::cout << "SimBackend D2D smoke passed at cycle " << device.cycle()
                  << ", done_count=" << status.done_count << "\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "SimBackend D2D smoke failed: " << e.what() << "\n";
        return 1;
    }
}
