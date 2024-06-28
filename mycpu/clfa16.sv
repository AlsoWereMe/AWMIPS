`timescale 1ns / 1ps
`include "defines.vh"

/* 16bit先行进位全加器模块 */
/* verilator lint_off UNUSED */
module clfa16(
    input   logic[15:0] ADDER1,
    input   logic[15:0] ADDER2,
    input   logic       CARRY_I,
    output  logic       GENER,
    output  logic       PROPA,
    output  logic[15:0] SUM,
    output  logic[15:0] CARRY_O
    );

    logic[3:0] propagation;
    logic[3:0] generation;
    logic[3:0] carry;

    // [3:0]加法计算
    clfa4 u_clfa4_0 (
        .ADDER1   (ADDER1[3:0]    ),
        .ADDER2   (ADDER2[3:0]    ),
        .CARRY_I  (CARRY_I        ),
        .GENER    (generation[0]  ),
        .PROPA    (propagation[0] ),
        .SUM      (SUM[3:0]       ),
        .CARRY_O  (CARRY_O[3:0]   )
    );

    // [7:4]加法计算
    clfa4 u_clfa4_1 (
        .ADDER1   (ADDER1[7:4]    ),
        .ADDER2   (ADDER2[7:4]    ),
        .CARRY_I  (carry[0]       ),
        .GENER    (generation[1]  ),
        .PROPA    (propagation[1] ),
        .SUM      (SUM[7:4]       ),
        .CARRY_O  (CARRY_O[7:4]   )
    );

    // [11:8]加法计算
    clfa4 u_clfa4_2 (
        .ADDER1   (ADDER1[11:8]   ),
        .ADDER2   (ADDER2[11:8]   ),
        .CARRY_I  (carry[1]       ),
        .GENER    (generation[2]  ),
        .PROPA    (propagation[2] ),
        .SUM      (SUM[11:8]      ),
        .CARRY_O  (CARRY_O[11:8]  )
    );

    // [15:12]加法计算
    clfa4 u_clfa4_3 (
        .ADDER1   (ADDER1[15:12]  ),
        .ADDER2   (ADDER2[15:12]  ),
        .CARRY_I  (carry[2]       ),
        .GENER    (generation[3]  ),
        .PROPA    (propagation[3] ),
        .SUM      (SUM[15:12]     ),
        .CARRY_O  (CARRY_O[15:12] )
    );

    // 计算4个fa4的进位
    cla4 u_cla4 (
        .PROPA_I  (propagation    ),
        .GENER_I  (generation     ),
        .CARRY_I  (CARRY_I        ),
        .CARRY_O  (carry          ),
        .GENER_O  (GENER          ),
        .PROPA_O  (PROPA          )
    );
endmodule
/* verilator lint_off UNUSED */
