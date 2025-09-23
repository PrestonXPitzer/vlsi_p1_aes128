module data_mat (
    input        clk,
    input        reset_n,
    input  [31:0] col_in,
    input  [1:0] input_idx,     // index for either row or column
    input        input_row_col, // 0 = row, 1 = column
    input        write_enable,  // enable signal for writing
    input  [1:0] output_idx,    // index for either row or column
    input        output_row_col,// 0 = row, 1 = column
    output reg [31:0] out,      // holds output data until next read
    output [127:0] debug_state
);

    reg [7:0] state [0:15];

    // Debug view of the internal state (column-major order to match AES)
    assign debug_state = {
        state[ 0], state[ 4], state[ 8], state[12], // column 0
        state[ 1], state[ 5], state[ 9], state[13], // column 1
        state[ 2], state[ 6], state[10], state[14], // column 2
        state[ 3], state[ 7], state[11], state[15]  // column 3
    };

    integer i;

    // Synchronous write / reset
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 16; i = i + 1)
                state[i] <= 8'b0;
        end else if (write_enable) begin
            if (input_row_col) begin
                // Write a column
                state[0*4 + input_idx] <= col_in[31:24];
                state[1*4 + input_idx] <= col_in[23:16];
                state[2*4 + input_idx] <= col_in[15:8];
                state[3*4 + input_idx] <= col_in[7:0];
            end else begin
                // Write a row
                state[input_idx*4 + 0] <= col_in[31:24];
                state[input_idx*4 + 1] <= col_in[23:16];
                state[input_idx*4 + 2] <= col_in[15:8];
                state[input_idx*4 + 3] <= col_in[7:0];
            end
        end
    end

    // Combinational read
    always @(*) begin
        if (output_row_col) begin
            // Read a column
            out = { state[0*4 + output_idx],
                    state[1*4 + output_idx],
                    state[2*4 + output_idx],
                    state[3*4 + output_idx] };
        end else begin
            // Read a row
            out = { state[output_idx*4 + 0],
                    state[output_idx*4 + 1],
                    state[output_idx*4 + 2],
                    state[output_idx*4 + 3] };
        end
    end

endmodule