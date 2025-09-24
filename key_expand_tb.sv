`timescale 1ns/1ps

module tb_key_expand;

    // Testbench signals
    logic clk;
    logic reset;
    logic start;
    logic [31:0] cipher_key;
    logic [1:0]  r_index;
    logic [3:0]  round_key_num;
    logic [31:0] round_key;
    logic done;

    // Instantiate DUT
    key_expand dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .cipher_key(cipher_key),
        .r_index(r_index),
        .round_key_num(round_key_num),
        .round_key(round_key),
        .done(done)
    );

    // Clock generation (50 MHz = 20 ns period)
    always #10 clk = ~clk;

    // Test sequence
    initial begin
        // Init
        clk = 0;
        reset = 1;
        start = 0;
        cipher_key = 32'd0;
        r_index = 0;
        round_key_num = 0;

        // Hold reset for a few cycles
        #50;
        reset = 0;

        start = 1;  // begin loading sequence
        @(posedge clk);
        start = 0; // finish start pulse
        cipher_key = 32'h54686174;  // "That"
        @(posedge clk);
        cipher_key = 32'h73206D79;  // "s my"
        @(posedge clk);
        cipher_key = 32'h204B756E;  // " Ku n"
        @(posedge clk);
        cipher_key = 32'h67204675;  // "g Fu"
        @(posedge clk);


        // Wait for expansion to complete
        wait(done);

        // Print out all round keys

        $display("All Round Keys:");
        for (int r = 0; r <= 10; r++) begin
            $write("Round %0d : ", r);
            for (int w = 0; w < 4; w++) begin
                round_key_num = r;
                r_index = w;
                #1; // small delay for combinational settle
                $write("%h ", round_key);
            end
            $display("");
        end

        // Hold reset for a few cycles
        #50;

        $display("All Round Keys after some wait:");
        for (int r = 0; r <= 10; r++) begin
            $write("Round %0d : ", r);
            for (int w = 0; w < 4; w++) begin
                round_key_num = r;
                r_index = w;
                #1; // small delay for combinational settle
                $write("%h ", round_key);
            end
            $display("");
        end

        #50;
	@(posedge clk);
        start = 1;  // begin loading sequence
        @(posedge clk);
        start = 0; // finish start pulse
        cipher_key = 32'h54680000;  // 
        @(posedge clk);
        cipher_key = 32'h71010D79;  // 
        @(posedge clk);
        cipher_key = 32'h2000056E;  // 
        @(posedge clk);
        cipher_key = 32'h6794E465;  // 
        @(posedge clk);

        // Wait for expansion to complete
        wait(done);

        // Print out all round keys

        $display("New Round Keys:");
        for (int r = 0; r <= 10; r++) begin
            $write("Round %0d : ", r);
            for (int w = 0; w < 4; w++) begin
                round_key_num = r;
                r_index = w;
                #1; // small delay for combinational settle
                $write("%h ", round_key);
            end
            $display("");
        end

        #50;
	@(posedge clk);
        start = 1;  // begin loading sequence
        @(posedge clk);
        start = 0; // finish start pulse
        cipher_key = 32'h54686174;  // "That"
        @(posedge clk);
        cipher_key = 32'h73206D79;  // "s my"
        @(posedge clk);
        cipher_key = 32'h204B756E;  // " Ku n"
        @(posedge clk);
        cipher_key = 32'h67204675;  // "g Fu"
        @(posedge clk);

        // Wait for expansion to complete
        wait(done);

        // Print out all round keys

        $display("Back to original:");
        for (int r = 0; r <= 10; r++) begin
            $write("Round %0d : ", r);
            for (int w = 0; w < 4; w++) begin
                round_key_num = r;
                r_index = w;
                #1; // small delay for combinational settle
                $write("%h ", round_key);
            end
            $display("");
        end
	
	#50 reset = 1;
	// Hold reset for a few cycles
        #50;
        reset = 0;

        start = 1;  // begin loading sequence
        @(posedge clk);
        start = 0; // finish start pulse
        cipher_key = 32'h54686174;  // "That"
        @(posedge clk);
        cipher_key = 32'h73206D79;  // "s my"
        @(posedge clk);
        cipher_key = 32'h204B756E;  // " Ku n"
        @(posedge clk);
        cipher_key = 32'h67204675;  // "g Fu"
        @(posedge clk);

        // Wait for expansion to complete
        wait(done);

        // Print out all round keys

        $display("check after reset:");
        for (int r = 0; r <= 10; r++) begin
            $write("Round %0d : ", r);
            for (int w = 0; w < 4; w++) begin
                round_key_num = r;
                r_index = w;
                #1; // small delay for combinational settle
                $write("%h ", round_key);
            end
            $display("");
        end

         #50;
        @(posedge clk);
        start = 1;  // begin loading sequence for new key
        @(posedge clk);
        start = 0; // finish start pulse
        cipher_key = 32'h2b7e1516;
        @(posedge clk);
        cipher_key = 32'h28aed2a6;  // careful: little vs big endian, see below
        @(posedge clk);
        cipher_key = 32'habf71588;
        @(posedge clk);
        cipher_key = 32'h09cf4f3c;
        @(posedge clk);

        // Wait for expansion to complete
        wait(done);

        // Print out all round keys
        $display("FIPS-197 Test Vector Key (2b7e...):");
        for (int r = 0; r <= 10; r++) begin
            $write("Round %0d : ", r);
            for (int w = 0; w < 4; w++) begin
                round_key_num = r;
                r_index = w;
                #1; // small delay for combinational settle
                $write("%h ", round_key);
            end
            $display("");
        end

	$stop;
        //$finish;
    end

endmodule
