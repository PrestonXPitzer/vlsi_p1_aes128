//implement the AddRoundKey AES transformation
//this module reads the contents of the state matrix (as 32-bit words) and the round key (also as 32-bit words)
//and performs a bitwise XOR between them, returning the modified word as output

module AddRoundKey (
    input wire [31:0] state_in, //input state word
    input wire [31:0] round_key, //input round key word
    output wire [31:0] state_out //output state word after AddRoundKey transformation
);

    //perform the AddRoundKey transformation using bitwise XOR
    assign state_out = state_in ^ round_key;
endmodule