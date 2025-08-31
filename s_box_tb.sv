//test the s_box module by providing a few random inputs
`timescale 1ns/1ps

module s_box_tb();

    reg [31:0] row_in;
    wire [31:0] row_out;

    //dut
    s_box dut (
        .row_in(row_in),
        .row_out(row_out)
    );

    //test some random vectors
    initial begin
        // test case 1
        row_in = 32'h00112233; // Input bytes: 00, 11, 22, 33
        #1;
        if (row_out !== 32'h638293c3) // Expected output bytes
            $display("Test case 1 failed: expected 638292c3, got %h", row_out);
        else
            $display("Test case 1 passed");
    end

    $finish;
endmodule

