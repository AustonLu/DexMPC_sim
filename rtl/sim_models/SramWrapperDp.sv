module SramWrapperDp #(
    parameter int DEPTH = 64,
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 64
)(
    input  var logic                         clock,

    input  var logic                         rw_enable_a,
    input  var logic [ADDR_WIDTH - 1 : 0]    rw_addr_a,
    input  var logic                         rw_write_a,
    input  var logic [DATA_WIDTH - 1 : 0]    rw_dataIn_a,
    output var logic [DATA_WIDTH - 1 : 0]    rw_dataOut_a,

    input  var logic                         rw_enable_b,
    input  var logic [ADDR_WIDTH - 1 : 0]    rw_addr_b,
    input  var logic                         rw_write_b,
    input  var logic [DATA_WIDTH - 1 : 0]    rw_dataIn_b,
    output var logic [DATA_WIDTH - 1 : 0]    rw_dataOut_b,

    input  var logic [DATA_WIDTH - 1 : 0]    rw_bweb_a,
    input  var logic [DATA_WIDTH - 1 : 0]    rw_bweb_b
);

`ifdef FLOW_ASIC

    logic                       mem_rw_clock;
    logic                       mem_rw_enable_a;
    logic                       mem_rw_write_a;
    logic [ADDR_WIDTH - 1 : 0]  mem_rw_addr_a;
    logic [DATA_WIDTH - 1 : 0]  mem_rw_dataIn_a;
    logic [DATA_WIDTH - 1 : 0]  mem_rw_bweb_a;

    logic                       mem_rw_enable_b;
    logic                       mem_rw_write_b;
    logic [ADDR_WIDTH - 1 : 0]  mem_rw_addr_b;
    logic [DATA_WIDTH - 1 : 0]  mem_rw_dataIn_b;
    logic [DATA_WIDTH - 1 : 0]  mem_rw_bweb_b;

    assign mem_rw_clock    = clock;
    assign mem_rw_enable_a = rw_enable_a;
    assign mem_rw_write_a  = rw_write_a;
    assign mem_rw_addr_a   = rw_addr_a;
    assign mem_rw_dataIn_a = rw_dataIn_a;
    assign mem_rw_bweb_a   = rw_bweb_a;

    assign mem_rw_enable_b = rw_enable_b;
    assign mem_rw_write_b  = rw_write_b;
    assign mem_rw_addr_b   = rw_addr_b;
    assign mem_rw_dataIn_b = rw_dataIn_b;
    assign mem_rw_bweb_b   = rw_bweb_b;

generate
    if (DATA_WIDTH == 64 && DEPTH == 1024) begin
        TSDN12FFCLLSVTA1024X64M4W uSramMacro (
            .WTSEL(2'b01),
            .RTSEL(2'b01),
            .AA(mem_rw_addr_a),
            .DA(mem_rw_dataIn_a),
            .BWEBA(mem_rw_bweb_a),
            .WEBA(!mem_rw_write_a),
            .CEBA(!mem_rw_enable_a),
            .CLKA(mem_rw_clock),
            .AB(mem_rw_addr_b),
            .DB(mem_rw_dataIn_b),
            .BWEBB(mem_rw_bweb_b),
            .WEBB(!mem_rw_write_b),
            .CEBB(!mem_rw_enable_b),
            .CLKB(mem_rw_clock),
            .QA(rw_dataOut_a),
            .QB(rw_dataOut_b)
        );
    end else if (DATA_WIDTH == 64 && DEPTH == 256) begin
        TSDN12FFCLLSVTA256X64M4W uSramMacro (
            .WTSEL(2'b01),
            .RTSEL(2'b01),
            .AA(mem_rw_addr_a),
            .DA(mem_rw_dataIn_a),
            .BWEBA(mem_rw_bweb_a),
            .WEBA(!mem_rw_write_a),
            .CEBA(!mem_rw_enable_a),
            .CLKA(mem_rw_clock),
            .AB(mem_rw_addr_b),
            .DB(mem_rw_dataIn_b),
            .BWEBB(mem_rw_bweb_b),
            .WEBB(!mem_rw_write_b),
            .CEBB(!mem_rw_enable_b),
            .CLKB(mem_rw_clock),
            .QA(rw_dataOut_a),
            .QB(rw_dataOut_b)
        );
    end else if (DATA_WIDTH == 64 && DEPTH == 448) begin
        TSDN12FFCLLSVTA448X64M4W uSramMacro (
            .WTSEL(2'b01),
            .RTSEL(2'b01),
            .AA(mem_rw_addr_a),
            .DA(mem_rw_dataIn_a),
            .BWEBA(mem_rw_bweb_a),
            .WEBA(!mem_rw_write_a),
            .CEBA(!mem_rw_enable_a),
            .CLKA(mem_rw_clock),
            .AB(mem_rw_addr_b),
            .DB(mem_rw_dataIn_b),
            .BWEBB(mem_rw_bweb_b),
            .WEBB(!mem_rw_write_b),
            .CEBB(!mem_rw_enable_b),
            .CLKB(mem_rw_clock),
            .QA(rw_dataOut_a),
            .QB(rw_dataOut_b)
        );
    end else if (DATA_WIDTH == 16 && DEPTH == 128) begin
        TSDN12FFCLLSVTA128X16M4W uSramMacro (
            .WTSEL(2'b01),
            .RTSEL(2'b01),
            .AA(mem_rw_addr_a),
            .DA(mem_rw_dataIn_a),
            .BWEBA(mem_rw_bweb_a),
            .WEBA(!mem_rw_write_a),
            .CEBA(!mem_rw_enable_a),
            .CLKA(mem_rw_clock),
            .AB(mem_rw_addr_b),
            .DB(mem_rw_dataIn_b),
            .BWEBB(mem_rw_bweb_b),
            .WEBB(!mem_rw_write_b),
            .CEBB(!mem_rw_enable_b),
            .CLKB(mem_rw_clock),
            .QA(rw_dataOut_a),
            .QB(rw_dataOut_b)
        );
    end else if (DATA_WIDTH == 32 && DEPTH == 256) begin
        TSDN12FFCLLSVTA256X32M4W uSramMacro (
            .WTSEL(2'b01),
            .RTSEL(2'b01),
            .AA(mem_rw_addr_a),
            .DA(mem_rw_dataIn_a),
            .BWEBA(mem_rw_bweb_a),
            .WEBA(!mem_rw_write_a),
            .CEBA(!mem_rw_enable_a),
            .CLKA(mem_rw_clock),
            .AB(mem_rw_addr_b),
            .DB(mem_rw_dataIn_b),
            .BWEBB(mem_rw_bweb_b),
            .WEBB(!mem_rw_write_b),
            .CEBB(!mem_rw_enable_b),
            .CLKB(mem_rw_clock),
            .QA(rw_dataOut_a),
            .QB(rw_dataOut_b)
        );
    end else begin
        // $fatal("Unsupported DEPTH and DATA_WIDTH combination"); // cannot pass design compiler
    end
endgenerate

`else

    SramFpgaDp #(
        .DEPTH      (DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .MASK_UNIT  (1'd1)
    ) uSramMacro (
        .rw0_clock   (clock),
        .rw0_enable  (rw_enable_a),
        .rw0_write   (rw_write_a),
        .rw0_addr    (rw_addr_a),
        .rw0_mask    (~rw_bweb_a),
        .rw0_dataIn  (rw_dataIn_a),
        .rw0_dataOut (rw_dataOut_a),
        .rw1_clock   (clock),
        .rw1_enable  (rw_enable_b),
        .rw1_write   (rw_write_b),
        .rw1_addr    (rw_addr_b),
        .rw1_mask    (~rw_bweb_b),
        .rw1_dataIn  (rw_dataIn_b),
        .rw1_dataOut (rw_dataOut_b)
    );

`endif

endmodule : SramWrapperDp
