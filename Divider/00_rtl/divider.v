`timescale 10ns / 100ps

`include "../00_rtl/divider_setup.v"

module divider #
(
    parameter   DIVIDEND_BITDEPTH   = `DEF_DIVIDEND_BITDEPTH  ,       // always DIVIDEND_BIPDEPTH >= DIVISOR_BITDEPTH
    parameter   DIVISOR_BITDEPTH    = `DEF_DIVISOR_BITDEPTH   ,
    parameter   DIVIDER_DIV         = `DEF_DIVIDER_DIV        ,       // output latency [clock]  1 : DIVIDEND_BITDEPTH,  2 : DIVIDEND_BITDEPTH / 2, ...
    parameter   DIVIDER_COUNT       = `DEF_DIVIDER_COUNT      ,       // DIVIDEND_BIPDEPTH / DIVIDER_DIV
    parameter   DIVIDER_REMAIN      = `DEF_DIVIDER_REMAIN             // DIVIDEND_BIPDEPTH % DIVIDER_DIV ###### NOT USED #####
)(
    input                           i_rstn          ,
    input                           i_sclk          ,
    input                           i_input_valid   ,
    input   [DIVIDEND_BITDEPTH-1:0] i_dividend      ,
    input   [ DIVISOR_BITDEPTH-1:0] i_divisor       ,
    output                          o_output_valid  ,
    output  [DIVIDEND_BITDEPTH-1:0] o_quotient      ,
    output  [DIVIDEND_BITDEPTH-1:0] o_remainder     
);
    reg     [DIVIDER_COUNT-1:0]     r_input_valid_d;

    wire    w_vld_upd   =   i_input_valid || (|r_input_valid_d);
    always @(posedge i_sclk or negedge i_rstn) 
         if (!i_rstn)   r_input_valid_d <= {DIVIDER_COUNT{1'd0}};
    else if (w_vld_upd) r_input_valid_d <= #1 {r_input_valid_d[DIVIDER_COUNT-2:0], i_input_valid};

    wire    [DIVIDEND_BITDEPTH:0]       w_dividend[0:DIVIDEND_BITDEPTH-1]   ;    
    wire    [DIVISOR_BITDEPTH-1:0]      w_divisor[0:DIVIDEND_BITDEPTH-1]    ;    
    wire    [DIVIDEND_BITDEPTH-1:0]     w_quotient                          ;
    wire    [DIVIDEND_BITDEPTH:0]       w_remainder[0:DIVIDEND_BITDEPTH-1]  ;    

    reg     [DIVIDEND_BITDEPTH:0]       r_dividend[0:DIVIDER_COUNT-1]       ;
    reg     [DIVISOR_BITDEPTH-1:0]      r_divisor[0:DIVIDER_COUNT-1]        ;
    reg     [DIVIDEND_BITDEPTH-1:0]     r_quotient[0:DIVIDER_COUNT-1]       ;
    reg     [DIVIDEND_BITDEPTH:0]       r_remainder[0:DIVIDER_COUNT-1]      ;

    wire    [DIVIDER_COUNT-1:0]         w_div_upd   ;

    `ifdef DIV2
        assign w_dividend[0]  =   {{(DIVIDEND_BITDEPTH){1'd0}} , i_dividend[DIVIDEND_BITDEPTH-1]}               ; 
        assign w_divisor[0]   =   {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, i_divisor}                     ;
        assign w_quotient[1]  =   w_dividend[0] < w_divisor[0] ? 1'd0 : 1'd1                                    ;
        assign w_remainder[0] =   w_quotient[1] ? w_dividend[0] - w_divisor[0] : w_dividend[0]                  ;

        assign w_dividend[1]  =  {w_remainder[0], i_dividend[DIVIDEND_BITDEPTH-2]}                              ;    
        assign w_divisor[1]   =   {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, i_divisor}                     ;
        assign w_quotient[0]  =   w_dividend[1] < w_divisor[1] ? 1'd0 : 1'd1                                    ;
        assign w_remainder[1] =   w_quotient[0] ? w_dividend[1] - w_divisor[1] : w_dividend[1]                  ;
    `elsif DIV3
        assign w_dividend[0]  =  {{(DIVIDEND_BITDEPTH){1'd0}} ,   i_dividend[DIVIDEND_BITDEPTH-1]}              ; 
        assign w_divisor[0]   =   {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, i_divisor}                     ;
        assign w_quotient[2]  =   w_dividend[0] < w_divisor[0] ? 1'd0 : 1'd1                                    ;
        assign w_remainder[0] =   w_quotient[2] ? w_dividend[0] - w_divisor[0] : w_dividend[0]                  ;

        assign w_dividend[1]  =  {w_remainder[0], i_dividend[DIVIDEND_BITDEPTH-2]}                              ;    
        assign w_divisor[1]   =   {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, i_divisor}                     ;
        assign w_quotient[1]  =   w_dividend[1] < w_divisor[1] ? 1'd0 : 1'd1                                    ;
        assign w_remainder[1] =   w_quotient[1] ? w_dividend[1] - w_divisor[1] : w_dividend[1]                  ;

        assign w_dividend[2]  =  {w_remainder[1], i_dividend[DIVIDEND_BITDEPTH-3]}                              ;    
        assign w_divisor[2]   =   {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, i_divisor}                     ;
        assign w_quotient[0]  =   w_dividend[2] < w_divisor[2] ? 1'd0 : 1'd1                                    ;
        assign w_remainder[2] =   w_quotient[0] ? w_dividend[2] - w_divisor[2] : w_dividend[2]                  ;
    `else
        assign w_dividend[0]  =  {{(DIVIDEND_BITDEPTH){1'd0}} ,   i_dividend[DIVIDEND_BITDEPTH-1]}              ; 
        assign w_divisor[0]   =  {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, i_divisor}                      ;
        assign w_quotient[0]  =  w_dividend[0] < w_divisor[0] ? 1'd0 : 1'd1                                     ;
        assign w_remainder[0] =  w_quotient[0] ? w_dividend[0] - w_divisor[0] : w_dividend[0]                   ;
    `endif

    always  @(posedge i_sclk or negedge i_rstn)
        if (!i_rstn) begin
            r_dividend[0]   <=  {(DIVIDEND_BITDEPTH+1){1'd0}}     ;
            r_divisor[0]    <=  {(DIVISOR_BITDEPTH){1'd0}}      ;
            r_quotient[0]   <=  {(DIVIDEND_BITDEPTH){1'd0}}     ;
            r_remainder[0]  <=  {(DIVIDEND_BITDEPTH+1){1'd0}}     ;
        end
    else if(i_input_valid)   begin
            r_dividend[0]   <=  #1 {1'd0, i_dividend[DIVIDEND_BITDEPTH-1-DIVIDER_DIV:0] , {DIVIDER_DIV{1'd0}}}  ;
            r_divisor[0]    <=  #1 w_divisor[0]                                                                 ;
            r_quotient[0]   <=  #1 {{(DIVIDEND_BITDEPTH-DIVIDER_DIV){1'd0}}, w_quotient[DIVIDER_DIV-1:0]}       ;
            r_remainder[0]  <=  #1 w_remainder[DIVIDER_DIV-1]                                                   ;
        end

    genvar i;
    generate for ( i = 0 ; i < DIVIDER_COUNT - 1 ; i=i+1) begin : loop_for_divider
        assign  w_div_upd[i] = r_input_valid_d[i]      ;

    `ifdef DIV2
        assign w_dividend[(i+1)*DIVIDER_DIV]    = {r_remainder[i], r_dividend[i][DIVIDEND_BITDEPTH-1]}                                                          ;    
        assign w_divisor[(i+1)*DIVIDER_DIV]     = {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, r_divisor[i]}                                                  ;
        assign w_quotient[(i+1)*DIVIDER_DIV+1]  = w_dividend[(i+1)*DIVIDER_DIV] < w_divisor[(i+1)*DIVIDER_DIV] ? 1'd0 : 1'd1                                    ;
        assign w_remainder[(i+1)*DIVIDER_DIV]   = w_quotient[(i+1)*DIVIDER_DIV+1] ? w_dividend[(i+1)*DIVIDER_DIV] - w_divisor[(i+1)*DIVIDER_DIV]: 
                                                                                    w_dividend[(i+1)*DIVIDER_DIV]                                               ;

        assign w_dividend[(i+1)*DIVIDER_DIV+1]  = {w_remainder[(i+1)*DIVIDER_DIV], r_dividend[i][DIVIDEND_BITDEPTH-2]}                   ;    
        assign w_divisor[(i+1)*DIVIDER_DIV+1]   = {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, r_divisor[i]}                                                  ;
        assign w_quotient[(i+1)*DIVIDER_DIV]    = w_dividend[(i+1)*DIVIDER_DIV+1] < w_divisor[(i+1)*DIVIDER_DIV+1] ? 1'd0 : 1'd1                                ;
        assign w_remainder[(i+1)*DIVIDER_DIV+1] = w_quotient[(i+1)*DIVIDER_DIV] ? w_dividend[(i+1)*DIVIDER_DIV+1] - w_divisor[(i+1)*DIVIDER_DIV+1]: 
                                                                                  w_dividend[(i+1)*DIVIDER_DIV+1]                                               ;
    `elsif DIV3
        assign w_dividend[(i+1)*DIVIDER_DIV]    = {r_remainder[i], r_dividend[i][DIVIDEND_BITDEPTH-1]}                                                          ;    
        assign w_divisor[(i+1)*DIVIDER_DIV]     = {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, r_divisor[i]}                                                  ;
        assign w_quotient[(i+1)*DIVIDER_DIV+2]  = w_dividend[(i+1)*DIVIDER_DIV] < w_divisor[(i+1)*DIVIDER_DIV] ? 1'd0 : 1'd1                                    ;
        assign w_remainder[(i+1)*DIVIDER_DIV]   = w_quotient[(i+1)*DIVIDER_DIV+2] ? w_dividend[(i+1)*DIVIDER_DIV] - w_divisor[(i+1)*DIVIDER_DIV]: 
                                                                                    w_dividend[(i+1)*DIVIDER_DIV]                                               ;

        assign w_dividend[(i+1)*DIVIDER_DIV+1]  = {w_remainder[(i+1)*DIVIDER_DIV], r_dividend[i][DIVIDEND_BITDEPTH-2]}                   ;    
        assign w_divisor[(i+1)*DIVIDER_DIV+1]   = {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, r_divisor[i]}                                                  ;
        assign w_quotient[(i+1)*DIVIDER_DIV+1]  = w_dividend[(i+1)*DIVIDER_DIV+1] < w_divisor[(i+1)*DIVIDER_DIV+1] ? 1'd0 : 1'd1                                ;
        assign w_remainder[(i+1)*DIVIDER_DIV+1] = w_quotient[(i+1)*DIVIDER_DIV+1] ? w_dividend[(i+1)*DIVIDER_DIV+1] - w_divisor[(i+1)*DIVIDER_DIV+1]: 
                                                                                    w_dividend[(i+1)*DIVIDER_DIV+1]                                             ;

        assign w_dividend[(i+1)*DIVIDER_DIV+2]  = {w_remainder[(i+1)*DIVIDER_DIV+1], r_dividend[i][DIVIDEND_BITDEPTH-3]}                 ;    
        assign w_divisor[(i+1)*DIVIDER_DIV+2]   = {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, r_divisor[i]}                                                  ;
        assign w_quotient[(i+1)*DIVIDER_DIV]    = w_dividend[(i+1)*DIVIDER_DIV+2] < w_divisor[(i+1)*DIVIDER_DIV+2] ? 1'd0 : 1'd1                                ;
        assign w_remainder[(i+1)*DIVIDER_DIV+2] = w_quotient[(i+1)*DIVIDER_DIV] ? w_dividend[(i+1)*DIVIDER_DIV+2] - w_divisor[(i+1)*DIVIDER_DIV+2]: 
                                                                                  w_dividend[(i+1)*DIVIDER_DIV+2]                                               ;
    `else
        assign w_dividend[(i+1)*DIVIDER_DIV]    = {r_remainder[i], r_dividend[i][DIVIDEND_BITDEPTH-1]}                                                          ;    
        assign w_divisor[(i+1)*DIVIDER_DIV]     = {{(DIVIDEND_BITDEPTH-DIVISOR_BITDEPTH){1'd0}}, r_divisor[i]}                                                  ;
        assign w_quotient[(i+1)*DIVIDER_DIV]    = w_dividend[(i+1)*DIVIDER_DIV] < w_divisor[(i+1)*DIVIDER_DIV] ? 1'd0 : 1'd1                                    ;
        assign w_remainder[(i+1)*DIVIDER_DIV]   = w_quotient[(i+1)*DIVIDER_DIV] ? w_dividend[(i+1)*DIVIDER_DIV] - w_divisor[(i+1)*DIVIDER_DIV]: 
                                                                                  w_dividend[(i+1)*DIVIDER_DIV]                                                 ;
    `endif
        always  @(posedge i_sclk or negedge i_rstn)
        if (!i_rstn) begin
            r_dividend[i+1]   <=  {(DIVIDEND_BITDEPTH){1'd0}}       ;
            r_divisor[i+1]    <=  {(DIVIDEND_BITDEPTH){1'd0}}       ;
            r_quotient[i+1]   <=  {(DIVIDEND_BITDEPTH){1'd0}}       ;
            r_remainder[i+1]  <=  {(DIVIDEND_BITDEPTH){1'd0}}       ;
        end
        else if(w_div_upd[i])   begin
            r_dividend[i+1]   <=  #1 {r_dividend[i][DIVIDEND_BITDEPTH:0] , {DIVIDER_DIV{1'd0}} }                                                                                          ; 
            r_divisor[i+1]    <=  #1 r_divisor[i]                                                                                                                                           ;
            r_quotient[i+1]   <=  #1 {{(DIVIDEND_BITDEPTH-(i+2)*DIVIDER_DIV){1'd0}}, r_quotient[i][(i+1)*DIVIDER_DIV-1:0], w_quotient[(i+1)*DIVIDER_DIV+DIVIDER_DIV-1:(i+1)*DIVIDER_DIV]}   ;
            r_remainder[i+1]  <=  #1 w_remainder[(i+1)*DIVIDER_DIV+(DIVIDER_DIV-1)]                                                                                                         ;
        end
    end
    endgenerate

    assign          o_output_valid  =   r_input_valid_d[DIVIDER_COUNT-1] ;
    assign          o_quotient      =   r_quotient[DIVIDER_COUNT-1]      ;
    assign          o_remainder     =   r_remainder[DIVIDER_COUNT-1]     ;
endmodule
