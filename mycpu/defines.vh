/* 全局宏定义 */
// 零字
`define ZERO_WORD       32'h00000000
// 寄存器零地址
`define ZERO_ADDR       5'b00000
// 使能信号
`define RST_EN          1'b1            
`define WENABLE         1'b1
`define WDISABLE        1'b0
`define RENABLE         1'b1
`define RDISABLE        1'b0
`define CENABLE         1'b1
`define CDISABLE        1'b0
// 译码阶段输出aluop_o                
`define ALU_OP_BUS        7:0
// 译码阶段输出alusel_o            
`define ALU_SEL_BUS       2:0
// 有效信号
`define INST_VALID       1'b1
`define INST_INVALID     1'b0
// 异常信号
`define ERROR           1'b1
`define NOERR           1'b0

/* 流水线暂停信号宏定义 */
`define STOP            1'b1
`define NOT_STOP        1'b0
`define STALL_BUS       5:0
`define STALL_ID        6'b000111
`define STALL_EX        6'b001111
`define STALL_MEM       6'b011111
/* 符号运算宏定义 */
`define SIGNED      1'b1
`define UNSIGNED    1'b0

/* 结果就绪信号宏定义 */
`define RESULT_READY       1'b1
`define RESULT_NOT_READY   1'b0

/* 跳转指令相关信号宏定义 */
`define NOT_BRANCH          1'b0
`define GO_BRANCH           1'b1
`define OUT_DELAY_SLOT      1'b0
`define IN_DELAY_SLOT       1'b1

/* MIPS指令信号宏定义 */
// SPECIAL_FUNC
`define EXE_AND         6'b100100
`define EXE_OR          6'b100101
`define EXE_XOR         6'b100110
`define EXE_NOR         6'b100111
`define EXE_SLL         6'b000000
`define EXE_SLLV        6'b000100
`define EXE_SRL         6'b000010
`define EXE_SRLV        6'b000110
`define EXE_SRA         6'b000011
`define EXE_SRAV        6'b000111
`define EXE_SYNC        6'b001111
`define EXE_MOVN        6'b001011
`define EXE_MOVZ        6'b001010
`define EXE_MFHI        6'b010000
`define EXE_MTHI        6'b010001
`define EXE_MFLO        6'b010010
`define EXE_MTLO        6'b010011
`define EXE_ADD         6'b100000
`define EXE_ADDU        6'b100001
`define EXE_SUB         6'b100010
`define EXE_SUBU        6'b100011
`define EXE_SLT         6'b101010
`define EXE_SLTU        6'b101011
`define EXE_MULT        6'b011000
`define EXE_MULTU       6'b011001
`define EXE_DIV         6'b011010
`define EXE_DIVU        6'b011011
`define EXE_JALR        6'b001001
`define EXE_JR          6'b001000
`define EXE_TEQ         6'b110100
`define EXE_TGE         6'b110000
`define EXE_TGEU        6'b110001
`define EXE_TLT         6'b110010
`define EXE_TLTU        6'b110011
`define EXE_TNE         6'b110110
`define EXE_SYSCALL     6'b001100
`define EXE_NOP         6'b000000
// SPECIAL2_FUNC
`define EXE_CLZ         6'b100000
`define EXE_CLO         6'b100001
`define EXE_MUL         6'b000010
// REGIMM_OP
`define EXE_BLTZ        5'b00000
`define EXE_BLTZAL      5'b10000
`define EXE_BGEZ        5'b00001
`define EXE_BGEZAL      5'b10001
`define EXE_TEQI        5'b01100
`define EXE_TGEI        5'b01000
`define EXE_TGEIU       5'b01001
`define EXE_TLTI        5'b01010
`define EXE_TLTIU       5'b01011
`define EXE_TNEI        5'b01110
// op
`define EXE_ANDI        6'b001100
`define EXE_ORI         6'b001101
`define EXE_XORI        6'b001110
`define EXE_LUI         6'b001111
`define EXE_PREF        6'b110011
`define EXE_ADDI        6'b001000
`define EXE_ADDIU       6'b001001
`define EXE_SLTI        6'b001010
`define EXE_SLTIU       6'b001011
`define EXE_J           6'b000010
`define EXE_JAL         6'b000011
`define EXE_BEQ         6'b000100
`define EXE_BNE         6'b000101
`define EXE_BGTZ        6'b000111
`define EXE_BLEZ        6'b000110
`define EXE_LB          6'b100000
`define EXE_LBU         6'b100100
`define EXE_LH          6'b100001
`define EXE_LHU         6'b100101
`define EXE_LW          6'b100011
`define EXE_SB          6'b101000
`define EXE_SH          6'b101001
`define EXE_SW          6'b101011
`define EXE_SPECIAL     6'b000000
`define EXE_SPECIAL2    6'b011100
`define EXE_REGIMM      6'b000001
// Op信号和Sel信号为我自定义的值,只需让Alu模块能够区分出类型即可
// Alu_Op
`define EXE_OR_OP       8'b00100101
`define EXE_AND_OP      8'b00100110
`define EXE_XOR_OP      8'b00100111
`define EXE_NOR_OP      8'b00101000
`define EXE_SLL_OP      8'b00101001
`define EXE_SRL_OP      8'b00101010
`define EXE_SRA_OP      8'b00101011
`define EXE_SYNC_OP     8'b00101100
`define EXE_MFHI_OP     8'b00101101
`define EXE_MTHI_OP     8'b00101110
`define EXE_MFLO_OP     8'b00101111
`define EXE_MTLO_OP     8'b00110000
`define EXE_MOVN_OP     8'b00110001
`define EXE_MOVZ_OP     8'b00110010
`define EXE_ADD_OP      8'b00110011
`define EXE_ADDU_OP     8'b00110100
`define EXE_SUB_OP      8'b00110101
`define EXE_SUBU_OP     8'b00110110
`define EXE_SLT_OP      8'b00110111
`define EXE_SLTU_OP     8'b00111000
`define EXE_MULT_OP     8'b00111001
`define EXE_MULTU_OP    8'b00111010
`define EXE_CLZ_OP      8'b00111011
`define EXE_CLO_OP      8'b00111100
`define EXE_MUL_OP      8'b00111101
`define EXE_LUI_OP      8'b00111110
`define EXE_MADD_OP     8'b00111111
`define EXE_MADDU_OP    8'b01000000
`define EXE_MSUB_OP     8'b01000001
`define EXE_MSUBU_OP    8'b01000010
`define EXE_DIV_OP      8'b01000011
`define EXE_DIVU_OP     8'b01000100
`define EXE_JR_OP       8'b01000101
`define EXE_JALR_OP     8'b01000110
`define EXE_J_OP        8'b01000111
`define EXE_JAL_OP      8'b01001000
`define EXE_BEQ_OP      8'b01001001
`define EXE_BGTZ_OP     8'b01001010
`define EXE_BLEZ_OP     8'b01001011
`define EXE_BNE_OP      8'b01001100
`define EXE_BLTZ_OP     8'b01001101
`define EXE_BGEZ_OP     8'b01001110
`define EXE_BLTZAL_OP   8'b01001111
`define EXE_BGEZAL_OP   8'b01010000
`define EXE_LB_OP       8'B01010001
`define EXE_LBU_OP      8'B01010010
`define EXE_LH_OP       8'B01010011
`define EXE_LHU_OP      8'B01010100
`define EXE_LW_OP       8'B01010101
`define EXE_SB_OP       8'B01010110
`define EXE_SH_OP       8'B01010111
`define EXE_SW_OP       8'B01011000
`define EXE_NOP_OP      8'b00000000
// Alu_Sel
`define EXE_RES_LOGIC   3'b001
`define EXE_RES_SHIFT   3'b010
`define EXE_RES_MOVE    3'b011
`define EXE_RES_ARITH   3'b100
`define EXE_RES_MUL     3'b101
`define EXE_RES_JB      3'b110
`define EXE_RES_LS      3'b111
`define EXE_RES_NOP     3'b000

