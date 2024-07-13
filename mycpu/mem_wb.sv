`timescale 1ns / 1ps
`include "defines.vh"

module mem_wb(
    input   logic                 RST,
    input   logic                 CLK,
    input   logic [1:0]           STALL,
    input   logic                 MEM_GPR_WE,
    input   logic [`REG_DATA_BUS] MEM_GPR_WDATA,
    input   logic [`REG_ADDR_BUS] MEM_GPR_WADDR,

    output  logic                 WB_GPR_WE,
    output  logic [`REG_DATA_BUS] WB_GPR_WDATA,
    output  logic [`REG_ADDR_BUS] WB_GPR_WADDR
    );

    logic [`REG_DATA_BUS] wb_wdata;
    logic [`REG_ADDR_BUS] wb_waddr;
    logic                 wb_wen;

    always_ff @(posedge CLK) begin
        if(RST == `RST_EN) begin
            wb_waddr <= `REG_ZERO_ADDR;
            wb_wdata <= `ZERO_WORD;
            wb_wen   <= ~`WE;
        end else if (STALL[0] == `STOP && STALL[1] == `NOT_STOP) begin
            wb_waddr <= `REG_ZERO_ADDR;
            wb_wdata <= `ZERO_WORD;
            wb_wen   <= ~`WE;
        end else if (STALL[0] == `NOT_STOP) begin
            wb_waddr <= MEM_GPR_WADDR;
            wb_wdata <= MEM_GPR_WDATA;
            wb_wen   <= MEM_GPR_WE;
        end else begin
            wb_waddr <= wb_waddr;
            wb_wdata <= wb_wdata;
            wb_wen   <= wb_wen;
        end
    end

    assign WB_GPR_WDATA = wb_wdata;
    assign WB_GPR_WADDR = wb_waddr;
    assign WB_GPR_WE    = wb_wen;
endmodule
