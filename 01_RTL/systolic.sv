module systolic (
    input clk, 
    input rst, 
    input tile_en, 
    input [15:0] tileA_data [0:3], 
    input [15:0] tileB_data [0:3],
    output logic o_valid,
    output logic [15:0] tileO_data [0:3][0:3]
);
    // input buffers
    logic [15:0] tileA_w [0:3][0:6], tileA_r [0:3][0:6];
    logic [15:0] tileB_w [0:3][0:6], tileB_r [0:3][0:6];

    // state machine 
    typedef enum logic [1:0] {
        LOADING, 
        COMPUTE,
        DONE
    } state_t;
    state_t state_w, state_r;

    logic [1:0] load_num_w, load_num_r;
    logic [4:0] propagate_num_w, propagate_num_r;

    always_comb begin
        state_w = state_r;
        case (state_r)
            LOADING: begin
                if (tile_en && load_num_r == 3) begin
                    state_w = COMPUTE;
                end
            end
            COMPUTE: begin
                // Assuming some condition to go to DONE state
                if(propagate_num_r == 11) begin
                    state_w = DONE;
                end
            end
            DONE: begin
                state_w = LOADING; // Loop back to LOADING for next tile
            end
        endcase
    end

    logic [15:0] next_a [0:3][0:3], next_b [0:3][0:3];
    logic [15:0] tileA_in [0:3], tileB_in [0:3];
    logic PE_clear, PE_en, PE_out;
    logic PE_input_gate;
    assign PE_input_gate = (state_r == LOADING || state_r == COMPUTE) && PE_en;

    

    // systolic array 

    //                 tileB_in[0]  tileB_in[1] tileB_in[2] tileB_in[3]
    //  tileA_in[0]    PE00         PE01        PE02        PE03
    //  tileA_in[1]    PE10         PE11        PE12        PE13
    //  tileA_in[2]    PE20         PE21        PE22        PE23
    //  tileA_in[3]    PE30         PE31        PE32        PE33

    PE pe00 (
        .*,
        .a(tileA_in[0]), 
        .b(tileB_in[0]),
        .next_a(next_a[0][0]), 
        .next_b(next_b[0][0]),
        .o(tileO_data[0][0])
    );
    PE pe01 (
        .*,
        .a(next_a[0][0]), 
        .b(tileB_in[1]),
        .next_a(next_a[0][1]),
        .next_b(next_b[0][1]),
        .o(tileO_data[0][1])
    );
    PE pe02 (
        .*,
        .a(next_a[0][1]), 
        .b(tileB_in[2]),
        .next_a(next_a[0][2]),
        .next_b(next_b[0][2]),
        .o(tileO_data[0][2])
    );
    PE pe03 (
        .*,
        .a(next_a[0][2]), 
        .b(tileB_in[3]),
        .next_a(),
        .next_b(next_b[0][3]),
        .o(tileO_data[0][3])
    );
    PE pe10 (
        .*,
        .a(tileA_in[1]), 
        .b(next_b[0][0]),
        .next_a(next_a[1][0]),
        .next_b(next_b[1][0]),
        .o(tileO_data[1][0])
    );
    PE pe11 (
        .*,
        .a(next_a[1][0]), 
        .b(next_b[0][1]),
        .next_a(next_a[1][1]),
        .next_b(next_b[1][1]),
        .o(tileO_data[1][1])
    );
    PE pe12 (
        .*,
        .a(next_a[1][1]), 
        .b(next_b[0][2]),
        .next_a(next_a[1][2]),
        .next_b(next_b[1][2]),
        .o(tileO_data[1][2])
    );
    PE pe13 (
        .*,
        .a(next_a[1][2]), 
        .b(next_b[0][3]),
        .next_a(),
        .next_b(next_b[1][3]),
        .o(tileO_data[1][3])
    );
    PE pe20 (
        .*,
        .a(tileA_in[2]), 
        .b(next_b[1][0]),
        .next_a(next_a[2][0]),
        .next_b(next_b[2][0]),
        .o(tileO_data[2][0])
    );
    PE pe21 (
        .*,
        .a(next_a[2][0]), 
        .b(next_b[1][1]),
        .next_a(next_a[2][1]),
        .next_b(next_b[2][1]),
        .o(tileO_data[2][1])
    );
    PE pe22 (
        .*,
        .a(next_a[2][1]), 
        .b(next_b[1][2]),
        .next_a(next_a[2][2]),
        .next_b(next_b[2][2]),
        .o(tileO_data[2][2])
    );
    PE pe23 (
        .*,
        .a(next_a[2][2]), 
        .b(next_b[1][3]),
        .next_a(),
        .next_b(next_b[2][3]),
        .o(tileO_data[2][3])
    );
    PE pe30 (
        .*,
        .a(tileA_in[3]), 
        .b(next_b[2][0]),
        .next_a(next_a[3][0]),
        .next_b(),
        .o(tileO_data[3][0])
    );
    PE pe31 (
        .*,
        .a(next_a[3][0]), 
        .b(next_b[2][1]),
        .next_a(next_a[3][1]),
        .next_b(),
        .o(tileO_data[3][1])
    );
    PE pe32 (
        .*,
        .a(next_a[3][1]), 
        .b(next_b[2][2]),
        .next_a(next_a[3][2]),
        .next_b(),
        .o(tileO_data[3][2])
    );
    PE pe33 (
        .*,
        .a(next_a[3][2]), 
        .b(next_b[2][3]),
        .next_a(),
        .next_b(),
        .o(tileO_data[3][3])
    );



    always_comb begin
        load_num_w = load_num_r;
        propagate_num_w = propagate_num_r;
        tileA_w = tileA_r;
        tileB_w = tileB_r;
        PE_clear = 0;
        PE_en = 0;
        PE_out = 0;
        o_valid = 0;
        for(int i=0; i<4; i++) begin
            tileA_in[i] = 0;
            tileB_in[i] = 0;
        end
        case(state_r)
            LOADING: begin
                if(tile_en) begin
                    // tile
                    // 05 04 03 02 01 00
                    // 15 14 13 12 11 10
                    // 25 24 23 22 21 20
                    // 35 34 33 32 31 30
                    load_num_w = load_num_r + 1;
                    case(load_num_r)
                    0: begin
                        tileA_w[0][0] = tileA_data[0];
                        tileA_w[0][1] = tileA_data[1];
                        tileA_w[0][2] = tileA_data[2];
                        tileA_w[0][3] = tileA_data[3];
                        tileB_w[0][0] = tileB_data[0];
                        tileB_w[1][1] = tileB_data[1];
                        tileB_w[2][2] = tileB_data[2];
                        tileB_w[3][3] = tileB_data[3];
                    end
                    1: begin
                        tileA_w[1][1] = tileA_data[0];
                        tileA_w[1][2] = tileA_data[1];
                        tileA_w[1][3] = tileA_data[2];
                        tileA_w[1][4] = tileA_data[3];
                        tileB_w[0][1] = tileB_data[0];
                        tileB_w[1][2] = tileB_data[1];
                        tileB_w[2][3] = tileB_data[2];
                        tileB_w[3][4] = tileB_data[3];
                    end
                    2: begin
                        tileA_w[2][2] = tileA_data[0];
                        tileA_w[2][3] = tileA_data[1];
                        tileA_w[2][4] = tileA_data[2];
                        tileA_w[2][5] = tileA_data[3];
                        tileB_w[0][2] = tileB_data[0];
                        tileB_w[1][3] = tileB_data[1];
                        tileB_w[2][4] = tileB_data[2];
                        tileB_w[3][5] = tileB_data[3];
                    end
                    3: begin
                        load_num_w = 0;
                        tileA_w[3][3] = tileA_data[0];
                        tileA_w[3][4] = tileA_data[1];
                        tileA_w[3][5] = tileA_data[2];
                        tileA_w[3][6] = tileA_data[3];
                        tileB_w[0][3] = tileB_data[0];
                        tileB_w[1][4] = tileB_data[1];
                        tileB_w[2][5] = tileB_data[2];
                        tileB_w[3][6] = tileB_data[3];
                    end
                    endcase
                end
            end
            COMPUTE: begin
                propagate_num_w = propagate_num_r + 1;
                case(propagate_num_r)
                0,1,2,3,4,5,6: begin
                    for(int i=0; i<4; i++) begin
                        tileA_in[i] = tileA_r[i][propagate_num_r];
                        tileB_in[i] = tileB_r[i][propagate_num_r];
                    end
                    PE_en = 1;
                end
                11: begin // last cycle
                    PE_en = 1;
                    propagate_num_w = 0; // Reset for next tile
                end                    
                default: begin
                    PE_en = 1;
                end
                endcase
            end
            DONE: begin
                PE_out  = 1;
                o_valid = 1;
                PE_clear = 1;
            end
        endcase
    end

    // systolic array 

    //                 tileB_in[0]  tileB_in[1] tileB_in[2] tileB_in[3]
    //  tileA_in[0]    PE00         PE01        PE02        PE03
    //  tileA_in[1]    PE10         PE11        PE12        PE13
    //  tileA_in[2]    PE20         PE21        PE22        PE23
    //  tileA_in[3]    PE30         PE31        PE32        PE33

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 7; j++) begin
                    tileA_r[i][j] <= 0;
                    tileB_r[i][j] <= 0;
                end
            end
        end
        else if(state_r == LOADING) begin
            // Load the tileA and tileB data
            tileA_r <= tileA_w;
            tileB_r <= tileB_w;
        end
    end
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic
            state_r <= LOADING;
            load_num_r <= 0;
            propagate_num_r <= 0;
        end else begin 
            // Write logic
            state_r <= state_w;
            load_num_r <= load_num_w;
            propagate_num_r <= propagate_num_w;
        end
    end


