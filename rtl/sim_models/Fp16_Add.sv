module Fp16_Add #(
    parameter int SIG_WIDTH       = 10,
    parameter int EXP_WIDTH       = 5,
    parameter int IEEE_COMPLIANCE = 0,
    parameter int FPW             = (1 + EXP_WIDTH + SIG_WIDTH)
)(
    input  logic [FPW-1:0] a,
    input  logic [FPW-1:0] b,
    input  logic [2:0]     rnd,
    output logic [FPW-1:0] z,
    output logic [7:0]     status
);

    DW_fp_add #(SIG_WIDTH, EXP_WIDTH, IEEE_COMPLIANCE) U_DW_FP_ADD (
        .a      (a),
        .b      (b),
        .rnd    (rnd),
        .z      (z),
        .status (status)
    );

endmodule