/* ROM宏定义 */
/* 只在ROM中使用 */
// 指令地址线
`define INST_ADDR_BUS       31:0                
// 指令数据线
`define INST_DATA_BUS       31:0                
// ROM存储128Kb的指令
`define INST_MEM_NUM        131072           
// ROM实际访存使用的地址线宽度，为17位，即128Kb的对数   
`define INST_MEM_NUM_LOG2   17                  

/* RAM宏定义 */
/* 只在RAM中使用 */
// 数据地址线
`define DATA_ADDR_BUS       31:0                
// 数据字线
`define DATA_BUS            31:0 
`define DATA_WIDTH          32 
// RAM存储16Kb的数据
`define DATA_MEM_NUM        16384
// RAM实际访存使用的地址线宽度，为14位，为16Kb的对数   
`define DATA_MEM_NUM_LOG2   14

/* 通用寄存器宏定义 */
// 寄存器堆地址线
`define REG_ADDR_BUS            4:0                 
// 寄存器堆数据线  
`define REG_DATA_BUS            31:0                
`define REG_DATA_WIDTH          32                  
`define DOUBLE_REG_DATA_BUS     63:0
`define DOUBLE_REG_DATA_WIDTH   64
`define REG_NUM                 32
`define REG_NUM_LOG2            5                   
`define NOP_Reg_Addr            5'b00000 

/* 除法模块宏定义 */
// 状态机
`define DIV_FREE    2'b00
`define DIV_ZERO    2'b01
`define DIV_BUSY    2'b10
`define DIV_DONE    2'b11
// 开始与结束信号
`define DIV_START   1'b1
`define DIV_STOP    1'b0
// 取消信号
`define DIV_CANCEL      1'b1
`define DIV_NOT_CANCEL  1'b0

/* 乘法模块宏定义 */
// 状态机
`define MUL_FREE    1'b0
`define MUL_BUSY    1'b1
// 开始与结束信号
`define MUL_START   1'b1
`define MUL_STOP    1'b0
// 取消信号
`define MUL_CANCEL      1'b1
`define MUL_NOT_CANCEL  1'b0
