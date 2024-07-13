`timescale 1ns / 1ps
`include "defines.vh"

module id(
    input   logic                  RST,
    input   logic [`SRAM_ADDR_BUS] PC_I,
    input   logic [`SRAM_DATA_BUS] INST_I,
    input   logic                  CUR_INST_DS_FLAG_I,
    // GPRs2ID
    input   logic [ `REG_DATA_BUS] REG1_DATA_I,
    input   logic [ `REG_DATA_BUS] REG2_DATA_I,
    // EXfw2ID
    input   logic                  EX_GPR_WE_I,
    input   logic [   `ALU_OP_BUS] EX_ALU_OP_I,
    input   logic [ `REG_ADDR_BUS] EX_GPR_WADDR_I,
    input   logic [ `REG_DATA_BUS] EX_GPR_WDATA_I,
    // MEMfw2ID
    input   logic                  MEM_GPR_WE_I,
    input   logic [ `REG_ADDR_BUS] MEM_GPR_WADDR_I,
    input   logic [ `REG_DATA_BUS] MEM_GPR_WDATA_I,

    output  logic                  ERROR,
    output  logic                  STALL_REQ,
    // GPRs
    output  logic                  REG1_RE_O,
    output  logic                  REG2_RE_O,
    output  logic [ `REG_ADDR_BUS] REG1_ADDR_O,
    output  logic [ `REG_ADDR_BUS] REG2_ADDR_O,
    // ID2EX
    output  logic                  GPR_WE_O,
    output  logic                  CUR_INST_DS_FLAG_O,
    output  logic                  NEXT_INST_DS_FLAG_O,
    output  logic [   `ALU_OP_BUS] ALU_OP_O,
    output  logic [  `ALU_SEL_BUS] ALU_SEL_O,
    output  logic [ `REG_DATA_BUS] REG1_DATA_O,
    output  logic [ `REG_DATA_BUS] REG2_DATA_O,
    output  logic [ `REG_ADDR_BUS] GPR_WADDR_O,
    output  logic [`SRAM_DATA_BUS] INST_O,
    // ID2IF
    output  logic                  BRANCH_FLAG,
    output  logic [ `REG_DATA_BUS] BRANCH_TAR_ADDR,
    output  logic [ `REG_DATA_BUS] BRANCH_LINK_ADDR
);
    /* 指令拆分后的各个部分 */
    logic [          5:0] op;
    logic [          4:0] sa;
    logic [          5:0] func;
    logic [          4:0] rs;
    logic [          4:0] rt;
    logic [          4:0] rd;
    logic [         15:0] imm;
    logic [         25:0] target;
    logic [`REG_DATA_BUS] pc_plus_4;
    logic [`REG_DATA_BUS] pc_plus_8;
    logic [`REG_DATA_BUS] ext_addr_sll2;
    logic [`REG_DATA_BUS] jump_addr_sll2;
    /* 特殊信号 */
    logic                 inst_valid;
    logic                 reg1_stall_req;
    logic                 reg2_stall_req;
    logic [`REG_DATA_BUS] ext_imm;

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
            inst_valid            = `INST_INVALID;
            ext_imm               = `ZERO_WORD;
            ERROR                 = `NOERR;
            ALU_OP_O              = `EXE_NOP_OP;
            ALU_SEL_O             = `EXE_RES_NOP;
            GPR_WADDR_O           = `REG_ZERO_ADDR;
            GPR_WE_O              = ~`WE;
            REG1_RE_O             = ~`RE;
            REG2_RE_O             = ~`RE;
            REG1_ADDR_O           = `REG_ZERO_ADDR;
            REG2_ADDR_O           = `REG_ZERO_ADDR;
            BRANCH_FLAG           = `NOT_BRANCH;
            BRANCH_TAR_ADDR       = `ZERO_WORD;
            BRANCH_LINK_ADDR      = `ZERO_WORD;
            NEXT_INST_DS_FLAG_O   = `OUT_DELAY_SLOT;
        end else begin
            inst_valid            = `INST_INVALID;
            ext_imm               = `ZERO_WORD;
            ERROR                 = `NOERR;
            ALU_OP_O              = `EXE_NOP_OP;
            ALU_SEL_O             = `EXE_RES_NOP;
            GPR_WADDR_O           = rd;
            GPR_WE_O              = ~`WE;
            REG1_RE_O             = ~`RE;
            REG2_RE_O             = ~`RE;
            REG1_ADDR_O           = rs;
            REG2_ADDR_O           = rt;
            BRANCH_FLAG           = `NOT_BRANCH;
            BRANCH_TAR_ADDR       = `ZERO_WORD;
            BRANCH_LINK_ADDR      = `ZERO_WORD;
            NEXT_INST_DS_FLAG_O   = `OUT_DELAY_SLOT;
            case (op)
                // ORI指令
                `EXE_ORI: begin
                    GPR_WADDR_O       = rt;                   
                    GPR_WE_O          = `WE;
                    ALU_OP_O          = `EXE_OR_OP;
                    ALU_SEL_O         = `EXE_RES_LOGIC;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = ~`RE;
                    ext_imm           = {16'h0, imm};
                    inst_valid        = `INST_VALID;
                end
                `EXE_ANDI: begin
                    GPR_WADDR_O       = rt;
                    GPR_WE_O          = `WE;
                    ALU_OP_O          = `EXE_AND_OP;
                    ALU_SEL_O         = `EXE_RES_LOGIC;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = ~`RE;
                    ext_imm           = {16'h0, imm};
                    inst_valid        = `INST_VALID;
                end
                `EXE_XORI: begin
                    GPR_WADDR_O       = rt;
                    GPR_WE_O          = `WE;
                    ALU_OP_O          = `EXE_XOR_OP;
                    ALU_SEL_O         = `EXE_RES_LOGIC;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = ~`RE;
                    ext_imm           = {16'h0, imm};
                    inst_valid        = `INST_VALID;
                end
                `EXE_LUI: begin
                    GPR_WADDR_O       = rt;
                    GPR_WE_O          = `WE;
                    ALU_OP_O          = `EXE_LUI_OP;
                    ALU_SEL_O         = `EXE_RES_LOGIC;
                    REG1_RE_O         = ~`RE;
                    REG2_RE_O         = ~`RE;
                    ext_imm           = {imm, 16'h0};
                    inst_valid        = `INST_VALID;
                end
                `EXE_ADDI: begin
                    GPR_WADDR_O       = rt;
                    GPR_WE_O          = `WE;
                    ALU_OP_O          = `EXE_ADD_OP;
                    ALU_SEL_O         = `EXE_RES_ARITH;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = ~`RE;
                    ext_imm           = {{16{imm[15]}}, imm};
                    inst_valid        = `INST_VALID;
                end
                `EXE_ADDIU: begin
                    GPR_WADDR_O       = rt;
                    GPR_WE_O          = `WE;
                    ALU_OP_O          = `EXE_ADDU_OP;
                    ALU_SEL_O         = `EXE_RES_ARITH;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = ~`RE;
                    ext_imm           = {{16{imm[15]}}, imm};
                    inst_valid        = `INST_VALID;
                end
                `EXE_J: begin
                    GPR_WE_O          = ~`WE;
                    ALU_OP_O          = `EXE_J_OP;
                    ALU_SEL_O         = `EXE_RES_JB;
                    REG1_RE_O         = ~`RE;
                    REG2_RE_O         = ~`RE;
                    BRANCH_FLAG       = `GO_BRANCH;
                    BRANCH_TAR_ADDR   = jump_addr_sll2;
                    BRANCH_LINK_ADDR  = `ZERO_WORD;
                    NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                    inst_valid        = `INST_VALID;
                end
                `EXE_JAL: begin
                    GPR_WE_O          = `WE;
                    GPR_WADDR_O       = 5'b11111;
                    ALU_OP_O          = `EXE_JAL_OP;
                    ALU_SEL_O         = `EXE_RES_JB;
                    REG1_RE_O         = ~`RE;
                    REG2_RE_O         = ~`RE;
                    BRANCH_FLAG       = `GO_BRANCH;
                    BRANCH_TAR_ADDR   = jump_addr_sll2;
                    BRANCH_LINK_ADDR  = pc_plus_8;
                    NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                    inst_valid        = `INST_VALID;
                end
                `EXE_BEQ: begin
                    GPR_WE_O          = ~`WE;
                    ALU_OP_O          = `EXE_BEQ_OP;
                    ALU_SEL_O         = `EXE_RES_JB;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = `RE;
                    inst_valid        = `INST_VALID;
                    if (REG1_DATA_O == REG2_DATA_O) begin
                        BRANCH_FLAG       = `GO_BRANCH;
                        BRANCH_TAR_ADDR   = ext_addr_sll2 + pc_plus_4;
                        BRANCH_LINK_ADDR  = `ZERO_WORD;
                        NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                    end
                end
                `EXE_BNE: begin
                    GPR_WE_O          = ~`WE;
                    ALU_OP_O          = `EXE_BNE_OP;
                    ALU_SEL_O         = `EXE_RES_JB;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = `RE;
                    inst_valid        = `INST_VALID;
                    if (REG1_DATA_O != REG2_DATA_O) begin
                        BRANCH_FLAG       = `GO_BRANCH;
                        BRANCH_TAR_ADDR   = ext_addr_sll2 + pc_plus_4;
                        BRANCH_LINK_ADDR  = `ZERO_WORD;
                        NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                    end
                end
                `EXE_BGTZ: begin
                    GPR_WE_O          = ~`WE;
                    ALU_OP_O          = `EXE_BGTZ_OP;
                    ALU_SEL_O         = `EXE_RES_JB;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = ~`RE;
                    inst_valid        = `INST_VALID;
                    if (REG1_DATA_O > 32'b0) begin
                        BRANCH_FLAG       = `GO_BRANCH;
                        BRANCH_TAR_ADDR   = ext_addr_sll2 + pc_plus_4;
                        BRANCH_LINK_ADDR  = `ZERO_WORD;
                        NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                    end
                end
                `EXE_BLEZ: begin
                    GPR_WE_O          = ~`WE;
                    ALU_OP_O          = `EXE_BLEZ_OP;
                    ALU_SEL_O         = `EXE_RES_JB;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = ~`RE;
                    inst_valid        = `INST_VALID;
                    if (REG1_DATA_O <= 32'b0) begin
                        BRANCH_FLAG       = `GO_BRANCH;
                        BRANCH_TAR_ADDR   = ext_addr_sll2 + pc_plus_4;
                        BRANCH_LINK_ADDR  = `ZERO_WORD;
                        NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                    end
                end
                `EXE_LB: begin
                    GPR_WADDR_O       = rt;
                    GPR_WE_O          = `WE;
                    ALU_OP_O          = `EXE_LB_OP;
                    ALU_SEL_O         = `EXE_RES_LS;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = ~`RE;
                    ext_imm           = {{16{imm[15]}}, imm};
                    inst_valid        = `INST_VALID;
                end
                `EXE_LW: begin
                    GPR_WADDR_O       = rt;
                    GPR_WE_O          = `WE;
                    ALU_OP_O          = `EXE_LW_OP;
                    ALU_SEL_O         = `EXE_RES_LS;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = ~`RE;
                    ext_imm           = {{16{imm[15]}}, imm};
                    inst_valid        = `INST_VALID;
                end
                `EXE_SB: begin
                    GPR_WE_O          = ~`WE;
                    ALU_OP_O          = `EXE_SB_OP;
                    ALU_SEL_O         = `EXE_RES_LS;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = `RE;
                    inst_valid        = `INST_VALID;
                end
                `EXE_SW: begin
                    GPR_WE_O          = ~`WE;
                    ALU_OP_O          = `EXE_SW_OP;
                    ALU_SEL_O         = `EXE_RES_LS;
                    REG1_RE_O         = `RE;
                    REG2_RE_O         = `RE;
                    inst_valid        = `INST_VALID;
                end
                `EXE_SPECIAL: begin
                    case (sa)
                    // 当sa�?0，指令有�?
                    5'b00000: begin
                        case (func)
                            `EXE_OR: begin
                                GPR_WE_O          = `WE;
                                ALU_OP_O          = `EXE_OR_OP;
                                ALU_SEL_O         = `EXE_RES_LOGIC;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_AND: begin
                                GPR_WE_O          = `WE;
                                ALU_OP_O          = `EXE_AND_OP;
                                ALU_SEL_O         = `EXE_RES_LOGIC;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_XOR: begin
                                GPR_WE_O          = `WE;
                                ALU_OP_O          = `EXE_XOR_OP;
                                ALU_SEL_O         = `EXE_RES_LOGIC;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_SLLV: begin
                                GPR_WE_O          = `WE;
                                ALU_OP_O          = `EXE_SLL_OP;
                                ALU_SEL_O         = `EXE_RES_SHIFT;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_SRLV: begin
                                GPR_WE_O          = `WE;
                                ALU_OP_O          = `EXE_SRL_OP;
                                ALU_SEL_O         = `EXE_RES_SHIFT;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_SRAV: begin
                                GPR_WE_O          = `WE;
                                ALU_OP_O          = `EXE_SRA_OP;
                                ALU_SEL_O         = `EXE_RES_SHIFT;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_ADD: begin
                                GPR_WE_O          = `WE;
                                ALU_OP_O          = `EXE_ADD_OP;
                                ALU_SEL_O         = `EXE_RES_ARITH;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_ADDU: begin
                                GPR_WE_O          = `WE;
                                ALU_OP_O          = `EXE_ADDU_OP;
                                ALU_SEL_O         = `EXE_RES_ARITH;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_SUB: begin
                                GPR_WE_O          = `WE;
                                ALU_OP_O          = `EXE_SUB_OP;
                                ALU_SEL_O         = `EXE_RES_ARITH;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_SLT: begin
                                GPR_WE_O          = `WE;
                                ALU_OP_O          = `EXE_SLT_OP;
                                ALU_SEL_O         = `EXE_RES_ARITH;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_DIV: begin
                                GPR_WE_O          = ~`WE;
                                ALU_OP_O          = `EXE_DIV_OP;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_DIVU: begin
                                GPR_WE_O          = ~`WE;
                                ALU_OP_O          = `EXE_DIVU_OP;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = `RE;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_JR: begin
                                GPR_WE_O          = ~`WE;
                                ALU_OP_O          = `EXE_JR_OP;
                                ALU_SEL_O         = `EXE_RES_JB;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = ~`RE;
                                BRANCH_FLAG       = `GO_BRANCH;
                                BRANCH_TAR_ADDR   = REG1_DATA_O;
                                BRANCH_LINK_ADDR  = `ZERO_WORD;
                                NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                                inst_valid        = `INST_VALID;
                            end
                            `EXE_JALR: begin
                                GPR_WE_O          = `WE;
                                GPR_WADDR_O       = rd == 5'b00000 ? 5'b11111 : rd;
                                ALU_OP_O          = `EXE_JALR_OP;
                                ALU_SEL_O         = `EXE_RES_JB;
                                REG1_RE_O         = `RE;
                                REG2_RE_O         = ~`RE;
                                BRANCH_FLAG       = `GO_BRANCH;
                                BRANCH_TAR_ADDR   = REG1_DATA_O;
                                BRANCH_LINK_ADDR  = pc_plus_8;
                                NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                                inst_valid        = `INST_VALID;
                            end
                            default: begin
                                
                            end
                        endcase
                    end
                    default: begin
                        // 假如sa位不全为0，这种指令要么是无效的，要么是直接移位指�?
                    end
                    endcase
                end
                `EXE_SPECIAL2: begin
                    case (func)
                        // MUL指令
                        `EXE_MUL: begin
                            GPR_WE_O          = `WE;
                            ALU_OP_O          = `EXE_MUL_OP;
                            ALU_SEL_O         = `EXE_RES_MUL;
                            REG1_RE_O         = `RE;
                            REG2_RE_O         = `RE;
                            inst_valid        = `INST_VALID;
                        end
                        default: begin
                            
                        end
                    endcase
                end
                `EXE_REGIMM: begin
                    case (rt)
                        `EXE_BLTZ: begin
                            GPR_WE_O          = ~`WE;
                            ALU_OP_O          = `EXE_BLTZ_OP;
                            ALU_SEL_O         = `EXE_RES_JB;
                            REG1_RE_O         = `RE;
                            REG2_RE_O         = ~`RE;
                            inst_valid        = `INST_VALID;
                            if (REG1_DATA_O[31]) begin
                                BRANCH_FLAG       = `GO_BRANCH;
                                BRANCH_TAR_ADDR   = ext_addr_sll2 + pc_plus_4;
                                BRANCH_LINK_ADDR  = `ZERO_WORD;
                                NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                            end
                        end
                        `EXE_BGEZ: begin
                            GPR_WE_O          = ~`WE;
                            ALU_OP_O          = `EXE_BGEZ_OP;
                            ALU_SEL_O         = `EXE_RES_JB;
                            REG1_RE_O         = `RE;
                            REG2_RE_O         = ~`RE;
                            inst_valid        = `INST_VALID;
                            if (!REG1_DATA_O[31]) begin
                                BRANCH_FLAG       = `GO_BRANCH;
                                BRANCH_TAR_ADDR   = ext_addr_sll2 + pc_plus_4;
                                BRANCH_LINK_ADDR  = `ZERO_WORD;
                                NEXT_INST_DS_FLAG_O = `IN_DELAY_SLOT;
                            end
                        end
                        default: begin
                            
                        end
                    endcase
                end
                default: begin
                    // 若op中无可能对应指令，该指令无效
                    ERROR = inst_valid;
                end
            endcase
            // 空指令和直接移位指令的译�?
            if ({op, rs} == 11'b00000000000) begin
                case (func)
                    `EXE_SLL: begin
                        GPR_WADDR_O       = rd;
                        GPR_WE_O          = `WE;
                        // 直接偏移量sa作为ext_imm的低5位传给ex�?
                        ext_imm[4:0]      = sa;
                        ALU_OP_O          = `EXE_SLL_OP;
                        ALU_SEL_O         = `EXE_RES_SHIFT;
                        REG1_RE_O         = ~`RE;
                        REG2_RE_O         = `RE;
                        inst_valid        = `INST_VALID;
                    end
                    `EXE_SRL: begin
                        GPR_WADDR_O       = rd;
                        GPR_WE_O          = `WE;
                        ext_imm[4:0]      = sa;
                        ALU_OP_O          = `EXE_SRL_OP;
                        ALU_SEL_O         = `EXE_RES_SHIFT;
                        REG1_RE_O         = ~`RE;
                        REG2_RE_O         = `RE;
                        inst_valid        = `INST_VALID;
                    end
                    `EXE_SRA: begin
                        GPR_WADDR_O       = rd;
                        GPR_WE_O          = `WE;
                        ext_imm[4:0]      = sa;
                        ALU_OP_O          = `EXE_SRA_OP;
                        ALU_SEL_O         = `EXE_RES_SHIFT;
                        REG1_RE_O         = ~`RE;
                        REG2_RE_O         = `RE;
                        inst_valid        = `INST_VALID;
                    end
                    default: begin
                        
                    end
                endcase
            end
        end
    end

    /* Part2:确定源操作数1 */
    always_comb begin: REG1_DATA_VALUE
        if(RST == `RST_EN) begin
            REG1_DATA_O = `ZERO_WORD;
        end else if((REG1_RE_O == `RE) && (EX_GPR_WE_I == `WE) && (EX_GPR_WADDR_I == REG1_ADDR_O) && (EX_GPR_WADDR_I != 0)) begin
            // EX-ID旁路
            REG1_DATA_O = EX_GPR_WDATA_I;
        end else if((REG1_RE_O == `RE) && (MEM_GPR_WE_I == `WE) && (MEM_GPR_WADDR_I == REG1_ADDR_O)) begin 
            // MEM-ID旁路
            REG1_DATA_O = MEM_GPR_WDATA_I;
        end else if(REG1_RE_O == `RE) begin
            REG1_DATA_O = REG1_DATA_I;
        end else begin
            REG1_DATA_O = ext_imm;
        end
    end

    /* Part3:确定源操作数2 */
    always_comb begin: REG2_DATA_VALUE
        if(RST == `RST_EN) begin
            REG2_DATA_O = `ZERO_WORD;
        end else if((REG2_RE_O == `RE) && (EX_GPR_WE_I == `WE) && (EX_GPR_WADDR_I == REG2_ADDR_O) && (EX_GPR_WADDR_I != 0)) begin 
            REG2_DATA_O = EX_GPR_WDATA_I;
        end else if((REG2_RE_O == `RE) && (MEM_GPR_WE_I == `WE) && (MEM_GPR_WADDR_I == REG2_ADDR_O)) begin 
            REG2_DATA_O = MEM_GPR_WDATA_I;
        end else if(REG2_RE_O == `RE) begin
            REG2_DATA_O = REG2_DATA_I;
        end else begin
            REG2_DATA_O = ext_imm;
        end
    end

    /* Part4: 延迟槽指示信号传�? */
    always_comb begin : DELAY_SLOT_FLAG
        if (RST == `RST_EN) begin
            CUR_INST_DS_FLAG_O = `OUT_DELAY_SLOT;
        end else begin
            CUR_INST_DS_FLAG_O = CUR_INST_DS_FLAG_I; 
        end
    end

    /* Part5: 流水线停滞信�? */
    always_comb begin : STALL_REQUEST_REG1
        if (RST == `RST_EN) begin
            reg1_stall_req = `NOT_STOP;
        end else begin
            case (EX_ALU_OP_I)
                `EXE_LW_OP, `EXE_LB_OP: begin
                    // 当一条指令在ex阶段�?要使用其前一条指令的加载指令结果数据�?,只能流水线暂�?
                        // 即在id级如若检测到ex级的指令类型为load且当前指令需要使用该load指令的目标数�?
                        // 则发起暂停请�?
                    if (EX_GPR_WADDR_I == REG1_ADDR_O) begin
                        reg1_stall_req = `STOP;
                    end else begin
                        reg1_stall_req = `NOT_STOP;
                    end
                end 
                default: begin
                    reg1_stall_req = `NOT_STOP;
                end
            endcase
        end
    end

    always_comb begin : STALL_REQUEST_REG2
        if (RST == `RST_EN) begin
            reg2_stall_req = `NOT_STOP;
        end else begin
            case (EX_ALU_OP_I)
                `EXE_LW_OP, `EXE_LB_OP: begin
                    if (EX_GPR_WADDR_I == REG2_ADDR_O) begin
                        reg2_stall_req = `STOP;
                    end else begin
                        reg2_stall_req = `NOT_STOP;
                    end
                end 
                default: begin
                    reg2_stall_req = `NOT_STOP;
                end
            endcase
        end
    end
    
    assign STALL_REQ = reg1_stall_req | reg2_stall_req;
endmodule
