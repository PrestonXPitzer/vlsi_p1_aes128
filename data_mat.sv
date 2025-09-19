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
    output reg [31:0] out, //reg to hold output data until next read 
    output [127:0] debug_state
);

    //internal 4x4 matrix of bytes, represented as a 2D array
    reg [7:0] state [0:3][0:3];
    assign debug_state = {
        state[0][0], state[1][0], state[2][0], state[3][0],
        state[0][1], state[1][1], state[2][1], state[3][1],
        state[0][2], state[1][2], state[2][2], state[3][2],
        state[0][3], state[1][3], state[2][3], state[3][3]
    };

    //synchronous write operation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            integer i, j;
            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1)
                    state[i][j] <= 8'b0;
        end else if (write_enable) begin
            if (input_row_col) begin
                // Writing to a column
                state[0][input_idx] <= col_in[31:24];
                state[1][input_idx] <= col_in[23:16];
                state[2][input_idx] <= col_in[15:8];
                state[3][input_idx] <= col_in[7:0];
            end else begin
                // Writing to a row
                state[input_idx][0] <= col_in[31:24];
                state[input_idx][1] <= col_in[23:16];
                state[input_idx][2] <= col_in[15:8];
                state[input_idx][3] <= col_in[7:0];
            end
        end
    end

    //combinational read operation
    always @(*) begin
        if (output_row_col) begin
            // Reading a column
            out = {state[0][output_idx], state[1][output_idx], state[2][output_idx], state[3][output_idx]};
        end else begin
            // Reading a row
            out = {state[output_idx][0], state[output_idx][1], state[output_idx][2], state[output_idx][3]};
        end
    end


endmodule