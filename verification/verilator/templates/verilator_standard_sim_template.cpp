// verilator_standard_sim_template.cpp
// A reusable C++ simulation template for Verilator-based RTL verification.
//
// Usage example:
//   verilator -Wall --cc -f filelist.f \
//     --top-module top \
//     --exe verification/verilator/templates/verilator_standard_sim_template.cpp \
//     --Mdir build/verilator/example_top \
//     --build
//   ./build/verilator/example_top/Vtop
//
// Notes:
//   1. Replace "Vtop.h" and "Vtop" if your top module is not named "top".
//      For example, if your top module is "our", use "Vour.h" and "Vour".
//   2. Replace signal names such as clk/rst_n with your actual top-level ports.
//   3. Add your driver.step(), memory.step(), software stack bridge, trace logic, etc.

#include "Vtop.h"
#include "verilated.h"

#include <cstdint>
#include <iostream>
#include <memory>
#include <stdexcept>

class Sim {
public:
    Sim(int argc, char** argv) {
        contextp_ = std::make_unique<VerilatedContext>();
        contextp_->commandArgs(argc, argv);

        top_ = std::make_unique<Vtop>(contextp_.get());

        // Initialize common top-level signals.
        // Modify these names according to your RTL top module.
        top_->clk = 0;
        top_->rst_n = 0;
    }

    ~Sim() {
        if (top_) {
            top_->final();
        }
    }

    Sim(const Sim&) = delete;
    Sim& operator=(const Sim&) = delete;

    Vtop* dut() {
        return top_.get();
    }

    const Vtop* dut() const {
        return top_.get();
    }

    VerilatedContext* context() {
        return contextp_.get();
    }

    const VerilatedContext* context() const {
        return contextp_.get();
    }

    uint64_t cycle() const {
        return cycle_count_;
    }

    bool finished() const {
        return contextp_->gotFinish();
    }

    void eval() {
        top_->eval();
    }

    // Advance one full clock cycle.
    // Here one cycle = low phase + high phase = 10 time units.
    // Adjust timeInc() values if you want a different simulated period.
    void tick() {
        // Low phase
        top_->clk = 0;
        top_->eval();
        contextp_->timeInc(5);

        // High phase. The posedge-triggered sequential logic is evaluated here.
        top_->clk = 1;
        top_->eval();
        contextp_->timeInc(5);

        ++cycle_count_;
    }

    // Apply reset for n cycles, then release reset.
    void reset(int n = 10) {
        top_->rst_n = 0;
        for (int i = 0; i < n; ++i) {
            tick();
        }

        top_->rst_n = 1;
        tick();
    }

    // Run for at most max_cycles cycles.
    // You can place driver/memory/software-stack stepping logic in the loop.
    void run(uint64_t max_cycles) {
        while (!finished()) {
            // -----------------------------------------------------------------
            // Add your custom per-cycle simulation logic here.
            // Examples:
            //   driver.step(dut());
            //   memory.step(dut());
            //   software_stack_bridge.step(dut());
            // -----------------------------------------------------------------

            tick();

            if (cycle_count_ >= max_cycles) {
                throw std::runtime_error("Simulation timeout");
            }
        }
    }

private:
    std::unique_ptr<VerilatedContext> contextp_;
    std::unique_ptr<Vtop> top_;
    uint64_t cycle_count_ = 0;
};

int main(int argc, char** argv) {
    try {
        Sim sim(argc, argv);

        sim.reset();

        auto* dut = sim.dut();

        // ---------------------------------------------------------------------
        // Put one-time test initialization here.
        // Examples:
        //   MemoryModel memory;
        //   memory.load_binary("program.bin", 0x80000000);
        //
        //   CpuDriver driver(sim);
        //   driver.send_program(program);
        // ---------------------------------------------------------------------
        (void)dut;  // Remove this line after using dut.

        constexpr uint64_t kMaxCycles = 100000;
        sim.run(kMaxCycles);

        std::cout << "Simulation finished at cycle "
                  << sim.cycle() << std::endl;

        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Simulation failed: " << e.what() << std::endl;
        return 1;
    }
}
