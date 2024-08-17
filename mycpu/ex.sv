`timescale 1ns / 1ps
`include "defines.vh"
module ex(
    input   logic                  RST,
    input   logic [   `ALU_OP_BUS] ALU_OP_I,
    input   logic [  `ALU_SEL_BUS] ALU_SEL_I,
    input   logic [          15:0] IMM,
    input   logic                  GPR_WE_I,
    input   logic [ `REG_ADDR_BUS] GPR_WADDR_I,
    input   logic [ `REG_DATA_BUS] REG1_DATA_I,
    input   logic [ `REG_DATA_BUS] REG2_DATA_I,
    input   logic [ `CPU_ADDR_BUS] BRANCH_LINK_ADDR,

    output  logic [   `ALU_OP_BUS] ALU_OP_O,
    output  logic                  GPR_WE_O,
    output  logic [ `REG_ADDR_BUS] GPR_WADDR_O,
    output  logic [ `REG_DATA_BUS] GPR_WDATA_O,
    output  logic                  SRAM_DATA_WE_O,
    output  logic                  SRAM_DATA_CE_O,
    output  logic [`SRAM_BSEL_BUS] SRAM_DATA_BE_O,
    output  logic [`SRAM_DATA_BUS] SRAM_DATA_WDATA_O,
    output  logic [ `CPU_ADDR_BUS] SRAM_DATA_VADDR_O
);

/*************** LOGIC EXECUTION BEGIN ***************/
    logic [`REG_DATA_BUS] logic_res;
    always_comb begin: LOGIC_EXE
        if(RST == `RST_EN) begin
            logic_res = `ZERO_WORD;
        end else begin
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
                `EXE_LUI_OP: begin
                    logic_res = {REG1_DATA_I};
                end
                default: begin
                    logic_res = `ZERO_WORD;
                end
            endcase
        end
    end
/**************** LOGIC EXECUTION END ****************/

/*************** ARTIH EXECUTION BEGIN ***************/
    logic                        reg1_lt_reg2;
    logic        [`REG_DATA_BUS] add_res;
    logic        [`REG_DATA_BUS] arith_res;
    logic signed [`REG_DATA_BUS] signed_reg1;
    logic signed [`REG_DATA_BUS] signed_reg2;
    assign signed_reg1 = REG1_DATA_I;
    assign signed_reg2 = REG2_DATA_I;
    
    always_comb begin : COMPARISON
        if (RST == `RST_EN) begin
            reg1_lt_reg2 = 1'b0;
        end else begin
            if (ALU_OP_I == `EXE_SLT_OP) begin
                reg1_lt_reg2 = signed_reg1 < signed_reg2;
            end else begin
                reg1_lt_reg2 = REG1_DATA_I < REG2_DATA_I;
            end
        end
    end
    
    always_comb begin : ADD_SUB
        if (RST == `RST_EN) begin
            add_res = `ZERO_WORD;
        end else begin
            case (ALU_OP_I)
                `EXE_ADD_OP: begin
                    add_res = signed_reg1 + signed_reg2;
                end
                `EXE_SUB_OP: begin
                    add_res = signed_reg1 - signed_reg2;
                end
                `EXE_ADDU_OP: begin
                    add_res = REG1_DATA_I + REG2_DATA_I;
                end
                default: begin
                    add_res = `ZERO_WORD;
                end
            endcase
        end
    end

    always_comb begin : ARITHMETIC_RESULT
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
/**************** ARTIH EXECUTION END ****************/

/*************** MULTIPLICATION EXECUTION BEGIN ***************/
    /* 依据CPU设计实战所说,直接调用*号可以综合出不错的乘法器IP */
    logic signed [`DREG_DATA_BUS] tmp_mul_res;
    logic        [ `REG_DATA_BUS] mul_res;
    assign tmp_mul_res = signed_reg1 * signed_reg2;
    always_comb begin : MULTIPLICATION
        if (RST == `RST_EN) begin
            mul_res = `ZERO_WORD;
        end else begin
            mul_res = tmp_mul_res[31:0];
        end
    end
/**************** MULTIPLICATION EXECUTION END ****************/

/*************** MEMORY EXECUTION BEGIN ***************/
    assign ALU_OP_O    = ALU_OP_I;
    always_comb begin : MEMORY_ACCESS
        if (RST == `RST_EN) begin
            SRAM_DATA_WE_O    = ~`WE;
            SRAM_DATA_CE_O    = ~`CE;
            SRAM_DATA_BE_O    = ~`BE;
            SRAM_DATA_VADDR_O = `ZERO_WORD;
            SRAM_DATA_WDATA_O = `ZERO_WORD;
        end else begin
            case (ALU_OP_I)
                `EXE_LB_OP: begin
                    SRAM_DATA_WE_O    = ~`WE;
                    SRAM_DATA_CE_O    = `CE;
                    SRAM_DATA_VADDR_O = REG1_DATA_I + {{16{IMM[15]}},IMM};
                    SRAM_DATA_WDATA_O = `ZERO_WORD;  
                    case (SRAM_DATA_VADDR_O[1:0])
                        2'b00: begin
                            SRAM_DATA_BE_O   = 4'b1110;
                        end 
                        2'b01: begin
                            SRAM_DATA_BE_O   = 4'b1101;
                        end 
                        2'b10: begin
                            SRAM_DATA_BE_O   = 4'b1011;
                        end 
                        2'b11: begin
                            SRAM_DATA_BE_O   = 4'b0111;
                        end 
                    endcase
                end 
                `EXE_LW_OP: begin
                    SRAM_DATA_WE_O    = ~`WE;
                    SRAM_DATA_CE_O    = `CE;
                    SRAM_DATA_BE_O    = `BE;
                    SRAM_DATA_VADDR_O = REG1_DATA_I + {{16{IMM[15]}},IMM};
                    SRAM_DATA_WDATA_O = `ZERO_WORD;
                end
                `EXE_SB_OP: begin
                    SRAM_DATA_WE_O    = `WE;
                    SRAM_DATA_CE_O    = `CE;
                    SRAM_DATA_VADDR_O = REG1_DATA_I + {{16{IMM[15]}},IMM[15:0]};
                    SRAM_DATA_WDATA_O = {4{REG2_DATA_I[7:0]}};
                    case (SRAM_DATA_VADDR_O[1:0])
                        2'b00: begin
                            SRAM_DATA_BE_O = 4'b1110;
                        end 
                        2'b01: begin
                            SRAM_DATA_BE_O = 4'b1101;
                        end 
                        2'b10: begin
                            SRAM_DATA_BE_O = 4'b1011;
                        end 
                        2'b11: begin
                            SRAM_DATA_BE_O = 4'b0111;
                        end 
                    endcase
                end
                `EXE_SW_OP: begin
                    SRAM_DATA_WE_O    = `WE;
                    SRAM_DATA_CE_O    = `CE;
                    SRAM_DATA_BE_O    = `BE;
                    SRAM_DATA_VADDR_O = REG1_DATA_I + {{16{IMM[15]}},IMM[15:0]};
                    SRAM_DATA_WDATA_O = REG2_DATA_I;
                end
                default: begin
                    SRAM_DATA_WE_O    = ~`WE;
                    SRAM_DATA_CE_O    = ~`CE;
                    SRAM_DATA_BE_O    = ~`BE;
                    SRAM_DATA_VADDR_O = `ZERO_WORD;
                    SRAM_DATA_WDATA_O = `ZERO_WORD;
                end
            endcase
        end
    end
