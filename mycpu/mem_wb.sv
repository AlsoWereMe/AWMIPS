`timescale 1ns / 1ps
`include "defines.vh"

/* 访存-写回 */
module mem_wb(
    input   logic                   RST,
    input   logic                   CLK,
    // 暂停信号输入
    input   logic[1:0]              STALL,
    // 存储器信号输出
    input   logic[`REG_DATA_BUS]    MEM_WDATA,
    input   logic[`REG_ADDR_BUS]    MEM_WADDR,
    input   logic                   MEM_WEN,
    input   logic[`REG_DATA_BUS]    MEM_HI,
    input   logic[`REG_DATA_BUS]    MEM_LO,
    input   logic                   MEM_WEN_HILO,
    // 写回信号输出
    output  logic[`REG_DATA_BUS]    WB_WDATA,
    output  logic[`REG_ADDR_BUS]    WB_WADDR,
    output  logic                   WB_WEN,
    output  logic[`REG_DATA_BUS]    WB_HI,
    output  logic[`REG_DATA_BUS]    WB_LO,
    output  logic                   WB_WEN_HILO
    );

    always_ff @(posedge CLK) begin
        if(RST == `RST_EN) begin
            WB_WADDR    <= `ZERO_ADDR;
            WB_WDATA    <= `ZERO_WORD;
            WB_WEN      <= `WDISABLE;
            WB_HI       <= `ZERO_WORD;
            WB_LO       <= `ZERO_WORD;
            WB_WEN_HILO <= `WDISABLE;
        end else if (STALL[0] == `STOP && STALL[1] == `NOT_STOP) begin
            // 在MEM阶段停滞而WB阶段运行时,不向WB阶段传递下一条指令
            WB_WADDR    <= `ZERO_ADDR;
            WB_WDATA    <= `ZERO_WORD;
            WB_WEN      <= `WDISABLE;
            WB_HI       <= `ZERO_WORD;
            WB_LO       <= `ZERO_WORD;
            WB_WEN_HILO <= `WDISABLE;
        end else if (STALL[0] == `NOT_STOP) begin
            WB_WADDR    <= MEM_WADDR;
            WB_WDATA    <= MEM_WDATA;
            WB_WEN      <= MEM_WEN;
            WB_HI       <= MEM_HI;
            WB_LO       <= MEM_LO;
            WB_WEN_HILO <= MEM_WEN_HILO;
        end
    end
endmodule
