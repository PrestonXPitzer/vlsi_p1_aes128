`timescale 1ns / 1ps

module state_manager_tb;
    // Inputs
    reg clock;
    reg reset_n;
    reg start_write_n;
    reg start_read_n;
    reg key_expand_done;

    // Outputs
    wire [5:0] dbg_state;
    wire [3:0] dbg_round;
    wire [3:0] matrix_in_sel;
    wire matrix_write_enable;
    wire input_mat_row_col;
    wire [1:0] input_mat_idx;
    wire output_mat_row_col;
    wire [1:0] output_mat_idx;
    wire key_start;
    wire [1:0] count_4_out;

    // Instantiate the DUT
    state_manager dut (
        .clock(clock),
        .reset_n(reset_n),
        .start_write_n(start_write_n),
        .start_read_n(start_read_n),
        .key_expand_done(key_expand_done),
        .done(done),
        .dbg_state(dbg_state),
        .dbg_round(dbg_round),
        .matrix_in_sel(matrix_in_sel),
        .matrix_write_enable(matrix_write_enable),
        .input_mat_row_col(input_mat_row_col),
        .output_mat_row_col(output_mat_row_col),
        .output_mat_idx(output_mat_idx),
        .key_start(key_start),
        .count_4_out(count_4_out)
    );

    // Clock generation
    initial clock = 0;
    always #5 clock = ~clock;

    // VCD dump
    initial begin
        $dumpfile("state_manager_tb.vcd");
        $dumpvars(0, state_manager_tb);
    end

    // Stimulus
    initial begin
        // Initialize inputs
        reset_n = 0;
        start_write_n = 1;
        start_read_n = 1;
        key_expand_done = 0;
        #20;
        reset_n = 1;
        #10;

        // Start write (active low)
        start_write_n = 0;
        #10;
        start_write_n = 1;

        // Wait for PTEXT_WRITE and KEY_WRITE to finish
        repeat (10) @(posedge clock);

        // Simulate key expansion done
        key_expand_done = 1;
        @(posedge clock);
        key_expand_done = 0;

        // Wait for rounds to complete
        wait (done == 1);

        #10;
        // Start read (active low)
        start_read_n = 0;
        #10;
        start_read_n = 1;

        // Wait for CTEXT_READ and done
        repeat (10) @(posedge clock);

        $finish;
    end
endmodule