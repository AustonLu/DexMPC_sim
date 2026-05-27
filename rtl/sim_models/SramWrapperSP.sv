`ifndef SRAMWRAPPERSP_DEFINED
`define SRAMWRAPPERSP_DEFINED
module SramWrapperSp#(
    parameter int DEPTH = 64,
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 64
)(
    input  var logic                        clock,

    input  var logic                        rw_enable,
    input  var logic [ADDR_WIDTH - 1 : 0]   rw_addr,
    input  var logic                        rw_write,
    input  var logic [DATA_WIDTH - 1 : 0]   rw_dataIn,
    output var logic [DATA_WIDTH - 1 : 0]   rw_dataOut,

    input  var logic [DATA_WIDTH - 1 : 0]   rw_bweb
);

`ifdef FLOW_ASIC
    logic                       mem_rw_clock ;
    logic                       mem_rw_enable;
    logic                       mem_rw_write ;
    logic [ADDR_WIDTH - 1 : 0]  mem_rw_addr  ;
    logic [DATA_WIDTH - 1 : 0]  mem_rw_dataIn;
    logic [DATA_WIDTH - 1 : 0]  mem_rw_bweb;

    assign  mem_rw_clock  = clock;
    assign  mem_rw_enable = rw_enable;
    assign  mem_rw_write  = rw_write;
    assign  mem_rw_addr   = rw_addr;
    assign  mem_rw_dataIn = rw_dataIn;
    assign  mem_rw_bweb   = rw_bweb;

    generate
        if (DEPTH == 2048 && DATA_WIDTH == 128) begin
            wire bankSel = mem_rw_addr[ADDR_WIDTH - 1];
            wire [ADDR_WIDTH - 2:0] bankAddr = mem_rw_addr[ADDR_WIDTH - 2:0];
            wire [DATA_WIDTH - 1:0] q0;
            wire [DATA_WIDTH - 1:0] q1;
            wire en0 = mem_rw_enable && !bankSel;
            wire en1 = mem_rw_enable && bankSel;
            reg  bankSel_q;

            TS1N12FFCLLSBSVTC1024X128M4SW uSramMacro0 (
                .CLK(mem_rw_clock),
                .CEB(!en0),
                .WEB(!mem_rw_write),
                .A(bankAddr),
                .D(mem_rw_dataIn),
                .BWEB(mem_rw_bweb),
                .RTSEL(2'b01),
                .WTSEL(2'b00),
                .Q(q0)
            );

            TS1N12FFCLLSBSVTC1024X128M4SW uSramMacro1 (
                .CLK(mem_rw_clock),
                .CEB(!en1),
                .WEB(!mem_rw_write),
                .A(bankAddr),
                .D(mem_rw_dataIn),
                .BWEB(mem_rw_bweb),
                .RTSEL(2'b01),
                .WTSEL(2'b00),
                .Q(q1)
            );

            always @(posedge mem_rw_clock) begin
                if (mem_rw_enable) begin
                    bankSel_q <= bankSel;
                end
            end

            assign rw_dataOut = bankSel_q ? q1 : q0;
        end else if (DEPTH == 1024 && DATA_WIDTH == 128) begin
            TS1N12FFCLLSBSVTC1024X128M4SW uSramMacro (
                .CLK(mem_rw_clock),
                .CEB(!mem_rw_enable),
                .WEB(!mem_rw_write),
                .A(mem_rw_addr),
                .D(mem_rw_dataIn),
                .BWEB(mem_rw_bweb),
                .RTSEL(2'b01),
                .WTSEL(2'b00),
                .Q(rw_dataOut)
            );
        end else if (DEPTH == 512 && DATA_WIDTH == 128) begin
            TS1N12FFCLLSBSVTC512X128M4SW uSramMacro (
                .CLK(mem_rw_clock),
                .CEB(!mem_rw_enable),
                .WEB(!mem_rw_write),
                .A(mem_rw_addr),
                .D(mem_rw_dataIn),
                .BWEB(mem_rw_bweb),
                .RTSEL(2'b01),
                .WTSEL(2'b00),
                .Q(rw_dataOut)
            );
        end else if (DEPTH == 448 && DATA_WIDTH == 128) begin
            wire bankSel = mem_rw_addr[ADDR_WIDTH - 1];
            wire [ADDR_WIDTH - 2:0] bankAddr = mem_rw_addr[ADDR_WIDTH - 2:0];
            wire [DATA_WIDTH - 1:0] q0;
            wire [DATA_WIDTH - 1:0] q1;
            wire en0 = mem_rw_enable && !bankSel;
            wire en1 = mem_rw_enable && bankSel;
            reg  bankSel_q;

            TS1N12FFCLLSBSVTC224X128M4SW uSramMacro0 (
                .CLK(mem_rw_clock),
                .CEB(!en0),
                .WEB(!mem_rw_write),
                .A(bankAddr),
                .D(mem_rw_dataIn),
                .BWEB(mem_rw_bweb),
                .RTSEL(2'b01),
                .WTSEL(2'b00),
                .Q(q0)
            );

            TS1N12FFCLLSBSVTC224X128M4SW uSramMacro1 (
                .CLK(mem_rw_clock),
                .CEB(!en1),
                .WEB(!mem_rw_write),
                .A(bankAddr),
                .D(mem_rw_dataIn),
                .BWEB(mem_rw_bweb),
                .RTSEL(2'b01),
                .WTSEL(2'b00),
                .Q(q1)
            );

            always @(posedge mem_rw_clock) begin
                if (mem_rw_enable) begin
                    bankSel_q <= bankSel;
                end
            end

            assign rw_dataOut = bankSel_q ? q1 : q0;
        end else if (DEPTH == 224 && DATA_WIDTH == 128) begin
            TS1N12FFCLLSBSVTC224X128M4SW uSramMacro (
                .CLK(mem_rw_clock),
                .CEB(!mem_rw_enable),
                .WEB(!mem_rw_write),
                .A(mem_rw_addr),
                .D(mem_rw_dataIn),
                .BWEB(mem_rw_bweb),
                .RTSEL(2'b01),
                .WTSEL(2'b00),
                .Q(rw_dataOut)
            );
        end else if (DEPTH == 256 && DATA_WIDTH == 32) begin
            TS1N12FFCLLSBSVTC256X32M8SW uSramMacro (
                .CLK(mem_rw_clock),
                .CEB(!mem_rw_enable),
                .WEB(!mem_rw_write),
                .A(mem_rw_addr),
                .D(mem_rw_dataIn),
                .BWEB(mem_rw_bweb),
                .RTSEL(2'b01),
                .WTSEL(2'b00),
                .Q(rw_dataOut)
            );
        end else if (DEPTH == 128 && DATA_WIDTH == 16) begin
            TS1N12FFCLLSBSVTC128X16M4SW uSramMacro (
                .CLK(mem_rw_clock),
                .CEB(!mem_rw_enable),
                .WEB(!mem_rw_write),
                .A(mem_rw_addr),
                .D(mem_rw_dataIn),
                .BWEB(mem_rw_bweb),
                .RTSEL(2'b01),
                .WTSEL(2'b00),
                .Q(rw_dataOut)
            );
        end else begin
            // $fatal("Unsupported DEPTH and DATA_WIDTH combination"); // cannot pass design compiler
        end
    endgenerate
`else
    SramFpgaSp #(
        .DEPTH      (DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .MASK_UNIT  (1'd1)
    ) uSramMacro (
        .rw0_clock  (clock),
        .rw0_enable (rw_enable),
        .rw0_write  (rw_write),
        .rw0_addr   (rw_addr),
        .rw0_mask   (~rw_bweb),
        .rw0_dataIn (rw_dataIn),
        .rw0_dataOut(rw_dataOut)
    );
`endif


endmodule : SramWrapperSp
`endif
