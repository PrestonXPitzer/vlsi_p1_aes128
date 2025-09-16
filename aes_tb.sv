`timescale 1ns / 1ps

module aes_tb();
    //instantiate uut
    reg clk;
    reg reset_n;
    reg start_n;
    reg start_read_n;
    reg [31:0] dword_in;
    wire [31:0] dword_out;
    wire done;

    aes uut(
        .clk(clk),
        .reset_n(reset_n),
        .start_n(start_n),
        .start_read_n(start_read_n),
        .dword_in(dword_in),
        .dword_out(dword_out),
        .done(done)
    );

    // VCD dump
    initial begin
        $dumpfile("aes_tb.vcd");
        $dumpvars(0, aes_tb);
    end

    //clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; //10ns clock period
    end

    //test sequence using a known plaintext/ciphertext pair from NIST
    //KEY =  00000000000000000000000000000000
    //PTEXT = ffffffffffffffffffffffffffffffff
    //CTEXT = 3f5b8cc9ea855a0afa7347d23e8d664e
    initial begin
        //reset
        reset_n = 0;
        start_n = 1;
        start_read_n = 1;
        dword_in = 32'd0;
        $display("[%0t] Reset asserted", $time);
        #20;
        reset_n = 1;
        $display("[%0t] Reset deasserted", $time);
        //start encryption by triggering the start signal and then supplying the plaintext
        start_n = 0; //active low start
        dword_in = 32'hffffffff; //first dword of plaintext
        $display("[%0t] Start asserted, dword_in = %h", $time, dword_in);
        #10;
        start_n = 1; //deassert start
        $display("[%0t] Start deasserted", $time);
        #10;
        dword_in = 32'hffffffff; //second dword of plaintext
        $display("[%0t] dword_in = %h", $time, dword_in);
        #10;
        dword_in = 32'hffffffff; //third dword of plaintext
        $display("[%0t] dword_in = %h", $time, dword_in);
        #10;
        dword_in = 32'hffffffff; //fourth dword of plaintext
        $display("[%0t] dword_in = %h", $time, dword_in);
        //wait for encryption to complete
        repeat (300) @(posedge clk); //wait sufficient time for encryption to complete
        $display("[%0t] Encryption done signal: %b", $time, done);
        //trigger the reading sequence
        start_read_n = 0;
        $display("[%0t] Start read asserted", $time);
        #10;
        start_read_n = 1;
        $display("[%0t] Start read deasserted", $time);
        //read out the ciphertext
        #10;
        $display("[%0t] Ciphertext Dword 0: %h", $time, dword_out); //should be 3f5b8cc9
        #10;
        $display("[%0t] Ciphertext Dword 1: %h", $time, dword_out); //should be ea855a0a
        #10;
        $display("[%0t] Ciphertext Dword 2: %h", $time, dword_out); //should be fa7347d2
        #10;
        $display("[%0t] Ciphertext Dword 3: %h", $time, dword_out); //should be 3e8d664e
        #10;
        $finish;
    end

endmodule