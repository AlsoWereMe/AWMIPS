`timescale 1ns / 1ps
`include "defines.vh"

/* 64bit全加器模块 */
/* 此部分代码实现思路参考https://github.com/SocialistDalao/UltraMIPS_NSCSCC/blob/master/FinalSubmission/fa64.v */
/* verilator lint_off UNUSED */
module fa64(
    input  logic[63:0] ADDER1,
    input  logic[63:0] ADDER2,
    input  logic       CARRY_I,
    input  logic       IS_SUB,
    output logic[63:0] SUM,
    output logic[63:0] CARRY_O
    );
    
    logic[63:0] adder2_comple;
    // real_carry存储最低部分的进位
    logic       real_carry;
    // propagation存储4个部分的传递信号
    logic[3:0]  propagation;
    logic[3:0]  generation;
    logic       temp_propa;
    logic       temp_gener;
    // carry存储后三个部分的进位
        // carry[0] -> C16
        // carry[1] -> C32
        // carry[2] -> C48
    logic[3:0]  carry;

    // 检测是减法还是加法
    assign adder2_comple = IS_SUB ? ~ADDER2 : ADDER2;
    assign real_carry = IS_SUB ^ CARRY_I;

    // 将双字拆分为4个部分并行计算
        // 小端法最低有效双字节为[15:0]
    // [15:0]加法计算
        // 假如是减法,将进位取反
    clfa16 u_clfa16_0 (
        .ADDER1 (ADDER1[15:0]         ),
        .ADDER2 (adder2_comple[15:0]  ),
        .CARRY_I(real_carry           ),
        .GENER  (generation[0]        ),
        .PROPA  (propagation[0]       ),
        .SUM    (SUM[15:0]            ),
        .CARRY_O(CARRY_O[15:0]        )
    );
    // [31:16]加法计算
    clfa16 u_clfa16_1(
        .ADDER1 (ADDER1[31:16]          ), 
        .ADDER2 (adder2_comple[31:16]   ), 
        .CARRY_I(carry[0]               ), 
        .GENER  (generation[1]          ), 
        .PROPA  (propagation[1]         ), 
        .SUM    (SUM[31:16]             ), 
        .CARRY_O(CARRY_O[31:16]         )
    );
    // [47:32]加法计算
    clfa16 u_clfa16_2(
        .ADDER1 (ADDER1[47:32]          ), 
        .ADDER2 (adder2_comple[47:32]   ), 
        .CARRY_I(carry[1]               ), 
        .GENER  (generation[2]          ), 
        .PROPA  (propagation[2]         ), 
        .SUM    (SUM[47:32]             ), 
        .CARRY_O(CARRY_O[47:32]         )
    );
    // [63:48]加法计算
    clfa16 u_clfa16_3 (
        .ADDER1 (ADDER1[63:48]        ),
        .ADDER2 (adder2_comple[63:48] ),
        .CARRY_I(carry[2]             ),
        .GENER  (generation[3]        ),
        .PROPA  (propagation[3]       ),
        .SUM    (SUM[63:48]           ),
        .CARRY_O(CARRY_O[63:48]       )
    );
    // 计算4个fa16的进位
    cla4 u_cla4(
        .PROPA_I(propagation), 
        .GENER_I(generation ), 
        .CARRY_I(CARRY_I    ), 
        .CARRY_O(carry      ), 
        .PROPA_O(temp_propa ), 
        .GENER_O(temp_gener )
    );
endmodule
/* verilator lint_off UNUSED */
