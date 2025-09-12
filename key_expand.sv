module key_expand(
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [31:0]  cipher_key,   // initial key pulled in 4cycles (32bit each)
    input  logic [1:0]   r_index,      // which 32 bit section of the key to output
    input  logic [3:0]   round_key_num,  // which round key to output (ask preston)
    output logic [31:0]  round_key,    // expanded round key
    output logic         done          // high when round_key output is valid
);

    logic [127:0] key_reg;      //stores the complete cipher key
    logic [1:0]   load_count;   // counts which 32-bit word we are on
    //logic         loading;      // high when we are loading the key
    logic [127:0] round_keys [0:10]; // 2D-aray : 11 round keys (0 = initial key, 10 = last)

    //process for loading the cipher key
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            key_reg    <= 128'd0; //initialize
            load_count <= 2'd0;            
            loading    <= 1'd0;
        end else begin
            if (start) begin //assuming start stays high for all 4 loads
                // start loading from the first word
                load_count <= 2'b0;
                loading    <= 1'b1;
            end 
            else if (loading) begin
                // shift in each 32-bit word
                case (load_count)
                    2'd0: key_reg[127:96] <= cipher_key;  // first word (MSB)
                    2'd1: key_reg[95:64]  <= cipher_key;
                    2'd2: key_reg[63:32]  <= cipher_key;
                    2'd3: key_reg[31:0]   <= cipher_key;  // last word (LSB)
                endcase

                // increment counter
                if (load_count == 2'd3) begin
                    load_count <= 2'b00;  // done loading all 4 words
                    loading    <= 1'b0;
                end else begin
                    load_count <= load_count + 1'b1;
                end
            end
        end
    end


    //key expansion code
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            done <= 0;
        end else if (!loading) begin
            // Load initial key
            round_keys[0] <= key_reg;

            // Expand keys
            for (int i = 1; i <= 10; i++) begin
                logic [127:0] prev_key = round_keys[i-1];

                // Extract last word of previous round key
                logic [31:0] temp = get_word(prev_key, 3);

                // Special schedule core every 4th word
                temp = sub_word(rot_word(temp)) ^ rcon(i);

                // Build new round key word by word
                logic [31:0] w0 = get_word(prev_key, 0) ^ temp;
                logic [31:0] w1 = get_word(prev_key, 1) ^ w0;
                logic [31:0] w2 = get_word(prev_key, 2) ^ w1;
                logic [31:0] w3 = get_word(prev_key, 3) ^ w2;

                round_keys[i] <= {w0, w1, w2, w3};
            end

            done <= 1;
        end
    end
        
    

    //process for returning the round keys
    always_comb begin
        round_key = round_keys[round_key_num][ (r_index*32) +: 32 ]; //bit slicing
    end


    //helper functions

    // 1byte circular left shift in a word
    function automatic logic [31:0] rot_word(input logic [31:0] w);
        return {w[23:0], w[31:24]};
    endfunction

    //grabs proper sbox word out of the sbox lookup table
    function automatic logic [31:0] sub_word(input logic [31:0] w);
        logic [31:0] out_w;
        s_box sbox_inst(.row_in(w), .row_out(out_w));
        return out_w;
    endfunction

    //returns the round constant to be xor'd with each word
    function automatic logic [31:0] rcon(input int i);
        logic [7:0] rc;
        case(i)
            1: rc = 8'h01;
            2: rc = 8'h02;
            3: rc = 8'h04;
            4: rc = 8'h08;
            5: rc = 8'h10;
            6: rc = 8'h20;
            7: rc = 8'h40;
            8: rc = 8'h80;
            9: rc = 8'h1B;
            10: rc = 8'h36;
            default: rc = 8'h00;
        endcase
        return {rc, 24'h000000};
    endfunction

    //allows me to grab a desired quarter from 128 bit string
    function automatic logic [31:0] get_word(input logic [127:0] block, input int idx);
        return block[127 - 32*idx -: 32];  // idx=0 → MS word, idx=3 → LS word
    endfunction

    //allows me to place a word into the 128 bit strings
    function automatic logic [127:0] set_word(
        input logic [127:0] block, input int idx, input logic [31:0] word
    );
        logic [127:0] temp = block;
        temp[127 - 32*idx -: 32] = word;
        return temp;
    endfunction


endmodule 