`timescale 10ns / 100ps

module dpsram_model #
(
    parameter P_INIT_FILE   =   ""              ,
    parameter P_LENGTH      =   16'd1024        ,
    parameter P_ADDR_LEN    =   16'd10          ,   // 2 ** P_ADDR_LEN >= P_LENGTH
    parameter P_BITDEPTH    =   16'd16          
)(
    input                       i_rdclk         ,
    input                       i_wrclk         ,
    input                       i_rden          ,
    input   [P_ADDR_LEN-1:0]    i_rdaddr        ,
    output  [P_BITDEPTH-1:0]    o_rddata        ,
    input                       i_wren          ,
    input   [P_ADDR_LEN-1:0]    i_wraddr        ,
    input   [P_BITDEPTH-1:0]    i_wrdata        
);

    reg [P_BITDEPTH - 1:0]      r_mem[0:P_LENGTH-1]   ;
    initial begin
        if(P_INIT_FILE != "")  begin
            $display("Initialzed[From file]... ");
            $readmemb("", r_mem);
        end
        else begin
            $display("Initialzed[0x00]... ");
            for(integer i = 0 ; i < P_LENGTH ; i=i+1) begin
                r_mem[i] = 0;
            end
        end
    end
    // Read Block
    reg  [P_BITDEPTH-1:0]    r_rddata                       ;
    always  @(posedge i_rdclk)
         if (i_rden)    r_rddata        <= r_mem[i_rdaddr]  ;
    // Write Block
    always  @(posedge i_wrclk)
         if (i_wren)    r_mem[i_wraddr] <=  i_wrdata        ;

    assign      o_rddata    =   r_rddata                    ;
endmodule
