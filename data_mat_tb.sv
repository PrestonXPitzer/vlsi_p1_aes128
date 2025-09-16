//test the data matrix module

`timescale 1ns/1ps

module data_mat_tb();
    reg clk;
    reg [1:0] input_idx;
    reg input_row_col;
    reg [1:0] output_idx;
    reg output_row_col;
    reg write_enable;
    reg [31:0] col_in;
    wire [31:0] out;
    wire [127:0] debug_state;
    reg reset_n;

    // Instantiate the DUT
    data_mat dut (
        .clk(clk),
        .reset_n(reset_n),
        .col_in(col_in),
        .input_idx(input_idx),
        .input_row_col(input_row_col),
        .write_enable(write_enable),
        .output_idx(output_idx),
        .output_row_col(output_row_col),
        .out(out),
        .debug_state(debug_state)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    //vcddump
    initial begin
        $dumpfile("data_mat_tb.vcd");
        $dumpvars(0, data_mat_tb);
    end

    initial begin
        reset_n = 0;
        col_in = 0;
        input_idx = 0;
        input_row_col = 0;
        write_enable = 0;
        output_idx = 0;
        output_row_col = 0;
        #20;
        reset_n = 1;
        #10;
        //write to row 0 
        col_in = 32'h00112233;
        input_idx = 0;
        input_row_col = 0; //row
        write_enable = 1;
        #10;
        write_enable = 0;
        #10;
        //read row 0
        output_idx = 0;
        output_row_col = 0; //row
        #10;
        if (out !== 32'h00112233) $display("Test 1 Failed: Expected 0x00112233, got %h", out);
        else $display("Test 1 Passed");
        #10;
        //write to column 1
        col_in = 32'h44556677;
        input_idx = 1;
        input_row_col = 1; //column
        write_enable = 1;
        #10;
        write_enable = 0;
        #10;
        //read column 1
        output_idx = 1;
        output_row_col = 1; //column
        #10;
        if (out !== 32'h44556677) $display("Test 2 Failed: Expected 0x44556677, got %h", out);
        else $display("Test 2 Passed");
        #10;
        //read row 0 again to ensure it is unchanged
        output_idx = 0;
        output_row_col = 0; //row
        #10;
        if (out !== 32'h00112233) $display("Test 3 Failed: Expected 0x00112233, got %h", out);
        else $display("Test 3 Passed");
        #10;
        $finish;
    end
endmodule