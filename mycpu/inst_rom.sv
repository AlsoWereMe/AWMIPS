`timescale 1ns / 1ps
`include "defines.vh"

module inst_rom(
    input   logic                   CEN,
    /* verilator lint_off UNUSED */
    input   logic[`INST_ADDR_BUS]   ADDR,
    /* verilator lint_off UNUSED */
    output  logic[`INST_DATA_BUS]   INST
    );

    logic[`INST_DATA_BUS]   inst_mem[`INST_MEM_NUM];
    logic[`INST_MEM_NUM_LOG2 - 1 : 0] virtual_addr;
    // 计算虚拟地址
    assign virtual_addr = ADDR[`INST_MEM_NUM_LOG2 + 1 : 2];
    // 读实际物理地址存储的方法
		// 输入虚拟地址,访问物理地址
		// data将被设置为访问到的数据
	import "DPI-C" function 
		void mm_read(
		input	longint		addr,
		output	longint		data
	);
    // 初始化指令集,从mem中读出32条指令到inst_mem[31:0]
    logic[`INST_ADDR_BUS]		pc;
    logic[63:0]                 expand_pc;
    logic[63:0]                 expand_inst;
    initial begin
        // 默认初始化全为0
        for (int i = 0; i < `INST_MEM_NUM; i++) begin
            inst_mem[i] = 0;
        end
        // pc值默认为GUEST_BASE
        pc = 32'h0100;
        // 读出64条指令使用
        for (int i = 0; i < 64; i = i + 1) begin
            expand_pc   = {`ZERO_WORD,pc};
            expand_inst = {`ZERO_WORD,`ZERO_WORD};
            mm_read(expand_pc, expand_inst);
            inst_mem[i] = expand_inst[`INST_DATA_BUS];
            pc = pc + 32'd4;
        end
    end
    // 输出给外界的指令
    always_comb begin : INST_VALUE
        if(CEN == `CDISABLE) begin
            INST = `ZERO_WORD;
        end else begin
            /* MIPS用字节寻址,指令给出的地址每加1代表偏移一个字节,而每一条指令四个字节 */
            /* 于是,对于给出的地址addr,假如他是0x4,他代表指令存储器里的第二条指令,也即inst_mem[1] */
            /* 我们实际使用17bit来寻址 */
            /* 所以寻址时,需要将addr除4,也即右移2位然后取低17位 */
            /* 反映在代码上就是addr[`INST_MEM_NUM_LOG2 + 1:2] */
            /* 它等价于(addr >> 2)[`INST_MEM_NUM_LOG2:0] */
            INST = inst_mem[virtual_addr];
        end
    end
endmodule
