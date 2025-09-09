//implements the mix columns step of AES, which uses a matrix multiplication in GF(2^8)
//this multiplication can be abstracted to xor and shift, which allows it to be implemented combinationally

module MixColumns(
    input [31:0] col_in,
    output [31:0] col_out

);
    //implement the rinjadel MixColumns matrix transformation
    wire [7:0] s0, s1, s2, s3;
    assign s0 = col_in[31:24];
    assign s1 = col_in[23:16];
    assign s2 = col_in[15:8];
    assign s3 = col_in[7:0];

    //multiplication by 2 in GF(2^8) is a left shift and a conditional xor with 0x1b
    function [7:0] xtime;
        input [7:0] byte_in;
        begin
            xtime = {byte_in[6:0], 1'b0} ^ (byte_in[7] ? 8'h1b : 8'h00);
        end
    endfunction
    //multiplication by 3 in GF(2^8) is xtime(byte) xor byte itself
    function [7:0] mul_by_3;
        input [7:0] byte_in;
        begin
            mul_by_3 = xtime(byte_in) ^ byte_in;
        end
    endfunction

    //"matrix" multiplication is precomputed using the functions above
    // [2 3 1 1]
    // [1 2 3 1]
    // [1 1 2 3]
    // [3 1 1 2]
    assign col_out[31:24] = xtime(s0) ^ mul_by_3(s1) ^ s2 ^ s3;
    assign col_out[23:16] = s0 ^ xtime(s1) ^ mul_by_3(s2) ^ s3;
    assign col_out[15:8]  = s0 ^ s1 ^ xtime(s2) ^ mul_by_3(s3);
    assign col_out[7:0]   = mul_by_3(s0) ^ s1 ^ s2 ^ xtime(s3); 

endmodule
