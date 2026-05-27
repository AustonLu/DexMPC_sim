// +FHDR========================================================================
//  License:
//      Copyright (c) 2022 Authors. All rights reserved.
// =============================================================================
//  File Name:      host_spi.v
//                  Shiwei Liu (liusw18@fudan.edu.com)
//  Organization:
//  Description:
//      Host for SPI Master.
// -FHDR========================================================================

`timescale 1ns/1ps

module SpiHost #(
    // DW = cmd width + addr width + data width = 8 + 32 + 32 = 72
    // 理论上spi write不需要8 cycle的dummy，但是spi读需要，所以写变成了72+8=80
    parameter   DW = 80,
    parameter   RX = 32
)(
    // Global Signals
    input                   clk,
    input                   rst,

    // Host Interface
    input                   spi_start,
    output  reg             spi_complete,
    input       [DW-1:0]    spi_tx_data,
    output      [RX-1:0]    spi_rx_data,
    output  reg             spi_rx_valid,

    // SPI Interface
    output                  spi_sck,
    output  reg             spi_csn,
    output  reg             spi_mosi,
    input                   spi_miso
);

    parameter       SPI_BEAT = DW << 1;

    parameter       SPI_IDLE = 2'b01,
                    SPI_WORK = 2'b10;
    reg     [1:0]   spi_state;

    reg     [DW-1:0]    spi_tx_reg;
    reg     [RX-1:0]    spi_rx_reg;
    reg     [7:0]       spi_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            spi_state    <= 'd0;
            spi_complete <= 1'b0;
            spi_tx_reg   <= 'd0;
            spi_rx_reg   <= 'd0;
            spi_rx_valid <= 1'b0;
            spi_cnt      <= 'd0;
            spi_csn      <= 1'b1;
            spi_mosi     <= 1'b0;
        end
        else begin
            case (spi_state)
                SPI_IDLE: begin
                    spi_complete <= 1'b0;
                    spi_rx_valid <= 1'b0;
                    if (spi_start) begin
                        spi_state  <= SPI_WORK;
                        spi_tx_reg <= spi_tx_data << 1'b1;
                        spi_rx_reg <= 'd0;
                        spi_cnt    <= 'd0;
                        spi_csn    <= 1'b0;
                        spi_mosi   <= spi_tx_data[DW-1];
                    end
                end
                SPI_WORK: begin
                    if (spi_cnt == SPI_BEAT - 1'b1) begin
                        spi_state    <= SPI_IDLE;
                        spi_complete <= 1'b1;
                        spi_rx_valid <= 1'b1;
                        spi_cnt      <= 'd0;
                        spi_csn      <= 1'b1;
                        spi_mosi     <= 1'b0;
                    end
                    else begin
                        spi_cnt <= spi_cnt + 1'b1;
                        if (spi_cnt[0] == 1'b1) begin   // TX
                            spi_mosi   <= spi_tx_reg[DW-1];
                            spi_tx_reg <= spi_tx_reg << 1'b1;
                        end
                        else begin  // RX
                            spi_rx_reg <= {spi_rx_reg[RX-2:0], spi_miso};
                        end
                    end
                end
                default: begin
                    spi_state <= SPI_IDLE;
                end
            endcase
        end
    end

    assign  spi_rx_data = spi_rx_reg;
    assign  spi_sck     = spi_cnt[0];

endmodule