/**************** MEMORY EXECUTION END ****************/

/*************** SHIFT EXECUTION BEGIN ***************/
    logic [          5:0] sa;
    logic [`REG_DATA_BUS] shift_res;
    /* 移位运算的偏移量在id中被赋值给寄存器1的低5位 */
    assign sa = REG1_DATA_I[4:0];
    always_comb begin : SHIFT_EXE
        if(RST == `RST_EN) begin
            shift_res = `ZERO_WORD;
        end else begin
            case (ALU_OP_I)
                `EXE_SLL_OP: begin
                    shift_res = (REG2_DATA_I <<  sa);
                end
                `EXE_SRL_OP: begin
                    shift_res = (REG2_DATA_I >>  sa);
                end
                `EXE_SRA_OP: begin
                    shift_res = (signed_reg2 >>> sa);
                end
                default: begin
                    shift_res = `ZERO_WORD;
                end
            endcase
        end
    end
/**************** SHIFT EXECUTION END ****************/

/*************** RESULT BEGIN ***************/
    always_comb begin : CHOOSE_RESULT
        GPR_WE_O    = GPR_WE_I;
        GPR_WADDR_O = GPR_WADDR_I;
        case (ALU_SEL_I)
            `EXE_RES_LOGIC: begin
                GPR_WDATA_O = logic_res;
            end
            `EXE_RES_SHIFT: begin
                GPR_WDATA_O = shift_res;
            end
            `EXE_RES_MUL: begin
                GPR_WDATA_O = mul_res[31:0];
            end
            `EXE_RES_ARITH: begin
                GPR_WDATA_O = arith_res;
            end
            `EXE_RES_JB: begin
                GPR_WDATA_O = BRANCH_LINK_ADDR;
            end
            `EXE_RES_LS: begin
                GPR_WDATA_O = `ZERO_WORD;   // EX级未收到访存传来数据,MEM级再修改
            end
            default: begin
                GPR_WDATA_O = `ZERO_WORD;
            end
        endcase
    end
/**************** RESULT BEGIN ****************/
endmodule
