//implement the data structure for the AES stast matrix, which is a 4x4 matrix of bytes

module data_mat (
    input wire [31:0] col_in,
    input wire [1:0] idx, //index for either row or column
    input wire row_col, //0 for row, 1 for column
    input wire read_write, //0 for read, 1 for write
    input wire write_enable, //enable signal for writing
    output reg [31:0] out //reg to hold output data until next read 
);

    //internal 4x4 matrix of bytes, represented as 4 32-bit words (each word is a column)
    reg [31:0] state [0:3];

    always @(*) begin
        if (write_enable && read_write) begin
            // Write operation
            if (row_col) begin
                // Writing to a column
                state[idx] = col_in;
            end else begin
                // Writing to a row
                state[0][(idx*8)+7 -: 8] = col_in[31:24];
                state[1][(idx*8)+7 -: 8] = col_in[23:16];
                state[2][(idx*8)+7 -: 8] = col_in[15:8];
                state[3][(idx*8)+7 -: 8] = col_in[7:0];
            end
            out = 32'hxxxxxxxx; // output is don't care during write
        end else if (!read_write) begin
            // Read operation
            if (row_col) begin
                // Reading from a column
                out = state[idx];
            end else begin
                // Reading from a row
                out = {state[0][(idx*8)+7 -: 8], state[1][(idx*8)+7 -: 8], state[2][(idx*8)+7 -: 8], state[3][(idx*8)+7 -: 8]};
            end
        end else begin
            out = 32'hxxxxxxxx; // output is don't care if not reading or writing
        end
    end

endmodule