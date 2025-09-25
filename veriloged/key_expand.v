module key_expand(
    input       clk,
    input       reset,
    input       start,          //one cycle start pulse sent begin key expansion
    input [31:0]  cipher_key,    // initial key pulled in 4cycles (32bit each)
    input  [1:0]   r_index,       // which 32 bit section of the key to output
    input  [3:0]   round_key_num, // which round key to output (ask preston)
    output [31:0]  round_key,     // expanded round key
    output         done           // high when round_key output is valid
);

    reg [127:0] key_reg;      //stores the complete cipher key
    reg [1:0]   load_count;   // counts which 32-bit word we are on
    reg         loading;      // high when we are loading the key
    reg [127:0] round_keys [0:10]; // 2D-aray : 11 round keys (0 = initial key, 10 = last)


    reg [31:0] w [0:43]; // 44 words total (AES-128)
    // Key loading state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            key_reg    <= 128'd0;
            load_count <= 2'd0;
            loading    <= 1'b0;
        end else begin
            if (start) begin
                load_count <= 2'd0;
                loading    <= 1'b1;
            end 
            else if (loading) begin
                case (load_count)
                    2'd0: key_reg[127:96] <= cipher_key;
                    2'd1: key_reg[95:64]  <= cipher_key;
                    2'd2: key_reg[63:32]  <= cipher_key;
                    2'd3: key_reg[31:0]   <= cipher_key;
                endcase
                if (load_count == 2'd3) begin
                    loading  <= 1'b0;
                    load_count <= 2'b00;
                end
                else load_count <= load_count + 1'b1;
            end
        end
    end


    //varibles for 11 stage round key expansion:
    localparam IDLE=2'b00, LOAD=2'b01, EXPAND=2'b10, DONE=2'b11;
    reg [1:0] state;

    reg [5:0] round_ctr; //edited
    reg [127:0] current_key;

    //vars for key expansion
    reg [31:0] temp;
    reg [31:0] after_rot;
    reg [31:0] after_sub_rcon;
    reg [31:0] new_word;
    integer r;

    //key expansion code
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            round_ctr <= 0;
            done <= 0;
        end 
        else if (start)begin 
            state   <= LOAD;
            done <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    state <= IDLE;
                end
                LOAD:begin
                    if (!loading) begin
                        done <= 0;
                        current_key <= key_reg;  // initial key
                        round_keys[0]   <= key_reg;
                        w[0] <= key_reg[127:96];
                        w[1] <= key_reg[95:64];
                        w[2] <= key_reg[63:32];
                        w[3] <= key_reg[31:0];
                        round_ctr   <= 4;
                        state       <= EXPAND;
                    end 
                end
                EXPAND: begin
                    if (round_ctr <= 43) begin/*
                        w[round_ctr] <= next_word(round_ctr, w[round_ctr-1], w[round_ctr-4], round_ctr>>2); //(>>2 equiv to divide by 4)
                        round_ctr <= round_ctr + 1;

                        // Print intermediate values for debugging
                    $display("Time %0t | i=%0d | prev_word=%h | wordNk=%h | temp (after sub/rot/rcon)=%h | w[i]=%h",
                            $time, round_ctr, w[round_ctr-1], w[round_ctr-4], 
                            (round_ctr % 4 == 0) ? (sub_word(rot_word(w[round_ctr-1])) ^ rcon(round_ctr>>2)) : w[round_ctr-1],
                            next_word(round_ctr, w[round_ctr-1], w[round_ctr-4], round_ctr>>2));*/
                        

                        temp = w[round_ctr-1];
                        after_rot = (round_ctr % 4 == 0) ? rot_word(temp) : temp;
                        after_sub_rcon = (round_ctr % 4 == 0) ? (sub_word(after_rot) ^ rcon(round_ctr>>2)) : temp;
                        new_word = w[round_ctr-4] ^ after_sub_rcon;
                        w[round_ctr] <= new_word;
                        
                        if (round_ctr == 4) begin
                            // Print header once before first expansion step
                            $display("i temp    ROTWORD() SUBWORD() Rcon  SUBWD^Rcon  w[i]");
                        end
                        $display("%0d %h %h %h %h %h %h",
                            round_ctr,
                            temp,                 // temp (prev_word)
                            after_rot,            // after ROTWORD
                            sub_word(after_rot),  // after SUBWORD
                            rcon(round_ctr>>2),   // Rcon[i/Nk]
                            after_sub_rcon,       // after SUBWORD ^ Rcon
                            new_word              // final w[i]
                        );

                        round_ctr <= round_ctr + 1;

                    end else begin
                        // pack round keys into 128-bit blocks
                        
                        for (r = 0; r <= 10; r++) begin
                            round_keys[r] <= {w[4*r], w[4*r+1], w[4*r+2], w[4*r+3]};
                        end
                        state <= DONE;
                    end
                end
                DONE: begin
                    done <= 1;
                    state <= IDLE; //stay in done until new start pulse
                end
            endcase
        end
    end
        
    

    //process for returning the round keys
    always(*)begin
        case (r_index)
            2'd0: round_key = round_keys[round_key_num][127:96];
            2'd1: round_key = round_keys[round_key_num][95:64];
            2'd2: round_key = round_keys[round_key_num][63:32];
            2'd3: round_key = round_keys[round_key_num][31:0];
        endcase
    end
    


    function [31:0] next_word;
        input [5:0] i;           // was "integer i" → AES-128 only needs up to 43
        input [31:0] prev_word;
        input [31:0] wordNk;
        input [3:0] round_num;   // was "integer round_num", AES-128 only needs 0..10
        reg [31:0] temp;
        begin
            temp = prev_word;
            if (i % 4 == 0) begin
                temp = sub_word(rot_word(temp)) ^ rcon(round_num);
            end
            next_word = wordNk ^ temp;
        end
    endfunction

    function [31:0] get_word;
        input [127:0] key;
        input [1:0] index;  // only 0..3 needed for AES-128
        begin
            case (index)
                2'd0: get_word = key[127:96];
                2'd1: get_word = key[95:64];
                2'd2: get_word = key[63:32];
                2'd3: get_word = key[31:0];
                default: get_word = 32'h00000000;
            endcase
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
        reg [31:0] tmp;
        begin
            tmp[31:24] = sbox_lookup(w[31:24]);
            tmp[23:16] = sbox_lookup(w[23:16]);
            tmp[15:8]  = sbox_lookup(w[15:8]);
            tmp[7:0]   = sbox_lookup(w[7:0]);
            sub_word   = tmp;
        end
    endfunction

    // Rcon: round constant
    function [31:0] rcon;
        input [3:0] i;   // 4 bits is enough for AES-128 rounds
        reg [7:0] rc;
        begin
            case (i)
                4'd1:  rc = 8'h01;
                4'd2:  rc = 8'h02;
                4'd3:  rc = 8'h04;
                4'd4:  rc = 8'h08;
                4'd5:  rc = 8'h10;
                4'd6:  rc = 8'h20;
                4'd7:  rc = 8'h40;
                4'd8:  rc = 8'h80;
                4'd9:  rc = 8'h1B;
                4'd10: rc = 8'h36;
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
                8'h27: sbox_lookup = 8'hcc;
                8'h28: sbox_lookup = 8'h34;
                8'h29: sbox_lookup = 8'ha5;
                8'h2a: sbox_lookup = 8'he5;
                8'h2b: sbox_lookup = 8'hf1;
                8'h2c: sbox_lookup = 8'h71;
                8'h2d: sbox_lookup = 8'hd8;
                8'h2e: sbox_lookup = 8'h31;
                8'h2f: sbox_lookup = 8'h15;

                8'h30: sbox_lookup = 8'h04;
                8'h31: sbox_lookup = 8'hc7;
                8'h32: sbox_lookup = 8'h23;
                8'h33: sbox_lookup = 8'hc3;
                8'h34: sbox_lookup = 8'h18;
                8'h35: sbox_lookup = 8'h96;
                8'h36: sbox_lookup = 8'h05;
                8'h37: sbox_lookup = 8'h9a;
                8'h38: sbox_lookup = 8'h07;
                8'h39: sbox_lookup = 8'h12;
                8'h3a: sbox_lookup = 8'h80;
                8'h3b: sbox_lookup = 8'he2;
                8'h3c: sbox_lookup = 8'heb;
                8'h3d: sbox_lookup = 8'h27;
                8'h3e: sbox_lookup = 8'hb2;
                8'h3f: sbox_lookup = 8'h75;
                                // Row 4: 0x40 – 0x4F
                8'h40: sbox_lookup = 8'h09;
                8'h41: sbox_lookup = 8'h83;
                8'h42: sbox_lookup = 8'h2c;
                8'h43: sbox_lookup = 8'h1a;
                8'h44: sbox_lookup = 8'h1b;
                8'h45: sbox_lookup = 8'h6e;
                8'h46: sbox_lookup = 8'h5a;
                8'h47: sbox_lookup = 8'ha0;
                8'h48: sbox_lookup = 8'h52;
                8'h49: sbox_lookup = 8'h3b;
                8'h4a: sbox_lookup = 8'hd6;
                8'h4b: sbox_lookup = 8'hb3;
                8'h4c: sbox_lookup = 8'h29;
                8'h4d: sbox_lookup = 8'he3;
                8'h4e: sbox_lookup = 8'h2f;
                8'h4f: sbox_lookup = 8'h84;

                // Row 5: 0x50 – 0x5F
                8'h50: sbox_lookup = 8'h53;
                8'h51: sbox_lookup = 8'hd1;
                8'h52: sbox_lookup = 8'h00;
                8'h53: sbox_lookup = 8'hed;
                8'h54: sbox_lookup = 8'h20;
                8'h55: sbox_lookup = 8'hfc;
                8'h56: sbox_lookup = 8'hb1;
                8'h57: sbox_lookup = 8'h5b;
                8'h58: sbox_lookup = 8'h6a;
                8'h59: sbox_lookup = 8'hcb;
                8'h5a: sbox_lookup = 8'hbe;
                8'h5b: sbox_lookup = 8'h39;
                8'h5c: sbox_lookup = 8'h4a;
                8'h5d: sbox_lookup = 8'h4c;
                8'h5e: sbox_lookup = 8'h58;
                8'h5f: sbox_lookup = 8'hcf;

                                // Row 6: 0x60 – 0x6F
                8'h60: sbox_lookup = 8'hd0;
                8'h61: sbox_lookup = 8'hef;
                8'h62: sbox_lookup = 8'haa;
                8'h63: sbox_lookup = 8'hfb;
                8'h64: sbox_lookup = 8'h43;
                8'h65: sbox_lookup = 8'h4d;
                8'h66: sbox_lookup = 8'h33;
                8'h67: sbox_lookup = 8'h85;
                8'h68: sbox_lookup = 8'h45;
                8'h69: sbox_lookup = 8'hf9;
                8'h6a: sbox_lookup = 8'h02;
                8'h6b: sbox_lookup = 8'h7f;
                8'h6c: sbox_lookup = 8'h50;
                8'h6d: sbox_lookup = 8'h3c;
                8'h6e: sbox_lookup = 8'h9f;
                8'h6f: sbox_lookup = 8'ha8;

                // Row 7: 0x70 – 0x7F
                8'h70: sbox_lookup = 8'h51;
                8'h71: sbox_lookup = 8'ha3;
                8'h72: sbox_lookup = 8'h40;
                8'h73: sbox_lookup = 8'h8f;
                8'h74: sbox_lookup = 8'h92;
                8'h75: sbox_lookup = 8'h9d;
                8'h76: sbox_lookup = 8'h38;
                8'h77: sbox_lookup = 8'hf5;
                8'h78: sbox_lookup = 8'hbc;
                8'h79: sbox_lookup = 8'hb6;
                8'h7a: sbox_lookup = 8'hda;
                8'h7b: sbox_lookup = 8'h21;
                8'h7c: sbox_lookup = 8'h10;
                8'h7d: sbox_lookup = 8'hff;
                8'h7e: sbox_lookup = 8'hf3;
                8'h7f: sbox_lookup = 8'hd2;

                // Row 8: 0x80 – 0x8F
                8'h80: sbox_lookup = 8'hcd;
                8'h81: sbox_lookup = 8'h0c;
                8'h82: sbox_lookup = 8'h13;
                8'h83: sbox_lookup = 8'hec;
                8'h84: sbox_lookup = 8'h5f;
                8'h85: sbox_lookup = 8'h97;
                8'h86: sbox_lookup = 8'h44;
                8'h87: sbox_lookup = 8'h17;
                8'h88: sbox_lookup = 8'hc4;
                8'h89: sbox_lookup = 8'ha7;
                8'h8a: sbox_lookup = 8'h7e;
                8'h8b: sbox_lookup = 8'h3d;
                8'h8c: sbox_lookup = 8'h64;
                8'h8d: sbox_lookup = 8'h5d;
                8'h8e: sbox_lookup = 8'h19;
                8'h8f: sbox_lookup = 8'h73;

                // Row 9: 0x90 – 0x9F
                8'h90: sbox_lookup = 8'h60;
                8'h91: sbox_lookup = 8'h81;
                8'h92: sbox_lookup = 8'h4f;
                8'h93: sbox_lookup = 8'hdc;
                8'h94: sbox_lookup = 8'h22;
                8'h95: sbox_lookup = 8'h2a;
                8'h96: sbox_lookup = 8'h90;
                8'h97: sbox_lookup = 8'h88;
                8'h98: sbox_lookup = 8'h46;
                8'h99: sbox_lookup = 8'hee;
                8'h9a: sbox_lookup = 8'hb8;
                8'h9b: sbox_lookup = 8'h14;
                8'h9c: sbox_lookup = 8'hde;
                8'h9d: sbox_lookup = 8'h5e;
                8'h9e: sbox_lookup = 8'h0b;
                8'h9f: sbox_lookup = 8'hdb;

                                // Row A: 0xA0 – 0xAF
                8'hA0: sbox_lookup = 8'he0;
                8'hA1: sbox_lookup = 8'h32;
                8'hA2: sbox_lookup = 8'h3a;
                8'hA3: sbox_lookup = 8'h0a;
                8'hA4: sbox_lookup = 8'h49;
                8'hA5: sbox_lookup = 8'h06;
                8'hA6: sbox_lookup = 8'h24;
                8'hA7: sbox_lookup = 8'h5c;
                8'hA8: sbox_lookup = 8'hc2;
                8'hA9: sbox_lookup = 8'hd3;
                8'hAA: sbox_lookup = 8'hac;
                8'hAB: sbox_lookup = 8'h62;
                8'hAC: sbox_lookup = 8'h91;
                8'hAD: sbox_lookup = 8'h95;
                8'hAE: sbox_lookup = 8'he4;
                8'hAF: sbox_lookup = 8'h79;

                // Row B: 0xB0 – 0xBF
                8'hB0: sbox_lookup = 8'he7;
                8'hB1: sbox_lookup = 8'hc8;
                8'hB2: sbox_lookup = 8'h37;
                8'hB3: sbox_lookup = 8'h6d;
                8'hB4: sbox_lookup = 8'h8d;
                8'hB5: sbox_lookup = 8'hd5;
                8'hB6: sbox_lookup = 8'h4e;
                8'hB7: sbox_lookup = 8'ha9;
                8'hB8: sbox_lookup = 8'h6c;
                8'hB9: sbox_lookup = 8'h56;
                8'hBA: sbox_lookup = 8'hf4;
                8'hBB: sbox_lookup = 8'hea;
                8'hBC: sbox_lookup = 8'h65;
                8'hBD: sbox_lookup = 8'h7a;
                8'hBE: sbox_lookup = 8'hae;
                8'hBF: sbox_lookup = 8'h08;

                // Row C: 0xC0 – 0xCF
                8'hC0: sbox_lookup = 8'hba;
                8'hC1: sbox_lookup = 8'h78;
                8'hC2: sbox_lookup = 8'h25;
                8'hC3: sbox_lookup = 8'h2e;
                8'hC4: sbox_lookup = 8'h1c;
                8'hC5: sbox_lookup = 8'ha6;
                8'hC6: sbox_lookup = 8'hb4;
                8'hC7: sbox_lookup = 8'hc6;
                8'hC8: sbox_lookup = 8'he8;
                8'hC9: sbox_lookup = 8'hdd;
                8'hCA: sbox_lookup = 8'h74;
                8'hCB: sbox_lookup = 8'h1f;
                8'hCC: sbox_lookup = 8'h4b;
                8'hCD: sbox_lookup = 8'hbd;
                8'hCE: sbox_lookup = 8'h8b;
                8'hCF: sbox_lookup = 8'h8a;

                // Row D: 0xD0 – 0xDF
                8'hD0: sbox_lookup = 8'h70;
                8'hD1: sbox_lookup = 8'h3e;
                8'hD2: sbox_lookup = 8'hb5;
                8'hD3: sbox_lookup = 8'h66;
                8'hD4: sbox_lookup = 8'h48;
                8'hD5: sbox_lookup = 8'h03;
                8'hD6: sbox_lookup = 8'hf6;
                8'hD7: sbox_lookup = 8'h0e;
                8'hD8: sbox_lookup = 8'h61;
                8'hD9: sbox_lookup = 8'h35;
                8'hDA: sbox_lookup = 8'h57;
                8'hDB: sbox_lookup = 8'hb9;
                8'hDC: sbox_lookup = 8'h86;
                8'hDD: sbox_lookup = 8'hc1;
                8'hDE: sbox_lookup = 8'h1d;
                8'hDF: sbox_lookup = 8'h9e;

                // Row E: 0xE0 – 0xEF
                8'hE0: sbox_lookup = 8'he1;
                8'hE1: sbox_lookup = 8'hf8;
                8'hE2: sbox_lookup = 8'h98;
                8'hE3: sbox_lookup = 8'h11;
                8'hE4: sbox_lookup = 8'h69;
                8'hE5: sbox_lookup = 8'hd9;
                8'hE6: sbox_lookup = 8'h8e;
                8'hE7: sbox_lookup = 8'h94;
                8'hE8: sbox_lookup = 8'h9b;
                8'hE9: sbox_lookup = 8'h1e;
                8'hEA: sbox_lookup = 8'h87;
                8'hEB: sbox_lookup = 8'he9;
                8'hEC: sbox_lookup = 8'hce;
                8'hED: sbox_lookup = 8'h55;
                8'hEE: sbox_lookup = 8'h28;
                8'hEF: sbox_lookup = 8'hdf;

                // Row F: 0xF0 – 0xFF
                8'hF0: sbox_lookup = 8'h8c;
                8'hF1: sbox_lookup = 8'ha1;
                8'hF2: sbox_lookup = 8'h89;
                8'hF3: sbox_lookup = 8'h0d;
                8'hF4: sbox_lookup = 8'hbf;
                8'hF5: sbox_lookup = 8'he6;
                8'hF6: sbox_lookup = 8'h42;
                8'hF7: sbox_lookup = 8'h68;
                8'hF8: sbox_lookup = 8'h41;
                8'hF9: sbox_lookup = 8'h99;
                8'hFA: sbox_lookup = 8'h2d;
                8'hFB: sbox_lookup = 8'h0f;
                8'hFC: sbox_lookup = 8'hb0;
                8'hFD: sbox_lookup = 8'h54;
                8'hFE: sbox_lookup = 8'hbb;
                8'hFF: sbox_lookup = 8'h16;

                default: sbox_lookup = 8'h00;
            endcase
        end
    endfunction

endmodule