`timescale 1ns / 1ps
`include "defines.vh"

/* 存储器顶层控制模块 */
module mem(
    input   logic                   RST,
    // 从数据存储器中读出的数据
    input   logic[`REG_DATA_BUS]    LDATA_I,
    input   logic[`ALU_OP_BUS]      ALU_OP_I,
    input   logic[`REG_DATA_BUS]    LSADDR_I,
    // ex阶段给出的rt寄存器值,用以存入存储器
    input   logic[`REG_DATA_BUS]    SDATA_I,
    input   logic[`REG_ADDR_BUS]    WADDR_I,
    input   logic[`REG_DATA_BUS]    WDATA_I,
    input   logic                   WEN_I,
    input   logic[`REG_DATA_BUS]    HI_DATA_I,
    input   logic[`REG_DATA_BUS]    LO_DATA_I,
    input   logic                   WEN_HILO_I,
    // 暂停信号
    output  logic                   STALL_REQ,
    // 将要被写入存储器的数据
    output  logic[`REG_DATA_BUS]    SDATA_O,
    output  logic[`REG_DATA_BUS]    LSADDR_O,
    // 存储器写使能信号
    output  logic                   MEM_WEN_O,
    // CPU使能信号
    output  logic                   MEM_CEN_O,
    // 字节选择信号
        // 用以lb和lh指令选择要读出的字节
        // 以XXXXB表示,若要读第一个字节则为1000B
        // Lab要求小端法,0x0地址对应字节为最低有效字节
    output  logic[3:0]              BYTE_SEL_O,
    output  logic[`REG_ADDR_BUS]    WADDR_O,
    output  logic[`REG_DATA_BUS]    WDATA_O,
    output  logic                   WEN_O,
    output  logic[`REG_DATA_BUS]    HI_DATA_O,
    output  logic[`REG_DATA_BUS]    LO_DATA_O,
    output  logic                   WEN_HILO_O
    );

    assign STALL_REQ = `NOT_STOP;
    
    // 确认指令是否为访存指令
    function logic is_mem_op(logic[`ALU_OP_BUS] op);
        return op == `EXE_LB_OP || op == `EXE_LBU_OP || op == `EXE_LH_OP || op == `EXE_LHU_OP ||
               op == `EXE_LW_OP || op == `EXE_SB_OP || op == `EXE_SH_OP || op == `EXE_SW_OP;
    endfunction
    // 用寄存器存储使能信号
    logic   ram_wen;
    assign MEM_WEN_O = ram_wen;
    always_comb begin : MEM_CTRL
        if (RST == `RST_EN) begin
            ram_wen     = `WDISABLE;
            MEM_CEN_O   = `CDISABLE;
            SDATA_O     = `ZERO_WORD;
            LSADDR_O    = `ZERO_WORD;
            BYTE_SEL_O  = 4'b0000;
            WADDR_O     = `ZERO_ADDR;
            WDATA_O     = `ZERO_WORD;
            WEN_O       = `WDISABLE;
            HI_DATA_O   = `ZERO_WORD;
            LO_DATA_O   = `ZERO_WORD;
            WEN_HILO_O  = `WDISABLE;
        end else begin
            ram_wen     = `WDISABLE;
            MEM_CEN_O   = `CDISABLE;
            SDATA_O     = `ZERO_WORD;
            LSADDR_O    = `ZERO_WORD;
            BYTE_SEL_O  = 4'b0000;
            WADDR_O     = WADDR_I;
            WDATA_O     = WDATA_I;
            WEN_O       = WEN_I;
            HI_DATA_O   = HI_DATA_I;
            LO_DATA_O   = LO_DATA_I;
            WEN_HILO_O  = WEN_HILO_I;
            case (ALU_OP_I)
                // LSADDR的最低两位映射含义如下
                    // 存储指令: 存进去的数据字将要被写到哪个字节里
                    // 加载指令: 读出来的数据字中,哪个字节有效
                    // BYTE_SEL负责指示RAM将要被访问的字节位置
                // 产生这种映射的原因是防止地址不对齐
                    // 取低2位作字节选择而不参与地址指示,能保证访问的位置为4的倍数
                    // 而MIPS一个指令恰需要4个字节存储,这样就能防止地址不对齐访问出错
                // 本CPU数据格式定义为reg[31:0],为了采用小端法,需要在0x0访问最低有效字节,0x3访问最高有效字节,则对应关系如下
                // LSADDR[2:0]  :  11B       10B      01B       0B
                // BYTE_SEL     : 1000      0100     0010      0001     
                // DATA_BITS    : 31-24     23-16    15-8      7-0
                `EXE_LB_OP: begin
                    ram_wen   = `WDISABLE;
                    MEM_CEN_O = `CENABLE;
                    LSADDR_O  = LSADDR_I;
                    case (LSADDR_I[1:0])
                        2'b00:  begin
                            WDATA_O = {{24{LDATA_I[7]}}, LDATA_I[7:0]};
                            BYTE_SEL_O = 4'b0001;
                        end 
                        2'b01:  begin
                            WDATA_O = {{24{LDATA_I[15]}}, LDATA_I[15:8]};
                            BYTE_SEL_O = 4'b0010;
                        end 
                        2'b10:  begin
                            WDATA_O = {{24{LDATA_I[23]}}, LDATA_I[23:16]};
                            BYTE_SEL_O = 4'b0100;
                        end 
                        2'b11:  begin
                            WDATA_O = {{24{LDATA_I[31]}}, LDATA_I[31:24]};
                            BYTE_SEL_O = 4'b1000;
                        end 
                    endcase
                end 
                `EXE_LBU_OP: begin
                    LSADDR_O  = LSADDR_I;
                    ram_wen   = `WDISABLE;
                    MEM_CEN_O = `CENABLE;
                    case (LSADDR_I[1:0])
                        2'b00:  begin
                            WDATA_O = {24'b0, LDATA_I[7:0]};
                            BYTE_SEL_O = 4'b0001;
                        end 
                        2'b01:  begin
                            WDATA_O = {24'b0, LDATA_I[15:8]};
                            BYTE_SEL_O = 4'b0010;
                        end 
                        2'b10:  begin
                            WDATA_O = {24'b0, LDATA_I[23:16]};
                            BYTE_SEL_O = 4'b0100;
                        end 
                        2'b11:  begin
                            WDATA_O = {24'b0, LDATA_I[31:24]};
                            BYTE_SEL_O = 4'b1000;
                        end 
                    endcase
                end 
                `EXE_LH_OP: begin
                    LSADDR_O  = LSADDR_I;
                    ram_wen   = `WDISABLE;
                    MEM_CEN_O = `CENABLE;
                    case (LSADDR_I[1:0])
                        2'b00:  begin
                            WDATA_O = {{16{LDATA_I[15]}}, LDATA_I[15:0]};
                            BYTE_SEL_O = 4'b0011;
                        end 
                        2'b10:  begin
                            WDATA_O = {{16{LDATA_I[31]}}, LDATA_I[31:16]};
                            BYTE_SEL_O = 4'b1100;
                        end 
                        default:    begin
                            WDATA_O = `ZERO_WORD;
                            BYTE_SEL_O = 4'b0000;
                        end
                    endcase
                end 
                `EXE_LHU_OP: begin
                    LSADDR_O  = LSADDR_I;
                    ram_wen   = `WDISABLE;
                    MEM_CEN_O = `CENABLE;
                    case (LSADDR_I[1:0])
                        2'b00:  begin
                            WDATA_O = {16'b0, LDATA_I[15:0]};
                            BYTE_SEL_O = 4'b0011;
                        end 
                        2'b10:  begin
                            WDATA_O = {16'b0, LDATA_I[31:16]};
                            BYTE_SEL_O = 4'b1100;
                        end 
                        default:    begin
                            WDATA_O = `ZERO_WORD;
                            BYTE_SEL_O = 4'b0000;
                        end
                    endcase
                end
                `EXE_LW_OP: begin
                    LSADDR_O   = LSADDR_I;
                    ram_wen    = `WDISABLE;
                    MEM_CEN_O  = `CENABLE;
                    WDATA_O    = LDATA_I;
                    BYTE_SEL_O = 4'b1111;
                end
                `EXE_SB_OP: begin
                    LSADDR_O   = LSADDR_I;
                    ram_wen    = `WENABLE;
                    MEM_CEN_O  = `CENABLE;
                    // SB指令只取rt寄存器的最低字节数据
                    SDATA_O    = {4{SDATA_I[7:0]}};
                    case (LSADDR_I[1:0])
                        2'b11:  begin
                            BYTE_SEL_O = 4'b1000;
                        end 
                        2'b10:  begin
                            BYTE_SEL_O = 4'b0100;
                        end 
                        2'b01:  begin
                            BYTE_SEL_O = 4'b0010;
                        end 
                        2'b00:  begin
                            BYTE_SEL_O = 4'b0001;
                        end 
                    endcase
                end
                `EXE_SH_OP: begin
                    LSADDR_O   = LSADDR_I;
                    ram_wen    = `WENABLE;
                    MEM_CEN_O  = `CENABLE;
                    // SH指令取rt寄存器的最低半字数据
                    SDATA_O    = {2{SDATA_I[15:0]}};
                    case (LSADDR_I[1:0])
                        2'b10:  begin
                            BYTE_SEL_O = 4'b1100;
                        end 
                        2'b00:  begin
                            BYTE_SEL_O = 4'b0011;
                        end 
                        default:    begin
                            WDATA_O = `ZERO_WORD;
                            BYTE_SEL_O = 4'b0000;
                        end
                    endcase
                end
                `EXE_SW_OP: begin
                    LSADDR_O   = LSADDR_I;
                    ram_wen    = `WENABLE;
                    MEM_CEN_O  = `CENABLE;
                    SDATA_O    = SDATA_I;
                    BYTE_SEL_O = 4'b1111;
                end
                default: begin
                    
                end
            endcase
        end
    end
endmodule
