module key_expand(
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [31:0]  cipher_key,   // initial key pulled in 4cycles (32bit each)
    input  logic [1:0]   r_index,      // which 32 bit section of the key to output
    input  logic [3:0]   round_key_n,  // which round key to output (ask preston)
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
            key_reg    <= 128'b0; //initialize
            load_count <= 2'b0; 
            
            //loading    <= 1'b0;
        end else begin
            if (start) begin //assuming start stays high for all 4 loads
                // start loading from the first word
                //load_count <= 2'b0;
                //loading    <= 1'b1;
          //  end else if (loading) begin
                // shift in each 32-bit word
                case (load_count)
                    2'd0: key_reg[127:96] <= cipher_key;  // first word (MSB)
                    2'd1: key_reg[95:64]  <= cipher_key;
                    2'd2: key_reg[63:32]  <= cipher_key;
                    2'd3: key_reg[31:0]   <= cipher_key;  // last word (LSB)
                endcase

                // increment counter
                if (load_count == 2'd3) begin
                    load_count <= 2'b0;  // done loading all 4 words
                end else begin
                    load_count <= load_count + 1'b1;
                end
           // end
            end
        end
    end


    //key expansion code{
    
    
    //}

    //process for returning the round keys
    always_comb begin
        round_key = round_keys[round_key_n][ (r_index*32) +: 32 ]; //bit slicing
    end


endmodule 