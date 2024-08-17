`timescale 1ns / 1ps
`include "defines.vh"
module df(
    input   logic                  RST,
    input   logic                  GPR_WE_I,
    input   logic [ `REG_ADDR_BUS] GPR_WADDR_I,
    input   logic [ `REG_DATA_BUS] GPR_WDATA_I,
    input   logic [`SRAM_BSEL_BUS] SRAM_DATA_BE_I,
    input   logic [   `ALU_OP_BUS] ALU_OP_I,
    output  logic                  GPR_WE_O,
    output  logic [ `REG_ADDR_BUS] GPR_WADDR_O,
    output  logic [ `REG_DATA_BUS] GPR_WDATA_O, 
    output  logic [`SRAM_BSEL_BUS] SRAM_DATA_BE_O,
    output  logic [   `ALU_OP_BUS] ALU_OP_O
);

    always_comb begin : TRANSMISSTION
        if (RST == `RST_EN) begin
            ALU_OP_O       = `EXE_NOP_OP;
            GPR_WE_O       = ~`WE;
            GPR_WADDR_O    = `REG_ZERO_ADDR;
            GPR_WDATA_O    = `ZERO_WORD;
            SRAM_DATA_BE_O = ~`BE;
        end else begin
            ALU_OP_O       = ALU_OP_I;
            GPR_WE_O       = GPR_WE_I;
            GPR_WADDR_O    = GPR_WADDR_I;
            GPR_WDATA_O    = GPR_WDATA_I;
            SRAM_DATA_BE_O = SRAM_DATA_BE_I;
        end
    end
endmodule
