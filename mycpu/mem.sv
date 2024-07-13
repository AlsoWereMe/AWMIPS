`timescale 1ns / 1ps
`include "defines.vh"
module mem(
    input   logic                  RST,
    input   logic [   `ALU_OP_BUS] ALU_OP_I,
    // GPR相关输入数据
    input   logic                  GPR_WE_I,
    input   logic [ `REG_ADDR_BUS] GPR_WADDR_I,
    input   logic [ `REG_DATA_BUS] GPR_WDATA_I,
    // SRAM相关输入数据
    input   logic [`SRAM_ADDR_BUS] SRAM_ADDR_I,
    input   logic [`SRAM_DATA_BUS] SRAM_RDATA,
    input   logic [`SRAM_DATA_BUS] SRAM_WDATA_I,

    output  logic                  STALL_REQ,
    // SRAM相关输出数据  
    output  logic                  SRAM_WE_O,
    output  logic                  SRAM_CE_O,
    output  logic [`SRAM_BSEL_BUS] SRAM_BE_O,
    output  logic [`SRAM_DATA_BUS] SRAM_WDATA_O,
    output  logic [`SRAM_ADDR_BUS] SRAM_ADDR_O,
    // GPR相关输出数据
    output  logic                  GPR_WE_O,
    output  logic [ `REG_ADDR_BUS] GPR_WADDR_O,
    output  logic [ `REG_DATA_BUS] GPR_WDATA_O
    );

    assign STALL_REQ = `NOT_STOP;

    // 用寄存器存储使能信号
    logic   ram_wen;
    always_comb begin : MEM_CTRL
        if (RST == `RST_EN) begin
            ram_wen      = ~`WE;
            SRAM_CE_O    = ~`CE;
            SRAM_WDATA_O = `ZERO_WORD;
            SRAM_ADDR_O  = `ZERO_WORD;
            SRAM_BE_O    = 4'b1111;
            GPR_WADDR_O  = `REG_ZERO_ADDR;
            GPR_WDATA_O  = `ZERO_WORD;
            GPR_WE_O     = ~`WE;
        end else begin
            ram_wen      = ~`WE;
            SRAM_CE_O    = ~`CE;
            SRAM_WDATA_O = `ZERO_WORD;
            SRAM_ADDR_O  = `ZERO_WORD;
            SRAM_BE_O    = 4'b1111;
            GPR_WADDR_O  = GPR_WADDR_I;
            GPR_WDATA_O  = GPR_WDATA_I;
            GPR_WE_O     = GPR_WE_I;
            case (ALU_OP_I)
                `EXE_LB_OP: begin
                    ram_wen     = ~`WE;
                    SRAM_CE_O   = `CE;
                    SRAM_ADDR_O = SRAM_ADDR_I;
                    case (SRAM_ADDR_I[1:0])
                        2'b00: begin
                            GPR_WDATA_O = {{24{SRAM_RDATA[7]}}, SRAM_RDATA[7:0]};
                            SRAM_BE_O   = 4'b1110;
                        end 
                        2'b01: begin
                            GPR_WDATA_O = {{24{SRAM_RDATA[15]}}, SRAM_RDATA[15:8]};
                            SRAM_BE_O   = 4'b1101;
                        end 
                        2'b10: begin
                            GPR_WDATA_O = {{24{SRAM_RDATA[23]}}, SRAM_RDATA[23:16]};
                            SRAM_BE_O   = 4'b1011;
                        end 
                        2'b11: begin
                            GPR_WDATA_O = {{24{SRAM_RDATA[31]}}, SRAM_RDATA[31:24]};
                            SRAM_BE_O   = 4'b0111;
                        end 
                    endcase
                end 
                `EXE_LW_OP: begin
                    SRAM_ADDR_O = SRAM_ADDR_I;
                    ram_wen     = ~`WE;
                    SRAM_CE_O   = `CE;
                    GPR_WDATA_O = SRAM_RDATA;
                    SRAM_BE_O   = 4'b0000;
                end
                `EXE_SB_OP: begin
                    SRAM_ADDR_O  = SRAM_ADDR_I;
                    ram_wen      = `WE;
                    SRAM_CE_O    = `CE;
                    // SB指令只取rt寄存器的最低字节数据
                    SRAM_WDATA_O = {4{SRAM_WDATA_I[7:0]}};
                    case (SRAM_ADDR_I[1:0])
                        2'b11: begin
                            SRAM_BE_O = 4'b0111;
                        end 
                        2'b10: begin
                            SRAM_BE_O = 4'b1011;
                        end 
                        2'b01: begin
                            SRAM_BE_O = 4'b1101;
                        end 
                        2'b00: begin
                            SRAM_BE_O = 4'b1110;
                        end 
                    endcase
                end
                `EXE_SW_OP: begin
                    SRAM_ADDR_O  = SRAM_ADDR_I;
                    ram_wen      = `WE;
                    SRAM_CE_O    = `CE;
                    SRAM_WDATA_O = SRAM_WDATA_I;
                    SRAM_BE_O    = 4'b0000;
                end
                default: begin
                    
                end
            endcase
        end
    end
    assign SRAM_WE_O = ram_wen;
endmodule
