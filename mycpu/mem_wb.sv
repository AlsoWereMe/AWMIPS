`timescale 1ns / 1ps
`include "defines.vh"

module mem_wb(
    input   logic                 RST,
    input   logic                 CLK,
    input   logic [          1:0] STALL,
    input   logic                 MEM_GPR_WE,
    input   logic [`REG_ADDR_BUS] MEM_GPR_WADDR,
    input   logic [`REG_DATA_BUS] MEM_GPR_WDATA,
    output  logic                 WB_GPR_WE,
    output  logic [`REG_ADDR_BUS] WB_GPR_WADDR,
    output  logic [`REG_DATA_BUS] WB_GPR_WDATA
);

    logic                 wb_we;
    logic [`REG_DATA_BUS] wb_wdata;
    logic [`REG_ADDR_BUS] wb_waddr;

    always_ff @( posedge CLK ) begin : REGISTER_MAINTENANCE
        if(RST == `RST_EN) begin
            wb_we    <= ~`WE;
            wb_waddr <= `REG_ZERO_ADDR;
            wb_wdata <= `ZERO_WORD;
        end else if (STALL[0] == ~`STOP) begin
            wb_we    <= MEM_GPR_WE;
            wb_waddr <= MEM_GPR_WADDR;
            wb_wdata <= MEM_GPR_WDATA;
        end else if (STALL[1] == ~`STOP) begin
            wb_we    <= ~`WE;
            wb_waddr <= `REG_ZERO_ADDR;
            wb_wdata <= `ZERO_WORD;
        end else begin
            wb_we    <= wb_we;
            wb_waddr <= wb_waddr;
            wb_wdata <= wb_wdata;
        end
    end
    assign WB_GPR_WE    = wb_we;
    assign WB_GPR_WADDR = wb_waddr;
    assign WB_GPR_WDATA = wb_wdata;
endmodule
