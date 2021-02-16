module motion_detection(
	input   [15:0] sdram_read_data,
	output  [23:0] sdram_read_addr,
	input  sdram_read, 
	input  clk,
	input  VGA_clk, 
	input  rst_n,
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	output  [15:0] VGA_out,
	output  [19:0] counter, 
	output  [9:0]  index_x,
	output  [9:0]  index_y 
	);



// my parameter 
localparam N = 2 ;
localparam S_READ 	= 0 ; 
localparam S_WRITE 	= 1 ;
localparam S_READ_V = 2 ;
localparam S_WRITE_V  = 3 ;
localparam S_WRITE_E  = 4 ; 

localparam SDRAM_FINISH_ADDR        = 640*480 ; 
localparam SDRAM_START_ADDR  		= 0 ;

localparam SRAM_BACK_START_ADDR     = 0 + 20'h0_0000;
localparam SRAM_BACK_FINISH_ADDR    = SRAM_BACK_START_ADDR + 640*480 ;

localparam SRAM_START_ADDR_V        = 0 + 20'h2_0000;
localparam SRAM_FINISH_ADDR_V       = SRAM_START_ADDR_V + 640*480 ; 

localparam SRAM_START_ADDR_E        = 0 + 20'h4_0000;
localparam SRAM_FINISH_ADDR_E       = SRAM_START_ADDR_E + 640*480 ; 


reg [2:0]  state_r, state_w; 
reg [23:0] sdram_read_addr_r, sdram_read_addr_w ;
reg [19:0] read_addr_r ,  read_addr_w ; 
reg [19:0] write_addr_r, write_addr_w ;
reg [19:0] adder_counter_r, adder_counter_w  ; 
reg signed [15:0] background_r, background_w ;
reg signed [15:0] input_pict_r, input_pict_w ;
reg [15:0] write_data_r, write_data_w ;
reg [15:0] O_error_r   , O_error_w    ; 
reg signed [15:0] computation_buf_1, computation_buf_2 , computation_buf_3;
reg [15:0] V_r , V_w, E_r, E_w        ; 
reg [15:0] read_data_r, read_data_w ;
reg [15:0] sdram_read_data_r, sdram_read_data_w ;
reg [19:0] index_counter_r, index_counter_w ; 
reg [9:0] index_x_left_r, index_x_left_w, index_x_right_r, index_x_right_w ;
reg [9:0] index_y_left_r, index_y_left_w, index_y_right_r, index_y_right_w ; 
reg [19:0] total_num_r, total_num_w ;
reg [19:0] last_total_num_r, last_total_num_w ; 
reg global_start_r, global_start_w ; 
reg [9:0] x_counter_r, x_counter_w ; 
reg [9:0] y_counter_r, y_counter_w ; 

wire [15:0] read_data ; 
reg enable_r, enable_w ; 
reg [15:0] max_data_r, max_data_w ; 

reg finished_r, finished_w ; 
integer i ; 

// SDRAM control
// assign sdram_read_addr = (state_r == S_READ) ? sdram_read_addr_w : 0 ;
assign sdram_read_addr = 0 ;
// assign sdram_read      = (state_r == S_READ) ? 1'b1 : 1'b0 ;
// assign sdram_read      = 1'b1;
assign VGA_out          = E_r; 
assign counter 		   = adder_counter_r;
assign index_x 		   = (index_x_left_r + index_x_right_r)>>1;
assign index_y  	      = (index_y_left_r + index_y_right_r)>>1; 
// assign VGA_out      = sdram_read_data ; 

// SRAM control 
assign o_SRAM_ADDR = (state_r == S_WRITE || state_r == S_WRITE_V || state_r == S_WRITE_E) ? write_addr_w: read_addr_w ; 
assign io_SRAM_DQ  = (state_r == S_WRITE || state_r == S_WRITE_V || state_r == S_WRITE_E) ? write_data_w: 16'dz; // sram_dq as output
assign read_data   = (state_r != S_WRITE && state_r != S_WRITE_V && state_r != S_WRITE_E) ? io_SRAM_DQ  : 16'd0;  // sram_dq as input
assign o_SRAM_WE_N = (state_r == S_WRITE || state_r == S_WRITE_V || state_r == S_WRITE_E) ? 1'b0 : 1'b1;

assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

