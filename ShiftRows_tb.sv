`timescale 1ns/1ps
module ShiftRows_tb();

    reg [1:0] idx_row;
    reg [31:0] row_in;
    reg start;
    wire done;
    wire [31:0] row_out;

    // Instantiate the DUT
    ShiftRows dut (
        .idx_row(idx_row),
        .row_in(row_in),
        .start(start),
        .done(done),
        .row_out(row_out)
    );

    // Test sequence (define using a task)
    task test_shiftrows;
        input [1:0] idx;
        input [31:0] in_data;
        input [31:0] expected_out;
        begin
            // Apply inputs
            idx_row = idx;
            row_in = in_data;
            start = 1;

            // Check output
            #1; // Small delay to allow combinational logic to settle
            if (row_out !== expected_out || done !== 1) begin
                $display("Test failed for idx_row=%0d, row_in=%h: expected %h, got %h", idx, in_data, expected_out, row_out);
            end else begin
                $display("Test passed for idx_row=%0d, row_in=%h: got %h", idx, in_data, row_out);
            end

            start = 0; // Reset start signal
        end
    endtask

    // Run the test for random vectors, 1 for each row value
    initial begin
        // Test for row 0 (no shift)
        test_shiftrows(2'b00, 32'h01234567, 32'h01234567);
        // Test for row 1 (1-byte left shift)
        test_shiftrows(2'b01, 32'h89abcdef, 32'h9abcdef8);
        // Test for row 2 (2-byte left shift)
        test_shiftrows(2'b10, 32'hfedcba98, 32'hdcbafedc);
        // Test for row 3 (3-byte left shift)
        test_shiftrows(2'b11, 32'h76543210, 32'h43210765);

        $finish;
    end

endmodule
