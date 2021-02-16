module PICselector(
                    clk,  // 50M
                    rst_n,
                    x, // 0~639
                    switch,
                    picnum,
                    isboss
                    );
    input        clk, rst_n, switch;
    input  [9:0] x;
    output [4:0] picnum, isboss;

    localparam DISPSIZE  = 10'd480;
    // localparam MAXTIME   = 27'd100;
    localparam MAXTIME   = 27'd400000000; // about 4 sec 
    // localparam MDMAXTIME = 27'd10000000; // about 0.1 sec 
    localparam M         = 5'd0; // With Smile: PICNUM plus 5
    localparam L         = 5'd1;
    localparam ML        = 5'd2;
    localparam MR        = 5'd3;
    localparam R         = 5'd4;

    localparam GAME      = 5'd0;
    localparam BOSS      = 5'd1;

    localparam NORMAL    = 1'd0;
    localparam SMILING   = 1'd1;

    localparam PLAY      = 1'd0;
    localparam WORK      = 1'd1;


    reg    [26:0] counter_r, counter_w;
    // reg    [26:0] bosscounter_r, bosscounter_w;
    // reg    [26:0] mdcounter_r, mdcounter_w; 
    reg           state_r, state_w;
    reg           bossstate_r, bossstate_w;
    reg    [4:0]  mdstate_r;
    reg           switch_r;
    wire   [4:0]  modeLR;

    // reg    [4:0]  modeLR_1_r, modeLR_1_w, modeLR_2_r, modeLR_2_w, modeLR_3_r, modeLR_3_w, modeLR_4_r, modeLR_4_w; 
    // reg    [4:0]  modeLR_5_r, modeLR_5_w, modeLR_6_r, modeLR_6_w, modeLR_7_r, modeLR_7_w, modeLR_8_r, modeLR_8_w; 
     
    // reg    [4:0]  picnum_r, picnum_w ; 

    assign modeLR = (x < DISPSIZE / 5) ? R
    : ((x < DISPSIZE / 5 * 2 && x > DISPSIZE / 5) ? MR
    : ((x < DISPSIZE / 5 * 3 && x > DISPSIZE / 5 * 2) ? M
    : ((x < DISPSIZE / 5 * 4 && x > DISPSIZE / 5 * 3) ? ML
    : L
    )));

    assign picnum = (state_r == SMILING) ? mdstate_r + 5 : mdstate_r;
    assign isboss = (bossstate_r == WORK) ? BOSS : GAME;
    // assign picnum = picnum_r;

    always@(*) begin
        if (state_r == NORMAL) begin
            if (counter_r >= MAXTIME) begin
                counter_w = 27'b0;
                state_w = SMILING;
            end
            else if (mdstate_r == modeLR) begin
                counter_w = counter_r + 1;
                state_w = NORMAL;
            end
            else begin
                counter_w = 27'b0;
                state_w = NORMAL;
            end
        end
        else if (state_r == SMILING) begin
            counter_w = 27'b0;
            if (mdstate_r == modeLR) begin
                state_w = SMILING;
            end
            else begin
                state_w = NORMAL;
            end
        end


        // Boss Detector
        if (bossstate_r == PLAY) begin
            //bosscounter_w = 27'b0;
            if (mdstate_r == modeLR) begin
                bossstate_w = PLAY;
            end
            else begin
                bossstate_w = WORK;
            end
        end
        else if (bossstate_r == WORK) begin
            // if (bosscounter_r >= MAXTIME) begin
            //     bosscounter_w = 27'b0;
            //     bossstate_w = PLAY;
            // end
            // else if (mdstate_r == modeLR) begin
            //     bosscounter_w = bosscounter_r + 1;
            //     bossstate_w = WORK;
            // end
            // else begin
            //     bosscounter_w = 27'b0;
            //     bossstate_w = WORK;
            // end
            if (switch != switch_r) begin
                bossstate_w = PLAY;
            end
            else begin
                bossstate_w = WORK;
            end
        end
    end
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_r <= 27'b0;
            state_r <= NORMAL;
            mdstate_r <= modeLR;
            switch_r <= switch;
            bossstate_r <= PLAY;
            // bosscounter_r <= 27'b0;
        end
        else begin
            counter_r <= counter_w;
            state_r <= state_w;
            mdstate_r <= modeLR;
            switch_r <= switch;
            bossstate_r <= bossstate_w;
            // bosscounter_r <= bosscounter_w;
        end
    end

    // always@(*)
    //  begin
    //     modeLR_1_w = modeLR_2_r ;
    //     modeLR_2_w = modeLR_3_r ;
    //     modeLR_3_w = modeLR_4_r ;
    //     modeLR_4_w = modeLR_5_r ;
    //     modeLR_5_w = modeLR_6_r ;
    //     modeLR_6_w = modeLR_7_r ;
    //     modeLR_7_w = modeLR_8_r ;
    //     modeLR_8_w = modeLR ;
        
    //     if(modeLR_1_r == modeLR_2_r && modeLR_2_r == modeLR_3_r && modeLR_3_r == modeLR_4_r && modeLR_4_r == modeLR_5_r && modeLR_5_r == modeLR_6_r && modeLR_6_r == modeLR_7_r && modeLR_7_r == modeLR_8_r )
    //     begin
    //         picnum_w = modeLR_1_r ; 
    //     end
    //     else
    //     begin
    //         picnum_w = picnum_r ; 
    //     end 
    //  end
     
    //  always@(posedge clk)
    //  begin
    //     if(!rst_n)
    //     begin
    //         modeLR_1_r <= 0 ;
    //         modeLR_2_r <= 0 ;
    //         modeLR_3_r <= 0 ;
    //         modeLR_4_r <= 0 ;
    //         modeLR_5_r <= 0 ;
    //         modeLR_6_r <= 0 ;
    //         modeLR_7_r <= 0 ;
    //         modeLR_8_r <= 0 ;
    //         picnum_r   <= 0 ; 
    //     end
    //     else
    //     begin
    //         modeLR_1_r <= modeLR_1_w ;
    //         modeLR_2_r <= modeLR_2_w ;
    //         modeLR_3_r <= modeLR_3_w ;
    //         modeLR_4_r <= modeLR_4_w ;
    //         modeLR_5_r <= modeLR_5_w ;
    //         modeLR_6_r <= modeLR_6_w ;
    //         modeLR_7_r <= modeLR_7_w ;
    //         modeLR_8_r <= modeLR_8_w ;
    //         picnum_r   <= picnum_w   ; 
    //     end
    //  end
endmodule