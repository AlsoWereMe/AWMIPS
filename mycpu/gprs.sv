`timescale 1ns / 1ps
`include "defines.vh"

module gprs(
    input  logic                  CLK,
    input  logic                  RST,
    // 写端口   
    input   logic                 WE,   
    input   logic [`REG_ADDR_BUS] WADDR, 
    input   logic [`REG_DATA_BUS] WDATA, 
    // 读端口1  
    input   logic                 RE1,
    input   logic [`REG_ADDR_BUS] RADDR1,
    output  logic [`REG_DATA_BUS] RDATA1,
    // 读端口2
    input   logic                 RE2,
    input   logic [`REG_ADDR_BUS] RADDR2,
    output  logic [`REG_DATA_BUS] RDATA2
);
    // 定义寄存器堆
    logic[`REG_DATA_BUS] regs[`REG_NUM];

    always_ff @( posedge CLK ) begin : WRITE
        if(RST == `RST_EN) begin
            for (int i = 0; i < 32; i = i + 1) begin
                regs[i] <= `ZERO_WORD;
            end
        end else begin 
            if (WE == `WE) begin
                // 通用寄存器0恒存储0字,不可写入
                if (WADDR != `REG_ZERO_ADDR) begin
                    regs[WADDR] <= WDATA;
                end else begin
                    regs[WADDR] <= regs[WADDR];
                end
            end else begin
                regs[WADDR] <= regs[WADDR];
            end
        end
    end
    
    always_comb begin : READ_1
        if (RE1 == `RE) begin
            if ((RADDR1 == WADDR) && (WE == `WE) && (WADDR != `REG_ZERO_ADDR)) begin
                RDATA1 = WDATA;
            end else begin
                RDATA1 = regs[RADDR1];
            end
        end else begin
            RDATA1 = `ZERO_WORD;
        end
    end
    
    always_comb begin : READ_2
        if (RE2 == `RE) begin
            if ((RADDR2 == WADDR) && (WE == `WE) && (WADDR != `REG_ZERO_ADDR)) begin
                RDATA2 = WDATA;
            end else begin
                RDATA2 = regs[RADDR2];
            end
        end else begin
            RDATA2 = `ZERO_WORD;
        end
    end
endmodule
