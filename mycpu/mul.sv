`timescale 1ns / 1ps
`include "defines.vh"

/* 乘法器模块 */
/* 此部分代码实现部分参考https://github.com/SocialistDalao/UltraMIPS_NSCSCC/blob/master/FinalSubmission/mul.v */
/* verilator lint_off UNUSED */
module mul(
    input   logic                       RST,
    input   logic                       CLK,
    input   logic                       SIGNED_MUL,
    input   logic[`REG_DATA_BUS]        MULTIPLIER,
    input   logic[`REG_DATA_BUS]        MULTIPLICAND,
    input   logic                       START,
    input   logic                       CANCEL,
    output  logic[`DOUBLE_REG_DATA_BUS] RESULT,
    output  logic                       READY
);
    // 状态
    logic state;
    logic s_next;
    // 加数
    logic[`DOUBLE_REG_DATA_BUS] adder1;
    logic[`DOUBLE_REG_DATA_BUS] adder2;
    // 扩展后乘数与被乘数
    logic[32:0] MULTIPLICAND_ext;
    logic[33:0] MULTIPLIER_ext;
    // 用Booth算法生成部分积
    logic[63:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15, pp16; 
    logic[63:0] pp17;
    logic[33:0] c;
    // 第一级压缩结果
    logic[63:0] s_l1_1, s_l1_2, s_l1_3, s_l1_4, s_l1_5, s_l1_6;
    logic[63:0] c_l1_1, c_l1_2, c_l1_3, c_l1_4, c_l1_5, c_l1_6;
    // 第二级压缩结果
    logic[63:0] s_l2_1, s_l2_2, s_l2_3, s_l2_4;
    logic[63:0] c_l2_1, c_l2_2, c_l2_3, c_l2_4;
    // 第三级压缩结果
    logic[63:0] s_l3_1, s_l3_2;
    logic[63:0] c_l3_1, c_l3_2;
    // 第四级压缩结果
    logic[63:0] s_l4_1, s_l4_2;
    logic[63:0] c_l4_1, c_l4_2;
    // 第五级压缩结果
    logic[63:0] s_l5_1;
    logic[63:0] c_l5_1;
    // 第六级压缩结果
    logic[63:0] s_l6_1;
    logic[63:0] c_l6_1;
    // 进位寄存器
    logic[63:0] carry;
    
    /* 根据有符号还是无符号乘法对x进行扩展 */
    assign MULTIPLICAND_ext = SIGNED_MUL ? {MULTIPLICAND[31], MULTIPLICAND} : {1'b0, MULTIPLICAND};
    assign MULTIPLIER_ext = SIGNED_MUL ? {{2{MULTIPLIER[31]}}, MULTIPLIER} : {2'b00, MULTIPLIER};
    
   /* 生成部分积 */
    booth u_b0(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3({MULTIPLIER_ext[1:0], 1'b0}),
        .PARTIAL_PRODUCT(pp0),
        .CARRY(c[1:0])
    );
    booth u_b1(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[3:1]),
        .PARTIAL_PRODUCT(pp1),
        .CARRY(c[3:2])
    );
    booth u_b2(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[5:3]),
        .PARTIAL_PRODUCT(pp2),
        .CARRY(c[5:4])
    );
    booth u_b3(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[7:5]),
        .PARTIAL_PRODUCT(pp3),
        .CARRY(c[7:6])
    );
    booth u_b4(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[9:7]),
        .PARTIAL_PRODUCT(pp4),
        .CARRY(c[9:8])
    );
    booth u_b5(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[11:9]),
        .PARTIAL_PRODUCT(pp5),
        .CARRY(c[11:10])
    );
    booth u_b6(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[13:11]),
        .PARTIAL_PRODUCT(pp6),
        .CARRY(c[13:12])
    );
    booth u_b7(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[15:13]),
        .PARTIAL_PRODUCT(pp7),
        .CARRY(c[15:14])
    );
    booth u_b8(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[17:15]),
        .PARTIAL_PRODUCT(pp8),
        .CARRY(c[17:16])
    );
    booth u_b9(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[19:17]),
        .PARTIAL_PRODUCT(pp9),
        .CARRY(c[19:18])
    );
    booth u_b10(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[21:19]),
        .PARTIAL_PRODUCT(pp10),
        .CARRY(c[21:20])
    );
    booth u_b11(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[23:21]),
        .PARTIAL_PRODUCT(pp11),
        .CARRY(c[23:22])
    );
    booth u_b12(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[25:23]),
        .PARTIAL_PRODUCT(pp12),
        .CARRY(c[25:24])
    );
    booth u_b13(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[27:25]),
        .PARTIAL_PRODUCT(pp13),
        .CARRY(c[27:26])
    );
    booth u_b14(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[29:27]),
        .PARTIAL_PRODUCT(pp14),
        .CARRY(c[29:28])
    );
    booth u_b15(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[31:29]),
        .PARTIAL_PRODUCT(pp15),
        .CARRY(c[31:30])
    );
    booth u_b16(
        .MULTIPLICAND(MULTIPLICAND_ext),
        .MULTIPLIER_3(MULTIPLIER_ext[33:31]),
        .PARTIAL_PRODUCT(pp16),
        .CARRY(c[33:32])
    );
    assign pp17 = {30'b0, c};

    /* 压缩部分积 */
    csa u_csa_l1_1(
        .ADDER1(pp0),
        .ADDER2({pp1[61:0], 2'b0}),
        .ADDER3({pp2[59:0], 4'b0}),
        .SUM(s_l1_1),
        .CARRY(c_l1_1)
    );
    csa u_csa_l1_2(
        .ADDER1({pp3[57:0], 6'b0}),
        .ADDER2({pp4[55:0], 8'b0}),
        .ADDER3({pp5[53:0], 10'b0}),
        .SUM(s_l1_2),
        .CARRY(c_l1_2)
    );
    csa u_csa_l1_3(
        .ADDER1({pp6[51:0], 12'b0}),
        .ADDER2({pp7[49:0], 14'b0}),
        .ADDER3({pp8[47:0], 16'b0}),
        .SUM(s_l1_3),
        .CARRY(c_l1_3)
    );
    csa u_csa_l1_4(
        .ADDER1({pp9[45:0], 18'b0}),
        .ADDER2({pp10[43:0], 20'b0}),
        .ADDER3({pp11[41:0], 22'b0}),
        .SUM(s_l1_4),
        .CARRY(c_l1_4)
    );
    csa u_csa_l1_5(
        .ADDER1({pp12[39:0], 24'b0}),
        .ADDER2({pp13[37:0], 26'b0}),
        .ADDER3({pp14[35:0], 28'b0}),
        .SUM(s_l1_5),
        .CARRY(c_l1_5)
    );
    csa u_csa_l1_6(
        .ADDER1({pp15[33:0], 30'b0}),
        .ADDER2({pp16[31:0], 32'b0}),
        .ADDER3(pp17),
        .SUM(s_l1_6),
        .CARRY(c_l1_6)
    );
    csa u_csa_l2_1(
        .ADDER1(s_l1_1),
        .ADDER2(s_l1_2),
        .ADDER3(s_l1_3),
        .SUM(s_l2_1),
        .CARRY(c_l2_1)
    );
    csa u_csa_l2_2(
        .ADDER1(s_l1_4),
        .ADDER2(s_l1_5),
        .ADDER3(s_l1_6),
        .SUM(s_l2_2),
        .CARRY(c_l2_2)
    );
    csa u_csa_l2_3(
        .ADDER1({c_l1_1[62:0], 1'b0}),
        .ADDER2({c_l1_2[62:0], 1'b0}),
        .ADDER3({c_l1_3[62:0], 1'b0}),
        .SUM(s_l2_3),
        .CARRY(c_l2_3)
    );
    csa u_csa_l2_4(
        .ADDER1({c_l1_4[62:0], 1'b0}),
        .ADDER2({c_l1_5[62:0], 1'b0}),
        .ADDER3({c_l1_6[62:0], 1'b0}),
        .SUM(s_l2_4),
        .CARRY(c_l2_4)
    );
    csa u_csa_l3_1(
        .ADDER1(s_l2_1),
        .ADDER2(s_l2_2),
        .ADDER3(s_l2_3),
        .SUM(s_l3_1),
        .CARRY(c_l3_1)
    );
    csa u_csa_l3_2(
        .ADDER1(s_l2_4),
        .ADDER2({c_l2_1[62:0], 1'b0}),
        .ADDER3({c_l2_2[62:0], 1'b0}),
        .SUM(s_l3_2),
        .CARRY(c_l3_2)
    );
    csa u_csa_l4_1(
        .ADDER1(s_l3_1),
        .ADDER2(s_l3_2),
        .ADDER3({c_l3_1[62:0], 1'b0}),
        .SUM(s_l4_1),
        .CARRY(c_l4_1)
    );
    csa u_csa_l4_2(
        .ADDER1({c_l3_2[62:0], 1'b0}),
        .ADDER2({c_l2_3[62:0], 1'b0}),
        .ADDER3({c_l2_4[62:0], 1'b0}),
        .SUM(s_l4_2),
        .CARRY(c_l4_2)
    );
    csa u_csa_l5_1(
        .ADDER1(s_l4_1),
        .ADDER2(s_l4_2),
        .ADDER3({c_l4_1[62:0], 1'b0}),
        .SUM(s_l5_1),
        .CARRY(c_l5_1)
    );
    csa u_csa_l6_1(
        .ADDER1(s_l5_1),
        .ADDER2({c_l5_1[62:0], 1'b0}),
        .ADDER3({c_l4_2[62:0], 1'b0}),
        .SUM(s_l6_1),
        .CARRY(c_l6_1)
    );

    /* 运算结果 */
    fa64 u_fa64 (
        .ADDER1(adder1),
        .ADDER2(adder2),
        .CARRY_I(1'b0),
        .IS_SUB(1'b0),
        .SUM(RESULT),
        .CARRY_O(carry)
    );

    /* 状态机定义 */
    always_comb begin : STATUS_MACHINE
        if (RST == `RST_EN) begin
            s_next = `MUL_FREE;
        end else begin
            case (state)
                `MUL_FREE: begin
                    if (START == `MUL_START && CANCEL != `MUL_CANCEL) begin
                        s_next = `MUL_BUSY;
                    end else begin 
                        s_next = `MUL_FREE;
                    end
                end
                `MUL_BUSY: begin
                    s_next = `MUL_FREE;
                end 
                default: begin 
                    s_next = `MUL_FREE;
                end
            endcase
        end
    end
    /* 切换状态 */
    always_ff @( posedge CLK ) begin : STATE_CHANGE
        state <= s_next;
    end
    /* 输出信号控制与加数赋值 */
    always_ff @(posedge CLK) begin : RESULT_VALUE
        case (s_next)
            `MUL_FREE: begin
                adder1 <= {`ZERO_WORD, `ZERO_WORD};
                adder2 <= {`ZERO_WORD, `ZERO_WORD};
                READY <= 1'b0;
            end
            `MUL_BUSY: begin
                adder1 <= s_l6_1;
                adder2 <= {c_l6_1[62:0], 1'b0};
                READY <= 1'b1;
            end
            default: begin
                adder1 <= {`ZERO_WORD, `ZERO_WORD};
                adder2 <= {`ZERO_WORD, `ZERO_WORD};
                READY <= 1'b0;
            end
        endcase
    end
endmodule
/* verilator lint_off UNUSED */
