module top (
    input clk,
    input rst, 
    input  [7:0]  addr_A, 
    input         en_A,
    input  [15:0] data_A,
    input  [7:0]  addr_B,
    input         en_B,
    input  [15:0] data_B,
    input  [7:0]  addr_I,
    input         en_I,
    input  [5:0]  data_I,
    input  [7:0]  addr_O,
    output logic [15:0] data_O,
    input         en_O,
    output logic  out_valid,
    input         ap_start,
    output        ap_done
);

    logic [15:0] matrixA_w [0:15][0:3], matrixA_r [0:15][0:3];
    logic [15:0] matrixB_w [0:3][0:15], matrixB_r [0:3][0:15];
    logic [15:0] matrixO1_w [0:15][0:15], matrixO1_r [0:15][0:15];
    logic [5:0]  inst_m_w  [0:5], inst_m_r  [0:5];

    logic tile_en;
    logic [15:0] tileA_data [0:3], tileB_data [0:3];
    logic [15:0] tileO_data [0:3][0:3];
    logic o_valid;

    systolic systolic_inst (
        .clk(clk),
        .rst(rst),
        .tile_en(tile_en),
        .tileA_data(tileA_data),
        .tileB_data(tileB_data),
        .tileO_data(tileO_data),
        .o_valid(o_valid)
    );

    typedef enum logic [2:0] {
        IDLE, 
        LOADING, 
        FILLING,
        COMPUTE, 
        DONE, 
        FINISH
    } state_t;
    state_t state_w, state_r;

    logic [1:0] load_num_w, load_num_r;
    logic [2:0] inst_num_w, inst_num_r;
    logic [1:0] inst_length;
    logic [1:0] tile_row_num_w, tile_row_num_r;
    logic [1:0] tile_col_num_w, tile_col_num_r;

    logic [15:0] odata_w, odata_r;
    logic out_valid_w, out_valid_r;

    assign ap_done   = (state_r == DONE);
    assign data_O    = odata_r;
    assign out_valid = out_valid_r;
    

    always_comb begin
        state_w = state_r;
        case (state_r)
        IDLE: begin
            state_w = LOADING;
        end
        LOADING: begin
            if(ap_start) begin
                state_w = FILLING;
            end
            if(en_I && data_I==0) begin
                state_w = FINISH;
            end
        end
        FILLING: begin
            if(load_num_r == 3) begin
                state_w = COMPUTE;
            end
        end
        COMPUTE: begin
            if(o_valid) begin
                case(inst_m_r[inst_num_r])
                4: begin
                    state_w = DONE;
                end
                8: begin
                    if(tile_row_num_r == 1 && tile_col_num_r == 1) begin
                        state_w = DONE; // Move to DONE after filling first tile
                    end else begin
                        state_w = FILLING; // Continue filling next tile
                    end
                end
                16: begin
                    if(tile_row_num_r == 3 && tile_col_num_r == 3) begin
                        // state_w = DONE; // Move to DONE after filling second tile
                        state_w = DONE;
                    end else begin
                        state_w = FILLING; // Continue filling next tile
                    end
                end
                endcase
            end
        end
        DONE: begin
            if(en_O && addr_O == 255) begin
                state_w = LOADING; // Otherwise, go back to LOADING
            end
        end
        FINISH: begin
        end
        endcase
    end
    always_ff @(posedge clk or posedge rst) begin
        if (rst) state_r <= IDLE;
        else state_r <= state_w;
    end

    
    always_comb begin
        matrixA_w  = matrixA_r;
        matrixB_w  = matrixB_r;
        matrixO1_w = matrixO1_r;
        inst_m_w   = inst_m_r;
        tile_en    = 0;
        load_num_w = load_num_r;
        inst_num_w = inst_num_r;
        tile_row_num_w = tile_row_num_r;
        tile_col_num_w = tile_col_num_r;
        for(int i=0; i<4; i++) begin
            tileA_data[i] = 0;
            tileB_data[i] = 0;
        end
        odata_w     = odata_r;
        out_valid_w = 0;

        case(state_r)
        IDLE: begin end
        LOADING: begin
            if(en_A) begin // and en_B
                matrixA_w[addr_A[5:2]][addr_A[1:0]] = data_A;
                matrixB_w[addr_B[5:4]][addr_B[3:0]] = data_B;
            end
            if(en_I && data_I!=0) begin
                inst_m_w[addr_I[2:0]] = data_I;
            end
        end
        FILLING: begin
            load_num_w = load_num_r + 1;
            tile_en = 1; // Enable tile for processing
            if(load_num_r == 3) begin        
                load_num_w = 0;
            end
            // 0000 0001 0010 0011
            // 0100 0101 0110 0111
            // 1000 1001 1010 1011
            // 1100 1101 1110 1111
            case(load_num_r)
            0: begin
                for(int i=0;i<4;i++) begin
                    tileA_data[i] = matrixA_r[4*tile_row_num_r][i];
                    tileB_data[i] = matrixB_r[0][4*tile_col_num_r + i];
                end
            end
            1: begin
                for(int i=0;i<4;i++) begin
                    tileA_data[i] = matrixA_r[4*tile_row_num_r + 1][i];
                    tileB_data[i] = matrixB_r[1][4*tile_col_num_r + i];
                end
            end
            2: begin
                for(int i=0;i<4;i++) begin
                    tileA_data[i] = matrixA_r[4*tile_row_num_r + 2][i];
                    tileB_data[i] = matrixB_r[2][4*tile_col_num_r + i];
                end
            end
            3: begin
                for(int i=0;i<4;i++) begin
                    tileA_data[i] = matrixA_r[4*tile_row_num_r + 3][i];
                    tileB_data[i] = matrixB_r[3][4*tile_col_num_r + i];
                end
            end
            endcase
        end
            
        COMPUTE: begin
            if(o_valid) begin
                for(int i=0; i<4; i++) begin
                    for(int j=0; j<4; j++) begin
                        matrixO1_w[4*tile_row_num_r + i][4*tile_col_num_r + j] = tileO_data[i][j];
                    end
                end
                case(inst_m_r[inst_num_r])
                4: begin
                end
                8: begin
                    tile_col_num_w = tile_col_num_r + 1;
                    if(tile_col_num_r == 1) begin
                        tile_row_num_w = 1;
                        tile_col_num_w = 0; // Reset column for next row
                        if(tile_row_num_r == 1) begin
                            tile_row_num_w = 0;
                        end
                    end
                end
                16: begin
                    tile_col_num_w = tile_col_num_r + 1;
                    if(tile_col_num_r == 3) begin
                        tile_row_num_w = tile_row_num_r + 1;
                        tile_col_num_w = 0; // Reset column for next row
                        if(tile_row_num_r == 3) begin
                            tile_row_num_w = 0;
                        end
                    end
                end
                endcase
            end
        end
        DONE: begin
            if(en_O) begin
                out_valid_w = 1;
                odata_w = matrixO1_r[addr_O[7:4]][addr_O[3:0]];
                if(addr_O == 255) begin
                    inst_num_w = inst_num_r + 1;
                    for(int i = 0; i < 16; i++) begin
                        for (int j = 0; j < 16; j++) begin
                            matrixO1_w[i][j] = 0; // Reset output matrix after reading
                        end
                    end
                end
            end
            
        end
        endcase
    end
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            for(int i = 0; i < 16; i++) begin
                for (int j = 0; j < 16; j++) begin
                    matrixO1_r[i][j] <= 0;
                end
            end
        end
        else if(state_r == COMPUTE || state_r == DONE) begin
            for(int i = 0; i < 16; i++) begin
                for (int j = 0; j < 16; j++) begin
                    matrixO1_r[i][j] <= matrixO1_w[i][j];
                end
            end
        end
    end
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for(int i = 0; i < 16; i++) begin
                for (int j = 0; j < 4; j++) begin
                    matrixA_r[i][j] <= 0;
                end
            end
            for(int i = 0; i < 4; i++) begin
                for (int j = 0; j < 16; j++) begin
                    matrixB_r[i][j] <= 0;
                end
            end
            for (int k = 0; k < 6; k++) begin
                inst_m_r[k] <= 0;
            end
        end else if(state_r == LOADING) begin
            for(int i = 0; i < 16; i++) begin
                for (int j = 0; j < 4; j++) begin
                    matrixA_r[i][j] <= matrixA_w[i][j];
                end
            end
            for(int i = 0; i < 4; i++) begin
                for (int j = 0; j < 16; j++) begin
                    matrixB_r[i][j] <= matrixB_w[i][j];
                end
            end
            for (int k = 0; k < 6; k++) begin
                inst_m_r[k] <= inst_m_w[k];
            end
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            odata_r <= 0;
        end
        else if(state_r == DONE) begin
            odata_r <= odata_w;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            out_valid_r    <= 0;
            load_num_r     <= 0;
            inst_num_r     <= 0;
            tile_row_num_r <= 0;
            tile_col_num_r <= 0;
        end else begin
            out_valid_r    <= out_valid_w;
            load_num_r     <= load_num_w;
            inst_num_r     <= inst_num_w;
            tile_row_num_r <= tile_row_num_w;
            tile_col_num_r <= tile_col_num_w;
        end
    end


endmodule


