`timescale 1ns / 1ps
`include "defines.vh"

module gprs(
    input  logic                    CLK,
    input  logic                    RST,

    // 写端口   
    input  logic                    WEN,   // 写使能
    input  logic[`REG_ADDR_BUS]     WADDR, // 写入的地址
    input  logic[`REG_DATA_BUS]     WDATA, // 写入的数据

    // 读端口1  
    input  logic                    REN1,
    input  logic[`REG_ADDR_BUS]     RADDR1,
    output  logic[`REG_DATA_BUS]     RDATA1,

    // 读端口2
    input  logic                    REN2,
    input  logic[`REG_ADDR_BUS]     RADDR2,
    output  logic[`REG_DATA_BUS]     RDATA2
    );
    // 定义寄存器堆
    logic[`REG_DATA_BUS] regs[`REG_NUM];

    // 写端口之逻辑
    genvar i;
    generate
    for (i = 0; i < 32; i = i + 1) begin
        always_ff @( posedge CLK ) begin : WRITE
            if(RST == `RST_EN) begin
                regs[i] <= `ZERO_WORD;
            end else begin 
                // 通用寄存器0恒存储0字,不可写入
                if ((WEN == `WE) && (WADDR != `REG_ZERO_ADDR)) begin                        
                    regs[WADDR] <= WDATA;
            end
            end
        end
    end
    endgenerate

    // 读端口1之逻辑
    always_comb begin : READ_1
        if (RST == `RST_EN) begin
            RDATA1 = `ZERO_WORD;
        end else if ((RADDR1 == WADDR) && (WEN == `WE) && (REN1 == `RE)) begin
            // 读写端同时启用时,意味着出现数据相关,进行旁路处理
            RDATA1 = WDATA;
        end else if (REN1 == `RE) begin
            RDATA1 = regs[RADDR1];
        end else begin
            RDATA1 = `ZERO_WORD;
        end
    end
    
    // 读端口2之逻辑
    always_comb begin : READ_2
        if (RST == `RST_EN) begin
            RDATA2 = `ZERO_WORD;
        end else if ((RADDR2 == WADDR) && (WEN == `WE) && (REN2 == `RE)) begin   
            RDATA2 = WDATA;
        end else if (REN2 == `RE) begin
            RDATA2 = regs[RADDR2];
        end else begin
            RDATA2 = `ZERO_WORD;
        end
    end
endmodule
