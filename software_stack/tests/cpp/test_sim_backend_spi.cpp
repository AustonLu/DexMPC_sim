#define DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
#define DEX_TOPCHIP_TRANSPORT_SPI

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

        auto device = Device::open_sim(argc, argv, Transport::SPI);
        if (device.backend_kind() != BackendKind::SimModel) {
            throw std::runtime_error("expected SimModel backend");
        }
        if (device.transport() != Transport::SPI) {
            throw std::runtime_error("expected SPI transport");
        }

        device.reset();

        constexpr std::uint32_t kRegPattern = 0x5aa55aa5u;
        device.write_register(dexsim::topchip::kCfgCmdWord00, kRegPattern);
        const auto reg_value = device.read_register(dexsim::topchip::kCfgCmdWord00);
        if (reg_value != kRegPattern) {
            throw std::runtime_error("register readback mismatch");
        }

        const Word128 word{0x76543210u, 0xfedcba98u, 0x2468ace0u, 0x13579bdfu};
        device.write_memory_word(dexsim::kMemGlobal, 0, word);
        expect_word_eq(device.read_memory_word(dexsim::kMemGlobal, 0), word, "global");

        const auto status = device.read_status();
        std::cout << "SimBackend SPI smoke passed at cycle " << device.cycle()
                  << ", done_count=" << status.done_count << "\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "SimBackend SPI smoke failed: " << e.what() << "\n";
        return 1;
    }
}
