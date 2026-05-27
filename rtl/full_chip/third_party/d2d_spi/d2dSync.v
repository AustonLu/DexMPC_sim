module NegSync#(
    parameter DW = 12
)(
    input  wire          clock,
    input  wire          reset,
    input  wire [DW-1:0] x,
    output wire [DW-1:0] y
);

    reg [DW-1:0] r;
    always @(negedge clock or posedge reset) begin
        if (reset) r <= 0;
        else r <= x;
    end
    assign y = r;

endmodule // NegSync

module ResetSync_d2d (
    input  wire     clock,
    input  wire     reset_in,
    output wire     reset_out
);

    reg reset_d1, reset_d2;

    always @(posedge clock or posedge reset_in) begin
        if (reset_in) begin
            reset_d1 <= 1'b1;
            reset_d2 <= 1'b1;
        end
        else begin
            reset_d1 <= 1'b0;
            reset_d2 <= reset_d1;
        end
    end

    assign reset_out = reset_d2;

endmodule // ResetSync_d2d