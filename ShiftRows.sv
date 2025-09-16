//Implements the ShiftRows step of AES, which does a byte-wise cyclic left shift 
//based on the row number (combinational logic)
module ShiftRows(
    input [1:0] idx_row,
    input [31:0] row_in,
    output [31:0] row_out
);

reg [31:0] row_out_reg;
assign row_out = row_out_reg;
always @* begin
    case (idx_row)
        2'b00: row_out_reg = row_in; // No shift
        2'b01: begin // 1-byte left shift
            row_out_reg[31:24] = row_in[23:16];
            row_out_reg[23:16] = row_in[15:8];
            row_out_reg[15:8]  = row_in[7:0];
            row_out_reg[7:0]   = row_in[31:24];
        end
        2'b10: begin // 2-byte left shift
            row_out_reg[31:24] = row_in[15:8];
            row_out_reg[23:16] = row_in[7:0];
            row_out_reg[15:8]  = row_in[31:24];
            row_out_reg[7:0]   = row_in[23:16];
        end
        2'b11: begin // 3-byte left shift
            row_out_reg[31:24] = row_in[7:0];
            row_out_reg[23:16] = row_in[31:24];
            row_out_reg[15:8]  = row_in[23:16];
            row_out_reg[7:0]   = row_in[15:8];
        end
        default: row_out_reg = row_in;
    endcase
end

endmodule