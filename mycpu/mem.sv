`timescale 1ns/1ps
`include "defines.vh"
module mem(
    input   logic                  RST,
    input   logic                  GPR_WE_I,
    input   logic [ `REG_DATA_BUS] GPR_WDATA_I,
    input   logic [ `REG_ADDR_BUS] GPR_WADDR_I,
    input   logic [`SRAM_BSEL_BUS] SRAM_BE,
    input   logic [`SRAM_DATA_BUS] SRAM_RDATA,
    input   logic [   `ALU_OP_BUS] ALU_OP,
    output  logic                  GPR_WE_O,
    output  logic [ `REG_DATA_BUS] GPR_WDATA_O,
    output  logic [ `REG_ADDR_BUS] GPR_WADDR_O
);  
    assign GPR_WE_O    = GPR_WE_I;
    assign GPR_WADDR_O = GPR_WADDR_I; 
    always_comb begin : LOAD_EXECUTION
        if (RST == `RST_EN) begin
            GPR_WDATA_O = `ZERO_WORD;
        end else begin
            case (ALU_OP)
                `EXE_LB_OP: begin
                    case (SRAM_BE)
                        4'b1110: begin
                            GPR_WDATA_O = {{24{SRAM_RDATA[7]}}, SRAM_RDATA[7:0]};
                        end 
                        4'b1101: begin
                            GPR_WDATA_O = {{24{SRAM_RDATA[15]}}, SRAM_RDATA[15:8]};
                        end 
                        4'b1011: begin
                            GPR_WDATA_O = {{24{SRAM_RDATA[23]}}, SRAM_RDATA[23:16]};
                        end 
                        4'b0111: begin
                            GPR_WDATA_O = {{24{SRAM_RDATA[31]}}, SRAM_RDATA[31:24]};
                        end 
                        default: begin
                            GPR_WDATA_O = `ZERO_WORD;
                        end
                    endcase
                end
                `EXE_LW_OP: begin
                    GPR_WDATA_O = SRAM_RDATA;
                end
                default: begin
                    GPR_WDATA_O = GPR_WDATA_I;
                end
            endcase
        end
    end
endmodule