
//`define DIV1
`define DIV2
//`define DIV3

`ifdef DIV2
    `define DEF_DIVIDER_DIV       (8'd2)        // output latency [clock]  1 : DIVIDEND_BITDEPTH,  2 : DIVIDEND_BITDEPTH / 2, ...
`elsif DIV3
    `define DEF_DIVIDER_DIV       (8'd3)        // output latency [clock]  1 : DIVIDEND_BITDEPTH,  2 : DIVIDEND_BITDEPTH / 2, ...
`else
    `define DEF_DIVIDER_DIV       (8'd1)       // output latency [clock]  1 : DIVIDEND_BITDEPTH,  2 : DIVIDEND_BITDEPTH / 2, ...
`endif

`define DEF_DIVIDEND_BITDEPTH     (8'd16                                      )      // always DIVIDEND_BIPDEPTH >= DIVISOR_BITDEPTH
`define DEF_DIVISOR_BITDEPTH      (8'd16                                      )
`define DEF_DIVIDER_COUNT         (`DEF_DIVIDEND_BITDEPTH / `DEF_DIVIDER_DIV  )      // output latency [clock]  1 : DIVIDEND_BITDEPTH,  2 : DIVIDEND_BITDEPTH / 2, ...
`define DEF_DIVIDER_REMAIN        (`DEF_DIVIDEND_BITDEPTH % `DEF_DIVIDER_DIV  )      // This value should be '0'