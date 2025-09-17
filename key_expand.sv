module key_expand(
    input  logic        clk,
    input  logic        reset,
    input  logic        start,          //one cycle start pulse sent begin key expansion
    input  logic [31:0]  cipher_key,    // initial key pulled in 4cycles (32bit each)
    input  logic [1:0]   r_index,       // which 32 bit section of the key to output
    input  logic [3:0]   round_key_num, // which round key to output (ask preston)
    output logic [31:0]  round_key,     // expanded round key
    output logic         done           // high when round_key output is valid
);

    logic [127:0] key_reg;      //stores the complete cipher key
    logic [1:0]   load_count;   // counts which 32-bit word we are on
    logic         loading;      // high when we are loading the key
    logic [127:0] round_keys [0:10]; // 2D-aray : 11 round keys (0 = initial key, 10 = last)
    logic         expanded;     // high when expansion is done

    // Key loading state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            key_reg    <= 128'd0;
            load_count <= 2'd0;
            loading    <= 1'b0;
            expanded   <= 1'b0;
        end else begin
            if (start) begin
                load_count <= 2'd0;
                loading    <= 1'b1;
                expanded   <= 1'b0;
            end else if (loading) begin
                case (load_count)
                    2'd0: key_reg[127:96] <= cipher_key;
                    2'd1: key_reg[95:64]  <= cipher_key;
                    2'd2: key_reg[63:32]  <= cipher_key;
                    2'd3: key_reg[31:0]   <= cipher_key;
                endcase
                if (load_count == 2'd3) begin
                    loading  <= 1'b0;
                    expanded <= 1'b0;
                end
                load_count <= load_count + 1'b1;
            end
        end
    end


    //varibles for 11 stage round key expansion:
    typedef enum logic [1:0] {IDLE, LOAD, EXPAND, DONE} state_t;
    state_t state;

    logic [3:0] round_ctr;
    logic [127:0] current_key;

    //key expansion code
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            round_ctr <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: if (!loading) begin
                    current_key <= key_reg;  // initial key
                    round_keys[0]   <= key_reg;
                    round_ctr   <= 0;
                    state       <= EXPAND;
                end
                EXPAND: begin
                    //done after 10 cycles
                    if (round_ctr <= 9) begin
                        // generate next_key from current_key
                        current_key <= next_key(current_key, round_ctr+1);
                        round_keys[round_ctr+1] <= next_key(current_key, round_ctr+1);
                        round_ctr <= round_ctr + 1;
                    end 
                    else state <= DONE;
                end
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end

        //in case of another start pulse
        if(loading) begin
            done <= 1'd0;
            round_ctr <= 0;
            state <= IDLE;
        end
    end
        
    

    //process for returning the round keys
    always_comb begin
        round_key = round_keys[round_key_num][127 - (r_index*32) -: 32];
    end

    function automatic logic [31:0] get_word(
        input logic [127:0] key,
        input int index
    );
        begin
            get_word = key[127 - (index*32) -: 32];
        end
    endfunction

    //helper functions
    // Function to generate the next round key
    function automatic logic [127:0] next_key(
            input logic [127:0] prev_key,
            input int round_num
        );
            logic [31:0] temp, w0, w1, w2, w3;
        begin
            // pull last word of previous round key
            temp = get_word(prev_key, 3);

            // Special schedule core every 4th word
            temp = sub_word(rot_word(temp)) ^ rcon(round_num);

            // Build new round key word by word
            w0 = get_word(prev_key, 0) ^ temp;
            w1 = get_word(prev_key, 1) ^ w0;
            w2 = get_word(prev_key, 2) ^ w1;
            w3 = get_word(prev_key, 3) ^ w2;

            return {w0, w1, w2, w3};
        end
    endfunction

    // RotWord: rotate left by 8 bits
    function [31:0] rot_word;
        input [31:0] w;
        begin
            rot_word = {w[23:0], w[31:24]};
        end
    endfunction

    // SubWord: apply S-box to each byte
    function [31:0] sub_word;
        input [31:0] w;
        begin
            sub_word[31:24] = sbox_lookup(w[31:24]);
            sub_word[23:16] = sbox_lookup(w[23:16]);
            sub_word[15:8]  = sbox_lookup(w[15:8]);
            sub_word[7:0]   = sbox_lookup(w[7:0]);
        end
    endfunction

    // Rcon: round constant
    function [31:0] rcon;
        input integer i;
        reg [7:0] rc;
        begin
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
            rcon = {rc, 24'h000000};
        end
    endfunction

    // S-box lookup table (AES standard)
    function [7:0] sbox_lookup;
        input [7:0] byte_in;
        begin
            case (byte_in)
                8'h00: sbox_lookup = 8'h63;
                8'h01: sbox_lookup = 8'h7c;
                8'h02: sbox_lookup = 8'h77;
                8'h03: sbox_lookup = 8'h7b;
                8'h04: sbox_lookup = 8'hf2;
                8'h05: sbox_lookup = 8'h6b;
                8'h06: sbox_lookup = 8'h6f;
                8'h07: sbox_lookup = 8'hc5;
                8'h08: sbox_lookup = 8'h30;
                8'h09: sbox_lookup = 8'h01;
                8'h0a: sbox_lookup = 8'h67;
                8'h0b: sbox_lookup = 8'h2b;
                8'h0c: sbox_lookup = 8'hfe;
                8'h0d: sbox_lookup = 8'hd7;
                8'h0e: sbox_lookup = 8'hab;
                8'h0f: sbox_lookup = 8'h76;
                8'h10: sbox_lookup = 8'hca;
                8'h11: sbox_lookup = 8'h82;
                8'h12: sbox_lookup = 8'hc9;
                8'h13: sbox_lookup = 8'h7d;
                8'h14: sbox_lookup = 8'hfa;
                8'h15: sbox_lookup = 8'h59;
                8'h16: sbox_lookup = 8'h47;
                8'h17: sbox_lookup = 8'hf0;
                8'h18: sbox_lookup = 8'had;
                8'h19: sbox_lookup = 8'hd4;
                8'h1a: sbox_lookup = 8'ha2;
                8'h1b: sbox_lookup = 8'haf;
                8'h1c: sbox_lookup = 8'h9c;
                8'h1d: sbox_lookup = 8'ha4;
                8'h1e: sbox_lookup = 8'h72;
                8'h1f: sbox_lookup = 8'hc0;
                8'h20: sbox_lookup = 8'hb7;
                8'h21: sbox_lookup = 8'hfd;
                8'h22: sbox_lookup = 8'h93;
                8'h23: sbox_lookup = 8'h26;
                8'h24: sbox_lookup = 8'h36;
                8'h25: sbox_lookup = 8'h3f;
                8'h26: sbox_lookup = 8'hf7;
                8'h27: sbox_lookup = 8'he0;
                8'h28: sbox_lookup = 8'heb;
                8'h29: sbox_lookup = 8'h27;
                8'h2a: sbox_lookup = 8'hb2;
                8'h2b: sbox_lookup = 8'h75;
                8'h2c: sbox_lookup = 8'hc4;
                8'h2d: sbox_lookup = 8'h62;
                8'h2e: sbox_lookup = 8'h91;
                8'h2f: sbox_lookup = 8'h95;
                8'h30: sbox_lookup = 8'h79;
                8'h31: sbox_lookup = 8'heb;
                8'h32: sbox_lookup = 8'hf9;
                8'h33: sbox_lookup = 8'hf0;
                8'h34: sbox_lookup = 8'h73;
                8'h35: sbox_lookup = 8'hcf;
                8'h36: sbox_lookup = 8'h44;
                8'h37: sbox_lookup = 8'h33;
                8'h38: sbox_lookup = 8'h85;
                8'h39: sbox_lookup = 8'h53;
                8'h3a: sbox_lookup = 8'hf1;
                8'h3b: sbox_lookup = 8'h71;
                8'h3c: sbox_lookup = 8'h60;
                8'h3d: sbox_lookup = 8'h35;
                8'h3e: sbox_lookup = 8'h07;
                8'h3f: sbox_lookup = 8'h90;
                8'h40: sbox_lookup = 8'h2b;
                8'h41: sbox_lookup = 8'h12;
                8'h42: sbox_lookup = 8'h20;
                8'h43: sbox_lookup = 8'h8c;
                8'h44: sbox_lookup = 8'hbc;
                8'h45: sbox_lookup = 8'hda;
                8'h46: sbox_lookup = 8'h74;
                8'h47: sbox_lookup = 8'h1c;
                8'h48: sbox_lookup = 8'h5c;
                8'h49: sbox_lookup = 8'h7f;
                8'h4a: sbox_lookup = 8'he4;
                8'h4b: sbox_lookup = 8'h1f;
                8'h4c: sbox_lookup = 8'hdd;
                8'h4d: sbox_lookup = 8'h60;
                8'h4e: sbox_lookup = 8'h9e;
                8'h4f: sbox_lookup = 8'h7d;
                8'h50: sbox_lookup = 8'hfa;
                8'h51: sbox_lookup = 8'hf0;
                8'h52: sbox_lookup = 8'h60;
                8'h53: sbox_lookup = 8'h51;
                8'h54: sbox_lookup = 8'h7f;
                8'h55: sbox_lookup = 8'hb3;
                8'h56: sbox_lookup = 8'h7a;
                8'h57: sbox_lookup = 8'hc9;
                8'h58: sbox_lookup = 8'h0c;
                8'h59: sbox_lookup = 8'h13;
                8'h5a: sbox_lookup = 8'he0;
                8'h5b: sbox_lookup = 8'h61;
                8'h5c: sbox_lookup = 8'h0d;
                8'h5d: sbox_lookup = 8'h0e;
                8'h5e: sbox_lookup = 8'hf2;
                8'h5f: sbox_lookup = 8'h56;
                8'h60: sbox_lookup = 8'h3e;
                8'h61: sbox_lookup = 8'hb2;
                8'h62: sbox_lookup = 8'h75;
                8'h63: sbox_lookup = 8'hc4;
                8'h64: sbox_lookup = 8'h67;
                8'h65: sbox_lookup = 8'h2b;
                8'h66: sbox_lookup = 8'h6c;
                8'h67: sbox_lookup = 8'h94;
                8'h68: sbox_lookup = 8'h0a;
                8'h69: sbox_lookup = 8'h55;
                8'h6a: sbox_lookup = 8'h28;
                8'h6b: sbox_lookup = 8'hdf;
                8'h6c: sbox_lookup = 8'hf4;
                8'h6d: sbox_lookup = 8'h0b;
                8'h6e: sbox_lookup = 8'h8a;
                8'h6f: sbox_lookup = 8'h70;
                8'h70: sbox_lookup = 8'h3e;
                8'h71: sbox_lookup = 8'hb2;
                8'h72: sbox_lookup = 8'h75;
                8'h73: sbox_lookup = 8'hc4;
                8'h74: sbox_lookup = 8'h67;
                8'h75: sbox_lookup = 8'h2b;
                8'h76: sbox_lookup = 8'h6c;
                8'h77: sbox_lookup = 8'h94;
                8'h78: sbox_lookup = 8'h0a;
                8'h79: sbox_lookup = 8'h55;
                8'h7a: sbox_lookup = 8'h28;
                8'h7b: sbox_lookup = 8'hdf;
                8'h7c: sbox_lookup = 8'hf4;
                8'h7d: sbox_lookup = 8'h0b;
                8'h7e: sbox_lookup = 8'h8a;
                8'h7f: sbox_lookup = 8'h70;
                8'h80: sbox_lookup = 8'h3e;
                8'h81: sbox_lookup = 8'hb2;
                8'h82: sbox_lookup = 8'h75;
                8'h83: sbox_lookup = 8'hc4;
                8'h84: sbox_lookup = 8'h67;
                8'h85: sbox_lookup = 8'h2b;
                8'h86: sbox_lookup = 8'h6c;
                8'h87: sbox_lookup = 8'h94;
                8'h88: sbox_lookup = 8'h0a;
                8'h89: sbox_lookup = 8'h55;
                8'h8a: sbox_lookup = 8'h28;
                8'h8b: sbox_lookup = 8'hdf;
                8'h8c: sbox_lookup = 8'hf4;
                8'h8d: sbox_lookup = 8'h0b;
                8'h8e: sbox_lookup = 8'h8a;
                8'h8f: sbox_lookup = 8'h70;
                8'h90: sbox_lookup = 8'h3e;
                8'h91: sbox_lookup = 8'hb2;
                8'h92: sbox_lookup = 8'h75;
                8'h93: sbox_lookup = 8'hc4;
                8'h94: sbox_lookup = 8'h67;
                8'h95: sbox_lookup = 8'h2b;
                8'h96: sbox_lookup = 8'h6c;
                8'h97: sbox_lookup = 8'h94;
                8'h98: sbox_lookup = 8'h0a;
                8'h99: sbox_lookup = 8'h55;
                8'h9a: sbox_lookup = 8'h28;
                8'h9b: sbox_lookup = 8'hdf;
                8'h9c: sbox_lookup = 8'hf4;
                8'h9d: sbox_lookup = 8'h0b;
                8'h9e: sbox_lookup = 8'h8a;
                8'h9f: sbox_lookup = 8'h70;
                8'ha0: sbox_lookup = 8'h3e;
                8'ha1: sbox_lookup = 8'hb2;
                8'ha2: sbox_lookup = 8'h75;
                8'ha3: sbox_lookup = 8'hc4;
                8'ha4: sbox_lookup = 8'h67;
                8'ha5: sbox_lookup = 8'h2b;
                8'ha6: sbox_lookup = 8'h6c;
                8'ha7: sbox_lookup = 8'h94;
                8'ha8: sbox_lookup = 8'h0a;
                8'ha9: sbox_lookup = 8'h55;
                8'haa: sbox_lookup = 8'h28;
                8'hab: sbox_lookup = 8'hdf;
                8'hac: sbox_lookup = 8'hf4;
                8'had: sbox_lookup = 8'h0b;
                8'hae: sbox_lookup = 8'h8a;
                8'haf: sbox_lookup = 8'h70;
                8'hb0: sbox_lookup = 8'h3e;
                8'hb1: sbox_lookup = 8'hb2;
                8'hb2: sbox_lookup = 8'h75;
                8'hb3: sbox_lookup = 8'hc4;
                8'hb4: sbox_lookup = 8'h67;
                8'hb5: sbox_lookup = 8'h2b;
                8'hb6: sbox_lookup = 8'h6c;
                8'hb7: sbox_lookup = 8'h94;
                8'hb8: sbox_lookup = 8'h0a;
                8'hb9: sbox_lookup = 8'h55;
                8'hba: sbox_lookup = 8'h28;
                8'hbb: sbox_lookup = 8'hdf;
                8'hbc: sbox_lookup = 8'hf4;
                8'hbd: sbox_lookup = 8'h0b;
                8'hbe: sbox_lookup = 8'h8a;
                8'hbf: sbox_lookup = 8'h70;
                8'hc0: sbox_lookup = 8'h3e;
                8'hc1: sbox_lookup = 8'hb2;
                8'hc2: sbox_lookup = 8'h75;
                8'hc3: sbox_lookup = 8'hc4;
                8'hc4: sbox_lookup = 8'h67;
                8'hc5: sbox_lookup = 8'h2b;
                8'hc6: sbox_lookup = 8'h6c;
                8'hc7: sbox_lookup = 8'h94;
                8'hc8: sbox_lookup = 8'h0a;
                8'hc9: sbox_lookup = 8'h55;
                8'hca: sbox_lookup = 8'h28;
                8'hcb: sbox_lookup = 8'hdf;
                8'hcc: sbox_lookup = 8'hf4;
                8'hcd: sbox_lookup = 8'h0b;
                8'hce: sbox_lookup = 8'h8a;
                8'hcf: sbox_lookup = 8'h70;
                8'hd0: sbox_lookup = 8'h3e;
                8'hd1: sbox_lookup = 8'hb2;
                8'hd2: sbox_lookup = 8'h75;
                8'hd3: sbox_lookup = 8'hc4;
                8'hd4: sbox_lookup = 8'h67;
                8'hd5: sbox_lookup = 8'h2b;
                8'hd6: sbox_lookup = 8'h6c;
                8'hd7: sbox_lookup = 8'h94;
                8'hd8: sbox_lookup = 8'h0a;
                8'hd9: sbox_lookup = 8'h55;
                8'hda: sbox_lookup = 8'h28;
                8'hdb: sbox_lookup = 8'hdf;
                8'hdc: sbox_lookup = 8'hf4;
                8'hdd: sbox_lookup = 8'h0b;
                8'hde: sbox_lookup = 8'h8a;
                8'hdf: sbox_lookup = 8'h70;
                default: sbox_lookup = 8'h00;
            endcase
        end
    endfunction

endmodule