/* 4bit先行进位加法器模块 */
/* 模块设计思路参考博客https://blog.csdn.net/e2788666/article/details/125455538 */
module cla4(
    input   logic[3:0]  PROPA_I,
    input   logic[3:0]  GENER_I,
    input   logic       CARRY_I,
    output  logic[3:0]  CARRY_O,
    output  logic       GENER_O,
    output  logic       PROPA_O
    );

    // 计算进位
    assign CARRY_O[0] = GENER_I[0] | (PROPA_I[0] & CARRY_I);

    assign CARRY_O[1] = GENER_I[1] | 
                        (PROPA_I[1] & GENER_I[0]) | 
                        (PROPA_I[1] & PROPA_I[0] & CARRY_I);

    assign CARRY_O[2] = GENER_I[2] | 
                        (PROPA_I[2] & GENER_I[1]) | 
                        (PROPA_I[2] & PROPA_I[1] & GENER_I[0]) | 
                        (PROPA_I[2] & PROPA_I[1] & PROPA_I[0] & CARRY_I);   

    // 总体传递信号与生成信号
    assign GENER_O = GENER_I[3] | 
                     (PROPA_I[3] & GENER_I[2]) | 
                     (PROPA_I[3] & PROPA_I[2] & GENER_I[1]) | 
                     (PROPA_I[3] & PROPA_I[2] & PROPA_I[1] & GENER_I[0]);

    assign PROPA_O = PROPA_I[0] & PROPA_I[1] & PROPA_I[2] & PROPA_I[3];

    // 计算最终进位
    assign CARRY_O[3] = GENER_O | (PROPA_O & CARRY_I);
endmodule
