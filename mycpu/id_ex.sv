`timescale 1ns / 1ps
`include "defines.vh"
module id_ex(
    input    logic                CLK,
    input    logic                RST,
    input    logic[          1:0] STALL,
    // 该信号指示id模块下一条将要译码的指令是否为延迟槽指令
    input    logic                ID_NINST_DS_FLAG_I,
    // 该信号指示当前传给ex模块的指令是否为延迟槽指令
    input    logic                ID_CINST_DS_FLAG,
    input    logic                ID_GPR_WE,
    input    logic[  `ALU_OP_BUS] ID_ALU_OP,
    input    logic[ `ALU_SEL_BUS] ID_ALU_SEL,
    input    logic[`REG_DATA_BUS] ID_REG1_DATA,
    input    logic[`REG_DATA_BUS] ID_REG2_DATA,
    input    logic[`REG_DATA_BUS] ID_INST,
    input    logic[`REG_ADDR_BUS] ID_GPR_WADDR,
    input    logic[`REG_DATA_BUS] ID_BRANCH_LINK_ADDR,
    
    output   logic                ID_NINST_DS_FLAG_O,
    output   logic                EX_CINST_DS_FLAG,
    output   logic                EX_GPR_WE,
    output   logic[  `ALU_OP_BUS] EX_ALU_OP,
    output   logic[ `ALU_SEL_BUS] EX_ALU_SEL,
    output   logic[`REG_DATA_BUS] EX_REG1_DATA,
    output   logic[`REG_DATA_BUS] EX_REG2_DATA,
    output   logic[`REG_DATA_BUS] EX_INST,
    output   logic[`REG_ADDR_BUS] EX_GPR_WADDR,
    output   logic[`REG_DATA_BUS] EX_BRANCH_LINK_ADDR
);
    logic                id_ninst_ds_flag_o;
    logic                ex_cinst_ds_flag;
    logic                ex_gpr_we;
    logic[  `ALU_OP_BUS] ex_alu_op;
    logic[ `ALU_SEL_BUS] ex_alu_sel;
    logic[`REG_DATA_BUS] ex_reg1_data;
    logic[`REG_DATA_BUS] ex_reg2_data;
    logic[`REG_DATA_BUS] ex_inst;
    logic[`REG_ADDR_BUS] ex_gpr_waddr;
    logic[`REG_DATA_BUS] ex_branch_link_addr;

    always_ff @(posedge CLK) begin: TRANSMISSION
        if (RST == `RST_EN) begin
            ex_alu_op           <= `EXE_NOP_OP;
            ex_alu_sel          <= `EXE_RES_NOP;
            ex_reg1_data        <= `ZERO_WORD;
            ex_reg2_data        <= `ZERO_WORD;
            ex_gpr_waddr        <= `REG_ZERO_ADDR;
            ex_gpr_we           <= ~`WE;
            ex_branch_link_addr <= `ZERO_WORD;
            id_ninst_ds_flag_o  <= `OUT_DELAY_SLOT;
            ex_cinst_ds_flag    <= `OUT_DELAY_SLOT;
        end else if (STALL[0] == `STOP && STALL[1] == `NOT_STOP) begin
            // 在ID阶段停滞而EX阶段运行时,不向EX阶段传递下一条指令
            ex_alu_op           <= `EXE_NOP_OP;
            ex_alu_sel          <= `EXE_RES_NOP;
            ex_reg1_data        <= `ZERO_WORD;
            ex_reg2_data        <= `ZERO_WORD;
            ex_inst             <= `ZERO_WORD;
            ex_gpr_waddr        <= `REG_ZERO_ADDR;
            ex_gpr_we           <= ~`WE;
            ex_branch_link_addr <= `ZERO_WORD;
            id_ninst_ds_flag_o  <= `OUT_DELAY_SLOT;
            ex_cinst_ds_flag    <= `OUT_DELAY_SLOT;
        end else if (STALL[0] == `NOT_STOP) begin
            ex_alu_op           <= ID_ALU_OP;
            ex_alu_sel          <= ID_ALU_SEL;
            ex_reg1_data        <= ID_REG1_DATA;
            ex_reg2_data        <= ID_REG2_DATA;
            ex_inst             <= ID_INST;
            ex_gpr_waddr        <= ID_GPR_WADDR;
            ex_gpr_we           <= ID_GPR_WE;
            ex_branch_link_addr <= ID_BRANCH_LINK_ADDR;
            id_ninst_ds_flag_o  <= ID_NINST_DS_FLAG_I;
            ex_cinst_ds_flag    <= ID_CINST_DS_FLAG;
        end else begin
            ex_alu_op           <= ex_alu_op;          
            ex_alu_sel          <= ex_alu_sel;         
            ex_reg1_data        <= ex_reg1_data;       
            ex_reg2_data        <= ex_reg2_data;       
            ex_inst             <= ex_inst;            
            ex_gpr_waddr        <= ex_gpr_waddr;       
            ex_gpr_we           <= ex_gpr_we;          
            ex_branch_link_addr <= ex_branch_link_addr;
            id_ninst_ds_flag_o  <= id_ninst_ds_flag_o; 
            ex_cinst_ds_flag    <= ex_cinst_ds_flag;   
        end
    end

    assign EX_ALU_OP           = ex_alu_op;
    assign EX_ALU_SEL          = ex_alu_sel;
    assign EX_REG1_DATA        = ex_reg1_data;
    assign EX_REG2_DATA        = ex_reg2_data;
    assign EX_INST             = ex_inst;
    assign EX_GPR_WADDR        = ex_gpr_waddr;
    assign EX_GPR_WE           = ex_gpr_we;
    assign EX_BRANCH_LINK_ADDR = ex_branch_link_addr;
    assign ID_NINST_DS_FLAG_O  = id_ninst_ds_flag_o;
    assign EX_CINST_DS_FLAG    = ex_cinst_ds_flag;
endmodule

