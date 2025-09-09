//test the data matrix module

`timescale 1ns/1ps

module data_mat_tb();
    reg [31:0] col_in;
    reg [1:0] idx; //index for either row or column
    reg row_col; //0 for row, 1 for column
    reg read_write; //0 for read, 1 for write
    reg write_enable; //enable signal for writing
    wire [31:0] out; //reg to hold output data until next read
    // Instantiate the DUT
    data_mat dut (
        .col_in(col_in),
        .idx(idx),
        .row_col(row_col),
        .read_write(read_write),
        .write_enable(write_enable),
        .out(out)
    );

    task test_data_mat;
        input [31:0] in_data;
        input [1:0] in_idx;
        input in_row_col;
        input in_read_write;
        input in_write_enable;
        input [31:0] expected_out;
        begin
            // Apply inputs
            col_in = in_data;
            idx = in_idx;
            row_col = in_row_col;
            read_write = in_read_write;
            write_enable = in_write_enable;

            // Check output
            #1; // Small delay to allow combinational logic to settle
            if (out !== expected_out) begin
                $display("Test failed for col_in=%h, idx=%b, row_col=%b, read_write=%b, write_enable=%b: expected %h, got %h", in_data, in_idx, in_row_col, in_read_write, in_write_enable, expected_out, out);
            end else begin
                $display("Test passed for col_in=%h, idx=%b, row_col=%b, read_write=%b, write_enable=%b: got %h", in_data, in_idx, in_row_col, in_read_write, in_write_enable, out);
            end
        end
    endtask

    // test case 1, write into column 0, and check that we got it back
    initial begin
        // Test case 1: Write to column 0
        test_data_mat(32'h11223344, 2'b00, 1'b1, 1'b1, 1'b1, 32'hxxxxxxxx); // writing, output is don't care
        // Read back column 0
        test_data_mat(32'h00000000, 2'b00, 1'b1, 1'b0, 1'b0, 32'h11223344); // reading, expect to get what we wrote

        // Test case 2: Write to row 2
        test_data_mat(32'h55667788, 2'b10, 1'b0, 1'b1, 1'b1, 32'hxxxxxxxx); // writing, output is don't care
        // Read back row 2
        test_data_mat(32'h00000000, 2'b10, 1'b0, 1'b0, 1'b0, 32'h55667788); // reading, expect to get what we wrote

        // Test case 3: Write to column 3
        test_data_mat(32'h99aabbcc, 2'b11, 1'b1, 1'b1, 1'b1, 32'hxxxxxxxx); // writing, output is don't care
        // Read back column 3
        test_data_mat(32'h00000000, 2'b11, 1'b1, 1'b0, 1'b0, 32'h99aabbcc); // reading, expect to get what we wrote

        $finish;
    end
endmodule