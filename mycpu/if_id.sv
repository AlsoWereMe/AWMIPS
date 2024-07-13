`timescale 1ns / 1ps
`include "defines.vh"

module if_id(
    input   logic                  CLK,
    input   logic                  RST,
    input   logic [           1:0] STALL,
    input   logic [`SRAM_ADDR_BUS ] IF_PC,
    input   logic [`SRAM_DATA_BUS] IF_INST, 

    output   logic [`SRAM_ADDR_BUS ] ID_PC,
    output   logic [`SRAM_DATA_BUS] ID_INST
    );

    always_ff @(posedge CLK) begin : INST_TRANSMIT
        if (RST == `RST_EN) begin
            ID_PC   <= `ZERO_WORD;
            ID_INST <= `ZERO_WORD;
        end else if (STALL[0] == `STOP && STALL[1] == `NOT_STOP) begin
            // 假如IF阶段停滞而ID阶段继续执行,不给ID阶段传下一条指令的信息
            ID_PC   <= `ZERO_WORD;
            ID_INST <= `ZERO_WORD;
        end else if (STALL[0] == `NOT_STOP)begin
            ID_PC   <= IF_PC;
            ID_INST <= IF_INST;
        end
    end
endmodule
