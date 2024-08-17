`timescale 1ns / 1ps
`include "defines.vh"
module id_ex(
    input    logic                 CLK,
    input    logic                 RST,
    input    logic [          1:0] STALL,
    input    logic                 ID_GPR_WE,
    input    logic [  `ALU_OP_BUS] ID_ALU_OP,
    input    logic [ `ALU_SEL_BUS] ID_ALU_SEL,
    input    logic [`REG_DATA_BUS] ID_REG1_DATA,
    input    logic [`REG_DATA_BUS] ID_REG2_DATA,
    input    logic [         15:0] ID_IMM,
    input    logic [`REG_ADDR_BUS] ID_GPR_WADDR,
    input    logic [`REG_DATA_BUS] ID_BRANCH_LINK_ADDR,
     
    output   logic                 EX_GPR_WE,
    output   logic [`REG_ADDR_BUS] EX_GPR_WADDR,
    output   logic [`REG_DATA_BUS] EX_REG1_DATA,
    output   logic [`REG_DATA_BUS] EX_REG2_DATA,
    output   logic [         15:0] EX_IMM,
    output   logic [  `ALU_OP_BUS] EX_ALU_OP,
    output   logic [ `ALU_SEL_BUS] EX_ALU_SEL,
    output   logic [`REG_DATA_BUS] EX_BRANCH_LINK_ADDR
); 

    logic                 ex_gpr_we;
    logic [  `ALU_OP_BUS] ex_alu_op;
    logic [ `ALU_SEL_BUS] ex_alu_sel;
    logic [`REG_DATA_BUS] ex_reg1_data;
    logic [`REG_DATA_BUS] ex_reg2_data;
    logic [         15:0] ex_imm;
    logic [`REG_ADDR_BUS] ex_gpr_waddr;
    logic [`REG_DATA_BUS] ex_branch_link_addr;

    always_ff @( posedge CLK ) begin: REGISTER_MAINTENANCE
        if (RST == `RST_EN) begin
            ex_gpr_we           <= ~`WE;
            ex_gpr_waddr        <= `REG_ZERO_ADDR;
            ex_reg1_data        <= `ZERO_WORD;
            ex_reg2_data        <= `ZERO_WORD;
            ex_imm              <= `ZERO_HFWD;
            ex_alu_op           <= `EXE_NOP_OP;
            ex_alu_sel          <= `EXE_RES_NOP;            
            ex_branch_link_addr <= `ZERO_WORD;
        end else if (STALL[0] == ~`STOP) begin
            ex_gpr_we           <= ID_GPR_WE;
            ex_gpr_waddr        <= ID_GPR_WADDR;
            ex_reg1_data        <= ID_REG1_DATA;
            ex_reg2_data        <= ID_REG2_DATA;
            ex_imm              <= ID_IMM;
            ex_alu_op           <= ID_ALU_OP;
            ex_alu_sel          <= ID_ALU_SEL;
            ex_branch_link_addr <= ID_BRANCH_LINK_ADDR;
        end else if (STALL[1] == ~`STOP) begin
            ex_gpr_we           <= ~`WE;
            ex_gpr_waddr        <= `REG_ZERO_ADDR;
            ex_reg1_data        <= `ZERO_WORD;
            ex_reg2_data        <= `ZERO_WORD;
            ex_imm              <= `ZERO_HFWD;
            ex_alu_op           <= `EXE_NOP_OP;
            ex_alu_sel          <= `EXE_RES_NOP;
            ex_branch_link_addr <= `ZERO_WORD;
        end else begin
            ex_gpr_we           <= ex_gpr_we;          
            ex_gpr_waddr        <= ex_gpr_waddr;       
            ex_reg1_data        <= ex_reg1_data;       
            ex_reg2_data        <= ex_reg2_data;       
            ex_imm              <= ex_imm;            
            ex_alu_op           <= ex_alu_op;          
            ex_alu_sel          <= ex_alu_sel;         
            ex_branch_link_addr <= ex_branch_link_addr;
        end
    end  
    assign EX_GPR_WE           = ex_gpr_we;
    assign EX_GPR_WADDR        = ex_gpr_waddr;
    assign EX_REG1_DATA        = ex_reg1_data;
    assign EX_REG2_DATA        = ex_reg2_data;
    assign EX_IMM              = ex_imm;
    assign EX_ALU_OP           = ex_alu_op;
    assign EX_ALU_SEL          = ex_alu_sel;
    assign EX_BRANCH_LINK_ADDR = ex_branch_link_addr;
endmodule

