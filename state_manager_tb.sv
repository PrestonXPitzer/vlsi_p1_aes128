`timescale 1ns / 1ps

module state_manager_tb();

    reg clock;
    reg reset_n;
    reg start_write_n; //active low start signal for writing the state matrix and key 
    reg start_read_n; //active low start signal for reading the ciphertext output
    reg key_expand_done; //signal from key expansion module indicating that round keys are ready
    wire done;
    wire [5:0] dbg_state; //debugging output to monitor current state
    wire [3:0] dbg_round; //debugging output to monitor current round
    wire [3:0] matrix_in_sel;
    wire matrix_write_enable;
    wire mat_row_col; //0 for row, 1 for column
    wire mat_read_write; //0 for read, 1 for write
    wire [1:0] mat_idx; //2 bit index for row/column

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


    //test sequence
    initial begin
        $dumpfile("state_manager_tb.vcd");
        $dumpvars(0, state_manager_tb);
        clock = 0;
        forever #5 clock = ~clock; // 10ns clock period
        // init inputs
        reset_n = 1;
        start_write_n = 1;
        start_read_n = 1;
        key_expand_done = 0;

        // apply reset and hold
        #10;
        reset_n = 0;
        #10;
        reset_n = 1;
        #10;

        //start writing plaintext
        start_write_n = 0;
        //the state manager will begin reading on the next cycle
        @(posedge clock);
        start_write_n = 1;
        $display("Started writing plaintext");
        @(dbg_state == 6'd2); //wait until we reach KEY_WRITE state
        //wait for key writing to finish
        $display("Finished writing plaintext, writing key");
        @(dbg_state == 6'd3); //wait until we reach COMPUTE_ROUNDKEYS state
        //simulate key expansion finishing
        key_expand_done = 1;
        #10;
        assert(dbg_state == 6'd4) else $display("Failed to enter SUBBYTES following key expansion, actual state is %d", dbg_state);
        key_expand_done = 0;
        $display("Key expansion done, entering SUBBYTES");
        //simulate going through all rounds
        repeat (10) begin
            //SUBBYTES
            @(dbg_state == 6'd5);
            assert(dbg_state == 6'd5) else $display("Failed to enter SHIFTROWS, actual state is %d", dbg_state);
            //SHIFTROWS
            @(dbg_state == 6'd6);
            assert(dbg_state == 6'd6) else $display("Failed to enter MIXCOLUMNS, actual state is %d", dbg_state);
            //MIXCOLUMNS (skipped in final round)
            if (dbg_round < 4'd9) begin
                @(dbg_state == 6'd7);
                assert(dbg_state == 6'd7) else $display("Failed to enter ADDROUNDKEY, actual state is %d", dbg_state);
                //ADDROUNDKEY
                @(dbg_state == 6'd4);
                assert(dbg_state == 6'd4) else $display("Failed to return to SUBBYTES, actual state is %d", dbg_state);
            end else begin
                //final round, go directly to ADDROUNDKEY
                @(dbg_state == 6'd7);
                assert(dbg_state == 6'd7) else $display("Failed to enter ADDROUNDKEY in final round, actual state is %d", dbg_state);
                //ADDROUNDKEY
                @(dbg_state == 6'd8);
                assert(dbg_state == 6'd8) else $display("Failed to enter ENCRYPTION_DONE, actual state is %d", dbg_state);
            end
        end
        $display("Completed all rounds, entering ENCRYPTION_DONE");
        //wait for done signal
        @(done == 1);
        $display("Encryption done signal asserted");
        //start reading ciphertext
        start_read_n = 0;
        #10;
        start_read_n = 1;
        $display("Started reading ciphertext");
        @(dbg_state == 6'd0); //wait until we return to IDLE state
        assert(dbg_state == 6'd0) else $display("Failed to return to IDLE state, actual state is %d", dbg_state);
        $display("Returned to IDLE state, test complete");
        #10;
        $finish;
    end

endmodule