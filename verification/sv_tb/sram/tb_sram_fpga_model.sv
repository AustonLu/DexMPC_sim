`timescale 1ns/1ps

module SramSpCompare #(
    parameter string NAME = "sp",
    parameter int DEPTH = 64,
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 64
)(
    output logic done
);

    logic clock;
    logic enable;
    logic write;
    logic [ADDR_WIDTH - 1 : 0] addr;
    logic [DATA_WIDTH - 1 : 0] data_in;
    logic [DATA_WIDTH - 1 : 0] bweb;
    logic [DATA_WIDTH - 1 : 0] wrapper_data_out;
    logic [DATA_WIDTH - 1 : 0] model_data_out;
    logic [DATA_WIDTH - 1 : 0] expected [0 : DEPTH - 1];

    SramWrapperSp #(
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_wrapper (
        .clock(clock),
        .rw_enable(enable),
        .rw_addr(addr),
        .rw_write(write),
        .rw_dataIn(data_in),
        .rw_dataOut(wrapper_data_out),
        .rw_bweb(bweb)
    );

    SramFpgaSp #(
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MASK_UNIT(1)
    ) u_model (
        .rw0_clock(clock),
        .rw0_enable(enable),
        .rw0_write(write),
        .rw0_addr(addr),
        .rw0_mask(~bweb),
        .rw0_dataIn(data_in),
        .rw0_dataOut(model_data_out)
    );

    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    function automatic logic [DATA_WIDTH - 1 : 0] pattern(
        input int unsigned addr_seed,
        input int unsigned salt
    );
        logic [DATA_WIDTH - 1 : 0] value;
        int unsigned mix;
        begin
            for (int bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx++) begin
                mix = (addr_seed * 32'h45D9F3B) ^ (salt * 32'h119DE1F3)
                      ^ (bit_idx * 32'h27D4EB2D);
                value[bit_idx] = mix[bit_idx % 17];
            end
            pattern = value;
        end
    endfunction

    function automatic logic [DATA_WIDTH - 1 : 0] mask_bweb(input int unsigned salt);
        logic [DATA_WIDTH - 1 : 0] value;
        begin
            for (int bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx++) begin
                value[bit_idx] = (((bit_idx + salt) % 3) == 0) ? 1'b0 : 1'b1;
            end
            mask_bweb = value;
        end
    endfunction

    function automatic logic [DATA_WIDTH - 1 : 0] apply_bweb(
        input logic [DATA_WIDTH - 1 : 0] old_data,
        input logic [DATA_WIDTH - 1 : 0] new_data,
        input logic [DATA_WIDTH - 1 : 0] bweb_mask
    );
        logic [DATA_WIDTH - 1 : 0] value;
        begin
            value = old_data;
            for (int bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx++) begin
                if (!bweb_mask[bit_idx]) begin
                    value[bit_idx] = new_data[bit_idx];
                end
            end
            apply_bweb = value;
        end
    endfunction

    task automatic drive_idle;
        begin
            enable = 1'b0;
            write = 1'b0;
            addr = '0;
            data_in = '0;
            bweb = '1;
        end
    endtask

    task automatic do_write(
        input int unsigned addr_i,
        input logic [DATA_WIDTH - 1 : 0] data_i,
        input logic [DATA_WIDTH - 1 : 0] bweb_i
    );
        begin
            @(negedge clock);
            enable = 1'b1;
            write = 1'b1;
            addr = addr_i[ADDR_WIDTH - 1 : 0];
            data_in = data_i;
            bweb = bweb_i;
            @(posedge clock);
            #1;
            expected[addr_i] = apply_bweb(expected[addr_i], data_i, bweb_i);
            drive_idle();
        end
    endtask

    task automatic do_read(input int unsigned addr_i);
        begin
            @(negedge clock);
            enable = 1'b1;
            write = 1'b0;
            addr = addr_i[ADDR_WIDTH - 1 : 0];
            data_in = '0;
            bweb = '1;
            @(posedge clock);
            #1;
            if (model_data_out !== expected[addr_i]) begin
                $fatal(1, "%s model mismatch addr=%0d got=%0h expected=%0h",
                       NAME, addr_i, model_data_out, expected[addr_i]);
            end
            if (wrapper_data_out !== expected[addr_i]) begin
                $fatal(1, "%s wrapper mismatch addr=%0d got=%0h expected=%0h",
                       NAME, addr_i, wrapper_data_out, expected[addr_i]);
            end
            drive_idle();
        end
    endtask

    task automatic run_addr(input int unsigned addr_i, input int unsigned salt);
        begin
            do_write(addr_i, pattern(addr_i, salt), '0);
            do_read(addr_i);
            do_write(addr_i, pattern(addr_i, salt + 17), mask_bweb(salt));
            do_read(addr_i);
        end
    endtask

    initial begin
        done = 1'b0;
        drive_idle();
        for (int addr_idx = 0; addr_idx < DEPTH; addr_idx++) begin
            expected[addr_idx] = '0;
        end

        repeat (2) @(posedge clock);
        run_addr(0, 1);
        if (DEPTH > 1) begin
            run_addr(1, 2);
        end
        if (DEPTH > 3) begin
            run_addr(DEPTH / 2, 3);
            run_addr(DEPTH - 2, 4);
        end
        run_addr(DEPTH - 1, 5);

        $display("%s single-port SRAM comparison passed", NAME);
        done = 1'b1;
    end

endmodule

module SramDpCompare #(
    parameter string NAME = "dp",
    parameter int DEPTH = 64,
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 64
)(
    output logic done
);

    logic clock;
    logic enable_a;
    logic write_a;
    logic [ADDR_WIDTH - 1 : 0] addr_a;
    logic [DATA_WIDTH - 1 : 0] data_in_a;
    logic [DATA_WIDTH - 1 : 0] bweb_a;
    logic [DATA_WIDTH - 1 : 0] wrapper_data_out_a;
    logic [DATA_WIDTH - 1 : 0] model_data_out_a;

    logic enable_b;
    logic write_b;
    logic [ADDR_WIDTH - 1 : 0] addr_b;
    logic [DATA_WIDTH - 1 : 0] data_in_b;
    logic [DATA_WIDTH - 1 : 0] bweb_b;
    logic [DATA_WIDTH - 1 : 0] wrapper_data_out_b;
    logic [DATA_WIDTH - 1 : 0] model_data_out_b;

    logic [DATA_WIDTH - 1 : 0] expected [0 : DEPTH - 1];

    SramWrapperDp #(
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_wrapper (
        .clock(clock),
        .rw_enable_a(enable_a),
        .rw_addr_a(addr_a),
        .rw_write_a(write_a),
        .rw_dataIn_a(data_in_a),
        .rw_dataOut_a(wrapper_data_out_a),
        .rw_enable_b(enable_b),
        .rw_addr_b(addr_b),
        .rw_write_b(write_b),
        .rw_dataIn_b(data_in_b),
        .rw_dataOut_b(wrapper_data_out_b),
        .rw_bweb_a(bweb_a),
        .rw_bweb_b(bweb_b)
    );

    SramFpgaDp #(
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MASK_UNIT(1)
    ) u_model (
        .rw0_clock(clock),
        .rw0_enable(enable_a),
        .rw0_write(write_a),
        .rw0_addr(addr_a),
        .rw0_mask(~bweb_a),
        .rw0_dataIn(data_in_a),
        .rw0_dataOut(model_data_out_a),
        .rw1_clock(clock),
        .rw1_enable(enable_b),
        .rw1_write(write_b),
        .rw1_addr(addr_b),
        .rw1_mask(~bweb_b),
        .rw1_dataIn(data_in_b),
        .rw1_dataOut(model_data_out_b)
    );

    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    function automatic logic [DATA_WIDTH - 1 : 0] pattern(
        input int unsigned addr_seed,
        input int unsigned salt
    );
        logic [DATA_WIDTH - 1 : 0] value;
        int unsigned mix;
        begin
            for (int bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx++) begin
                mix = (addr_seed * 32'h9E3779B9) ^ (salt * 32'h7F4A7C15)
                      ^ (bit_idx * 32'h85EBCA6B);
                value[bit_idx] = mix[bit_idx % 19];
            end
            pattern = value;
        end
    endfunction

    function automatic logic [DATA_WIDTH - 1 : 0] mask_bweb(input int unsigned salt);
        logic [DATA_WIDTH - 1 : 0] value;
        begin
            for (int bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx++) begin
                value[bit_idx] = (((bit_idx + salt) % 4) <= 1) ? 1'b0 : 1'b1;
            end
            mask_bweb = value;
        end
    endfunction

    function automatic logic [DATA_WIDTH - 1 : 0] apply_bweb(
        input logic [DATA_WIDTH - 1 : 0] old_data,
        input logic [DATA_WIDTH - 1 : 0] new_data,
        input logic [DATA_WIDTH - 1 : 0] bweb_mask
    );
        logic [DATA_WIDTH - 1 : 0] value;
        begin
            value = old_data;
            for (int bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx++) begin
                if (!bweb_mask[bit_idx]) begin
                    value[bit_idx] = new_data[bit_idx];
                end
            end
            apply_bweb = value;
        end
    endfunction

    task automatic drive_idle;
        begin
            enable_a = 1'b0;
            write_a = 1'b0;
            addr_a = '0;
            data_in_a = '0;
            bweb_a = '1;
            enable_b = 1'b0;
            write_b = 1'b0;
            addr_b = '0;
            data_in_b = '0;
            bweb_b = '1;
        end
    endtask

    task automatic cycle_access(
        input bit en_a,
        input bit wr_a,
        input int unsigned addr_ai,
        input logic [DATA_WIDTH - 1 : 0] data_ai,
        input logic [DATA_WIDTH - 1 : 0] bweb_ai,
        input bit en_b,
        input bit wr_b,
        input int unsigned addr_bi,
        input logic [DATA_WIDTH - 1 : 0] data_bi,
        input logic [DATA_WIDTH - 1 : 0] bweb_bi
    );
        begin
            @(negedge clock);
            enable_a = en_a;
            write_a = wr_a;
            addr_a = addr_ai[ADDR_WIDTH - 1 : 0];
            data_in_a = data_ai;
            bweb_a = bweb_ai;
            enable_b = en_b;
            write_b = wr_b;
            addr_b = addr_bi[ADDR_WIDTH - 1 : 0];
            data_in_b = data_bi;
            bweb_b = bweb_bi;

            @(posedge clock);
            #1;
            if (en_a && wr_a) begin
                expected[addr_ai] = apply_bweb(expected[addr_ai], data_ai, bweb_ai);
            end
            if (en_b && wr_b) begin
                expected[addr_bi] = apply_bweb(expected[addr_bi], data_bi, bweb_bi);
            end
            if (en_a && !wr_a) begin
                if (model_data_out_a !== expected[addr_ai]) begin
                    $fatal(1, "%s model port A mismatch addr=%0d got=%0h expected=%0h",
                           NAME, addr_ai, model_data_out_a, expected[addr_ai]);
                end
                if (wrapper_data_out_a !== expected[addr_ai]) begin
                    $fatal(1, "%s wrapper port A mismatch addr=%0d got=%0h expected=%0h",
                           NAME, addr_ai, wrapper_data_out_a, expected[addr_ai]);
                end
            end
            if (en_b && !wr_b) begin
                if (model_data_out_b !== expected[addr_bi]) begin
                    $fatal(1, "%s model port B mismatch addr=%0d got=%0h expected=%0h",
                           NAME, addr_bi, model_data_out_b, expected[addr_bi]);
                end
                if (wrapper_data_out_b !== expected[addr_bi]) begin
                    $fatal(1, "%s wrapper port B mismatch addr=%0d got=%0h expected=%0h",
                           NAME, addr_bi, wrapper_data_out_b, expected[addr_bi]);
                end
            end
            drive_idle();
        end
    endtask

    initial begin
        int unsigned addr0;
        int unsigned addr1;
        int unsigned addr2;
        int unsigned addr3;

        done = 1'b0;
        drive_idle();
        for (int addr_idx = 0; addr_idx < DEPTH; addr_idx++) begin
            expected[addr_idx] = '0;
        end

        addr0 = 0;
        addr1 = (DEPTH > 1) ? 1 : 0;
        addr2 = (DEPTH > 4) ? (DEPTH / 2) : 0;
        addr3 = DEPTH - 1;

        repeat (2) @(posedge clock);
        cycle_access(1'b1, 1'b1, addr0, pattern(addr0, 1), '0,
                     1'b1, 1'b1, addr1, pattern(addr1, 2), '0);
        cycle_access(1'b1, 1'b0, addr0, '0, '1,
                     1'b1, 1'b0, addr1, '0, '1);
        cycle_access(1'b1, 1'b1, addr2, pattern(addr2, 3), '0,
                     1'b1, 1'b1, addr3, pattern(addr3, 4), '0);
        cycle_access(1'b1, 1'b0, addr3, '0, '1,
                     1'b1, 1'b0, addr2, '0, '1);
        cycle_access(1'b1, 1'b1, addr0, pattern(addr0, 5), mask_bweb(5),
                     1'b1, 1'b1, addr3, pattern(addr3, 6), mask_bweb(6));
        cycle_access(1'b1, 1'b0, addr0, '0, '1,
                     1'b1, 1'b0, addr3, '0, '1);

        $display("%s dual-port SRAM comparison passed", NAME);
        done = 1'b1;
    end

endmodule

module tb_sram_fpga_model;
    logic done_sp_128x16;
    logic done_sp_256x32;
    logic done_sp_512x128;
    logic done_sp_2048x128;
    logic done_sp_224x128;
    logic done_dp_128x16;
    logic done_dp_256x32;
    logic done_dp_1024x64;

    SramSpCompare #(
        .NAME("sp_128x16"),
        .DEPTH(128),
        .ADDR_WIDTH(7),
        .DATA_WIDTH(16)
    ) sp_128x16 (.done(done_sp_128x16));

    SramSpCompare #(
        .NAME("sp_256x32"),
        .DEPTH(256),
        .ADDR_WIDTH(8),
        .DATA_WIDTH(32)
    ) sp_256x32 (.done(done_sp_256x32));

    SramSpCompare #(
        .NAME("sp_512x128"),
        .DEPTH(512),
        .ADDR_WIDTH(9),
        .DATA_WIDTH(128)
    ) sp_512x128 (.done(done_sp_512x128));

    SramSpCompare #(
        .NAME("sp_2048x128"),
        .DEPTH(2048),
        .ADDR_WIDTH(11),
        .DATA_WIDTH(128)
    ) sp_2048x128 (.done(done_sp_2048x128));

    SramSpCompare #(
        .NAME("sp_224x128"),
        .DEPTH(224),
        .ADDR_WIDTH(8),
        .DATA_WIDTH(128)
    ) sp_224x128 (.done(done_sp_224x128));

    SramDpCompare #(
        .NAME("dp_128x16"),
        .DEPTH(128),
        .ADDR_WIDTH(7),
        .DATA_WIDTH(16)
    ) dp_128x16 (.done(done_dp_128x16));

    SramDpCompare #(
        .NAME("dp_256x32"),
        .DEPTH(256),
        .ADDR_WIDTH(8),
        .DATA_WIDTH(32)
    ) dp_256x32 (.done(done_dp_256x32));

    SramDpCompare #(
        .NAME("dp_1024x64"),
        .DEPTH(1024),
        .ADDR_WIDTH(10),
        .DATA_WIDTH(64)
    ) dp_1024x64 (.done(done_dp_1024x64));

    initial begin
        wait (done_sp_128x16 && done_sp_256x32 && done_sp_512x128
              && done_sp_2048x128 && done_sp_224x128
              && done_dp_128x16 && done_dp_256x32 && done_dp_1024x64);
        $display("All SRAM model checks passed");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "SRAM model test timeout");
    end

endmodule
