`timescale 1ns / 1ps
`include "defines.vh"
module pc_reg(
    input   logic                    CLK,
    input   logic                    RST,
    input   logic                    STALL,
    input   logic                    BRANCH_FLAG,
    input   logic[`REG_DATA_BUS]     BRANCH_TAR,
    output  logic[`INST_ADDR_BUS]    PC,
    output  logic                    CE
    );

    always_ff @(posedge CLK) begin : CHIP_VALUE
        if (RST == `RST_EN) begin
            CE <= `CDISABLE;
        end else begin
            CE <= `CENABLE;
        end
    end

    always_ff @(posedge CLK) begin : PC_VALUE
        if (CE == `CDISABLE) begin
            PC <= `ZERO_WORD;
        end else if (STALL == `NOT_STOP) begin 
            if (BRANCH_FLAG == `GO_BRANCH) begin
                PC <= BRANCH_TAR;
            end else begin
                PC <= PC + 32'h4;
            end
        end
    end
    
endmodule
