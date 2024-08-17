`timescale 1ns / 1ps
`include "defines.vh"

module ex_df(
    input   logic                  CLK,
    input   logic                  RST,
    input   logic [           1:0] STALL,
    input   logic [   `ALU_OP_BUS] EX_ALU_OP,
    input   logic                  EX_GPR_WE,
    input   logic [ `REG_DATA_BUS] EX_GPR_WDATA,
    input   logic [ `REG_ADDR_BUS] EX_GPR_WADDR,
    input   logic [`SRAM_BSEL_BUS] EX_SRAM_DATA_BE,
    output  logic                  DF_GPR_WE,
    output  logic [ `REG_DATA_BUS] DF_GPR_WDATA,
    output  logic [ `REG_ADDR_BUS] DF_GPR_WADDR,
    output  logic [`SRAM_BSEL_BUS] DF_SRAM_DATA_BE,
    output  logic [   `ALU_OP_BUS] DF_ALU_OP
);

    logic                  df_gpr_we;
    logic [ `REG_DATA_BUS] df_gpr_wdata;
    logic [ `REG_ADDR_BUS] df_gpr_waddr;
    logic [`SRAM_BSEL_BUS] df_sram_data_be;
    logic [   `ALU_OP_BUS] df_alu_op;

    always_ff @( posedge CLK ) begin : REGISTER_MAINTENANCE
        if(RST == `RST_EN) begin
            df_alu_op       <= `EXE_NOP_OP;
            df_gpr_we       <= ~`WE;
            df_gpr_wdata    <= `ZERO_WORD;
            df_gpr_waddr    <= `REG_ZERO_ADDR;
            df_sram_data_be <= ~`BE;
        end else if (STALL[0] == ~`STOP) begin
            df_alu_op       <= EX_ALU_OP;
            df_gpr_we       <= EX_GPR_WE;
            df_gpr_wdata    <= EX_GPR_WDATA;
            df_gpr_waddr    <= EX_GPR_WADDR;
            df_sram_data_be <= EX_SRAM_DATA_BE;
        end else if (STALL[1] == ~`STOP) begin
            df_alu_op       <= `EXE_NOP_OP;
            df_gpr_we       <= ~`WE;
            df_gpr_wdata    <= `ZERO_WORD;
            df_gpr_waddr    <= `REG_ZERO_ADDR;
            df_sram_data_be <= ~`BE;
        end else begin
            df_alu_op       <= df_alu_op;
            df_gpr_we       <= df_gpr_we;
            df_gpr_wdata    <= df_gpr_wdata;
            df_gpr_waddr    <= df_gpr_waddr;
            df_sram_data_be <= df_sram_data_be;
        end
    end
    assign DF_ALU_OP        = df_alu_op;
    assign DF_GPR_WE        = df_gpr_we;
    assign DF_GPR_WDATA     = df_gpr_wdata;
    assign DF_GPR_WADDR     = df_gpr_waddr;
    assign DF_SRAM_DATA_BE  = df_sram_data_be;
endmodule
