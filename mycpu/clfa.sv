`timescale 1ns / 1ps
`include "defines.vh"

/* 1bit先行进位全加器模块 */
module clfa(
    input   logic ADDER1,
    input   logic ADDER2,
    input   logic CARRY_I,
    output   logic GENER,
    output   logic PROPA,
    output   logic SUM,
    output   logic CARRY_O
    );

    assign SUM = ADDER1 ^ ADDER2 ^ CARRY_I;
    assign CARRY_O = (ADDER1 & ADDER2) | (ADDER1 & CARRY_I) | (ADDER2 & CARRY_I);
    assign GENER = ADDER1 & ADDER2;
    assign PROPA = ADDER1 | ADDER2;
endmodule
