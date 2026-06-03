#define DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
#define DEX_TOPCHIP_TRANSPORT_D2D

#include "test_operator_mixed_common.hpp"

#include <exception>
#include <iostream>

int main(int argc, char** argv) {
    try {
        auto device = dexmpc::runtime::Device::open_sim(argc, argv, dexmpc::runtime::Transport::D2D);
        dexmpc::tests::OperatorMixedTest test(device, "D2D");
        test.run();
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Operator mixed D2D test failed: " << e.what() << "\n";
        return 1;
    }
}
