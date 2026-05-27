// Functional IO pad replacements for cycle simulation.
//
// These modules intentionally model only digital connectivity. They replace the
// foundry IO-pad simulation cells for cycle-accurate functional simulation.

module InputCell #(
    parameter int DIRECTION_V = 1
)(
    inout  wire  pad,
    output logic core_i,
    input  logic input_enable
);

    assign core_i = input_enable ? pad : 1'b0;

endmodule : InputCell

module OutputCell #(
    parameter int DIRECTION_V = 1,
    parameter int PULL = 0
)(
    inout  wire  pad,
    input  logic core_o,
    input  logic output_enable
);

    assign pad =
        output_enable ? core_o :
        (PULL == 2) ? 1'b1 :
        (PULL == 1) ? 1'b0 :
        1'bz;

endmodule : OutputCell

module PDB3AC_H (
    inout wire AIO
);

    assign AIO = 1'bz;

endmodule : PDB3AC_H