always @(*)
begin
	state_w = state_r ; 
	sdram_read_addr_w = sdram_read_addr_r ;
	read_addr_w       = read_addr_r ;
	write_addr_w      = write_addr_r ; 
	background_w      = background_r ;
	input_pict_w      = input_pict_r ; 
	write_data_w      = write_data_r ; 
	O_error_w         = O_error_r    ; 
	adder_counter_w   = adder_counter_r ; 
	V_w               = V_r ;
	E_w               = E_r ;
	index_counter_w   = index_counter_r ;
	index_x_left_w    = index_x_left_r;
	index_y_left_w    = index_y_left_r;
	index_x_right_w   = index_x_right_r;
	index_y_right_w   = index_y_right_r;
	total_num_w       = total_num_r ;
	computation_buf_1 = 0 ;
	computation_buf_2 = 0 ;
	computation_buf_3 = 0 ; 
	last_total_num_w  = last_total_num_r ;
	global_start_w    = global_start_r ; 
	max_data_w        = max_data_r ; 
	x_counter_w 		= x_counter_r ;
	y_counter_w 		= y_counter_r ; 

	case(state_r)
	S_READ: 	// to load background from SRAM and load picture of camera from SDRAM
	begin
	   if (!sdram_read)
		begin
			adder_counter_w   = adder_counter_r ; 
			index_counter_w   = index_counter_r ;
			// index_x_w         = index_x_r;
			// index_y_w  		   = index_y_r;
		end
		// else if (adder_counter_r < 20'd307200) // 640 * 480 
		// else if (adder_counter_r < 20'd15)
		else if ( ~(y_counter_r == 480 - 1 && x_counter_r == 640 - 1 ))
		begin
			adder_counter_w   = adder_counter_r + 1 ; 
			index_counter_w   = index_counter_r ;
			// index_x_w         = index_x_r;
			// index_y_w  		   = index_y_r;		
			if (x_counter_r >= 640 - 1 )
			begin
				y_counter_w = y_counter_r + 1 ;
				x_counter_w = 0 ;
			end
			else
			begin
				x_counter_w = x_counter_r + 1 ;
				y_counter_w = y_counter_r ; 
			end		
		end
		else 
		begin
			// index_y_w         = index_counter_r / total_num_r / 640 ; // 640 * 480 * 640
			// index_x_w 		   = index_counter_r / total_num_r - 640 * index_y_w ;
			// index_y_w         = index_counter_r / total_num_r / 5 ;
			// index_x_w 		  = index_counter_r / total_num_r - 5 * index_y_w ;
			// index_y_w = (index_counter_r >> 7) / 5  ;
			// index_y_w = index_counter_r >> 9 ; 
			// index_x_w = index_counter_r - index_y_w * 640;
			// index_y_w = index_y_r ;
			// index_x_w = index_x_r ;
			adder_counter_w   = 0 ; 
			index_counter_w   = 0 ;	
			last_total_num_w  = total_num_r ;
			total_num_w       = 0 ; 
			global_start_w    = 1 ; 
			max_data_w        = 0 ; 
			x_counter_w 		= 0 ;
			y_counter_w 		= 0 ; 
		end
		sdram_read_addr_w 	 = SDRAM_START_ADDR + adder_counter_r ;
		read_addr_w           = SRAM_BACK_START_ADDR + adder_counter_r;
		state_w               = (sdram_read) ? S_WRITE : S_READ ;
		background_w          = read_data;
		input_pict_w          = sdram_read_data ; 
	end
	S_WRITE:	// update the background picture and write back to SRAM
	begin 
		if (global_start_r == 0 ) 
		begin
			computation_buf_3 = input_pict_r ; 
		end
		else
		begin
			
			if (input_pict_r - background_r > 4  )
				computation_buf_3 = background_r + 4;
			else if (input_pict_r - background_r > 0  )
				computation_buf_3 = background_r + 2;
			else if  (background_r - input_pict_r > 4)
				computation_buf_3 = background_r - 4;
			else if  (background_r - input_pict_r > 0)
				computation_buf_3 = background_r - 2;
			else 
				computation_buf_3 = background_r ; 
			
			/*
			if (input_pict_r > background_r  )
				computation_buf_3 = background_r + 2;
			else if (background_r > input_pict_r )
				computation_buf_3 = background_r - 2;
			else
				computation_buf_3 = background_r ; 
			*/
		end
		
		computation_buf_1 = $signed({1'b0, background_r}) - $signed({1'b0, input_pict_r}) ; 
		if (computation_buf_1[15])
		begin
			computation_buf_2 = ~computation_buf_1 + 1 ; 
		end
		else 
		begin
			computation_buf_2 = computation_buf_1 ; 
		end
		
		if(computation_buf_2 < 24 || x_counter_r < 20  || x_counter_r > 620 )
		begin
			E_w = 0 ;
			index_counter_w = index_counter_r ;
			total_num_w = total_num_r ; 
		end
		else
		begin
			E_w = 255 ;
			
			if (total_num_r == (last_total_num_r >> 2))
			begin
				index_x_left_w = x_counter_r ;
				index_y_left_w = y_counter_r ; 
				index_x_right_w   = index_x_right_r;
				index_y_right_w   = index_y_right_r;
			end
			else if(total_num_r == (last_total_num_r >>2 ) * 3)
			begin
				index_x_right_w = x_counter_r ;
				index_y_right_w = y_counter_r ; 
				index_x_left_w    = index_x_left_r;
				index_y_left_w    = index_y_left_r;
			end
			else
			begin
			   index_x_left_w    = index_x_left_r;
				index_y_left_w    = index_y_left_r;
				index_x_right_w   = index_x_right_r;
				index_y_right_w   = index_y_right_r;
			end
			
			
			/*
			if (max_data_r < computation_buf_2 )
			begin
				index_counter_w = adder_counter_r ;
				max_data_w      = computation_buf_2 ; 
			end
			else
			begin
				index_counter_w = index_counter_r ; 
				max_data_w      = max_data_r ; 
			end
			*/
			
			total_num_w = total_num_r + 1 ; 
		end

		write_addr_w = read_addr_r      ; 
		write_data_w = computation_buf_3     ;  
		state_w      = S_READ         ;
	end
	/*
	S_READ_V:	// to deal with the data from SDAM and SRAM and output the black-white picture to SRAM
	begin
		computation_buf_1 = $signed({1'b0, background_r}) - $signed({1'b0, input_pict_r}) ; 
		if (computation_buf_1[15])
		begin
			computation_buf_2 = ~computation_buf_1 + 1 ; 
		end
		else 
		begin
			computation_buf_2 = computation_buf_1 ; 
		end
		
		if(computation_buf_2 < 20)
		begin
			E_w = 0 ;
			index_counter_w = index_counter_r ;
			total_num_w = total_num_r ; 
		end
		else
		begin
			E_w = 256 - 1 ;
			
			if (total_num_r == (last_total_num_r >> 1))
				index_counter_w = adder_counter_r ;
			else
			   index_counter_w = index_counter_r ;
			
			
			if (total_num_r == 20'd0)
			begin
				index_counter_w = adder_counter_r ;
			end
			else
			begin
				index_counter_w = index_counter_r ; 
			end
			
			total_num_w = total_num_r + 1 ; 
		end

		// read_addr_w  = SRAM_START_ADDR_V + adder_counter_r - 1 ; 
		state_w      = S_READ         ;
		// V_w 			 = read_data ;
	end
	*/
	/*
	S_WRITE_V:
	begin
		computation_buf_2 = O_error_r << 1 ;
		if (V_r < computation_buf_2 )
		begin
			V_w = V_r + 1 ;
		end
		else if (V_r > computation_buf_2 ) 
			V_w = V_r - 1 ; 
		else 
		begin
			V_w = V_r ;
		end
		
		if (O_error_r < 20 )
		begin
			E_w = 0 ;
			index_counter_w = index_counter_r ;
			total_num_w = total_num_r ; 
		end
		else 
		begin
			E_w = 256 - 1 ;
			
			if (total_num_r == (last_total_num_r >> 1))
				index_counter_w = adder_counter_r ;
			else
			   index_counter_w = index_counter_r ;
			
			
			if (total_num_r == 20'd0)
			begin
				index_counter_w = adder_counter_r ;
			end
			else
			begin
				index_counter_w = index_counter_r ; 
			end
			
			total_num_w = total_num_r + 1 ; 
		end
		
		
		write_addr_w = read_addr_r ;
		write_data_w = V_w ;

		state_w      = S_READ   ;
	end
	*/
	endcase
