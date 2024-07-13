`timescale 1ns / 1ps
`include "defines.vh"

module stall_ctrl(
    input   logic             RST,
    input   logic             STALL_REQ_ID,
    input   logic             STALL_REQ_EX,
    input   logic             STALL_REQ_MEM,
    output  logic[`STALL_BUS] STALL
);

always_comb begin : STALL_HANDLE
    if (RST == `RST_EN) begin
        STALL = 6'b00000;
    end else if (STALL_REQ_ID == `STOP) begin
        STALL = `STALL_ID;
    end else if (STALL_REQ_EX == `STOP) begin
        STALL = `STALL_EX;
    end else if (STALL_REQ_MEM == `STOP) begin
        STALL = `STALL_MEM;
    end else begin
        STALL = 6'b00000;
    end
end
endmodule
