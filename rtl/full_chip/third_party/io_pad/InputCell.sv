// `default_nettype none

module InputCell #(
    parameter int DIRECTION_V = 1
)(
    inout  wire         pad,
    output logic        core_i,
    input  logic        input_enable
);

`ifdef FLOW_ASIC
    generate
        if (DIRECTION_V == 1) begin: g_IOCell_V_T12ULL
            PRWDWUWHWSWDGZ_V uIOCell (
                .C      (core_i),       // Output signal to core side
                .DS0    (1'b0),         // Driving selector
                .DS1    (1'b0),         // Driving selector
                .DS2    (1'b0),         // Driving selector
                .DS3    (1'b0),         // Driving selector
                .I      (1'b0),         // Input signal from core side
                .IE     (input_enable), // Input enable
                .OEN    (1'b1),         // Output enable
                .PAD    (pad),          // Signal pin on pad side
                .PE     (1'b0),         // Pull enable
                .PS     (1'b0),         // Pull selector
                .SPU    (1'b0),         // Retention signal bus
                .ST     (1'b0),         // schmitt trigger enable
                .SL     (1'b0),         // Slew-rate-control enable
                .RTE    (1'b0)          // Retention signal bus, 1'b1 will latch every port
                // .RTE    ()  // 0404 feedback
            );
        end
        else begin: g_IOCell_H_T12ULL
            PRWDWUWHWSWDGZ_H uIOCell (
                .C      (core_i),       // Output signal to core side
                .DS0    (1'b0),         // Driving selector
                .DS1    (1'b0),         // Driving selector
                .DS2    (1'b0),         // Driving selector
                .DS3    (1'b0),         // Driving selector
                .I      (1'b0),         // Input signal from core side
                .IE     (input_enable), // Input enable
                .OEN    (1'b1),         // Output enable
                .PAD    (pad),          // Signal pin on pad side
                .PE     (1'b0),         // Pull enable
                .PS     (1'b0),         // Pull selector
                .SPU    (1'b0),         // Retention signal bus
                .ST     (1'b0),         // schmitt trigger enable
                .SL     (1'b0),         // Slew-rate-control enable
                .RTE    (1'b0)          // Retention signal bus, 1'b1 will latch every port
                // .RTE    ()  // 0404 feedback
            );
        end
    endgenerate
`elsif FLOW_FPGA
    IBUF_IBUFDISABLE uIOCell (
        .O              (core_i),
        .I              (pad),
        .IBUFDISABLE    (!input_enable)
    );
`else

    assign core_i = input_enable ? pad : 1'b0;

`endif

endmodule: InputCell
