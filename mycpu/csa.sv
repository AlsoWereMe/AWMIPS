`timescale 1ns / 1ps
`include "defines.vh"

/* 三级保留进位加法器模块 */
/* 此部分代码设计思路参考https://github.com/SocialistDalao/UltraMIPS_NSCSCC/blob/master/FinalSubmission/csa.v */
module csa(         
    input   logic[63:0] ADDER1, // 第一个加数
    input   logic[63:0] ADDER2, // 第二个加数
    input   logic[63:0] ADDER3, // 第三个加数
    output  logic[63:0] SUM,    // 和
    output  logic[63:0] CARRY   // 进位
    );

    genvar i;
    generate
        for (i = 0; i < 64; i = i + 1) begin : gen_csa
            assign SUM[i] = ADDER1[i] ^ ADDER2[i] ^ ADDER3[i];
            assign CARRY[i] = (ADDER1[i] & ADDER2[i]) | (ADDER2[i] & ADDER3[i]) | (ADDER3[i] & ADDER1[i]);
        end
    endgenerate
endmodule
