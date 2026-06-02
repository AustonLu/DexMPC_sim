#define DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
#define DEX_TOPCHIP_TRANSPORT_SPI

#include "test_device_mixed_common.hpp"

#include <exception>
#include <filesystem>
#include <iostream>

#ifndef DEXMPC_RESULT_DIR
#define DEXMPC_RESULT_DIR "verification/results/software_stack/device_mixed/spi"
#endif

int main(int argc, char** argv) {
    try {
        auto device = dexmpc::runtime::Device::open_sim(argc, argv, dexmpc::runtime::Transport::SPI);
        dexmpc::tests::DeviceMixedTest test(device, std::filesystem::path(DEXMPC_RESULT_DIR), "SPI");
        test.run();
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Device mixed SPI test failed: " << e.what() << "\n";
        return 1;
    }
}
