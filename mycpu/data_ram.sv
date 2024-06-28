`timescale 1ns / 1ps
`include "defines.vh"

module data_ram(
    input   logic                   CLK,
    input   logic                   CEN,
    input   logic                   WEN,
    /* verilator lint_off UNUSED */
    input   logic[`DATA_ADDR_BUS]   ADDR,
    /* verilator lint_off UNUSED */
    input   logic[3:0]              BYTE_SEL,
    input   logic[`DATA_BUS]        SDATA,
    output  logic[`DATA_BUS]        LDATA,

    // 测试用读端口,将所有存储器值输出给测试程序监控
    output logic[`DATA_BUS]         RAM[8]
);
logic[`DATA_BUS]    data_ram[`DATA_MEM_NUM];
logic[`DATA_MEM_NUM_LOG2 - 1 : 0] real_addr;

assign real_addr = ADDR[`DATA_MEM_NUM_LOG2 + 1 : 2];
// 写操作
genvar i;
generate
for (i = 0; i < `DATA_WIDTH / 8; i = i + 1) begin
    always_ff @( posedge CLK ) begin : WRITE
        if (WEN == `WENABLE && CEN == `CENABLE && BYTE_SEL[i] == 1'b1) begin 
                data_ram[real_addr][8 * i +: 8] <= SDATA[8 * i +: 8];
        end
    end
end
endgenerate

// 输出给外部
genvar j;
generate
    for (j = 0; j < 8; j = j + 1) begin
        assign RAM[j] = data_ram[j];
    end
endgenerate

// 读操作
always_comb begin : READ
    if (CEN == `CDISABLE) begin
        LDATA = `ZERO_WORD;
    end else if (WEN == `WDISABLE) begin
        LDATA = data_ram[real_addr];
    end else begin
        LDATA = `ZERO_WORD;
    end
end
endmodule
