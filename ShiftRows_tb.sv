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
        test_shiftrows(2'b00, 32'h00112233, 32'h00112233); // No shift
        test_shiftrows(2'b01, 32'h00112233, 32'h11223300); // 1-byte left shift
        test_shiftrows(2'b10, 32'h00112233, 32'h22330011); // 2-byte left shift
        test_shiftrows(2'b11, 32'h00112233, 32'h33001122); // 3-byte left shift
        $finish;
    end

endmodule
