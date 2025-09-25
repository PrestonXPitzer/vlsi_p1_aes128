module state_manager (
    input wire clock,
    input wire reset_n,
    input wire start_write_n, //active low start signal for writing the state matrix and key 
    input wire start_read_n, //active low start signal for reading the ciphertext output
    input wire key_expand_done, //signal from key expansion module indicating that round keys are ready
    output reg done,
    output reg [5:0] dbg_state, //debugging output to monitor current state
    output reg [3:0] dbg_round, //debugging output to monitor current round
    output reg [3:0] matrix_in_sel,
    output reg matrix_write_enable,
    output reg input_mat_row_col, //0 for row, 1 for column
    output reg [1:0] input_mat_idx, //2 bit index for row/column
    output reg output_mat_row_col, //0 for row, 1 for column
    output reg [1:0] output_mat_idx, //2 bit index for row/column
    output reg key_start, //signal to start key expansion
    output wire [1:0] count_4_out //2-bit output for monitoring count_4
);
//finite state machine for managing the state of the AES encryption/decryption process


//define states
localparam IDLE = 6'd0;
localparam PTEXT_WRITE = 6'd1;
localparam KEY_WRITE = 6'd2;
localparam COMPUTE_ROUNDKEYS = 6'd3;
localparam SUBBYTES = 6'd4;
localparam SHIFTROWS = 6'd5;
localparam MIXCOLUMNS = 6'd6;
localparam ADDROUNDKEY = 6'd7;
localparam ENCRYPTION_DONE = 6'd8;
localparam CTEXT_READ = 6'd9;
localparam INIT_ADDROUNDKEY = 6'd10;

localparam NUM_ROUNDS = 4'd10;

reg [5:0] current_state, next_state;
reg [3:0] round_counter, next_round_counter; //4-bit counter for 10 rounds
reg [1:0] count_4, next_count_4; //2-bit counter for 4 rows/columns

assign count_4_out = count_4;

// State register
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        current_state <= IDLE;
        round_counter <= 4'd0;
        count_4 <= 2'd0;
        done <= 1'b0;
    end else begin
        current_state <= next_state;
        round_counter <= next_round_counter;
        count_4 <= next_count_4;
    end
end

