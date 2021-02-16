module motion_detection(
	input 	[7:0] sdram_read_data,
	output  [23:0] sdram_read_addr,
	output sdram_read, 
	input  clk,
	input  rst_n,
	// output [19:0] o_SRAM_ADDR,
	// inout  [15:0] io_SRAM_DQ,
	// output        o_SRAM_WE_N,
	// output        o_SRAM_CE_N,
	// output        o_SRAM_OE_N,
	// output        o_SRAM_LB_N,
	// output        o_SRAM_UB_N,
	input   VGA_read, 
	output  reg [15:0] VGA_out
	);


reg [7:0] background_r 	[640*480-1:0] ; // 640 * 480 
reg [7:0] background_w 	[640*480-1:0] ; // 640 * 480 
reg [7:0] V_r 					[640*480-1:0] ; // 640 * 480 
reg [7:0] V_w 					[640*480-1:0] ; // 640 * 480
reg signed [8:0] O_error ; 
reg signed [7:0] buffer_1 , buffer_2; 
reg [19:0] counter_r, counter_w ; // 20 bits 



integer i , j ; 

assign sdram_read 		= 1 ;
assign sdram_read_addr 	= 0 ; 


always@(*)
begin
	counter_w = counter_r + 1 ;
	for ( i = 0 ; i < 640*480 ; i = i + 1 )
	begin
		background_w[i] = background_r[i] ;
		V_w[i]          = V_r[i]    ; 
	end
	O_error = 0 ;
	buffer_1 = 0 ;
	buffer_2 = 0 ;

	if (VGA_read)
	begin
		if (background_r[counter_r] < sdram_read_data) 
			background_w[counter_r] = background_r[counter_r] + 1 ;
		else if (background_r[counter_r] > sdram_read_data)
			background_w[counter_r] = background_r[counter_r] - 1 ;
		else
			background_w[counter_r] = background_r[counter_r] ; 

		buffer_1 = $signed(background_w[counter_r]) - $signed(sdram_read_data) ;
		if (buffer_1[7])
		begin
			buffer_2 = ~buffer_1 + 1 ; 
		end
		else 
		begin
			buffer_2 = buffer_1 ; 
		end
		O_error = buffer_2 << 1 ; 

		if (V_r[counter_r] < O_error && V_r[counter_r] < 255) 
			V_w[counter_r] = V_r[counter_r] + 1 ;
		else if (V_r[counter_r] > O_error && V_r[counter_r] > 0)
			V_w[counter_r] = V_r[counter_r] - 1 ;
		else
			V_w[counter_r] = V_r[counter_r] ; 

		if ( O_error < V_w[counter_r] )
			VGA_out = 255 ;
		else 
			VGA_out = 0 ;  
	end
	else 
	begin
		counter_w = counter_r ; 
	end
end

always@(posedge clk)
begin
	if(!rst_n)
	begin
		for ( i = 0 ; i < 640*480 ; i = i + 1 )
		begin
			background_r[i] <= 0 ;
			V_r[i]          <= 0 ; 
		end
	end
	else 
	begin
		for ( i = 0 ; i < 640*480 ; i = i + 1 )
		begin
			background_r[i] <= background_w[i] ;
			V_r[i]          <= V_w[i] ; 
		end
	end
end

endmodule 