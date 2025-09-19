module aes(
    input logic clk,
    input logic reset_n,
    input logic start_n,
    input logic start_read_n, //active low signal to start reading the ciphertext
    input logic [31:0] dword_in,
    output logic [31:0] dword_out,
    output logic done,
    output logic [127:0] dbg_state
);

//internal signals
logic [5:0] current_state;
logic [3:0] round_counter;

// Add correct width declarations for all signals used in submodules
logic [3:0] matrix_in_sel;
logic write_enable;
logic row_col_sel;
logic output_mat_row_col;
logic [1:0] row_col_index;
logic [1:0] output_mat_idx;
logic key_start;

logic [31:0] dmatrix_in;
logic [31:0] state_word;
logic [31:0] sbox_out;
logic [31:0] shifted_row;
logic [31:0] mixed_col;
logic [31:0] round_key;
logic [3:0] round_index;
logic [3:0] round_key_output_sel;
logic key_done;
logic [31:0] ark_out;
logic [1:0] count_4;
logic [127:0] dbg_flattened_matrix;

//instantiate all of the submodules 
state_manager sm(
    .clock(clk),
    .reset_n(reset_n),
    .start_write_n(start_n),
    .start_read_n(start_read_n),
    .key_expand_done(key_done),
    .done(done),
    .dbg_state(current_state),
    .dbg_round(round_index),
    .matrix_in_sel(matrix_in_sel),      // 4 bits
    .matrix_write_enable(write_enable),
    .input_mat_row_col(row_col_sel),
    .input_mat_idx(row_col_index),      // 2 bits
    .output_mat_row_col(output_mat_row_col),
    .output_mat_idx(output_mat_idx),    // 2 bits
    .key_start(key_start),
    .count_4_out(count_4)                      // 2 bits (not used elsewhere)
);
//multiplexer for the data matrix input
always @(*) begin
    case (matrix_in_sel)
        4'd0: dmatrix_in = dword_in; //plaintext input
        4'd1: dmatrix_in = sbox_out; //SubBytes output
        4'd2: dmatrix_in = shifted_row; //ShiftRows output
        4'd3: dmatrix_in = mixed_col; //MixColumns output
        4'd4: dmatrix_in = ark_out; //AddRoundKey output
        default: dmatrix_in = 32'hxxxxxxxx; //don't care
    endcase
end

data_mat datamatrix(
    .clk(clk),
    .reset_n(reset_n),
    .col_in(dmatrix_in),               // 32 bits
    .input_idx(row_col_index),         // 2 bits
    .input_row_col(row_col_sel),
    .write_enable(write_enable),
    .output_idx(output_mat_idx),        // 2 bits
    .output_row_col(output_mat_row_col),
    .out(state_word),      // 32 bits
    .debug_state(dbg_state)
);

s_box sb(
    .row_in(state_word),                // 32 bits
    .row_out(sbox_out)                  // 32 bits
);

ShiftRows sr(
    .idx_row(row_col_index),            // 2 bits
    .row_in(state_word),                // 32 bits
    .row_out(shifted_row)               // 32 bits
);

key_expand ke(
    .clk(clk),
    .reset(!reset_n),
    .start(key_start),
    .cipher_key(dword_in),
    .r_index(count_4),              // 2 bits
    .round_key_num(round_index), // which round key to output (0-10)
    .round_key(round_key),              // 32 bits
    .done(key_done)
);

MixColumns mc(
    .col_in(state_word),                // 32 bits
    .col_out(mixed_col)                 // 32 bits
);

AddRoundKey ark(
    .state_in(state_word),              // 32 bits
    .round_key(round_key),              // 32 bits
    .state_out(ark_out)                 // 32 bits
);

assign dword_out = state_word;




endmodule
