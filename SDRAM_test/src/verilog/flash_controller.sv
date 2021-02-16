module FLASH_controller (
    input         i_rst_n,
    input         i_clk,
    input          i_boss,
    input 	[3:0] i_mode,
    input   [7:0] data,
	 
    output        o_valid,
    output  [22:1] o_addr,
    output  [15:0] o_data,
   
    

    output        ce_n,
    output        oe_n,
    output        we_n,
    output        reset_n,
    output        wp

);

logic [7:0] one_r, one_w;
logic [7:0] two_r, two_w;
logic [11:0] col_r, col_w;
logic [11:0] row_r, row_w;
logic [1:0] wait_cycle_r, wait_cycle_w;
logic [1:0] state_r, state_w;
logic [3:0] mode_r, mode_w;
logic [3:0] display_mode;
logic valid_r, valid_w;
logic boss_r, boss_w;

localparam S_IDLE = 0;
localparam S_ONE = 1;
localparam S_TWO = 2;

localparam COL_START = 80*2;
localparam COL_END = 240*2;
localparam COL_SMALLBLOCK = (240-80)*2;
localparam ROW_START = 160;
localparam ROW_END = 320;
localparam MAX_ROW = 480;
localparam MAX_COL = 1280;
localparam MAX_ADDR = 480*1280;
localparam MODE_OFFSET = (240-80)*2*(320 - 160);
localparam BOSS_OFFSET = 22'h200000;



assign ce_n = 0;
assign oe_n = 0;
assign we_n = 1;
assign reset_n = 1;
assign wp = 0;
assign o_data = {one_r,two_r};


assign o_valid = valid_r;
assign display_mode = (row_r >= ROW_START && row_r < ROW_END && col_r >= COL_START && col_r < COL_END) ? mode_r : 0;

assign o_addr = boss_r?(mode_r?col_r + row_r*MAX_COL+BOSS_OFFSET+MAX_ADDR:col_r + row_r*MAX_COL+BOSS_OFFSET):
(display_mode == 0)?col_r + row_r*MAX_COL:MAX_ADDR + MODE_OFFSET*(display_mode - 1)+ (col_r - COL_START)+(row_r - ROW_START)*COL_SMALLBLOCK;
//RRR GGG BB


always_comb begin
    one_w = one_r;
	 two_w = two_r;
    col_w = col_r;
	 row_w = row_r;
    wait_cycle_w = wait_cycle_r;
    valid_w = valid_r;
    state_w = state_r;
	 mode_w = mode_r;
     boss_w = boss_r;
    case(state_r)
        S_IDLE:begin            
            valid_w = 0;
				if(col_r == MAX_COL && row_r == MAX_ROW - 1) begin
					row_w = 0;
					col_w = 0;
					mode_w = i_mode;
                    boss_w = i_boss;
				end
				else if (col_r == MAX_COL) begin
					row_w = row_r+1;
					col_w = 0;
					mode_w = mode_r;
                    boss_w = boss_r;
				end
				else begin
					row_w = row_r;
					col_w = col_r;
					mode_w = mode_r;
                    boss_w = boss_r;
				end
            if(wait_cycle_r == 0) begin
                state_w = S_ONE;
            end
            else begin
                state_w = S_IDLE;
                wait_cycle_w = wait_cycle_r - 1;
            end
        end
        S_ONE:begin
            col_w = col_r+1;
            state_w = S_TWO;
            one_w = data;
        end            
        
        S_TWO:begin
				col_w = col_r+1;
            state_w = S_IDLE;
            valid_w = 1;
            two_w = data;
            if(col_r[2:0] == 7)begin
                wait_cycle_w = 2;
            end
            else begin
                wait_cycle_w = 0;
            end                
        end       
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        one_r <= 0;
		  two_r <= 0;
        col_r	 <= 0;
		  row_r	 <= 0;
        wait_cycle_r    <= 0;
        valid_r         <= 0;
        state_r         <= S_IDLE;
		  mode_r 			<= 0;
          boss_r <= 0;
    end
    else begin
        one_r <= one_w;
		  two_r <= two_w;
        col_r	 <= col_w;
		  row_r	 <= row_w;
        wait_cycle_r    <= wait_cycle_w;
        valid_r         <= valid_w;
        state_r         <= state_w;
		  mode_r				<= mode_w;
          boss_r <= boss_w;
    end
end

endmodule