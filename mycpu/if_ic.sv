`timescale 1ns / 1ps
`include "defines.vh"

module if_ic(
    input   logic                 CLK,
    input   logic                 RST,
    input   logic [          1:0] STALL,
    input   logic                 BRANCH_FLAG,
    input   logic [`CPU_ADDR_BUS] IF_PC,
    output  logic                 IC_IV,
    output  logic [`CPU_ADDR_BUS] IC_PC
);
    /* 
     * 问题: 由于长流水的级数问题,ID阶段发起跳转请求时IF阶段已经将跳转指令后的第二条指令取出,但龙芯杯只要求支持一条延迟槽指令,那么这第二条指令需要作废
     * 策略: 于是在IF_IC寄存器中添加对跳转信号的判断与IV信号的输出,若跳转则该条指令无效,IV信号对应无效,在IC_ID寄存器中检测IV信号即可
     */
    logic                 ic_inst_valid;
    logic [`CPU_ADDR_BUS] ic_pc;
    always_ff @( posedge CLK ) begin : REGISTER_MAINTENANCE
        if (RST == `RST_EN) begin
            ic_pc         <= `ZERO_WORD;
            ic_inst_valid <= ~`INST_VALID;
        end else if (STALL[0] == ~`STOP) begin
            ic_pc <= IF_PC;
            if (BRANCH_FLAG == `GO_BRANCH) begin
                ic_inst_valid <= ~`INST_VALID;
            end else begin
                ic_inst_valid <= `INST_VALID;
            end
        end else if (STALL[1] == ~`STOP) begin 
            ic_pc         <= `ZERO_WORD;
            ic_inst_valid <= ~`INST_VALID;
        end else begin
            ic_pc         <= ic_pc;
            ic_inst_valid <= ic_inst_valid;
        end
    end
    assign IC_PC = ic_pc;
    assign IC_IV = ic_inst_valid;  
endmodule
