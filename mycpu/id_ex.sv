`timescale 1ns / 1ps
`include "defines.vh"

/* id_ex模块是译码到执行阶段的中继模块，即为寄存器模块 */
/* 存储id模块向执行模块传递的信息，在下一个时钟上升沿到来时传给执行阶段 */
module id_ex(
    input   logic   CLK,
    input   logic   RST,
    // 暂停信号输入
    input   logic[1:0]        STALL,
    // 译码阶段信息
    // 该信号由id模块输入,指示id模块下一条将要译码的指令是否为延迟槽指令
    input   logic                   ID2_INST_DS_FLAG_I,
    // 该信号由id模块输入,指示当前传给ex模块的指令是否为延迟槽指令
    input   logic                   ID_CUR_INST_DS_FLAG,
    input   logic[`REG_DATA_BUS]    ID_BRANCH_LINK_ADDR,
    input   logic[`ALU_OP_BUS]      ID_ALU_OP,
    input   logic[`ALU_SEL_BUS]     ID_ALU_SEL,
    input   logic[`REG_DATA_BUS]    ID_REG1_DATA,
    input   logic[`REG_DATA_BUS]    ID_REG2_DATA,
    input   logic[`REG_DATA_BUS]    ID_INST,
    input   logic[`REG_ADDR_BUS]    ID_WADDR,
    input   logic                   ID_WEN,
    
    /* 执行阶段信息 */
    // 该信号输出给id模块,指示下一条译码指令是否为延迟槽指令
    output  logic                   ID2_INST_DS_FLAG_O,
    // 该信号输出给ex模块,指示当前执行的指令是否为延迟槽指令
    output  logic                   EX_CUR_INST_DS_FLAG,
    output  logic[`REG_DATA_BUS]    EX_BRANCH_LINK_ADDR,
    output  logic[`ALU_OP_BUS]      EX_ALU_OP,
    output  logic[`ALU_SEL_BUS]     EX_ALU_SEL,
    output  logic[`REG_DATA_BUS]    EX_REG1_DATA,
    output  logic[`REG_DATA_BUS]    EX_REG2_DATA,
    output  logic[`REG_DATA_BUS]    EX_INST,
    output  logic[`REG_ADDR_BUS]    EX_WADDR,
    output  logic                   EX_WEN
);

always_ff @(posedge CLK) begin : Transmit_Information
    if(RST == `RST_EN) begin
        EX_ALU_OP      <= `EXE_NOP_OP;
        EX_ALU_SEL     <= `EXE_RES_NOP;
        EX_REG1_DATA   <= `ZERO_WORD;
        EX_REG2_DATA   <= `ZERO_WORD;
        EX_WADDR       <= `NOP_Reg_Addr;
        EX_WEN         <= `WDISABLE;
        EX_BRANCH_LINK_ADDR <= `ZERO_WORD;
        ID2_INST_DS_FLAG_O  <= `OUT_DELAY_SLOT;
        EX_CUR_INST_DS_FLAG <= `OUT_DELAY_SLOT;
    end else if (STALL[0] == `STOP && STALL[1] == `NOT_STOP) begin
        // 在ID阶段停滞而EX阶段运行时,不向EX阶段传递下一条指令
        EX_ALU_OP      <= `EXE_NOP_OP;
        EX_ALU_SEL     <= `EXE_RES_NOP;
        EX_REG1_DATA   <= `ZERO_WORD;
        EX_REG2_DATA   <= `ZERO_WORD;
        EX_INST        <= `ZERO_WORD;
        EX_WADDR       <= `NOP_Reg_Addr;
        EX_WEN         <= `WDISABLE;
        EX_BRANCH_LINK_ADDR <= `ZERO_WORD;
        ID2_INST_DS_FLAG_O  <= `OUT_DELAY_SLOT;
        EX_CUR_INST_DS_FLAG <= `OUT_DELAY_SLOT;
    end else if (STALL[0] == `NOT_STOP) begin
        EX_ALU_OP      <= ID_ALU_OP;
        EX_ALU_SEL     <= ID_ALU_SEL;
        EX_REG1_DATA   <= ID_REG1_DATA;
        EX_REG2_DATA   <= ID_REG2_DATA;
        EX_INST        <= ID_INST;
        EX_WADDR       <= ID_WADDR;
        EX_WEN         <= ID_WEN;
        EX_BRANCH_LINK_ADDR <= ID_BRANCH_LINK_ADDR;
        ID2_INST_DS_FLAG_O  <= ID2_INST_DS_FLAG_I;
        EX_CUR_INST_DS_FLAG <= ID_CUR_INST_DS_FLAG;
    end
end
endmodule
