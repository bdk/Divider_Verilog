`timescale 10ns/100ps

`include "../00_rtl/divider_setup.v"         // File for the simulation condition 
                                             // Before operating simulation, you should modify this file.

module tb;
    parameter CLK_FREQ  = 10                 ;
    parameter VALID_NUM = 40                 ;    
    parameter R_VALID_LOW_LENGTH  = 30       ;

    initial begin
     if (`DEF_DIVIDER_REMAIN != 0) begin
          $display("[Error] DIVIDER_REMAIN is not '0'");
          $finish;
     end
    end

    reg i_rstn = 1'd0;
    reg i_sclk = 1'd0;
    reg r_data = 1'd0;
    
    always #(CLK_FREQ/2) i_sclk = ~i_sclk;

    reg [ 31:0]     r_vb_cnt            ;
    reg [ 31:0]     r_vld_high_ref_cnt  ;
    reg [ 31:0]     r_vld_high_cnt      ;
    reg [ 31:0]     r_vld_low_cnt       ;
    reg [ 31:0]     r_vld_num_cnt       ;    
    
    reg             r_active_area   ;
    reg                                 r_valid        ;
    reg                                 r_valid_d      ;
    reg   [`DEF_DIVIDEND_BITDEPTH-1:0]  r_dividend     ;
    reg   [ `DEF_DIVISOR_BITDEPTH-1:0]  r_divisor      ;
    wire                                w_output_valid ;
    wire  [`DEF_DIVIDEND_BITDEPTH-1:0]  w_quotient     ;
    wire  [`DEF_DIVIDEND_BITDEPTH-1:0]  w_remainder    ;    

    always  @(posedge i_sclk or negedge i_rstn)
         if (!i_rstn)   r_vb_cnt <= 32'd0               ;
    else if (!r_valid)  r_vb_cnt <= #1 r_vb_cnt + 32'd1 ;
    else                r_vb_cnt <= #1 32'd0            ;

    wire    w_vld_start     = r_vb_cnt == 32'd500           ;         // reset condition
    wire    w_vld_num_rst   = r_vld_num_cnt == VALID_NUM    ;         // simulation done flag
    always  @(posedge i_sclk or negedge i_rstn)
         if (!i_rstn)       r_active_area   <= 1'd0     ;
    else if (w_vld_num_rst) r_active_area   <= #1 1'd0  ;
    else if (w_vld_start)   r_active_area   <= #1 1'd1  ;

    always  @(posedge i_sclk or negedge i_rstn)
         if (!i_rstn)   r_vld_high_ref_cnt <= 32'd0                             ;
    else if (w_vld_f)   r_vld_high_ref_cnt <= #1 r_vld_high_ref_cnt + 32'd1     ;

    always  @(posedge i_sclk or negedge i_rstn)
         if (!i_rstn)   r_vld_high_cnt <= 32'd0                     ;
    else if (r_valid)   r_vld_high_cnt <= #1 r_vld_high_cnt + 32'd1 ;
    else                r_vld_high_cnt <= #1 32'd0                  ;

    always  @(posedge i_sclk or negedge i_rstn)
         if (!i_rstn)   r_vld_low_cnt <= 32'd0                     ;
    else if (!r_valid)  r_vld_low_cnt <= #1 r_vld_low_cnt + 32'd1  ;
    else                r_vld_low_cnt <= #1 32'd0                  ;

    wire    w_vld_rst   =   r_vld_high_cnt == r_vld_high_ref_cnt                    ;
    wire    w_vld_ac_st =   r_vld_low_cnt == R_VALID_LOW_LENGTH && r_active_area    ;
    always  @(posedge i_sclk or negedge i_rstn)
         if (!i_rstn)       r_valid <= 1'd0     ;
    else if (w_vld_start)   r_valid <= #1 1'd1  ;
    else if (w_vld_rst)     r_valid <= #1 1'd0  ;
    else if (w_vld_ac_st)   r_valid <= #1 1'd1  ;

    wire    w_vld_r     =   r_valid && !r_valid_d   ;
    wire    w_vld_f     =  !r_valid &&  r_valid_d   ;
    always  @(posedge i_sclk or negedge i_rstn)
         if (!i_rstn)       r_valid_d   <=  1'd0        ;
    else                    r_valid_d   <= #1 r_valid   ;

    always  @(posedge i_sclk or negedge i_rstn)
         if (!i_rstn)       r_vld_num_cnt <= 32'd0                     ;
    else if (w_vld_num_rst) r_vld_num_cnt <= #1 32'd0                  ;
    else if (w_vld_f)       r_vld_num_cnt <= #1 r_vld_num_cnt + 32'd1  ;

     always  @(posedge i_sclk or negedge i_rstn)
          if (!i_rstn)       r_dividend <= {(`DEF_DIVISOR_BITDEPTH){1'd0}}       ;
     else if (r_valid)       r_dividend <= #1 ($random % 65536) ;

     always  @(posedge i_sclk or negedge i_rstn)
          if (!i_rstn)       r_divisor <= {(`DEF_DIVISOR_BITDEPTH){1'd0}}       ;
     else if (r_valid)       r_divisor <= #1 ($random % 2 == 1) ? ($random % 65536) + 1 :  ($random % 32) + 1 ;

    divider # (
        .DIVIDEND_BITDEPTH   (`DEF_DIVIDEND_BITDEPTH  ),       // always DIVIDEND_BIPDEPTH >= DIVISOR_BITDEPTH
        .DIVISOR_BITDEPTH    (`DEF_DIVISOR_BITDEPTH   ),
        .DIVIDER_DIV         (`DEF_DIVIDER_DIV        ),       // output latency [clock]  1 : DIVIDEND_BITDEPTH,  2 : DIVIDEND_BITDEPTH / 2, ...
        .DIVIDER_COUNT       (`DEF_DIVIDER_COUNT      ),       // output latency [clock]  1 : DIVIDEND_BITDEPTH,  2 : DIVIDEND_BITDEPTH / 2, ...
        .DIVIDER_REMAIN      (`DEF_DIVIDER_REMAIN     )        // Should be '0'
    ) u_divider (
        .i_rstn              (i_rstn        ),
        .i_sclk              (i_sclk        ),
        .i_input_valid       (r_valid_d     ),
        .i_dividend          (r_dividend    ),
        .i_divisor           (r_divisor     ),
        .o_output_valid      (w_output_valid),
        .o_quotient          (w_quotient    ),
        .o_remainder         (w_remainder   )
);

     initial begin
          $dumpfile("divider.vcd");
          $dumpvars(-1,tb);  //  
     end

     integer div_input_info_file  ;
     integer div_input_file       ;
     integer div_output_file      ;
     initial begin
          div_input_info_file = $fopen("div_input_info.txt", "w");
          div_input_file = $fopen("div_input.txt", "w");
          div_output_file = $fopen("div_output.txt", "w");
     end

     always @(posedge i_sclk)
          if (r_valid_d) $fwrite(div_input_info_file, "Dividend : %d\tDivisor : %d\tQuotient : %d\tRemainder : %d\n", r_dividend, r_divisor,r_dividend / r_divisor,r_dividend %r_divisor );  

     always @(posedge i_sclk)
          if (r_valid_d) $fwrite(div_input_file, "[Input_Calc] \tQuotient : %d\tRemainder : %d\n", r_dividend / r_divisor,r_dividend %r_divisor );  

     always @(posedge i_sclk)
          if (w_output_valid) $fwrite(div_output_file, "[Output_Sim] \tQuotient : %d\tRemainder : %d\n", w_quotient,w_remainder );

     initial begin
          #10 i_rstn = 1'd1;
          #2000;
          @(w_vld_num_rst);
          #2000;
          $fclose(div_input_info_file);
          $fclose(div_input_file);
          $fclose(div_output_file);
          $finish;
     end
//iverilog -o divider.vvp divider.v divider_tb.v
//vvp divider.vvp
//gtkwave divider.vcd
endmodule