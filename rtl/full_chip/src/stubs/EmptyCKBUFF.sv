module CKBUFF (
    input   ckbuff_high_en,
    input   current_in,
    input   half_vdd,
    input   vin,
    input   vip,
    output  ck_out,
    output  ckb_out
);
    assign ck_out = 1'b0;
    // assign ck_out = current_in;
    assign ckb_out = 1'b0;
endmodule