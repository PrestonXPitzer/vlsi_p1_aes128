`timescale 1ns / 1ps

module state_manager_tb;
    // Inputs
    reg clock;
    reg reset_n;
    reg start_write_n;
    reg start_read_n;
    reg key_expand_done;

    // Outputs
    wire done;
    wire [5:0] dbg_state;
    wire [3:0] dbg_round;
    wire [3:0] matrix_in_sel;
    wire matrix_write_enable;
    wire mat_row_col;
    wire mat_read_write;
    wire [1:0] mat_idx;

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
        .mat_row_col(mat_row_col),
        .mat_read_write(mat_read_write),
        .mat_idx(mat_idx)
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
        repeat (160) @(posedge clock);

        // Start read (active low)
        start_read_n = 0;
        #10;
        start_read_n = 1;

        // Wait for CTEXT_READ and done
        repeat (10) @(posedge clock);

        $finish;
    end
endmodule