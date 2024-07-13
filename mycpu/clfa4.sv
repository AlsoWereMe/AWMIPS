`timescale 1ns / 1ps
`include "defines.vh"

/* 4bit先行进位全加器模块 */
/* verilator lint_off UNUSED */
module clfa4(
    input   logic[3:0] ADDER1,
    input   logic[3:0] ADDER2,
    input   logic      CARRY_I,
    output   logic      GENER,
    output   logic      PROPA,
    output   logic[3:0] SUM,
    output   logic[3:0] CARRY_O
    );

    logic[3:0] propagation;
    logic[3:0] generation;
    logic[3:0] carry;
    logic      temp_carry;

    // 最高进位以寄存器保留输出
    assign CARRY_O[3] = carry[3];

    clfa u_clfa_0 (
        .ADDER1   (ADDER1[0]      ),
        .ADDER2   (ADDER2[0]      ),
        .CARRY_I  (CARRY_I        ),
        .GENER    (generation[0]  ),
        .PROPA    (propagation[0] ),
        .SUM      (SUM[0]         ),
        .CARRY_O  (CARRY_O[0]     )
    );

    clfa u_clfa_1 (
        .ADDER1   (ADDER1[1]      ),
        .ADDER2   (ADDER2[1]      ),
        .CARRY_I  (carry[0]       ),
        .GENER    (generation[1]  ),
        .PROPA    (propagation[1] ),
        .SUM      (SUM[1]         ),
        .CARRY_O  (CARRY_O[1]     )
    );

    clfa u_clfa_2 (
        .ADDER1   (ADDER1[2]      ),
        .ADDER2   (ADDER2[2]      ),
        .CARRY_I  (carry[1]       ),
        .GENER    (generation[2]  ),
        .PROPA    (propagation[2] ),
        .SUM      (SUM[2]         ),
        .CARRY_O  (CARRY_O[2]     )
    );

    clfa u_clfa_3 (
        .ADDER1   (ADDER1[3]      ),
        .ADDER2   (ADDER2[3]      ),
        .CARRY_I  (carry[2]       ),
        .GENER    (generation[3]  ),
        .PROPA    (propagation[3] ),
        .SUM      (SUM[3]         ),
        .CARRY_O  (temp_carry     )
    );

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
