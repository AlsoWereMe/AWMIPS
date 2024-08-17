`timescale 1ns / 1ps
`include "defines.vh"

module pc(
    input   logic                  CLK,
    input   logic                  RST,
    input   logic                  STALL,
    input   logic                  BRANCH_FLAG,
    input   logic [ `CPU_ADDR_BUS] BRANCH_TAR_ADDR,
    output  logic                  SRAM_INST_CE,
    output  logic                  SRAM_INST_WE,
    output  logic [`SRAM_BSEL_BUS] SRAM_INST_BE,
    output  logic [`SRAM_DATA_BUS] SRAM_INST_WDATA,
    output  logic [ `CPU_ADDR_BUS] SRAM_INST_VADDR
);
    
    logic                 ce;
    logic [`CPU_ADDR_BUS] pc;

    always_ff @( posedge CLK ) begin : REG_MAINTENANCE
        if (RST == `RST_EN) begin
            ce <= ~`CE;
            pc <= `IF_INIT_ADDR;
        end else if (STALL == ~`STOP) begin
            ce <= `CE;
            if (BRANCH_FLAG == `GO_BRANCH) begin
                pc <= BRANCH_TAR_ADDR;
            end else begin
                pc <= pc + 32'h4;
            end
        end else begin
            ce <= ce;
            pc <= pc;
        end
    end
    assign SRAM_INST_CE      = ce;
    assign SRAM_INST_WE      = ~`WE;        // 恒不写
    assign SRAM_INST_BE      = `BE;         // 全字节使能
    assign SRAM_INST_WDATA   = `INST_NOOP;  // 无效指令
    assign SRAM_INST_VADDR   = pc;
endmodule
