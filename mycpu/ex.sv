`timescale 1ns / 1ps
`include "defines.vh"
module ex(
    input   logic                  RST,
    input   logic [   `ALU_OP_BUS] ALU_OP_I,
    input   logic [  `ALU_SEL_BUS] ALU_SEL_I,
    input   logic [`SRAM_DATA_BUS] INST_I,
    input   logic [ `REG_DATA_BUS] REG1_DATA_I,
    input   logic [ `REG_DATA_BUS] REG2_DATA_I,
    input   logic [ `REG_ADDR_BUS] GPR_WADDR_I,
    input   logic                  GPR_WE_I,
    input   logic                  CUR_INST_DS_FLAG,
    input   logic [`SRAM_ADDR_BUS] BRANCH_LINK_ADDR,
    input   logic                  MUL_READY,
    input   logic [`DREG_DATA_BUS] MUL_RESULT,

    output  logic                  ERROR,
    output  logic                  STALL_REQ,
    output  logic                  SIGNED_MUL,
    output  logic                  MUL_START,
    output  logic                  MUL_CANCEL,
    output  logic [ `REG_DATA_BUS] MULTIPLICAND,
    output  logic [ `REG_DATA_BUS] MULTIPLIER,
    output  logic [   `ALU_OP_BUS] ALU_OP_O,
    output  logic [`SRAM_ADDR_BUS] SRAM_ADDR_O,
    output  logic [`SRAM_DATA_BUS] SRAM_WDATA_O,
    output  logic                  GPR_WE_O,
    output  logic [ `REG_DATA_BUS] GPR_WDATA_O,
    output  logic [ `REG_ADDR_BUS] GPR_WADDR_O
    );

    // 保存各种运算的结果
    logic [`REG_DATA_BUS] logic_res;
    logic [`REG_DATA_BUS] shift_res;
    logic [`REG_DATA_BUS] arith_res;
    logic [`REG_DATA_BUS] add_res;
    // 溢出异常
    logic                 ov_sum;
    logic                 stall_req_mul; 
    logic                 reg1_lt_reg2;
    logic [`REG_DATA_BUS] reg2_comple;

    // 暂时假设永不取消计算
    assign MUL_CANCEL = `MUL_NOT_CANCEL;

    // 异常分配
    assign ERROR = ALU_SEL_I == `EXE_RES_ARITH ? ov_sum : `NOERR;
    
    /* Part: 逻辑运算 */
    always_comb begin : LOGIC_EXE
        if(RST == `RST_EN) begin
            logic_res = `ZERO_WORD;
        end else begin
            // 判断逻辑运算的子运算类型
            case (ALU_OP_I)
                `EXE_OR_OP: begin
                    logic_res = REG1_DATA_I | REG2_DATA_I;
                end
                `EXE_AND_OP: begin
                    logic_res = REG1_DATA_I & REG2_DATA_I;
                end
                `EXE_XOR_OP: begin
                    logic_res = REG1_DATA_I ^ REG2_DATA_I;
                end
                `EXE_NOR_OP: begin
                    logic_res = ~(REG1_DATA_I | REG2_DATA_I);
                end
                `EXE_LUI_OP: begin
                    logic_res = {REG1_DATA_I};
                end
                default: begin
                    logic_res = `ZERO_WORD;
                end
            endcase

        end
    end

    /* Part: 移位运算 */
    always_comb begin : SHIFT_EXE
        if(RST == `RST_EN) begin
            shift_res = `ZERO_WORD;
        end else begin
            // 判断移位运算的子类型
                // 移位运算的偏移量在id模块中被赋值给寄存器1的低5位
            case (ALU_OP_I)
                `EXE_SLL_OP: begin
                    shift_res = (REG2_DATA_I <<  REG1_DATA_I[4:0]);
                end
                `EXE_SRL_OP: begin
                    shift_res = (REG2_DATA_I >>  REG1_DATA_I[4:0]);
                end
                `EXE_SRA_OP: begin
                    shift_res = (REG2_DATA_I >>> REG1_DATA_I[4:0]);
                end
                default: begin
                    shift_res = `ZERO_WORD;
                end
            endcase
        end
    end

    /* Part: 简单算术运算 */
    always_comb begin: REG2_COMPLEMENT
        if (RST == `RST_EN) begin
            reg2_comple = `ZERO_WORD;
        end
        // 在SUB指令和SLT指令时，reg2_comple变量需要表示寄存器2中操作数的补码以代表"减"操作
        else if ((ALU_OP_I == `EXE_SUB_OP) || (ALU_OP_I == `EXE_SLT_OP)) begin
            reg2_comple = (~REG2_DATA_I) + 1;
        end else begin
            reg2_comple = REG2_DATA_I;
        end
    end

    assign add_res = REG1_DATA_I + reg2_comple;

    always_comb begin: OVERFLOW_DETECTION
        if (RST == `RST_EN) begin
            ov_sum = 1'b0;
        end else begin
            // 检测溢出
                // 1. 操作数都为正但add_res为负
                // 2. 操作数都为负但add_res为正
            ov_sum = (REG1_DATA_I[31]  & reg2_comple[31]  & ~add_res[31])
                   | (~REG1_DATA_I[31] & ~reg2_comple[31] & add_res[31]);
        end
    end
    
    always_comb begin : COMPARISON
        if (RST == `RST_EN) begin
            reg1_lt_reg2 = 1'b0;
        end else begin
            // 在有符号比较时，利用add_res的结果与两个操作数的正负赋值，此时add_res中存储左数减右数的结果
                // 1. rs为负且rt为正，比较结果为1
                // 2. rs为负且rt为负，add_res结果为负，比较结果为1
                // 3. rs为正且rt为正，add_res结果为负，比较结果为1  
            // 在无符号比较时，直接使用"<"即可
            if (ALU_OP_I == `EXE_SLT_OP) begin
                reg1_lt_reg2 = ((REG1_DATA_I[31] & (~REG2_DATA_I[31])) |
                                ((~REG1_DATA_I[31]) & (~REG2_DATA_I[31]) & add_res[31]) |
                                (REG1_DATA_I[31]  & REG2_DATA_I[31]  & add_res[31]));
            end else begin
                reg1_lt_reg2 = REG1_DATA_I < REG2_DATA_I;
            end
        end
    end
    
    always_comb begin : ARITHMETIC_EXECUTION
        if (RST == `RST_EN) begin
            arith_res = `ZERO_WORD;
        end else begin
            case (ALU_OP_I)
                `EXE_SLT_OP: begin
                    arith_res = {31'b0, reg1_lt_reg2};
                end
                `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_SUB_OP: begin
                    arith_res = add_res;
                end
                default: begin
                    arith_res = `ZERO_WORD;
                end
            endcase
        end
    end

    /* Part: 乘法信号处理 */
    always_comb begin : MULTIPLICATION_CALCULATION
        if (RST == `RST_EN) begin
            stall_req_mul   = `NOT_STOP;
            MULTIPLIER      = `ZERO_WORD;
            MULTIPLICAND    = `ZERO_WORD;
            MUL_START       = `MUL_STOP;
            SIGNED_MUL      = `UNSIGNED;
        end else begin
            case (ALU_OP_I)
                `EXE_MUL_OP:    begin
                    if (MUL_READY == `RESULT_NOT_READY) begin
                        // 在结果不可用时,则视作乘法模块正在运行,持续请求暂停
                        stall_req_mul   = `STOP;
                        MUL_START       = `MUL_START;
                        SIGNED_MUL      = `SIGNED;
                        MULTIPLICAND    = REG1_DATA_I;
                        MULTIPLIER      = REG2_DATA_I;
                    end else if (MUL_READY == `RESULT_READY) begin
                        // 结果可用时,认为运算结束,发送乘法结束信号
                        stall_req_mul   = `NOT_STOP;
                        MUL_START       = `MUL_STOP;
                        SIGNED_MUL      = `SIGNED;
                        MULTIPLICAND    = REG1_DATA_I;
                        MULTIPLIER      = REG2_DATA_I;
                    end
                end 
                default: begin
                    stall_req_mul   = `NOT_STOP;
                    MULTIPLIER      = `ZERO_WORD;
                    MULTIPLICAND    = `ZERO_WORD;
                    MUL_START       = `MUL_STOP;
                    SIGNED_MUL      = `UNSIGNED;
                end
            endcase
        end
    end
    
    /* Part:访存阶段信息传递 */
    assign ALU_OP_O = ALU_OP_I;
    // 访问地址 = rs寄存器值 + 有符号扩展offset
    assign SRAM_ADDR_O = REG1_DATA_I + {{16{INST_I[15]}},INST_I[15:0]};
    // 对于存储指令,REG2_DATA_I存放了将要存储的数据
    assign SRAM_WDATA_O  = REG2_DATA_I;
    // 停滞信号
    assign STALL_REQ = stall_req_mul;

    /* Part: 依据运算类型,选择一个运算结果作为最终结果,即使不需要写入GPR */
    always_comb begin : CHOOSE_RESULT
        GPR_WADDR_O = GPR_WADDR_I;
        GPR_WE_O    = GPR_WE_I;
        case (ALU_SEL_I)
            `EXE_RES_LOGIC: begin
                GPR_WDATA_O = logic_res;
            end
            `EXE_RES_SHIFT: begin
                GPR_WDATA_O = shift_res;
            end
            `EXE_RES_MUL: begin
                GPR_WDATA_O = MUL_RESULT[31:0];
            end
            `EXE_RES_ARITH: begin
                GPR_WDATA_O = arith_res;
            end
            `EXE_RES_JB: begin
                GPR_WDATA_O = BRANCH_LINK_ADDR;
            end
            default: begin
                GPR_WDATA_O = `ZERO_WORD;
            end
        endcase
    end
endmodule