// Next state logic
always @(*) begin
    next_state = current_state;
    next_round_counter = round_counter;
    next_count_4 = count_4;
    case (current_state)
        IDLE: begin
            if (!start_write_n) begin
                next_state = PTEXT_WRITE;
                next_count_4 = 2'd0;
            end
        end
        PTEXT_WRITE: begin
            if (count_4 == 2'd3) begin
                next_state = KEY_WRITE;
                next_count_4 = 2'd0;
            end else begin
                next_count_4 = count_4 + 1;
            end
        end
        KEY_WRITE: begin
            if (count_4 == 2'd3) begin
                next_state = COMPUTE_ROUNDKEYS;
                next_count_4 = 2'd0;
            end else begin
                next_count_4 = count_4 + 1;
            end
        end
        INIT_ADDROUNDKEY: begin
            if (count_4 == 2'd3) begin
                next_state = SUBBYTES;
                next_count_4 = 2'd0;
                next_round_counter = 4'd1;
            end else begin
                next_count_4 = count_4 +1;
            end
        end
        COMPUTE_ROUNDKEYS: begin
            if (key_expand_done) begin
                next_state = INIT_ADDROUNDKEY;
                next_round_counter = 4'd0;
                next_count_4 = 2'd0;
            end
        end
        SUBBYTES: begin
            if (count_4 == 2'd3) begin
                next_state = SHIFTROWS;
                next_count_4 = 2'd0;
            end else begin
                next_count_4 = count_4 + 1;
            end
        end
        SHIFTROWS: begin
            if (count_4 == 2'd3) begin
                //on the last round, skip MixColumns
                if (round_counter == NUM_ROUNDS) begin
                    next_state = ADDROUNDKEY;
                end else
                next_state = MIXCOLUMNS;
                next_count_4 = 2'd0;
            end else begin
                next_count_4 = count_4 + 1;
            end
        end
        MIXCOLUMNS: begin
            if (count_4 == 2'd3) begin
                next_state = ADDROUNDKEY;
                next_count_4 = 2'd0;
            end else begin
                next_count_4 = count_4 + 1;
            end
        end
        ADDROUNDKEY: begin
            //after AddRoundKey, either go to the next round or finish
            if (count_4 == 2'd3) begin
                if (round_counter == NUM_ROUNDS) begin
                    next_state = ENCRYPTION_DONE;
                    next_count_4 = 2'd0;
                end else begin
                    next_state = SUBBYTES;
                    next_round_counter = round_counter + 1;
                    next_count_4 = 2'd0;
                end
            end else begin
                next_count_4 = count_4 + 1;
            end
        end
        ENCRYPTION_DONE: begin
            if (!start_read_n) begin
                next_state = CTEXT_READ;
                next_count_4 = 2'd0;
            end
        end
        CTEXT_READ: begin
            if (count_4 == 2'd3) begin
                next_state = IDLE;
                next_count_4 = 2'd0;
            end else begin
                next_count_4 = count_4 + 1;
            end
        end
        default: begin
            next_state = IDLE;
            next_count_4 = 2'd0;
            next_round_counter = 4'd0;
        end
    endcase
end

//combinational output logic based on current state
always @(*) begin
    // Default assignments
    input_mat_row_col = 1'b0;
    input_mat_idx = 2'd0;
    output_mat_row_col = 1'b0;
    output_mat_idx = 2'd0;
    done = 1'b0;
    case(current_state)
        IDLE: begin
            matrix_in_sel = 4'd0;
            matrix_write_enable = 1'b0;
            dbg_state = IDLE;
            dbg_round = round_counter;
            key_start = 1'b0;
        end
        PTEXT_WRITE: begin
            matrix_in_sel = 4'd0; //plaintext input
            matrix_write_enable = 1'b1;
            input_mat_row_col = 1'b1; //writing columns
            input_mat_idx = count_4;
            dbg_state = PTEXT_WRITE;
            dbg_round = round_counter;
            key_start = count_4 == 2'd3 ? 1'b1 : 1'b0; //prime the start signal so that
                                                       //we start loading once we enter
                                                       //the key write state
        end
        KEY_WRITE: begin
            matrix_in_sel = 4'bxxxx; //don't care
            matrix_write_enable = 1'b0;
            input_mat_row_col = 1'b0; //writing rows
            input_mat_idx = count_4;
            dbg_state = KEY_WRITE;
            dbg_round = round_counter;
            key_start = 1'b0;
        end
        INIT_ADDROUNDKEY: begin
            matrix_in_sel = 4'd4; //AddRoundKey operation input
            matrix_write_enable = 1'b1;
            input_mat_row_col = 1'b1; //writing cols
            input_mat_idx = count_4;
            output_mat_row_col = 1'b1; //reading cols
            output_mat_idx = count_4;
            dbg_state = INIT_ADDROUNDKEY;
            dbg_round = 4'd0;
            key_start = 1'b0;
        end
        COMPUTE_ROUNDKEYS: begin
            matrix_in_sel = 4'bxxxx; //don't care
            matrix_write_enable = 1'b0;
            dbg_state = COMPUTE_ROUNDKEYS;
            dbg_round = round_counter;
            key_start = 1'b0;
        end
        SUBBYTES: begin
            matrix_in_sel = 4'd1; //SubBytes operation input
            matrix_write_enable = 1'b1;
            input_mat_row_col = 1'b1; //processing columns
            input_mat_idx = count_4;
            output_mat_row_col = 1'b1; //reading columns
            output_mat_idx = count_4;
            dbg_state = SUBBYTES;
            dbg_round = round_counter;
            key_start = 1'b0;
        end
        SHIFTROWS: begin
            matrix_in_sel = 4'd2; //ShiftRows operation input
            matrix_write_enable = 1'b1;
            input_mat_row_col = 1'b0; //processing rows
            input_mat_idx = count_4;    
            output_mat_row_col = 1'b0; //reading rows
            output_mat_idx = count_4;
            dbg_state = SHIFTROWS;
            dbg_round = round_counter;
            key_start = 1'b0;
        end
        MIXCOLUMNS: begin
            matrix_in_sel = 4'd3; //MixColumns operation input
            matrix_write_enable = 1'b1;
            input_mat_row_col = 1'b1; //processing columns
            input_mat_idx = count_4;
            output_mat_row_col = 1'b1; //reading columns
            output_mat_idx = count_4;
            dbg_state = MIXCOLUMNS;
            dbg_round = round_counter;
            key_start = 1'b0;
        end
        ADDROUNDKEY: begin
            matrix_in_sel = 4'd4; //AddRoundKey operation input
            matrix_write_enable = 1'b1;
            input_mat_row_col = 1'b1; //processing columns
            input_mat_idx = count_4;
            output_mat_row_col = 1'b1; //reading columns
            output_mat_idx = count_4;
            dbg_state = ADDROUNDKEY;
            dbg_round = round_counter;
            key_start = 1'b0;
        end
        ENCRYPTION_DONE: begin
            matrix_in_sel = 4'bxxxx; //don't care
            matrix_write_enable = 1'b0;
            dbg_state = ENCRYPTION_DONE;
            dbg_round = round_counter;
            key_start = 1'b0;
            done = (count_4 == 2'd0) ? 1'b1 : 1'b0;
        end
        CTEXT_READ: begin
            matrix_in_sel = 4'bxxxx; //don't care
            matrix_write_enable = 1'b0;
            output_mat_row_col = 1'b1; //reading columns
            output_mat_idx = count_4;
            dbg_state = CTEXT_READ;
            dbg_round = round_counter;
            key_start = 1'b0;
        end
        default: begin
            matrix_in_sel = 4'd0;
            matrix_write_enable = 1'b0;
            dbg_state = 6'bxxxxxx;
            dbg_round = 4'bxxxx;
            key_start = 1'b0;
            done = 1'b0;
        end
    endcase
end


endmodule