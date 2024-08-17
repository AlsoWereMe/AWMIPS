`timescale 1ns / 1ps
`include "defines.vh"
/* 访存需要一个周期的时间,IC级和DF级均用以匹配这个周期以让数据能被在合适的周期处理 */
module ic(
        input   logic                 RST,
        input   logic [`CPU_ADDR_BUS] PC_I,
        input   logic                 IV_I,
        output  logic [`CPU_ADDR_BUS] PC_O,
        output  logic                 IV_O
    );
    always_comb begin : TRANSMIT
        if (RST == `RST_EN) begin
            PC_O = `ZERO_WORD;
            IV_O = ~`INST_VALID;
        end else begin
            PC_O = PC_I;
            IV_O = IV_I;
        end
    end
endmodule