end

always @(negedge rst_n or posedge clk)
begin
	if(!rst_n)
	begin
		enable_r <= 0 ; 
	end
	else
	begin
		if( VGA_clk == 1 )
		begin
			enable_r <= 1 ; 
		end
		else
		begin
			enable_r <= 0 ; 
		end
	end
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		state_r 		      <= 0 ;
		sdram_read_addr_r <= 0 ; // change this value to the start place 
		read_addr_r       <= 0 ; // change to the place that the backgoruond picture store in SRAM
		write_addr_r      <= 0 ; 
		background_r  	   <= 0 ; 
		input_pict_r      <= 0 ;
		write_data_r      <= 0 ;
		O_error_r         <= 0 ; 
		adder_counter_r   <= 0 ;
		E_r               <= 0 ;
		V_r               <= 0 ;
		index_counter_r   <= 0 ;
		index_x_left_r    <= 0 ;
		index_y_left_r    <= 0 ;
		index_x_right_r   <= 0 ;
		index_y_right_r   <= 0 ;
		total_num_r       <= 0 ;
		last_total_num_r  <= 0 ; 
		global_start_r    <= 0 ; 
		max_data_r        <= 0 ; 
		x_counter_r   		<= 0 ;
		y_counter_r 		<= 0 ; 
	end
	else 
	begin
		state_r           <= state_w ;
		sdram_read_addr_r <= sdram_read_addr_w ; 
		read_addr_r       <= read_addr_w ;
		write_addr_r      <= write_addr_w ; 
		background_r  	   <= background_w ;
		input_pict_r      <= input_pict_w ;
		write_data_r      <= write_data_w ; 
		O_error_r         <= O_error_w    ;
		adder_counter_r   <= adder_counter_w ; 
		E_r               <= E_w ;
		V_r               <= V_w ;
		index_counter_r   <= index_counter_w ;
		index_x_left_r    <= index_x_left_w ;
		index_y_left_r    <= index_y_left_w ;
		index_x_right_r   <= index_x_right_w ;
		index_y_right_r   <= index_y_right_w ;
		total_num_r       <= total_num_w ;
		last_total_num_r  <= last_total_num_w ; 
		global_start_r    <= global_start_w ; 
		max_data_r        <= max_data_w ; 
		x_counter_r   		<= x_counter_w ;
		y_counter_r 		<= y_counter_w ;
	end
end

endmodule 