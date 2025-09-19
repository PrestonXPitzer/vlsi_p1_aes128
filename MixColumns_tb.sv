//using the standard test vectors, verify that the MixColumns module works as expected
`timescale 1ns/1ps

module MixColumns_tb();

    reg [31:0] col_in;
    wire [31:0] col_out;

    // Instantiate the DUT
    MixColumns dut (
        .col_in(col_in),
        .col_out(col_out)
    );

    // Test sequence (define using a task)
    task test_mixcolumns;
        input [31:0] in_data;
        input [31:0] expected_out;
        begin
            // Apply inputs
            col_in = in_data;

            // Check output
            #1; // Small delay to allow combinational logic to settle
            if (col_out !== expected_out) begin
                $display("Test failed for col_in=%h: expected %h, got %h", in_data, expected_out, col_out);
            end else begin
                $display("Test passed for col_in=%h: got %h", in_data, col_out);
            end
        end
    endtask

    // Run the test for standard AES MixColumns vectors
    initial begin
        // Test case 1
        test_mixcolumns(32'h6347a2f0, 32'h5de070bb);
        // Test case 2
        test_mixcolumns(32'hf20a225c, 32'h9fdc589d);
        // Test case 3
        test_mixcolumns(32'h01010101, 32'h01010101); // the identity case is a common corner case
        // test case 4
        test_mixcolumns(32'hd4d4d4d5, 32'hd5d5d7d6);
        $finish;
    end
endmodule