#define DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
#define DEX_TOPCHIP_TRANSPORT_SPI

#include "dexmpc/runtime/operator.hpp"

#include <cstdint>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {

void expect_matrix_eq(const dexsim::Matrix& got, const dexsim::Matrix& expected, const char* label) {
    if (got.size() != expected.size()) {
        throw std::runtime_error(std::string(label) + " row count mismatch");
    }
    for (std::size_t r = 0; r < expected.size(); ++r) {
        if (got[r].size() != expected[r].size()) {
            throw std::runtime_error(std::string(label) + " column count mismatch");
        }
        for (std::size_t c = 0; c < expected[r].size(); ++c) {
            if (got[r][c] != expected[r][c]) {
                throw std::runtime_error(std::string(label) + " element mismatch");
            }
        }
    }
}

} // namespace

int main(int argc, char** argv) {
    try {
        using namespace dexmpc::runtime;

        auto device = Device::open_sim(argc, argv, Transport::SPI);
        OperatorRuntime runtime(device);
        runtime.reset_program();
        runtime.reset_device();

        constexpr std::uint16_t kFp16One = 0x3c00;
        constexpr std::uint16_t kFp16Two = 0x4000;
        constexpr std::uint16_t kFp16NegThree = 0xc200;
        constexpr std::uint16_t kFp16Four = 0x4400;
        constexpr std::uint16_t kFp16Five = 0x4500;
        constexpr std::uint16_t kFp16NegSix = 0xc600;
        constexpr std::uint16_t kFp16Seven = 0x4700;
        constexpr std::uint16_t kFp16NegOne = 0xbc00;

        dexsim::Matrix src{
            {kFp16One, kFp16Two, kFp16NegThree, kFp16Four},
            {kFp16Five, kFp16NegSix, kFp16Seven, kFp16NegOne},
        };
        dexsim::Matrix expected_abs{
            {kFp16One, kFp16Two, 0x4200, kFp16Four},
            {kFp16Five, 0x4600, kFp16Seven, kFp16One},
        };

        auto input = runtime.upload_matrix(src, dexsim::kMemGlobal, "op_spi_input");
        int released_base = -1;
        {
            auto output = runtime.abs(input, dexsim::kMemLocal0, "op_spi_abs");
            released_base = output.word_addr();
            expect_matrix_eq(runtime.download_matrix(output), expected_abs, "operator abs SPI");
        }
        auto reused = runtime.empty_matrix(dexsim::kMemLocal0, 2, 4, "op_spi_reused");
        if (reused.word_addr() != released_base) {
            throw std::runtime_error("operator SPI result memory was not auto released and reused");
        }

        std::cout << "OperatorRuntime SPI smoke passed at cycle " << device.cycle() << "\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "OperatorRuntime SPI smoke failed: " << e.what() << "\n";
        return 1;
    }
}
