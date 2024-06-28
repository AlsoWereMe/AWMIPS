`timescale 1ns / 1ps
`include "defines.vh"

/* 执行-访存阶段的过渡 */
/* 每当一个上升沿到来,传值 */
module ex_mem(
    input   logic                   CLK,
    input   logic                   RST,
    // 暂停信号输入
    input  logic[1:0]               STALL,
    // 执行阶段传入信息
    input   logic[`ALU_OP_BUS]      EX_ALU_OP,
    input   logic[`REG_DATA_BUS]    EX_SDATA,
    input   logic[`REG_DATA_BUS]    EX_LSADDR,
    input   logic[`REG_DATA_BUS]    EX_WDATA,
    input   logic[`REG_ADDR_BUS]    EX_WADDR,
    input   logic                   EX_WEN,
    input   logic[`REG_DATA_BUS]    EX_HI,
    input   logic[`REG_DATA_BUS]    EX_LO,
    input   logic                   EX_WEN_HILO,
    // 传给访存阶段的信息
    output  logic[`ALU_OP_BUS]      MEM_ALU_OP,
    output  logic[`REG_DATA_BUS]    MEM_SDATA,
    output  logic[`REG_DATA_BUS]    MEM_LSADDR,
    output  logic[`REG_DATA_BUS]    MEM_WDATA,
    output  logic[`REG_ADDR_BUS]    MEM_WADDR,
    output  logic                   MEM_WEN,
    output  logic[`REG_DATA_BUS]    MEM_HI,
    output  logic[`REG_DATA_BUS]    MEM_LO,
    output  logic                   MEM_WEN_HILO
    );

    /* 传递指令 */
    always_ff @(posedge CLK) begin : TRANSMIT_SIGNAL
        if(RST == `RST_EN) begin
            MEM_ALU_OP   <= `EXE_NOP_OP;
            MEM_SDATA    <= `ZERO_WORD;
            MEM_LSADDR   <= `ZERO_WORD;
            MEM_WADDR    <= `ZERO_ADDR;
            MEM_WDATA    <= `ZERO_WORD;
            MEM_WEN      <= `WDISABLE;
            MEM_HI       <= `ZERO_WORD;
            MEM_LO       <= `ZERO_WORD;
            MEM_WEN_HILO <= `WDISABLE;
        end else if (STALL[0] == `STOP && STALL[1] == `NOT_STOP) begin
            // 在EX阶段停滞而MEM阶段运行时,不向MEM阶段传递下一条指令
            MEM_ALU_OP   <= `EXE_NOP_OP;
            MEM_SDATA    <= `ZERO_WORD;
            MEM_LSADDR   <= `ZERO_WORD;
            MEM_WADDR    <= `ZERO_ADDR;
            MEM_WDATA    <= `ZERO_WORD;
            MEM_WEN      <= `WDISABLE;
            MEM_HI       <= `ZERO_WORD;
            MEM_LO       <= `ZERO_WORD;
            MEM_WEN_HILO <= `WDISABLE;
        end else if (STALL[0] == `NOT_STOP) begin
            MEM_ALU_OP   <= EX_ALU_OP;
            MEM_SDATA    <= EX_SDATA;
            MEM_LSADDR   <= EX_LSADDR;
            MEM_WADDR    <= EX_WADDR;
            MEM_WDATA    <= EX_WDATA;
            MEM_WEN      <= EX_WEN;
            MEM_HI       <= EX_HI;
            MEM_LO       <= EX_LO;
            MEM_WEN_HILO <= EX_WEN_HILO;
        end
    end
endmodule
