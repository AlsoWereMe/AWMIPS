`timescale 1ns / 1ps
`include "defines.vh"

/* 优化后Booth算法模块 */
/* 本模块代码结构参考https://github.CARRYom/SoCARRYialistDalao/UltraMIPS_NSCARRYSCARRYCARRY/blob/master/FinalSubmission/booth2.v*/
module booth(
    input   logic[32:0]    MULTIPLICAND,    // 被乘数
    input   logic[2:0]     MULTIPLIER_3,    // 乘数的三位
    output  logic[63:0]    PARTIAL_PRODUCT, // 部分积
    output  logic[1:0]     CARRY            // 进位
    );
    logic[32:0] multiplicand_not;
    assign multiplicand_not = ~MULTIPLICAND;
    always_comb begin : BOOTH
        // 三位乘数决定部分积的值
        case(MULTIPLIER_3)
            3'b011: begin
                PARTIAL_PRODUCT = {{30{MULTIPLICAND[32]}}, MULTIPLICAND, 1'b0};
                CARRY = 2'b00;
            end
            3'b100: begin
                PARTIAL_PRODUCT = {{30{multiplicand_not[32]}}, multiplicand_not, 1'b0};
                CARRY = 2'b10;
            end
            3'b001, 3'b010: begin
                PARTIAL_PRODUCT = {{31{MULTIPLICAND[32]}}, MULTIPLICAND};
                CARRY = 2'b00;
            end
            3'b101, 3'b110: begin
                PARTIAL_PRODUCT = {{31{multiplicand_not[32]}}, multiplicand_not};
                CARRY = 2'b01;
            end
            default: begin
                PARTIAL_PRODUCT = 64'b0;
                CARRY = 2'b00;
            end
        endcase
    end
endmodule
