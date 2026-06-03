#define DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
#define DEX_TOPCHIP_TRANSPORT_D2D

#include "dexmpc/runtime/instruction.hpp"

#include <cstddef>
#include <cstdint>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

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

        InstructionRuntime runtime(device);
        runtime.reset_program();
        runtime.reset_device();

        constexpr std::uint32_t kRegPattern = 0x12345678u;
        runtime.write_register(dexsim::topchip::kCfgCmdWord00, kRegPattern);
        const auto reg_value = runtime.read_register(dexsim::topchip::kCfgCmdWord00);
        if (reg_value != kRegPattern) {
            throw std::runtime_error("register readback mismatch");
        }

        const auto global_ref = runtime.allocate_words("global_word", dexsim::kMemGlobal, 1);
        const Word128 global_word{0x01234567u, 0x89abcdefu, 0x13579bdfu, 0xfedcba98u};
        runtime.write_variable_words(global_ref.name, std::vector<Word128>{global_word});
        expect_word_eq(runtime.read_variable_words(global_ref.name).at(0), global_word, "global");

        const auto local_ref = runtime.allocate_words("local_word", dexsim::kMemLocal0, 1);
        const Word128 local_word{0x10203040u, 0x50607080u, 0x90a0b0c0u, 0xd0e0f001u};
        runtime.write_variable_words(local_ref.name, std::vector<Word128>{local_word});
        expect_word_eq(runtime.read_variable_words(local_ref.name).at(0), local_word, "local");

        const auto temp_ref = runtime.allocate_words("temp_word", dexsim::kMemTemp0, 1);
        const Word128 temp_word{0x0badcafeu, 0x55aa55aau, 0xa5a5f00du, 0x11223344u};
        runtime.write_variable_words(temp_ref.name, std::vector<Word128>{temp_word});
        expect_word_eq(runtime.read_variable_words(temp_ref.name).at(0), temp_word, "temp");

        runtime.release_variable(global_ref.name);
        const auto reused_global_ref = runtime.allocate_words("global_reused_word", dexsim::kMemGlobal, 1);
        if (reused_global_ref.word_addr != global_ref.word_addr) {
            throw std::runtime_error("released global variable address was not reused");
        }
        const Word128 reused_global_word{0xaaaa5555u, 0xbbbb6666u, 0xcccc7777u, 0xdddd8888u};
        runtime.write_variable_words(reused_global_ref.name, std::vector<Word128>{reused_global_word});
        expect_word_eq(runtime.read_variable_words(reused_global_ref.name).at(0),
                       reused_global_word, "global reused");

        const auto status = runtime.read_status();
        std::cout << "InstructionRuntime D2D smoke passed at cycle " << device.cycle()
                  << ", done_count=" << status.done_count << "\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "InstructionRuntime D2D smoke failed: " << e.what() << "\n";
        return 1;
    }
}
