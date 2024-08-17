`timescale 1ns / 1ps
`include "defines.vh"

module id(
    input   logic                  RST,
    /* IC2ID */
    input   logic [ `CPU_ADDR_BUS] PC_I,
    input   logic [`SRAM_DATA_BUS] INST_I,
    /* GPRs2ID */
    input   logic [ `REG_DATA_BUS] REG1_DATA_I,
    input   logic [ `REG_DATA_BUS] REG2_DATA_I,
    /* EXfw2ID */
    input   logic                  EX_GPR_WE_I,
    input   logic [ `REG_ADDR_BUS] EX_GPR_WADDR_I,
    input   logic [ `REG_DATA_BUS] EX_GPR_WDATA_I,
    input   logic [   `ALU_OP_BUS] EX_ALU_OP_I,
    /* DFfw2ID */
    input   logic                  DF_GPR_WE_I,
    input   logic [ `REG_ADDR_BUS] DF_GPR_WADDR_I,
    input   logic [ `REG_DATA_BUS] DF_GPR_WDATA_I,
    input   logic [   `ALU_OP_BUS] DF_ALU_OP_I,
    /* MEMfw2ID */
    input   logic                  MEM_GPR_WE_I,
    input   logic [ `REG_ADDR_BUS] MEM_GPR_WADDR_I,
    input   logic [ `REG_DATA_BUS] MEM_GPR_WDATA_I,
    /* ID2CTRL */
    output  logic                  STALL_REQ,
    /* ID2GPRs */
    output  logic                  REG1_RE_O,
    output  logic                  REG2_RE_O,
    output  logic [ `REG_ADDR_BUS] REG1_ADDR_O,
    output  logic [ `REG_ADDR_BUS] REG2_ADDR_O,
    /* ID2EX */
    output  logic                  GPR_WE_O,
    output  logic [ `REG_ADDR_BUS] GPR_WADDR_O,
    output  logic [ `REG_DATA_BUS] REG1_DATA_O,
    output  logic [ `REG_DATA_BUS] REG2_DATA_O,
    output  logic [          15:0] IMM,
    output  logic [   `ALU_OP_BUS] ALU_OP_O,
    output  logic [  `ALU_SEL_BUS] ALU_SEL_O,
    /* ID2IF */
    output  logic                  BRANCH_FLAG,
    output  logic [ `REG_DATA_BUS] BRANCH_TAR_ADDR,
    output  logic [ `REG_DATA_BUS] BRANCH_LINK_ADDR
);
/*************** INSTRUCTION SPLIT BEGIN ***************/
    logic [          5:0] op;
    logic [          4:0] sa;
    logic [          5:0] func;
    logic [          4:0] rs;
    logic [          4:0] rt;
    logic [          4:0] rd;
    logic [         15:0] imm;
    logic [         25:0] target;
    logic [`REG_DATA_BUS] ext_imm;
    logic [`REG_DATA_BUS] pc_plus_4;
    logic [`REG_DATA_BUS] pc_plus_8;
    logic [`REG_DATA_BUS] ext_addr_sll2;
    logic [`REG_DATA_BUS] jump_addr_sll2;

    always_comb begin : INSTRUCTION_SPLIT
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
        IMM            = INST_I[15:0];
    end
/**************** INSTRUCTION SPLIT END ****************/

/*************** CONFIRM SOURCE DATA BEGIN ***************/
    always_comb begin: REG1_DATA
        if (RST == `RST_EN) begin
            REG1_DATA_O = `ZERO_WORD;
        end else if (REG1_RE_O == `RE) begin
            if ((EX_GPR_WE_I == `WE) && (EX_GPR_WADDR_I == REG1_ADDR_O) && (EX_GPR_WADDR_I != `REG_ZERO_ADDR)) begin
                // EX-ID旁路
                REG1_DATA_O = EX_GPR_WDATA_I;
            end else if ((DF_GPR_WE_I == `WE) && (DF_GPR_WADDR_I == REG1_ADDR_O) && (DF_GPR_WADDR_I != `REG_ZERO_ADDR)) begin
                // DF-ID旁路
                REG1_DATA_O = DF_GPR_WDATA_I;
            end else if ((MEM_GPR_WE_I == `WE) && (MEM_GPR_WADDR_I == REG1_ADDR_O) && (MEM_GPR_WADDR_I != `REG_ZERO_ADDR)) begin
                // MEM-ID旁路
                REG1_DATA_O = MEM_GPR_WDATA_I;
            end else begin
                REG1_DATA_O = REG1_DATA_I;
            end
        end else begin
            REG1_DATA_O = ext_imm;
        end
    end

    always_comb begin: REG2_DATA
        if (RST == `RST_EN) begin
            REG2_DATA_O = `ZERO_WORD;
        end else if (REG2_RE_O == `RE) begin
            if ((EX_GPR_WE_I == `WE) && (EX_GPR_WADDR_I == REG2_ADDR_O) && (EX_GPR_WADDR_I != `REG_ZERO_ADDR)) begin
                // EX-ID旁路
                REG2_DATA_O = EX_GPR_WDATA_I;
            end else if ((DF_GPR_WE_I == `WE) && (DF_GPR_WADDR_I == REG2_ADDR_O) && (DF_GPR_WADDR_I != `REG_ZERO_ADDR)) begin
                // DF-ID旁路
                REG2_DATA_O = DF_GPR_WDATA_I;
            end else if ((MEM_GPR_WE_I == `WE) && (MEM_GPR_WADDR_I == REG2_ADDR_O) && (MEM_GPR_WADDR_I != `REG_ZERO_ADDR)) begin
                // MEM-ID旁路
                REG2_DATA_O = MEM_GPR_WDATA_I;
            end else begin
                REG2_DATA_O = REG2_DATA_I;
            end
        end else begin
            REG2_DATA_O = ext_imm;
        end
    end
/**************** CONFIRM SOURCE DATA END ****************/

/*************** INSTRUCTION DECODE BEGIN ***************/
    logic                 inst_valid;
    always_comb begin : INSTRUCTION_DECODE
        if (RST == `RST_EN) begin
            inst_valid            = ~`INST_VALID;
            ext_imm               = `ZERO_WORD;
            ALU_OP_O              = `EXE_NOP_OP;
            ALU_SEL_O             = `EXE_RES_NOP;
            GPR_WADDR_O           = `REG_ZERO_ADDR;
            GPR_WE_O              = ~`WE;
            REG1_RE_O             = ~`RE;
            REG2_RE_O             = ~`RE;
            REG1_ADDR_O           = `REG_ZERO_ADDR;
            REG2_ADDR_O           = `REG_ZERO_ADDR;
            BRANCH_FLAG           = ~`GO_BRANCH;
            BRANCH_TAR_ADDR       = `ZERO_WORD;
            BRANCH_LINK_ADDR      = `ZERO_WORD;
        end else begin
            inst_valid            = ~`INST_VALID;
            ext_imm               = `ZERO_WORD;
            ALU_OP_O              = `EXE_NOP_OP;
            ALU_SEL_O             = `EXE_RES_NOP;
            GPR_WADDR_O           = rd;
            GPR_WE_O              = ~`WE;
            REG1_RE_O             = ~`RE;
            REG2_RE_O             = ~`RE;
            REG1_ADDR_O           = rs;
            REG2_ADDR_O           = rt;
            BRANCH_FLAG           = ~`GO_BRANCH;
            BRANCH_TAR_ADDR       = `ZERO_WORD;
            BRANCH_LINK_ADDR      = `ZERO_WORD;
            case (op)
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
                                `EXE_JR: begin
                                    GPR_WE_O          = ~`WE;
                                    ALU_OP_O          = `EXE_JR_OP;
                                    ALU_SEL_O         = `EXE_RES_JB;
                                    REG1_RE_O         = `RE;
                                    REG2_RE_O         = ~`RE;
                                    BRANCH_FLAG       = `GO_BRANCH;
                                    BRANCH_TAR_ADDR   = REG1_DATA_O;
                                    BRANCH_LINK_ADDR  = `ZERO_WORD;
                                    inst_valid        = `INST_VALID;
                                end
                                `EXE_JALR: begin
                                    GPR_WE_O          = `WE;
                                    ALU_OP_O          = `EXE_JALR_OP;
                                    ALU_SEL_O         = `EXE_RES_JB;
                                    REG1_RE_O         = `RE;
                                    REG2_RE_O         = ~`RE;
                                    BRANCH_FLAG       = `GO_BRANCH;
                                    BRANCH_TAR_ADDR   = REG1_DATA_O;
                                    BRANCH_LINK_ADDR  = pc_plus_8;
                                    inst_valid        = `INST_VALID;
                                end
                                default: begin
                                    
                                end
                            endcase
                        end
                        default: begin
                            
                        end
                    endcase
                end
                `EXE_SPECIAL2: begin
                    case (func)
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
                            if (REG1_DATA_O[31] == 1'b1) begin
                                BRANCH_FLAG       = `GO_BRANCH;
                                BRANCH_TAR_ADDR   = ext_addr_sll2 + pc_plus_4;
                                BRANCH_LINK_ADDR  = `ZERO_WORD;
                            end
                        end
                        `EXE_BGEZ: begin
                            GPR_WE_O          = ~`WE;
                            ALU_OP_O          = `EXE_BGEZ_OP;
                            ALU_SEL_O         = `EXE_RES_JB;
                            REG1_RE_O         = `RE;
                            REG2_RE_O         = ~`RE;
                            inst_valid        = `INST_VALID;
                            if (REG1_DATA_O[31] == 1'b0) begin
                                BRANCH_FLAG       = `GO_BRANCH;
                                BRANCH_TAR_ADDR   = ext_addr_sll2 + pc_plus_4;
                                BRANCH_LINK_ADDR  = `ZERO_WORD;
                            end
                        end
                        default: begin
                            
                        end
                    endcase
                end
                default: begin

                end
            endcase
            // 空指令和直接移位指令的译码
            if ({op, rs} == 11'b00000000000) begin
                case (func)
                    `EXE_SLL: begin
                        GPR_WADDR_O       = rd;
                        GPR_WE_O          = `WE;
                        // 直接偏移量sa作为ext_imm的低5位传给ex
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
/**************** INSTRUCTION DECODE END ****************/

/*************** STALL JUDGE BEGIN ***************/
    /* 
     * 问题: LOAD指令写结果在mem级才被计算完成,则LOAD指令后两条指令需要使用LOAD指令结果,会产生结构冒险(EX2ID和DF2ID的写数据并不是正确的写数据),则需要暂停
     * 策略: 检查EX级旁路数据,若EX级为LOAD指令且写寄存器正是ID级读寄存器之一,暂停流水线,否则继续检查DF级旁路数据,若也无问题则无需暂停,反之暂停
     */
    logic reg1_stall_req;
    logic reg2_stall_req;
    always_comb begin : REG1_STALL
        if (RST == `RST_EN) begin
            reg1_stall_req = ~`STOP;
        end else begin
            if ((EX_ALU_OP_I == `EXE_LW_OP || EX_ALU_OP_I == `EXE_LB_OP) && (EX_GPR_WADDR_I == REG1_ADDR_O)) begin
                reg1_stall_req = `STOP;
            end else begin
                reg1_stall_req = ~`STOP;
            end
            if (reg1_stall_req == ~`STOP && 
               (DF_ALU_OP_I == `EXE_LW_OP || DF_ALU_OP_I == `EXE_LB_OP) && (DF_GPR_WADDR_I == REG1_ADDR_O)) begin
                reg1_stall_req = `STOP;
               end else begin
                    reg1_stall_req = ~`STOP;
               end
        end
    end

    always_comb begin : REG2_STALL
        if (RST == `RST_EN) begin
            reg2_stall_req = ~`STOP;
        end else begin
            reg2_stall_req = ~`STOP;
            if ((EX_ALU_OP_I == `EXE_LW_OP || EX_ALU_OP_I == `EXE_LB_OP) && (EX_GPR_WADDR_I == REG2_ADDR_O)) begin
                reg2_stall_req = `STOP;
            end
            if (reg2_stall_req == ~`STOP && 
               (DF_ALU_OP_I == `EXE_LW_OP || DF_ALU_OP_I == `EXE_LB_OP) && (DF_GPR_WADDR_I == REG2_ADDR_O)) begin
                reg2_stall_req = `STOP;
            end
        end
    end
    
    assign STALL_REQ = reg1_stall_req | reg2_stall_req;
/**************** STALL JUDGE END ****************/
endmodule
