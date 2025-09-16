//implement the data structure for the AES stast matrix, which is a 4x4 matrix of bytes
module data_mat (
    input wire clk,
    input wire reset_n,
    input wire [31:0] col_in,
    input wire [1:0] input_idx, //index for either row or column
    input wire input_row_col, //0 for row, 1 for column
    input wire write_enable, //enable signal for writing
    input wire [1:0] output_idx, //index for either row or column
    input wire output_row_col, //0 for row, 1 for column
    output reg [31:0] out //reg to hold output data until next read 
);

    //internal 4x4 matrix of bytes, represented as 4 32-bit words (each word is a column)
    reg [31:0] state [0:3];
    assign debug_state = {state[0], state[1], state[2], state[3]};

    //synchronous write operation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state[0] <= 32'b0;
            state[1] <= 32'b0;
            state[2] <= 32'b0;
            state[3] <= 32'b0;
        end else if (write_enable) begin
            if (input_row_col) begin
                // Writing to a column (column major order)
                state[0][(input_idx*8)+7 -: 8] <= col_in[31:24];
                state[1][(input_idx*8)+7 -: 8] <= col_in[23:16];
                state[2][(input_idx*8)+7 -: 8] <= col_in[15:8];
                state[3][(input_idx*8)+7 -: 8] <= col_in[7:0];
            end else begin
                // Writing to a row (row major order)
                state[0][input_idx*8 +: 8] <= col_in[31:24];
                state[1][input_idx*8 +: 8] <= col_in[23:16];
                state[2][input_idx*8 +: 8] <= col_in[15:8];
                state[3][input_idx*8 +: 8] <= col_in[7:0];
            end
        end
    end

    //combinationl read operation
    always @(*) begin
        if (output_row_col) begin
            // Reading a column (column major order)
            out = {state[0][output_idx*8 +: 8], state[1][output_idx*8 +: 8], state[2][output_idx*8 +: 8], state[3][output_idx*8 +: 8]};
        end else begin
            // Reading a row (row major order)
            out = {state[0][(output_idx*8)+7 -: 8], state[1][(output_idx*8)+7 -: 8], state[2][(output_idx*8)+7 -: 8], state[3][(output_idx*8)+7 -: 8]};
        end
    end


endmodule