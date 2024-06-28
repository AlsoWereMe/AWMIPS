`timescale 1ns / 1ps
`include "defines.vh"

module hilo_reg(
    input   logic   CLK,
    input   logic   RST,

    input   logic   WEN,
    input   logic[`REG_DATA_BUS]    HI_DATA_I,
    input   logic[`REG_DATA_BUS]    LO_DATA_I,

    output  logic[`REG_DATA_BUS]    HI_DATA_O,
    output  logic[`REG_DATA_BUS]    LO_DATA_O
    );

    logic[`REG_DATA_BUS]    hi;
    logic[`REG_DATA_BUS]    lo;
    assign HI_DATA_O = hi;
    assign LO_DATA_O = lo;
    
    always_ff @( posedge CLK ) begin : FunctionPart
        if (RST == `RST_EN) begin
            hi <= `ZERO_WORD;
            lo <= `ZERO_WORD;
        end else if(WEN == `WENABLE) begin
            // 假如复位无效且能写，存储新值并将新写入的值直接作为新值输出
            hi <= HI_DATA_I;
            lo <= LO_DATA_I;
        end
    end
endmodule