endmodule

module PE (
    input clk, 
    input rst, 
    input signed [15:0] a, 
    input signed [15:0] b, 
    input PE_clear, 
    input PE_en, 
    input PE_out,
    input PE_input_gate,
    output logic signed [15:0] next_a, 
    output logic signed [15:0] next_b,
    output logic signed [15:0] o
);
    logic signed [35:0] o_w, o_r;
    logic signed [15:0] a_r, b_r, a_w, b_w;
    
    assign a_w = a;
    assign b_w = b;
    assign next_a = a_r;
    assign next_b = b_r;
    
    localparam signed [35:0] NEG_MAX = -(1<<30);
    localparam signed [35:0] POS_MAX = (1<<30) - 1;
    
    always_comb begin
        o = 0;
        if (PE_out) begin
            if(o_r > 0) begin
                if(o_r >= POS_MAX) begin // > 1
                    o = 16'h7FFF; // Saturate to max positive value
                end else begin
                    o = {1'b0, o_r[29-:15]}; // Take the upper 15 bits and sign extend
                end
            end
            else begin
                if(o_r <= NEG_MAX) begin // < -1
                    o = 16'h8000; // Saturate to max negative value
                    
                end else begin
                    o = {1'b1, o_r[29-:15]}; // Take the upper 15 bits and sign extend
                end
            end
        end
    end
    always_comb begin
        o_w = o_r;
        if (PE_clear) begin
            o_w = 0;
        end else if (PE_en) begin
            o_w = o_r + a * b;
        end
    end
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            o_r <= 0;
        end
        else if(PE_en || PE_clear)begin 
            o_r <= o_w;
        end
    end
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            a_r <= 0;
            b_r <= 0;
        end
        else if(PE_input_gate) begin 
            a_r <= a_w;
            b_r <= b_w;
        end
    end

endmodule