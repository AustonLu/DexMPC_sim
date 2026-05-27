`ifndef SRAM_FPGA_MODEL_SV
`define SRAM_FPGA_MODEL_SV

// Cycle-level SRAM models used by the Verilator flow.
//
// The existing SRAM wrappers instantiate these modules when FLOW_ASIC is not
// defined. The wrapper converts the tapeout-style active-low BWEB signal into
// the active-high bit mask used here.

module SramFpgaSp #(
    parameter int DEPTH = 64,
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 64,
    parameter MASK_UNIT = 1,
    parameter int INIT_ZERO = 1
)(
    input  logic                         rw0_clock,
    input  logic                         rw0_enable,
    input  logic                         rw0_write,
    input  logic [ADDR_WIDTH - 1 : 0]    rw0_addr,
    input  logic [DATA_WIDTH - 1 : 0]    rw0_mask,
    input  logic [DATA_WIDTH - 1 : 0]    rw0_dataIn,
    output logic [DATA_WIDTH - 1 : 0]    rw0_dataOut
);

    logic [DATA_WIDTH - 1 : 0] mem [0 : DEPTH - 1];

    function automatic logic [DATA_WIDTH - 1 : 0] apply_mask(
        input logic [DATA_WIDTH - 1 : 0] old_data,
        input logic [DATA_WIDTH - 1 : 0] new_data,
        input logic [DATA_WIDTH - 1 : 0] mask
    );
        logic [DATA_WIDTH - 1 : 0] merged;
        begin
            merged = old_data;
            for (int bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx++) begin
                if (mask[bit_idx]) begin
                    merged[bit_idx] = new_data[bit_idx];
                end
            end
            apply_mask = merged;
        end
    endfunction

    function automatic bit addr_valid(input logic [ADDR_WIDTH - 1 : 0] addr);
        addr_valid = (int'(addr) < DEPTH);
    endfunction

    initial begin
        rw0_dataOut = '0;
        if (INIT_ZERO != 0) begin
            for (int addr_idx = 0; addr_idx < DEPTH; addr_idx++) begin
                mem[addr_idx] = '0;
            end
        end
    end

    always @(posedge rw0_clock) begin
        if (rw0_enable) begin
            if (!addr_valid(rw0_addr)) begin
`ifndef SYNTHESIS
                $error("SramFpgaSp address out of range: addr=%0d depth=%0d", rw0_addr, DEPTH);
`endif
                rw0_dataOut <= '0;
            end else begin
                rw0_dataOut <= mem[rw0_addr];
                if (rw0_write) begin
                    mem[rw0_addr] <= apply_mask(mem[rw0_addr], rw0_dataIn, rw0_mask);
                end
            end
        end
    end

endmodule

module SramFpgaDp #(
    parameter int DEPTH = 64,
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 64,
    parameter MASK_UNIT = 1,
    parameter int INIT_ZERO = 1
)(
    input  logic                         rw0_clock,
    input  logic                         rw0_enable,
    input  logic                         rw0_write,
    input  logic [ADDR_WIDTH - 1 : 0]    rw0_addr,
    input  logic [DATA_WIDTH - 1 : 0]    rw0_mask,
    input  logic [DATA_WIDTH - 1 : 0]    rw0_dataIn,
    output logic [DATA_WIDTH - 1 : 0]    rw0_dataOut,

    input  logic                         rw1_clock,
    input  logic                         rw1_enable,
    input  logic                         rw1_write,
    input  logic [ADDR_WIDTH - 1 : 0]    rw1_addr,
    input  logic [DATA_WIDTH - 1 : 0]    rw1_mask,
    input  logic [DATA_WIDTH - 1 : 0]    rw1_dataIn,
    output logic [DATA_WIDTH - 1 : 0]    rw1_dataOut
);

    logic [DATA_WIDTH - 1 : 0] mem [0 : DEPTH - 1];

    function automatic logic [DATA_WIDTH - 1 : 0] apply_mask(
        input logic [DATA_WIDTH - 1 : 0] old_data,
        input logic [DATA_WIDTH - 1 : 0] new_data,
        input logic [DATA_WIDTH - 1 : 0] mask
    );
        logic [DATA_WIDTH - 1 : 0] merged;
        begin
            merged = old_data;
            for (int bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx++) begin
                if (mask[bit_idx]) begin
                    merged[bit_idx] = new_data[bit_idx];
                end
            end
            apply_mask = merged;
        end
    endfunction

    function automatic bit addr_valid(input logic [ADDR_WIDTH - 1 : 0] addr);
        addr_valid = (int'(addr) < DEPTH);
    endfunction

    initial begin
        rw0_dataOut = '0;
        rw1_dataOut = '0;
        if (INIT_ZERO != 0) begin
            for (int addr_idx = 0; addr_idx < DEPTH; addr_idx++) begin
                mem[addr_idx] = '0;
            end
        end
    end

    always @(posedge rw0_clock) begin
        if (rw0_enable) begin
            if (!addr_valid(rw0_addr)) begin
`ifndef SYNTHESIS
                $error("SramFpgaDp port0 address out of range: addr=%0d depth=%0d", rw0_addr, DEPTH);
`endif
                rw0_dataOut <= '0;
            end else begin
                rw0_dataOut <= mem[rw0_addr];
                if (rw0_write) begin
                    mem[rw0_addr] <= apply_mask(mem[rw0_addr], rw0_dataIn, rw0_mask);
                end
            end
        end
    end

    always @(posedge rw1_clock) begin
        if (rw1_enable) begin
            if (!addr_valid(rw1_addr)) begin
`ifndef SYNTHESIS
                $error("SramFpgaDp port1 address out of range: addr=%0d depth=%0d", rw1_addr, DEPTH);
`endif
                rw1_dataOut <= '0;
            end else begin
                rw1_dataOut <= mem[rw1_addr];
                if (rw1_write) begin
                    mem[rw1_addr] <= apply_mask(mem[rw1_addr], rw1_dataIn, rw1_mask);
                end
            end
        end
    end

endmodule

`endif
