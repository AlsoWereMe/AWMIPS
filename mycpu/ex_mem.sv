`timescale 1ns / 1ps
`include "defines.vh"

module ex_mem(
    input   logic                  CLK,
    input   logic                  RST,
    input   logic [           1:0] STALL,
    input   logic [   `ALU_OP_BUS] EX_ALU_OP,
    input   logic                  EX_GPR_WE,
    input   logic [ `REG_DATA_BUS] EX_GPR_WDATA,
    input   logic [ `REG_ADDR_BUS] EX_GPR_WADDR,
    input   logic [`SRAM_DATA_BUS] EX_SRAM_WDATA,
    input   logic [`SRAM_ADDR_BUS] EX_SRAM_ADDR,
    
    output  logic [   `ALU_OP_BUS] MEM_ALU_OP,
    output  logic                  MEM_GPR_WE,
    output  logic [ `REG_DATA_BUS] MEM_GPR_WDATA,
    output  logic [ `REG_ADDR_BUS] MEM_GPR_WADDR,
    output  logic [`SRAM_DATA_BUS] MEM_SRAM_WDATA,
    output  logic [`SRAM_ADDR_BUS] MEM_SRAM_ADDR
    );

    logic [   `ALU_OP_BUS] mem_alu_op;
    logic                  mem_gpr_we;
    logic [ `REG_DATA_BUS] mem_gpr_wdata;
    logic [ `REG_ADDR_BUS] mem_gpr_waddr;
    logic [`SRAM_DATA_BUS] mem_sram_wdata;
    logic [`SRAM_ADDR_BUS] mem_sram_addr;

    always_ff @(posedge CLK) begin : TRANSMISSION
        if(RST == `RST_EN) begin
            mem_alu_op     <= `EXE_NOP_OP;
            mem_sram_wdata <= `ZERO_WORD;
            mem_sram_addr  <= `ZERO_WORD;
            mem_gpr_waddr  <= `REG_ZERO_ADDR;
            mem_gpr_wdata  <= `ZERO_WORD;
            mem_gpr_we     <= ~`WE;
        end else if (STALL[0] == `STOP && STALL[1] == `NOT_STOP) begin
            // 在EX阶段停滞而MEM阶段运行时,不向MEM阶段传递下一条指令
            mem_alu_op     <= `EXE_NOP_OP;
            mem_sram_wdata <= `ZERO_WORD;
            mem_sram_addr  <= `ZERO_WORD;
            mem_gpr_waddr  <= `REG_ZERO_ADDR;
            mem_gpr_wdata  <= `ZERO_WORD;
            mem_gpr_we     <= ~`WE;
        end else if (STALL[0] == `NOT_STOP) begin
            mem_alu_op     <= EX_ALU_OP;
            mem_sram_wdata <= EX_SRAM_WDATA;
            mem_sram_addr  <= EX_SRAM_ADDR;
            mem_gpr_waddr  <= EX_GPR_WADDR;
            mem_gpr_wdata  <= EX_GPR_WDATA;
            mem_gpr_we     <= EX_GPR_WE;
        end else begin
            mem_alu_op     <= mem_alu_op;
            mem_sram_wdata <= mem_sram_wdata;
            mem_sram_addr  <= mem_sram_addr;
            mem_gpr_waddr  <= mem_gpr_waddr;
            mem_gpr_wdata  <= mem_gpr_wdata;
            mem_gpr_we     <= mem_gpr_we;
        end
    end

    assign MEM_ALU_OP     = mem_alu_op;
    assign MEM_SRAM_WDATA = mem_sram_wdata;
    assign MEM_SRAM_ADDR  = mem_sram_addr;
    assign MEM_GPR_WADDR  = mem_gpr_waddr;
    assign MEM_GPR_WDATA  = mem_gpr_wdata;
    assign MEM_GPR_WE     = mem_gpr_we;
endmodule
