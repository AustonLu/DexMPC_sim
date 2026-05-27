// `default_nettype none

module OutputCell #(
    parameter int DIRECTION_V = 1,
    //0 for NONE, 1 for DOWN, 2 for UP
    parameter int PULL = 0 
)(
    inout  wire         pad,
    input  logic        core_o,
    input  logic        output_enable
);

`ifdef FLOW_ASIC
    logic pull_enable;
    logic pull_select;

    assign pull_enable = (PULL != 0) ? 1'b1 : 1'b0;;
    assign pull_select = (PULL == 2) ? 1'b1 : 1'b0;

    generate
        if (DIRECTION_V == 1) begin: g_IOCell_V_T12ULL
            PRWDWUWHWSWDGZ_V uIOCell (
                .C      (),           // Output signal to core side
                .DS0    (1'b0),             // Driving selector
                .DS1    (1'b0),             // Driving selector
                .DS2    (1'b0),             // Driving selector
                .DS3    (1'b0),             // Driving selector
                .I      (core_o),           // Input signal from core side
                .IE     (1'b0),             // Input enable
                .OEN    (!output_enable),   // Output enable
                .PAD    (pad),              // Signal pin on pad side
                .PE     (pull_enable),      // Pull enable
                .PS     (pull_select),      // Pull selector
                .SPU    (1'b0),             // Retention signal bus
                .ST     (1'b0),             // schmitt trigger enable
                .SL     (1'b0),             // Slew-rate-control enable
                .RTE    (1'b0)              // Retention signal bus, 1'b1 will latch every port
                // .RTE    ()  // 0404 feedback // useless for dc
            );
        end
        else begin: g_IOCell_H_T12ULL
            PRWDWUWHWSWDGZ_H uIOCell (
                .C      (),           // Output signal to core side
                .DS0    (1'b0),             // Driving selector
                .DS1    (1'b0),             // Driving selector
                .DS2    (1'b0),             // Driving selector
                .DS3    (1'b0),             // Driving selector
                .I      (core_o),           // Input signal from core side
                .IE     (1'b0),             // Input enable
                .OEN    (!output_enable),   // Output enable
                .PAD    (pad),              // Signal pin on pad side
                .PE     (pull_enable),      // Pull enable
                .PS     (pull_select),      // Pull selector
                .SPU    (1'b0),             // Retention signal bus
                .ST     (1'b0),             // schmitt trigger enable
                .SL     (1'b0),             // Slew-rate-control enable
                .RTE    (1'b0)              // Retention signal bus, 1'b1 will latch every port
                // .RTE    ()  // 0404 feedback
            );
        end
    endgenerate
`elsif FLOW_FPGA
    generate
        if (PULL == 2) begin: g_PullUp
            PULLUP uPullUp (
                .O      (pad)
            );
        end
        else if (PULL == 1) begin: g_PullDown
            PULLDOWN uPullDown (
                .O      (pad)
            );
        end
    endgenerate

    OBUFT uIOCell (
        .O      (pad),
        .I      (core_o),
        .T      (!output_enable)
    );
`else
    wire r;
    generate
        if (PULL == 2) begin: g_PullUp
            pullup pu(r);
        end
        else if (PULL == 1) begin: g_PullDown
            pulldown pd(r);
        end
        else begin: g_PullNone
            assign r = 1'bz;
        end
    endgenerate

    wire m, c;
    tran t1(r, m);
    tran t2(c, m);
    tran t3(pad, m);

    assign c = output_enable ? core_o : 1'bz;
`endif

endmodule: OutputCell
