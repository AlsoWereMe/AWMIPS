`timescale 1ns/1ps
`include "defines.vh"
module df_mem(
    input  logic                  CLK,
    input  logic                  RST,
    input  logic [           1:0] STALL,
    input  logic                  DF_GPR_WE,
    input  logic [ `REG_ADDR_BUS] DF_GPR_WADDR,
    input  logic [ `REG_DATA_BUS] DF_GPR_WDATA, 
    input  logic [`SRAM_BSEL_BUS] DF_SRAM_DATA_BE,
    input  logic [`SRAM_DATA_BUS] SRAM_RDATA,
    input  logic [   `ALU_OP_BUS] DF_ALU_OP,
    output logic                  MEM_GPR_WE,
    output logic [ `REG_ADDR_BUS] MEM_GPR_WADDR,
    output logic [ `REG_DATA_BUS] MEM_GPR_WDATA, 
    output logic [`SRAM_BSEL_BUS] MEM_SRAM_DATA_BE,
    output logic [`SRAM_DATA_BUS] MEM_SRAM_DATA,
    output logic [   `ALU_OP_BUS] MEM_ALU_OP
);
    
    logic                  gpr_we;
    logic [ `REG_ADDR_BUS] gpr_waddr;
    logic [ `REG_DATA_BUS] gpr_wdata; 
    logic [`SRAM_BSEL_BUS] sram_data_be;
    logic [`SRAM_DATA_BUS] sram_rdata;
    logic [   `ALU_OP_BUS] alu_op;

    always_ff @( posedge CLK ) begin : REGISTER_MAINTENANCE
        if (RST == `RST_EN) begin
            alu_op          = `EXE_NOP_OP;
            gpr_we          = ~`WE;
            gpr_waddr       = `REG_ZERO_ADDR;
            gpr_wdata       = `ZERO_WORD;
            sram_data_be    = ~`BE;
            sram_rdata      = `ZERO_WORD;
        end else if (STALL[0] == ~`STOP) begin
            alu_op          = DF_ALU_OP;
            gpr_we          = DF_GPR_WE;
            gpr_waddr       = DF_GPR_WADDR;
            gpr_wdata       = DF_GPR_WDATA;
            sram_data_be    = DF_SRAM_DATA_BE;
            sram_rdata      = SRAM_RDATA;
        end else if (STALL[1] == ~`STOP) begin
            alu_op          = `EXE_NOP_OP;
            gpr_we          = ~`WE;
            gpr_waddr       = `REG_ZERO_ADDR;
            gpr_wdata       = `ZERO_WORD;
            sram_data_be    = ~`BE;
            sram_rdata      = `ZERO_WORD;
        end else begin
            alu_op          = alu_op;         
            gpr_we          = gpr_we;         
            gpr_waddr       = gpr_waddr;      
            gpr_wdata       = gpr_wdata;      
            sram_data_be    = sram_data_be;   
            sram_rdata      = sram_rdata;     
        end
    end
    assign MEM_ALU_OP          = alu_op;
    assign MEM_GPR_WE          = gpr_we;
    assign MEM_GPR_WADDR       = gpr_waddr;
    assign MEM_GPR_WDATA       = gpr_wdata;
    assign MEM_SRAM_DATA_BE    = sram_data_be;
    assign MEM_SRAM_DATA       = sram_rdata;
endmodule