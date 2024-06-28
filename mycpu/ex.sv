`timescale 1ns / 1ps
`include "defines.vh"

/* ex模块,计算操作在这里完成 */
module ex(
    input   logic                       RST,
    input   logic[`ALU_OP_BUS]          ALU_OP_I,
    input   logic[`ALU_SEL_BUS]         ALU_SEL_I,
    /* verilator lint_off UNUSED */
    input   logic[`REG_DATA_BUS]        INST_I,
    /* verilator lint_off UNUSED */
    input   logic[`REG_DATA_BUS]        REG1_DATA_I,
    input   logic[`REG_DATA_BUS]        REG2_DATA_I,
    input   logic[`REG_ADDR_BUS]        WADDR_I,
    input   logic                       WEN_I,
    /* verilator lint_off UNUSED */
    input   logic                       CUR_INST_DS_FLAG,
    /* verilator lint_off UNUSED */
    input   logic[`REG_DATA_BUS]        BRANCH_LINK_ADDR,
    // 除法输入信号
    input   logic                       DIV_READY,
    input   logic[`DOUBLE_REG_DATA_BUS] DIV_RESULT,
    // 乘法输入信号
    input   logic                       MUL_READY,
    input   logic[`DOUBLE_REG_DATA_BUS] MUL_RESULT,
    // HILO寄存器值
    input   logic[`REG_DATA_BUS]        HI_DATA_I,
    input   logic[`REG_DATA_BUS]        LO_DATA_I,
    // 回写阶段HILO数据相关 
    input   logic[`REG_DATA_BUS]        WB_HI_DATA_I,
    input   logic[`REG_DATA_BUS]        WB_LO_DATA_I,
    input   logic                       WB_WEN_HILO_I,
    // 访存阶段HI，LO数据相关   
    input   logic[`REG_DATA_BUS]        MEM_HI_DATA_I,
    input   logic[`REG_DATA_BUS]        MEM_LO_DATA_I,
    input   logic                       MEM_WEN_HILO_I,
    // 暂停输出信号 
    output  logic                       STALL_REQ,
    // 输出给除法器的信号
    output  logic                       SIGNED_DIV,
    output  logic                       DIV_START,
    output  logic                       DIV_CANCEL,
    output  logic[`REG_DATA_BUS]        DIVISOR,
    output  logic[`REG_DATA_BUS]        DIVIDEND,
    // 输出给乘法器的信号
    output  logic                       SIGNED_MUL,
    output  logic                       MUL_START,
    output  logic                       MUL_CANCEL,
    output  logic[`REG_DATA_BUS]        MULTIPLICAND,
    output  logic[`REG_DATA_BUS]        MULTIPLIER,
    // 写HI与LO 
    output  logic[`REG_DATA_BUS]        HI_DATA_O,
    output  logic[`REG_DATA_BUS]        LO_DATA_O,
    output  logic                       WEN_HILO_O,
    // 指令子类型,用以MEM模块确认加载或存储操作
    output  logic[`ALU_OP_BUS]          ALU_OP_O,
    // 要访问的存储器地址
    output  logic[`DATA_ADDR_BUS]       MEM_LSADDR_O,
    // 要存储的数据
    output  logic[`DATA_BUS]            MEM_SDATA_O,
    // 写寄存器相关信息
    output  logic[`REG_DATA_BUS]        WDATA_O,
    output  logic[`REG_ADDR_BUS]        WADDR_O,
    output  logic                       WEN_O,
    // 异常
    output  logic                       ERROR
    );

    // 保存各种运算的结果
    logic[`REG_DATA_BUS]        logic_res;
    logic[`REG_DATA_BUS]        shift_res;
    logic[`REG_DATA_BUS]        move_res;
    logic[`REG_DATA_BUS]        arith_res;
    logic[`REG_DATA_BUS]        add_res;
    // MFHI,MFLO指令需要HI,LO寄存器的值
    logic[`REG_DATA_BUS]        mov_from_hi;
    logic[`REG_DATA_BUS]        mov_from_lo;
    // 异常检测变量
    logic   ov_sum;
    // 比较变量
    logic   reg1_lt_reg2;
    // 寄存器2源操作数的补码
    logic[`REG_DATA_BUS]        reg2_comple;
    // CLZ和CLO指令用到的计数器
    logic[4:0]  count;
    logic       done;
    // 乘除法器停止信号
    logic       stall_req_mul; 
    logic       stall_req_div; 
    
    // 暂时假设永不取消计算
    assign MUL_CANCEL = `MUL_NOT_CANCEL;
    assign DIV_CANCEL = `DIV_NOT_CANCEL;

    // 异常分配
    assign ERROR = ALU_SEL_I == `EXE_RES_ARITH ? ov_sum : `NOERR;
    
    /* Part: 逻辑运算 */
    always_comb begin : Logic_Result_Caculation
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
    always_comb begin : Shift_Result_Caculation
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

    /* Part: 移动运算 */
    // 计算移动指令需要的hi与lo寄存器中的值
    always_comb begin : MOV_FROM_HILO
        if (RST == `RST_EN) begin
            {mov_from_hi,mov_from_lo} = {`ZERO_WORD,`ZERO_WORD};
        end
        // 若访存模块或回写模块需要写入HILO模块
            // 代表当前ex模块的HILO输入数据字应当是现在要被写入HILO的输入数据字
        else if (MEM_WEN_HILO_I == `WENABLE) begin
            {mov_from_hi,mov_from_lo} = {MEM_HI_DATA_I,MEM_LO_DATA_I};
        end 
        else if (WB_WEN_HILO_I == `WENABLE) begin
            {mov_from_hi,mov_from_lo} = {WB_HI_DATA_I,WB_LO_DATA_I};
        end 
        else begin
            {mov_from_hi,mov_from_lo} = {HI_DATA_I,LO_DATA_I};
        end
    end

    // 根据指令类型,计算最终移动运算结果的值取哪个寄存器
    always_comb begin : MOV_HILO_Value
        if (RST == `RST_EN) begin
            move_res = `ZERO_WORD;
        end
        move_res = `ZERO_WORD;
        case (ALU_OP_I)
            `EXE_MFHI_OP:   begin
                move_res = mov_from_hi;
            end
            `EXE_MFLO_OP:   begin
                move_res = mov_from_lo;
            end 
            `EXE_MOVN_OP:   begin
                move_res = REG1_DATA_I;
            end
            `EXE_MOVZ_OP:   begin
                move_res = REG1_DATA_I;
            end
            default:    begin
                move_res = `ZERO_WORD;
            end
        endcase
    end
    

    /* Part: 简单算术运算 */
    // 简单赋值语句
    assign add_res = REG1_DATA_I + reg2_comple;
    // 寄存器补码确认
    always_comb begin : REG2_COMPLE
        if (RST == `RST_EN) begin
            reg2_comple = `ZERO_WORD;
        end
        // 在SUB类指令和SLT指令时，reg2_comple变量需要表示寄存器2中操作数的补码
        else if ((ALU_OP_I == `EXE_SUB_OP) || (ALU_OP_I == `EXE_SUBU_OP) || (ALU_OP_I == `EXE_SLT_OP)) begin
            reg2_comple = (~REG2_DATA_I) + 1;
        end else begin
            reg2_comple = REG2_DATA_I;
        end
    end
    // 溢出检测
    always_comb begin : OV_SUM_DETECTION
        if (RST == `RST_EN) begin
            ov_sum = 1'b0;
        end else begin
            // 检测溢出
                // 1. 操作数都为正但add_res为负
                // 2. 操作数都为负但add_res为正
            ov_sum = (REG1_DATA_I[31] & reg2_comple[31] & (~add_res[31])) ||
                    ((~REG1_DATA_I[31]) & (~reg2_comple[31]) & add_res[31]);
        end
    end
    // 比较运算
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
    // 简单算术运算执行
    always_comb begin : ARITHMETIC_EXECUTION
        if (RST == `RST_EN) begin
            arith_res = `ZERO_WORD;
            count = 5'b0;
            done  = 1'b0;
        end else begin
            arith_res = `ZERO_WORD;
            count = 5'b0;
            done  = 1'b0;
            // 判断算术运算子类型
            case (ALU_OP_I)
                // 比较运算结果通过reg1_lt_reg2赋值
                `EXE_SLT_OP, `EXE_SLTU_OP: begin
                    arith_res = {31'b0, reg1_lt_reg2};
                end
                // 加减法运算结果通过add_res赋值
                `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_SUB_OP, `EXE_SUBU_OP: begin
                    arith_res = add_res;
                end
                // 计数指令通过for循环完成
                `EXE_CLZ_OP: begin
                    for (int i = 31; i >= 0; i = i - 1) begin
                        // 通过done信号指示是否遍历过1
                        if (!REG1_DATA_I[i] && !done) begin
                            count = count + 1;
                        end else if (REG1_DATA_I[i] && !done) begin
                            done = 1'b1;
                        end
                    end
                    arith_res = {27'b0, count};
                end 
                `EXE_CLO_OP: begin
                    for (int i = 31; i >= 0; i = i - 1) begin
                        if (REG1_DATA_I[i] && !done) begin
                            count = count + 1;
                        end else if (!REG1_DATA_I[i] && !done) begin
                            done = 1'b1;
                        end
                    end
                    arith_res = {27'b0, count};
                end 
                default: begin

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
            stall_req_mul   = `NOT_STOP;
            MULTIPLIER      = `ZERO_WORD;
            MULTIPLICAND    = `ZERO_WORD;
            MUL_START       = `MUL_STOP;
            SIGNED_MUL      = `UNSIGNED;
            case (ALU_OP_I)
                `EXE_MUL_OP, `EXE_MULT_OP:    begin
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
                `EXE_MULTU_OP:    begin
                    if (MUL_READY == `RESULT_NOT_READY) begin
                        stall_req_mul   = `STOP;
                        MUL_START       = `MUL_START;
                        SIGNED_MUL      = `UNSIGNED;
                        MULTIPLICAND    = REG1_DATA_I;
                        MULTIPLIER      = REG2_DATA_I;
                    end else if (MUL_READY == `RESULT_READY) begin
                        stall_req_mul   = `NOT_STOP;
                        MUL_START       = `MUL_STOP;
                        SIGNED_MUL      = `UNSIGNED;
                        MULTIPLICAND    = REG1_DATA_I;
                        MULTIPLIER      = REG2_DATA_I;
                    end
                end
                default:    begin
                    
                end
            endcase
        end
    end

    /* Part: 除法信号处理 */
    always_comb begin : DIVISION_CALCULATION
        if (RST == `RST_EN) begin
            stall_req_div   = `NOT_STOP;
            DIVIDEND        = `ZERO_WORD;
            DIVISOR         = `ZERO_WORD;
            DIV_START       = `DIV_STOP;
            SIGNED_DIV      = `UNSIGNED;
        end else begin
            stall_req_div   = `NOT_STOP;
            DIVIDEND        = `ZERO_WORD;
            DIVISOR         = `ZERO_WORD;
            DIV_START       = `DIV_STOP;
            SIGNED_DIV      = `UNSIGNED;
            case (ALU_OP_I)
                `EXE_DIV_OP:    begin
                    if (DIV_READY == `RESULT_NOT_READY) begin
                        // 在结果不可用时,则视作除法模块正在运行,持续请求暂停
                        stall_req_div   = `STOP;
                        DIV_START       = `DIV_START;
                        SIGNED_DIV      = `SIGNED;
                        DIVIDEND        = REG1_DATA_I;
                        DIVISOR         = REG2_DATA_I;
                    end else if (DIV_READY == `RESULT_READY) begin 
                        // 结果可用时,认为运算结束,发送除法结束信号
                        stall_req_div   = `NOT_STOP;
                        DIV_START       = `DIV_STOP;
                        SIGNED_DIV      = `SIGNED;
                        DIVIDEND        = REG1_DATA_I;
                        DIVISOR         = REG2_DATA_I;
                    end
                end 
                `EXE_DIVU_OP:    begin
                    if (DIV_READY == `RESULT_NOT_READY) begin
                        stall_req_div   = `STOP;
                        DIV_START       = `DIV_START;
                        SIGNED_DIV      = `UNSIGNED;
                        DIVIDEND        = REG1_DATA_I;
                        DIVISOR         = REG2_DATA_I;
                    end else if (DIV_READY == `RESULT_READY) begin
                        stall_req_div   = `NOT_STOP;
                        DIV_START       = `DIV_STOP;
                        SIGNED_DIV      = `UNSIGNED;
                        DIVIDEND        = REG1_DATA_I;
                        DIVISOR         = REG2_DATA_I;
                    end
                end
                default:    begin
                    
                end
            endcase
        end
    end
    
    /* Part:访存阶段信息传递 */
    assign ALU_OP_O = ALU_OP_I;
    // 访问地址 = rs寄存器值 + 有符号扩展offset
    assign MEM_LSADDR_O = REG1_DATA_I + {{16{INST_I[15]}},INST_I[15:0]};
    // 对于存储指令,REG2_DATA_I存放了将要存储的数据
    assign MEM_SDATA_O  = REG2_DATA_I;

    /* Part: 暂停信号处理 */
    assign STALL_REQ = stall_req_div | stall_req_mul;

    /* Part: 写入HILO的指令处理 */
    always_comb begin : Write_To_HILO_Inst
        if (RST == `RST_EN) begin
            WEN_HILO_O = `WDISABLE;
            HI_DATA_O  = `ZERO_WORD;
            LO_DATA_O  = `ZERO_WORD;
        end else begin
            case (ALU_OP_I)
                `EXE_MTHI_OP: begin
                    WEN_HILO_O = `WENABLE;
                    HI_DATA_O  = REG1_DATA_I;
                    LO_DATA_O  = mov_from_lo;
                end
                `EXE_MTLO_OP: begin
                    WEN_HILO_O = `WENABLE;
                    HI_DATA_O  = mov_from_hi;
                    LO_DATA_O  = REG1_DATA_I;
                end
                `EXE_MULT_OP, `EXE_MULTU_OP: begin
                    WEN_HILO_O = `WENABLE;
                    HI_DATA_O  = MUL_RESULT[63:32];
                    LO_DATA_O  = MUL_RESULT[31:0];
                end
                `EXE_DIV_OP, `EXE_DIVU_OP: begin
                    WEN_HILO_O = `WENABLE;
                    HI_DATA_O  = DIV_RESULT[63:32];
                    LO_DATA_O  = DIV_RESULT[31:0];
                end
                default: begin
                    WEN_HILO_O = `WDISABLE;
                    HI_DATA_O  = `ZERO_WORD;
                    LO_DATA_O  = `ZERO_WORD;
                end
            endcase
        end
    end


    /* Part: 依据运算类型,选择一个运算结果作为最终结果,即使不需要写入GPR */
    always_comb begin : Choose_Result
        WADDR_O = WADDR_I;
        WEN_O = WEN_I;
        case (ALU_SEL_I)
            `EXE_RES_LOGIC: begin
                WDATA_O = logic_res;
            end
            `EXE_RES_SHIFT: begin
                WDATA_O = shift_res;
            end
            `EXE_RES_MOVE: begin
                WDATA_O = move_res;
            end
            `EXE_RES_MUL: begin
                WDATA_O = MUL_RESULT[31:0];
            end
            `EXE_RES_ARITH: begin
                WDATA_O = arith_res;
            end
            `EXE_RES_JB: begin
                WDATA_O = BRANCH_LINK_ADDR;
            end
            default: begin
                WDATA_O = `ZERO_WORD;
            end
        endcase
    end
endmodule
