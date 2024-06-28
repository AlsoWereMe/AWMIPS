`timescale 1ns / 1ps
`include "defines.vh"

module id(
    input logic                    RST,
    input logic[`INST_ADDR_BUS]    PC_I,
    input logic[`INST_DATA_BUS]    INST_I,
    // 指示当前处于译码阶段的指令是否为延迟槽指令
    input logic                    CUR_INST_DS_FLAG_I,
    // 从寄存器堆读操作数
    input logic[`REG_DATA_BUS]     REG1_DATA_I,
    input logic[`REG_DATA_BUS]     REG2_DATA_I,
    // 执行阶段写数据
    input logic                    EX_WEN_I,
    input logic[`ALU_OP_BUS]       EX_ALU_OP_I,
    input logic[`REG_ADDR_BUS]     EX_WADDR_I,
    input logic[`REG_DATA_BUS]     EX_WDATA_I,
    // 访存阶段写数据
    input logic                    MEM_WEN_I,
    input logic[`REG_ADDR_BUS]     MEM_WADDR_I,
    input logic[`REG_DATA_BUS]     MEM_WDATA_I,
    // 输出给寄存器堆的信号
    output logic                   REG1_REN_O,
    output logic                   REG2_REN_O,
    output logic[`REG_ADDR_BUS]    REG1_ADDR_O,
    output logic[`REG_ADDR_BUS]    REG2_ADDR_O,
    // 输出给执行阶段模块ex的信号
    output logic[`ALU_OP_BUS]      ALU_OP_O,
    output logic[`ALU_SEL_BUS]     ALU_SEL_O,
    output logic[`REG_DATA_BUS]    REG1_DATA_O,
    output logic[`REG_DATA_BUS]    REG2_DATA_O,
    output logic[`REG_ADDR_BUS]    WADDR_O,
    output logic                   WEN_O,
    output logic[`INST_DATA_BUS]   INST_O,
    // 流水线暂停控制信号
    output logic                   STALL_REQ,
    // 指令异常信号
    output logic                   INST_ERR,
    // 转移跳转信号
    output logic                   BRANCH_FLAG,
    // 将指示信号传递
    output logic                   CUR_INST_DS_FLAG_O,
    // 指示下一条进入译码阶段的指令是否为延迟槽指令
    output logic                   NEXT_INST_DS_FLAG_O,
    // 转移指令跳转地址
    output logic[`REG_DATA_BUS]    BRANCH_TAR_ADDR,
    // 转移指令返回地址
    output logic[`REG_DATA_BUS]    BRANCH_LINK_ADDR
);
/* 指令拆分后的各个部分 */
logic[5:0]    op;
logic[4:0]    sa;
logic[5:0]    func;
logic[4:0]    rs;
logic[4:0]    rt;
logic[4:0]    rd;
logic[15:0]   imm;
logic[25:0]   target;
logic[`REG_DATA_BUS]    pc_plus_4;
logic[`REG_DATA_BUS]    pc_plus_8;
logic[`REG_DATA_BUS]    ext_addr_sll2;
logic[`REG_DATA_BUS]    jump_addr_sll2;

/* 扩展后的立即数 */
logic[`REG_DATA_BUS]    ext_imm;

/* 指令有效信号 */
logic inst_valid;

/* 寄存器引起流水线停滞信号 */
logic   stall_req_reg1;
logic   stall_req_reg2;

/* 指令拆分 */
always_comb begin : Instruction_Split
    op             = INST_I[31:26];
    sa             = INST_I[10:6];
    func           = INST_I[5:0];
    rs             = INST_I[25:21];
    rt             = INST_I[20:16];
    rd             = INST_I[15:11];
    imm            = INST_I[15:0];
    target         = INST_I[25:0];
    pc_plus_4      = PC_I + 4;
    pc_plus_8      = PC_I + 8;
    ext_addr_sll2  = {{14{imm[15]}}, imm, 2'b00};
    jump_addr_sll2 = {pc_plus_4[31:28], target, 2'b00};
    INST_O         = INST_I;
end

/* Part1:指令译码 */
always_comb begin : Instruction_Decode
    if (RST == `RST_EN) begin
        inst_valid    = `INST_INVALID;
        ext_imm       = `ZERO_WORD;
        INST_ERR      = `NOERR;
        ALU_OP_O      = `EXE_NOP_OP;
        ALU_SEL_O     = `EXE_RES_NOP;
        WADDR_O       = `NOP_Reg_Addr;
        WEN_O         = `WDISABLE;
        REG1_REN_O    = `RDISABLE;
        REG2_REN_O    = `RDISABLE;
        REG1_ADDR_O   = `NOP_Reg_Addr;
        REG2_ADDR_O   = `NOP_Reg_Addr;
        BRANCH_FLAG   = `NOT_BRANCH;
        BRANCH_TAR_ADDR    = `ZERO_WORD;
        BRANCH_LINK_ADDR    = `ZERO_WORD;
        NEXT_INST_DS_FLAG_O = `OUT_DELAY_SLOT;
    end else begin
        // 所有信号之默认值，即无效指令NOP
        inst_valid    = `INST_INVALID;
        ext_imm       = `ZERO_WORD;
        INST_ERR      = `NOERR;
        ALU_OP_O      = `EXE_NOP_OP;
        ALU_SEL_O     = `EXE_RES_NOP;
        // 默认写入rd寄存器
        WADDR_O       = rd;
        // 默认不能对寄存器读写
        WEN_O         = `WDISABLE;
        REG1_REN_O    = `RDISABLE;
        REG2_REN_O    = `RDISABLE;
        // 寄存器1默认指向rs，寄存器2默认指向rt
        REG1_ADDR_O   = rs;
        REG2_ADDR_O   = rt;
        // 转移指令信号默认全不生效
        BRANCH_FLAG   = `NOT_BRANCH;
        BRANCH_TAR_ADDR    = `ZERO_WORD;
        BRANCH_LINK_ADDR    = `ZERO_WORD;
        NEXT_INST_DS_FLAG_O = `OUT_DELAY_SLOT;
        // 判断当前指令类型
        case (op)
        // ORI指令
        `EXE_ORI:   begin
            // I型指令之计算结果写入rt
            WADDR_O     = rt;                   
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_OR_OP;
            ALU_SEL_O   = `EXE_RES_LOGIC;
            // 读出rs里的数据,不需要读出rt里的数据
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            // 逻辑运算的I型指令之立即数均做无符号扩展
            ext_imm     = {16'h0,imm};
            inst_valid  = `INST_VALID;
        end
        // ANDI指令
        `EXE_ANDI:   begin                   
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_AND_OP;
            ALU_SEL_O   = `EXE_RES_LOGIC;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            ext_imm     = {16'h0,imm};
            inst_valid  = `INST_VALID;
        end
        // XORI指令
        `EXE_XORI:   begin                  
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_XOR_OP;
            ALU_SEL_O   = `EXE_RES_LOGIC;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            ext_imm     = {16'h0,imm};
            inst_valid  = `INST_VALID;
        end
        // LUI指令
        `EXE_LUI:   begin                  
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_LUI_OP;
            ALU_SEL_O   = `EXE_RES_LOGIC;
            REG1_REN_O  = `RDISABLE;
            REG2_REN_O  = `RDISABLE;
            // LUI指令将立即数置于高16位,低16位用0填充
            ext_imm     = {imm,16'h0};
            inst_valid  = `INST_VALID;
        end
        // ADDI指令
        `EXE_ADDI:   begin                  
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_ADD_OP;
            ALU_SEL_O   = `EXE_RES_ARITH;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            // 算术型指令之立即数做有符号位扩展
            ext_imm     = {{16{imm[15]}},imm};
            inst_valid  = `INST_VALID;
        end
        // ADDIU指令
        `EXE_ADDIU:   begin                  
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_ADDU_OP;
            ALU_SEL_O   = `EXE_RES_ARITH;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            ext_imm     = {{16{imm[15]}},imm};
            inst_valid  = `INST_VALID;
        end
        // SLTI指令
        `EXE_SLTI:   begin                  
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_SLT_OP;
            ALU_SEL_O   = `EXE_RES_ARITH;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            ext_imm     = {{16{imm[15]}},imm};
            inst_valid  = `INST_VALID;
        end
        // SLTIU指令
        `EXE_SLTIU:   begin                  
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_SLTU_OP;
            ALU_SEL_O   = `EXE_RES_ARITH;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            ext_imm     = {{16{imm[15]}},imm};
            inst_valid  = `INST_VALID;
        end
        // PREF指令
        `EXE_PREF:   begin                  
            WEN_O       = `WDISABLE;
            ALU_OP_O    = `EXE_NOP_OP;
            ALU_SEL_O   = `EXE_RES_LOGIC;
            REG1_REN_O  = `RDISABLE;
            REG2_REN_O  = `RDISABLE;
            inst_valid  = `INST_VALID;
        end
        // J指令
        `EXE_J: begin
            WEN_O           = `WDISABLE;
            ALU_OP_O        = `EXE_J_OP;
            ALU_SEL_O       = `EXE_RES_JB;
            REG1_REN_O      = `RDISABLE;
            REG2_REN_O      = `RDISABLE;
            BRANCH_FLAG     = `GO_BRANCH;
            BRANCH_TAR_ADDR     = jump_addr_sll2;
            BRANCH_LINK_ADDR    = `ZERO_WORD;
            NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
            inst_valid  = `INST_VALID;
        end
        // JAL指令
        `EXE_JAL: begin
            WEN_O           = `WENABLE;
            // JAL指令写GPR31
            WADDR_O         = 5'b11111;
            ALU_OP_O        = `EXE_JAL_OP;
            ALU_SEL_O       = `EXE_RES_JB;
            REG1_REN_O      = `RDISABLE;
            REG2_REN_O      = `RDISABLE;
            BRANCH_FLAG     = `GO_BRANCH;
            BRANCH_TAR_ADDR     = jump_addr_sll2;
            BRANCH_LINK_ADDR    = pc_plus_8;
            NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
            inst_valid  = `INST_VALID;
        end
        // BEQ指令
        `EXE_BEQ: begin
            WEN_O           = `WDISABLE;
            ALU_OP_O        = `EXE_BEQ_OP;
            ALU_SEL_O       = `EXE_RES_JB;
            REG1_REN_O      = `RENABLE;
            REG2_REN_O      = `RENABLE;
            inst_valid      = `INST_VALID;
            if (REG1_DATA_O == REG2_DATA_O) begin
                BRANCH_FLAG     = `GO_BRANCH;
                BRANCH_TAR_ADDR      = ext_addr_sll2 + pc_plus_4;
                BRANCH_LINK_ADDR    = `ZERO_WORD;
                NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
            end
        end
        // BNE指令
        `EXE_BNE: begin
            WEN_O           = `WDISABLE;
            ALU_OP_O        = `EXE_BNE_OP;
            ALU_SEL_O       = `EXE_RES_JB;
            REG1_REN_O      = `RENABLE;
            REG2_REN_O      = `RENABLE;
            inst_valid  = `INST_VALID;
            if (REG1_DATA_O != REG2_DATA_O) begin
                BRANCH_FLAG     = `GO_BRANCH;
                BRANCH_TAR_ADDR      = ext_addr_sll2 + pc_plus_4;
                BRANCH_LINK_ADDR    = `ZERO_WORD;
                NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
            end
        end
        // BGTZ指令
        `EXE_BGTZ: begin
            WEN_O           = `WDISABLE;
            ALU_OP_O        = `EXE_BGTZ_OP;
            ALU_SEL_O       = `EXE_RES_JB;
            REG1_REN_O      = `RENABLE;
            REG2_REN_O      = `RDISABLE;
            inst_valid  = `INST_VALID;
            if (REG1_DATA_O > 32'b0) begin
                BRANCH_FLAG     = `GO_BRANCH;
                BRANCH_TAR_ADDR      = ext_addr_sll2 + pc_plus_4;
                BRANCH_LINK_ADDR    = `ZERO_WORD;
                NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
            end
        end
        // BLEZ指令
        `EXE_BLEZ: begin
            WEN_O           = `WDISABLE;
            ALU_OP_O        = `EXE_BLEZ_OP;
            ALU_SEL_O       = `EXE_RES_JB;
            REG1_REN_O      = `RENABLE;
            REG2_REN_O      = `RDISABLE;
            inst_valid  = `INST_VALID;
            if (REG1_DATA_O <= 32'b0) begin
                BRANCH_FLAG     = `GO_BRANCH;
                BRANCH_TAR_ADDR      = ext_addr_sll2 + pc_plus_4;
                BRANCH_LINK_ADDR    = `ZERO_WORD;
                NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
            end
        end
        // LB指令
        `EXE_LB:    begin
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_LB_OP;
            ALU_SEL_O   = `EXE_RES_LS;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            ext_imm     = {{16{imm[15]}},imm};
            inst_valid  = `INST_VALID;
        end
        // LBU指令
        `EXE_LBU:    begin
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_LBU_OP;
            ALU_SEL_O   = `EXE_RES_LS;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            ext_imm     = {{16{imm[15]}},imm};
            inst_valid  = `INST_VALID;
        end
        // LH指令
        `EXE_LH:    begin
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_LH_OP;
            ALU_SEL_O   = `EXE_RES_LS;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            ext_imm     = {{16{imm[15]}},imm};
            inst_valid  = `INST_VALID;
        end
        // LHU指令
        `EXE_LHU:    begin
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_LHU_OP;
            ALU_SEL_O   = `EXE_RES_LS;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            ext_imm     = {{16{imm[15]}},imm};
            inst_valid  = `INST_VALID;
        end
        // LW指令
        `EXE_LW:    begin
            WADDR_O     = rt;
            WEN_O       = `WENABLE;
            ALU_OP_O    = `EXE_LW_OP;
            ALU_SEL_O   = `EXE_RES_LS;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RDISABLE;
            ext_imm     = {{16{imm[15]}},imm};
            inst_valid  = `INST_VALID;
        end
        // SB指令
        `EXE_SB:    begin
            WEN_O       = `WDISABLE;
            ALU_OP_O    = `EXE_SB_OP;
            ALU_SEL_O   = `EXE_RES_LS;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RENABLE;
            inst_valid  = `INST_VALID;
        end
        // SH指令
        `EXE_SH:    begin
            WEN_O       = `WDISABLE;
            ALU_OP_O    = `EXE_SH_OP;
            ALU_SEL_O   = `EXE_RES_LS;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RENABLE;
            inst_valid  = `INST_VALID;
        end
        // SW指令
        `EXE_SW:    begin
            WEN_O       = `WDISABLE;
            ALU_OP_O    = `EXE_SW_OP;
            ALU_SEL_O   = `EXE_RES_LS;
            REG1_REN_O  = `RENABLE;
            REG2_REN_O  = `RENABLE;
            inst_valid  = `INST_VALID;
        end
        // 如果是SPECIAL类型信号，检查sa是否为0                           
        `EXE_SPECIAL: begin
            case (sa)
                // 当sa为0，指令有效，检查FUNC信号                       
                5'b00000: begin
                    // 判断func类型
                    case (func)  
                        // OR指令            
                        `EXE_OR: begin
                            // 根据指令类型为各个输出信号赋值                      
                            WEN_O       = `WENABLE;
                            // 指明指令的类型与子类型
                            ALU_OP_O    = `EXE_OR_OP;
                            ALU_SEL_O   = `EXE_RES_LOGIC;
                            // 读出寄存器rs，rt里的数据
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            // 指令有效信号
                            inst_valid  = `INST_VALID;
                        end
                        // AND指令 
                        `EXE_AND: begin                      
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_AND_OP;
                            ALU_SEL_O   = `EXE_RES_LOGIC;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // XOR指令 
                        `EXE_XOR: begin                      
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_XOR_OP;
                            ALU_SEL_O   = `EXE_RES_LOGIC;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // NOR指令
                        `EXE_NOR: begin        
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_NOR_OP;
                            ALU_SEL_O   = `EXE_RES_LOGIC;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // SLLV指令
                            // SL for Shift Left，为左移
                            // V for Variable，代表左移的位数由一个寄存器中的变量决定
                            // L for Logic， 代表逻辑左移
                        `EXE_SLLV: begin                     
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_SLL_OP;
                            ALU_SEL_O   = `EXE_RES_SHIFT;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // SRLV指令
                        `EXE_SRLV: begin                       
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_SRL_OP;
                            ALU_SEL_O   = `EXE_RES_SHIFT;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // SRAV指令
                            // A for Arithmetic，代表算术右移  
                        `EXE_SRAV: begin                     
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_SRA_OP;
                            ALU_SEL_O   = `EXE_RES_SHIFT;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // SYNC指令  
                        `EXE_SYNC: begin                     
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_SYNC_OP;
                            ALU_SEL_O   = `EXE_RES_NOP;
                            REG1_REN_O  = `RDISABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // MFHI指令
                            // F for from，代表从HI寄存器中取值，写入rd寄存器中
                        `EXE_MFHI: begin       
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_MFHI_OP;
                            ALU_SEL_O   = `EXE_RES_MOVE;
                            REG1_REN_O  = `RDISABLE;
                            REG2_REN_O  = `RDISABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // MFLO指令
                        `EXE_MFLO: begin       
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_MFLO_OP;
                            ALU_SEL_O   = `EXE_RES_MOVE;
                            REG1_REN_O  = `RDISABLE;
                            REG2_REN_O  = `RDISABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // MTHI和MTLO指令不带有运算类型指示,他们单独处理
                        // MTHI指令
                            // T for To，代表将rs寄存器值写入HI寄存器中
                        `EXE_MTHI: begin       
                            WEN_O       = `WDISABLE;
                            ALU_OP_O    = `EXE_MTHI_OP;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RDISABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // MTLO指令
                        `EXE_MTLO:  begin       
                            WEN_O       = `WDISABLE;
                            ALU_OP_O    = `EXE_MTLO_OP;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RDISABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // MOVN指令
                            // rt寄存器中值不为0时，rs寄存器值存至rd中
                        `EXE_MOVN:  begin       
                            ALU_OP_O    = `EXE_MOVN_OP;
                            ALU_SEL_O   = `EXE_RES_MOVE;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                            if (REG2_DATA_O != `ZERO_WORD) begin
                                WEN_O   = `WENABLE;
                            end else begin
                                WEN_O   = `WDISABLE;
                            end
                        end
                        // MOVZ指令
                            // rt寄存器中值为0时，rs寄存器值存至rd中
                        `EXE_MOVZ:  begin  
                            ALU_OP_O    = `EXE_MOVZ_OP;
                            ALU_SEL_O   = `EXE_RES_MOVE;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                            if (REG2_DATA_O == `ZERO_WORD) begin
                                WEN_O   = `WENABLE;
                            end else begin
                                WEN_O   = `WDISABLE;
                            end
                        end
                        // ADD指令
                        `EXE_ADD:   begin   
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_ADD_OP;
                            ALU_SEL_O   = `EXE_RES_ARITH;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // ADDU指令
                        `EXE_ADDU:  begin   
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_ADDU_OP;
                            ALU_SEL_O   = `EXE_RES_ARITH;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // SUB指令
                        `EXE_SUB:   begin   
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_SUB_OP;
                            ALU_SEL_O   = `EXE_RES_ARITH;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // SUBU指令
                        `EXE_SUBU:  begin   
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_SUBU_OP;
                            ALU_SEL_O   = `EXE_RES_ARITH;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // SLT指令
                        `EXE_SLT:   begin   
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_SLT_OP;
                            ALU_SEL_O   = `EXE_RES_ARITH;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // SLTU指令
                        `EXE_SLTU:  begin   
                            WEN_O       = `WENABLE;
                            ALU_OP_O    = `EXE_SLTU_OP;
                            ALU_SEL_O   = `EXE_RES_ARITH;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // MULT指令    
                            // MULT写HI与LO寄存器而不是rd，所以拉低写入使能信号
                        `EXE_MULT:   begin   
                            WEN_O       = `WDISABLE;
                            ALU_OP_O    = `EXE_MULT_OP;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // MULTU指令
                        `EXE_MULTU:  begin   
                            WEN_O       = `WDISABLE;
                            ALU_OP_O    = `EXE_MULTU_OP;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // DIV指令
                        `EXE_DIV:  begin   
                            WEN_O       = `WDISABLE;
                            ALU_OP_O    = `EXE_DIV_OP;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // DIVU指令
                        `EXE_DIVU:  begin   
                            WEN_O       = `WDISABLE;
                            ALU_OP_O    = `EXE_DIVU_OP;
                            REG1_REN_O  = `RENABLE;
                            REG2_REN_O  = `RENABLE;
                            inst_valid  = `INST_VALID;
                        end
                        // JR指令
                        `EXE_JR:    begin
                            WEN_O           = `WDISABLE;
                            ALU_OP_O        = `EXE_JR_OP;
                            ALU_SEL_O       = `EXE_RES_JB;
                            REG1_REN_O      = `RENABLE;
                            REG2_REN_O      = `RDISABLE;
                            BRANCH_FLAG     = `GO_BRANCH;
                            BRANCH_TAR_ADDR      = REG1_DATA_O;
                            BRANCH_LINK_ADDR    = `ZERO_WORD;
                            NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                            inst_valid  = `INST_VALID;
                        end
                        // JALR指令
                        `EXE_JALR:    begin
                            WEN_O           = `WENABLE;
                            WADDR_O         = rd == 5'b00000 ? 5'b11111 : rd;
                            ALU_OP_O        = `EXE_JALR_OP;
                            ALU_SEL_O       = `EXE_RES_JB;
                            REG1_REN_O      = `RENABLE;
                            REG2_REN_O      = `RDISABLE;
                            BRANCH_FLAG     = `GO_BRANCH;
                            BRANCH_TAR_ADDR      = REG1_DATA_O;
                            BRANCH_LINK_ADDR    = pc_plus_8;
                            NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                            inst_valid  = `INST_VALID;
                        end
                        default: begin
                            // 此时的func若无对应则为nop指令
                        end
                    endcase
                end 
                default: begin
                    // 假如sa位不全为0，这种指令要么是无效的，要么是直接移位指令
                end
            endcase
        end
        // SPECIAL2型指令
        `EXE_SPECIAL2:  begin
            case (func)
                // CLZ指令
                `EXE_CLZ:   begin
                    WEN_O       = `WENABLE;
                    ALU_OP_O    = `EXE_CLZ_OP;
                    ALU_SEL_O   = `EXE_RES_ARITH;
                    // CLZ和CLO指令只需要读rs寄存器，不需要读rt寄存器
                    REG1_REN_O  = `RENABLE;
                    REG2_REN_O  = `RDISABLE;
                    inst_valid  = `INST_VALID;
                end
                // CLO指令
                `EXE_CLO:   begin
                    WEN_O       = `WENABLE;
                    ALU_OP_O    = `EXE_CLO_OP;
                    ALU_SEL_O   = `EXE_RES_ARITH;
                    REG1_REN_O  = `RENABLE;
                    REG2_REN_O  = `RDISABLE;
                    inst_valid  = `INST_VALID;
                end
                // MUL指令
                `EXE_MUL:   begin
                    WEN_O       = `WENABLE;
                    ALU_OP_O    = `EXE_MUL_OP;
                    ALU_SEL_O   = `EXE_RES_MUL;
                    REG1_REN_O  = `RENABLE;
                    REG2_REN_O  = `RENABLE;
                    inst_valid  = `INST_VALID;
                end
                default:    begin
                    // SPECIAL2型指令下无对应func即为无效指令
                    INST_ERR = inst_valid;
                end
            endcase
        end
        // REGIMM型指令
        `EXE_REGIMM: begin
            case (rt)
                `EXE_BLTZ:  begin
                    WEN_O           = `WDISABLE;
                    ALU_OP_O        = `EXE_BLTZ_OP;
                    ALU_SEL_O       = `EXE_RES_JB;
                    REG1_REN_O      = `RENABLE;
                    REG2_REN_O      = `RDISABLE;
                    inst_valid      = `INST_VALID;
                    if (REG1_DATA_O[31]) begin
                        BRANCH_FLAG     = `GO_BRANCH;
                        BRANCH_TAR_ADDR      = ext_addr_sll2 + pc_plus_4;
                        BRANCH_LINK_ADDR    = `ZERO_WORD;
                        NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                    end
                end
                `EXE_BGEZ:  begin
                    WEN_O           = `WDISABLE;
                    ALU_OP_O        = `EXE_BGEZ_OP;
                    ALU_SEL_O       = `EXE_RES_JB;
                    REG1_REN_O      = `RENABLE;
                    REG2_REN_O      = `RDISABLE;
                    inst_valid      = `INST_VALID;
                    if (!REG1_DATA_O[31]) begin
                        BRANCH_FLAG     = `GO_BRANCH;
                        BRANCH_TAR_ADDR      = ext_addr_sll2 + pc_plus_4;
                        BRANCH_LINK_ADDR    = `ZERO_WORD;
                        NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                    end
                end
                `EXE_BLTZAL:  begin
                    ALU_OP_O        = `EXE_BLTZAL_OP;
                    ALU_SEL_O       = `EXE_RES_JB;
                    REG1_REN_O      = `RENABLE;
                    REG2_REN_O      = `RDISABLE;
                    inst_valid      = `INST_VALID;
                    if (REG1_DATA_O[31]) begin
                        WEN_O           = `WENABLE;
                        WADDR_O         = 5'b11111;
                        BRANCH_FLAG     = `GO_BRANCH;
                        BRANCH_TAR_ADDR      = ext_addr_sll2 + pc_plus_4;
                        BRANCH_LINK_ADDR    = pc_plus_8;
                        NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                    end
                end
                `EXE_BGEZAL:  begin
                    ALU_OP_O        = `EXE_BGEZAL_OP;
                    ALU_SEL_O       = `EXE_RES_JB;
                    REG1_REN_O      = `RENABLE;
                    REG2_REN_O      = `RDISABLE;
                    inst_valid      = `INST_VALID;
                    if (!REG1_DATA_O[31]) begin
                        WEN_O           = `WENABLE;
                        WADDR_O         = 5'b11111;
                        BRANCH_FLAG     = `GO_BRANCH;
                        BRANCH_TAR_ADDR     = ext_addr_sll2 + pc_plus_4;
                        BRANCH_LINK_ADDR    = pc_plus_8;
                        NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                    end
                end 
                default:    begin
                    INST_ERR = inst_valid;
                end 
            endcase
        end
        default:    begin
            // 若op中无可能对应指令，该指令无效
            INST_ERR = inst_valid;
        end 
        endcase
        // 空指令和直接移位指令的译码
        if({op, rs} == 11'b00000000000)  begin
            case (func)
                `EXE_SLL:   begin
                    WADDR_O         = rd;
                    WEN_O           = `WENABLE;
                    // 以寄存器存储偏移量的移位指令的sa需要作为运算信息传递给ex模块
                    ext_imm[4:0]    = sa;
                    ALU_OP_O        = `EXE_SLL_OP;
                    ALU_SEL_O       = `EXE_RES_SHIFT;
                    REG1_REN_O      = `RDISABLE;
                    REG2_REN_O      = `RENABLE;
                    inst_valid      = `INST_VALID;
                end 
                `EXE_SRL:   begin
                    WADDR_O         = rd;
                    WEN_O           = `WENABLE;
                    ext_imm[4:0]    = sa;
                    ALU_OP_O        = `EXE_SRL_OP;
                    ALU_SEL_O       = `EXE_RES_SHIFT;
                    REG1_REN_O      = `RDISABLE;
                    REG2_REN_O      = `RENABLE;
                    inst_valid      = `INST_VALID;
                end
                `EXE_SRA:   begin
                    WADDR_O         = rd;
                    WEN_O           = `WENABLE;
                    ext_imm[4:0]    = sa;
                    ALU_OP_O        = `EXE_SRA_OP;
                    ALU_SEL_O       = `EXE_RES_SHIFT;
                    REG1_REN_O      = `RDISABLE;
                    REG2_REN_O      = `RENABLE;
                    inst_valid      = `INST_VALID;
                end
                default:    begin
                    
                end
            endcase
        end
    end
  end

  /* Part2:确定源操作数1 REG1_DATA_O */
  always_comb begin
    if(RST == `RST_EN) begin
        REG1_DATA_O = `ZERO_WORD;
    end else if((REG1_REN_O == `RENABLE) && (EX_WEN_I == `WENABLE) && (EX_WADDR_I == REG1_ADDR_O) && (EX_WADDR_I != 0)) begin
        // 相邻指令的数据前递
            // 检测上一条指令执行阶段所得到的写入地址和写使能信息
            // 假若执行模块指示上一条指令需要写寄存器且写地址为当前指令的源寄存器1，将上一条指令执行模块的写结果传递给当前指令的执行模块
        REG1_DATA_O = EX_WDATA_I;
    end else if((REG1_REN_O == `RENABLE) && (MEM_WEN_I == `WENABLE) && (MEM_WADDR_I == REG1_ADDR_O)) begin 
        // 相隔一条指令的数据前递 
            // 检测上上一条指令访存阶段所得到的写入地址和写使能信息
            // 假若访存模块指示上上一条指令需要写寄存器且写地址为当前指令的源寄存器1，将上上一条指令访存模块的写数据传递给当前指令的执行模块
        REG1_DATA_O = MEM_WDATA_I;
    end else if(REG1_REN_O == `RENABLE) begin
        REG1_DATA_O = REG1_DATA_I;
    end else if(REG1_REN_O == `RDISABLE) begin
        REG1_DATA_O = ext_imm;
    end else begin
        REG1_DATA_O = `ZERO_WORD;
    end
  end

  /* Part3:确定源操作数2 REG2_DATA_O */
  always_comb begin
    if(RST == `RST_EN) begin
        REG2_DATA_O = `ZERO_WORD;
    end else if((REG2_REN_O == `RENABLE) && (EX_WEN_I == `WENABLE) && (EX_WADDR_I == REG2_ADDR_O) && (EX_WADDR_I != 0)) begin 
        // 相邻指令的数据前递
            // 检测上一条指令执行阶段所得到的写入地址和写使能信息
            // 假若执行模块指示上一条指令需要写寄存器且写地址为当前指令的源寄存器2，将上一条指令执行模块的写结果传递给当前指令的执行模块
        REG2_DATA_O = EX_WDATA_I;
    end else if((REG2_REN_O == `RENABLE) && (MEM_WEN_I == `WENABLE) && (MEM_WADDR_I == REG2_ADDR_O)) begin 
        // 相隔一条指令的数据前递 
            // 检测上上一条指令访存阶段所得到的写入地址和写使能信息
            // 假若访存模块指示上上一条指令需要写寄存器且写地址为当前指令的源寄存器2，将上上一条指令访存模块的写数据传递给当前指令的执行模块
        REG2_DATA_O = MEM_WDATA_I;
    end else if(REG2_REN_O == `RENABLE) begin
        REG2_DATA_O = REG2_DATA_I;
    end else if(REG2_REN_O == `RDISABLE) begin
        REG2_DATA_O = ext_imm;
    end else begin
        REG2_DATA_O = `ZERO_WORD;
    end
  end

  /* Part4: 延迟槽指示信号 */
  always_comb begin : DELAY_SLOT_FLAG
    if (RST == `RST_EN) begin
        CUR_INST_DS_FLAG_O = `OUT_DELAY_SLOT;
    end else begin
        CUR_INST_DS_FLAG_O = CUR_INST_DS_FLAG_I; 
    end
  end

  /* Part5: 流水线停滞信号 */
  always_comb begin : STALL_REQUEST_REG1
    if (RST == `RST_EN) begin
        stall_req_reg1 = `NOT_STOP;
    end else begin
        case (EX_ALU_OP_I)
            `EXE_LW_OP, `EXE_LB_OP, `EXE_LH_OP, `EXE_LBU_OP, `EXE_LHU_OP: begin
                // 当上一条指令在LOAD段的写入地址为寄存器1,则寄存器1请求流水线停滞
                if (EX_WADDR_I == REG1_ADDR_O) begin
                    stall_req_reg1 = `STOP;
                end
            end 
            default: begin
                stall_req_reg1 = `NOT_STOP;
            end
        endcase
    end
  end

  always_comb begin : STALL_REQUEST_REG2
    if (RST == `RST_EN) begin
        stall_req_reg2 = `NOT_STOP;
    end else begin
        case (EX_ALU_OP_I)
            `EXE_LW_OP, `EXE_LB_OP, `EXE_LH_OP, `EXE_LBU_OP, `EXE_LHU_OP: begin
                // 当上一条指令在LOAD段的写入地址为寄存器2,则寄存器2请求流水线停滞
                if (EX_WADDR_I == REG2_ADDR_O) begin
                    stall_req_reg2 = `STOP;
                end
            end 
            default: begin
                stall_req_reg2 = `NOT_STOP;
            end
        endcase
    end
  end
  
  assign STALL_REQ = stall_req_reg1 | stall_req_reg2;
endmodule
