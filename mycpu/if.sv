`timescale 1ns / 1ps
`include "defines.vh"
module pc(
    input   logic                  CLK,
    input   logic                  RST,
    input   logic                  STALL,
    input   logic                  BRANCH_FLAG,
    input   logic [`SRAM_ADDR_BUS] BRANCH_TAR_ADDR,
    output  logic                  CE,
    output  logic [`SRAM_ADDR_BUS] PC
    );
    logic ce_reg;
    logic [`SRAM_ADDR_BUS] pc_reg;
    
    always_ff @(posedge CLK) begin : CHIP_VALUE
        if (RST == `RST_EN) begin
            ce_reg <= ~`CE;
        end else begin
            ce_reg <= `CE;
        end
    end
    assign CE = ce_reg;

    always_ff @(posedge CLK) begin : PC_VALUE
        if (RST == ~`RST_EN) begin
            pc_reg <= `ZERO_WORD;
        end else if (STALL == `NOT_STOP) begin 
            if (BRANCH_FLAG == `GO_BRANCH) begin
                pc_reg <= BRANCH_TAR_ADDR;
            end else begin
                pc_reg <= pc_reg + 32'h4;
            end
        end else begin
            pc_reg <= pc_reg;
        end
    end
    assign PC = pc_reg;
endmodule
