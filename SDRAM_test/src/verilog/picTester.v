module PICtester(
                    clk,  // 50M
                    rst_n,
                    Xaddr // 0~639
                    );
    input        clk, rst_n;
    output [9:0] Xaddr;

    reg [9:0]  x_r, x_w;
    reg [26:0] counter_r, counter_w;
    reg [4:0]  state_r, state_w;

    assign Xaddr = x_r;

    // localparam CHANGETIME = 27'd50;
    localparam CHANGETIME = 27'd50000000;
    localparam S_L        = 5'd0; 
    localparam S_ML       = 5'd1; 
    localparam S_M        = 5'd2; 
    localparam S_MR       = 5'd3; 
    localparam S_R        = 5'd4;
    // localparam S_STOP     = 5'd5;
    localparam L          = 10'd10;
    localparam ML         = 10'd138; 
    localparam M          = 10'd266; 
    localparam MR         = 10'd394; 
    localparam R          = 10'd522;

    always@(*) begin
		  state_w = state_r;
        x_w = x_r;
        counter_w = counter_r;
        case(state_r)
            S_L: begin
                x_w = L;
                if (counter_r >= CHANGETIME) begin
                    state_w = S_ML;
                    counter_w = 0;
                end
                else begin
                    state_w = S_L;
                    counter_w = counter_r + 1; 
                end
            end
            S_ML: begin
                x_w = ML;
                if (counter_r >= CHANGETIME) begin
                    state_w = S_M;
                    counter_w = 0;
                end
                else begin
                    state_w = S_ML;
                    counter_w = counter_r + 1; 
                end
            end
            S_M: begin
                x_w = M;
                if (counter_r >= CHANGETIME) begin
                    state_w = S_MR;
                    counter_w = 0;
                end
                else begin
                    state_w = S_M;
                    counter_w = counter_r + 1; 
                end
            end
            S_MR: begin
                x_w = MR;
                if (counter_r >= CHANGETIME) begin
                    state_w = S_R;
                    counter_w = 0;
                end
                else begin
                    state_w = S_MR;
                    counter_w = counter_r + 1; 
                end
            end
            S_R: begin
                x_w = R;
                if (counter_r >= CHANGETIME) begin
                    state_w = S_L;
                    counter_w = 0;
                end
                else begin
                    state_w = S_R;
                    counter_w = counter_r + 1; 
                end
            end
            // S_STOP: begin
            //     x_w = STOP;
            //     if (counter_r >= 3 * CHANGETIME) begin
            //         state_r = S_L;
            //         counter_w = 0;
            //     end
            //     else begin
            //         state_r = S_STOP;
            //         counter_w = counter_r + 1; 
            //     end
            // end
            default: begin
                state_w = state_r;
                x_w = x_r;
                counter_w = counter_r;
            end 
        endcase
    end

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r <= S_M;
            counter_r <= 0;
            x_r <= M;
        end
        else begin
            state_r <= state_w;
            counter_r <= counter_w;
            x_r <= x_w;
        end
    end
endmodule