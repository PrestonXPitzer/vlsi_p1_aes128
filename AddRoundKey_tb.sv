module AddRoundKey_tb();

    // Testbench for AddRoundKey module
    logic [31:0] state_in; //input state word
    logic [31:0] round_key; //input round key word
    logic [31:0] state_out; //output state word after AddRoundKey transformation

    // Instantiate the AddRoundKey module
    AddRoundKey uut (
        .state_in(state_in),
        .round_key(round_key),
        .state_out(state_out)
    );

    task test_addrk;
        input [31:0] in_state;
        input [31:0] in_key;
        input [31:0] expected_out;
        begin
            // Apply inputs
            state_in = in_state;
            round_key = in_key;

            // Check output
            #1; // Small delay to allow combinational logic to settle
            if (state_out !== expected_out) begin
                $display("Test failed for state_in=%h, round_key=%h: expected %h, got %h", in_state, in_key, expected_out, state_out);
            end else begin
                $display("Test passed for state_in=%h, round_key=%h: got %h", in_state, in_key, state_out);
            end
        end
    endtask

    // run the test for some funny vectors
    initial begin
        // Test case 1
        test_addrk(32'aaaaaaaaaa, 32'h55555555, 32'hffffffff);
        // Test case 2
        test_addrk(32'h00000000, 32'hffffffff, 32'hffffffff);
        // Test case 3
        test_addrk(32'h12345678, 32'h87654321, 32'h95511559);
        // Test case 4
        test_addrk(32'hdeadbeef, 32'hfeedface, 32'h2316c001);
        $finish;
    end
endmodule