module Fp16_Mac #(
    parameter int SIG_WIDTH       = 10,
    parameter int EXP_WIDTH       = 5,
    parameter int IEEE_COMPLIANCE = 0,
    parameter int EN_UBR_FLAG     = 0,
    parameter int FPW            = (1 + EXP_WIDTH + SIG_WIDTH)  // default 16
)(
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 clk_en,

    // ---- operands ----
    // mul core: mul_res = opA * opB
    // add core: add_res = mux(mul_res, opB) + mux(opC, acc)
    input  logic [FPW-1:0]       opA_in,
    input  logic [FPW-1:0]       opB_in,
    input  logic [FPW-1:0]       opC_in,

    // ---- function mode control ----
    // 3'd0: MAC        -> acc <= (opA*opB) + acc
    // 3'd1: MUL_ADD_C  -> acc <= (opA*opB) + opC
    // 3'd2: MUL        -> acc <= (opA*opB)
    // 3'd3: ADD        -> acc <= opB + opC
    // 3'd4: ACC        -> acc <= opB + acc
    // 3'd5: IDLE       -> hold internal pipeline and accumulator
    input  logic [2:0]           func_mode,

    // ---- accumulator ----
    input  logic                 acc_clr,         // clear acc to 0

    // ---- outputs ----
    output logic [FPW-1:0]       acc_out
);

    // ------------------------------------------------------------------------
    // Function decode (internal control generation)
    // ------------------------------------------------------------------------
    localparam logic [2:0] FUNC_MAC       = 3'd0;
    localparam logic [2:0] FUNC_MUL_ADD_C = 3'd1;
    localparam logic [2:0] FUNC_MUL       = 3'd2;
    localparam logic [2:0] FUNC_ADD       = 3'd3;
    localparam logic [2:0] FUNC_ACC       = 3'd4;
    localparam logic [2:0] FUNC_IDLE      = 3'd5;

    logic add_in0_sel_mul;
    logic add_in1_sel_acc;
    logic acc_write_add;
    logic acc_write_mul;
    logic is_idle;
    logic calc_en;

    always_comb begin
        add_in0_sel_mul = 1'b0;
        add_in1_sel_acc = 1'b0;
        acc_write_add   = 1'b0;
        acc_write_mul   = 1'b0;

        unique case (func_mode)
            FUNC_MAC: begin
                add_in0_sel_mul = 1'b1;
                add_in1_sel_acc = 1'b1;
                acc_write_add   = 1'b1;
            end
            FUNC_MUL_ADD_C: begin
                add_in0_sel_mul = 1'b1;
                acc_write_add   = 1'b1;
            end
            FUNC_MUL: begin
                acc_write_mul   = 1'b1;
            end
            FUNC_ADD: begin
                acc_write_add   = 1'b1;
            end
            FUNC_ACC: begin
                add_in1_sel_acc = 1'b1;
                acc_write_add   = 1'b1;
            end
            FUNC_IDLE: begin
            end
            default: begin
            end
        endcase
    end

    assign is_idle = (func_mode == FUNC_IDLE);
    assign calc_en = clk_en & ~is_idle;

    // ------------------------------------------------------------------------
    // Stage 0: register inputs
    // ------------------------------------------------------------------------
    logic [FPW-1:0] opA_r0, opB_r0, opC_r0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opA_r0 <= '0;
            opB_r0 <= '0;
            opC_r0 <= '0;
        end else if (calc_en) begin
            opA_r0 <= opA_in;
            opB_r0 <= opB_in;
            opC_r0 <= opC_in;
        end else begin
            opA_r0 <= opA_r0;
            opB_r0 <= opB_r0;
            opC_r0 <= opC_r0;
        end
    end

    // ------------------------------------------------------------------------
    // Accumulator register (feedback to adder input1 when selected)
    // ------------------------------------------------------------------------
    logic [FPW-1:0] acc_reg;
    assign acc_out = acc_reg;

    // ------------------------------------------------------------------------
    // Power-saving intent signals (operand isolation)
    // ------------------------------------------------------------------------
    logic mul_need;
    logic add_need;

    // mul is needed for add-path mul ops and pure MUL writeback.
    assign mul_need = (add_in0_sel_mul | acc_write_mul) & calc_en;

    // add is only needed when accumulator writeback comes from add path.
    assign add_need = acc_write_add & calc_en;

    // ------------------------------------------------------------------------
    // Stage 1: multiply (with operand isolation) + pipeline operands
    // ------------------------------------------------------------------------
    logic [FPW-1:0] mul_a_eff, mul_b_eff;
    logic [FPW-1:0] mul_w;
    logic [FPW-1:0] mul_r1;
    logic [FPW-1:0] opB_r1, opC_r1;

    // operand isolation for multiplier
    assign mul_a_eff = mul_need ? opA_r0 : '0;
    assign mul_b_eff = mul_need ? opB_r0 : '0;

    DW_fp_mult #(SIG_WIDTH, EXP_WIDTH, IEEE_COMPLIANCE)
    U_MUL (
        .a      (mul_a_eff),
        .b      (mul_b_eff),
        .rnd    (3'b000),
        .z      (mul_w),
        .status (/*unused*/)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_r1 <= '0;
            opB_r1 <= '0;
            opC_r1 <= '0;
        end else if (calc_en) begin
            // Deterministic latency; operand isolation reduces switching when mul_need=0
            mul_r1 <= mul_w;
            opB_r1 <= opB_r0;
            opC_r1 <= opC_r0;
        end else begin
            mul_r1 <= mul_r1;
            opB_r1 <= opB_r1;
            opC_r1 <= opC_r1;
        end
    end

    // ------------------------------------------------------------------------
    // Stage 2: adder input mux + add (with operand isolation)
    // ------------------------------------------------------------------------
    logic [FPW-1:0] add_in0_w, add_in1_w;
    logic [FPW-1:0] add_in0_eff, add_in1_eff;
    logic [FPW-1:0] add_w;

    // muxes defined by spec
    assign add_in0_w = add_in0_sel_mul ? mul_r1 : opB_r1;
    assign add_in1_w = add_in1_sel_acc ? acc_reg : opC_r1;

    // operand isolation for adder
    assign add_in0_eff = add_need ? add_in0_w : '0;
    assign add_in1_eff = add_need ? add_in1_w : '0;

    DW_fp_add #(SIG_WIDTH, EXP_WIDTH, IEEE_COMPLIANCE)
    U_ADD (
        .a      (add_in0_eff),
        .b      (add_in1_eff),
        .rnd    (3'b000),
        .z      (add_w),
        .status (/*unused*/)
    );

    // ------------------------------------------------------------------------
    // Accumulator writeback:
    // - ADD-path modes (MAC/MUL_ADD_C/ADD/ACC): acc <= add_w
    // - MUL mode: acc <= mul_r1
    // Input-to-acc writeback latency is 2 cycles.
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_reg <= '0;
        end else if (clk_en) begin
            if (acc_clr) begin
                acc_reg <= '0;
            end else if (calc_en && acc_write_mul) begin
                acc_reg <= mul_r1;
            end else if (calc_en && acc_write_add) begin
                acc_reg <= add_w;
            end else begin
                acc_reg <= acc_reg;
            end
        end else begin
            acc_reg <= acc_reg;
        end
    end

endmodule
