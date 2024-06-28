`timescale 1ns / 1ps
`include "defines.vh"

/* 将从存储器中取出的指令暂存起来，下一个时钟周期到来时，将其传出，也就是说，"取指"这个操作,占用一个完整的时钟周期 */
module if_id(
    input logic             CLK,
    input logic             RST,
    input logic[1:0]        STALL,

    // 取指阶段取得的指令及其地址
    input logic[`INST_ADDR_BUS]   IF_PC,
    // 将由指令存储器传入
    input logic[`INST_DATA_BUS]   IF_INST, 

    // 输出给译码阶段的指令及其地址
    output logic[`INST_ADDR_BUS]  ID_PC,
    output logic[`INST_DATA_BUS]  ID_INST
    );
    always_ff @(posedge CLK) begin : INST_TRANSMIT
        if (RST == `RST_EN) begin
            ID_PC   <= `ZERO_WORD;
            ID_INST <= `ZERO_WORD;
        end else if (STALL[0] == `STOP && STALL[1] == `NOT_STOP) begin
            // 假如IF阶段停滞而ID阶段继续执行,不给ID阶段传下一条指令的信息
            ID_PC   <= `ZERO_WORD;
            ID_INST <= `ZERO_WORD;
        end else if (STALL[0] == `NOT_STOP)begin
            ID_PC   <= IF_PC;
            ID_INST <= IF_INST;
        end
    end
endmodule
