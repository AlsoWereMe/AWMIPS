`timescale 1ns/1ps
`include "defines.vh"
/*  
 *  本模块为数据通路选择器,接受以下输入
 *      1. BASE_SRAM读数据BASE_SRAM_RDATA
 *      2. EXT_SRAM读数据EXT_SRAM_RDATA
 *      3. UART串口读数据UART_RDATA
 *      4. INST_MMU选择信号INST_SRAM_SEL
 *      5. DATA_MMU选择信号DATA_SRAM_SEL
 *      6. AWMIPS核IF级给出的INST相关使能信号
 *      7. AWMIPS核MEM级给出的DATA相关使能信号
 *  根据这些信号实现以下功能
 *      1. 判断INST和DATA将要访问哪一个SRAM
 *      2. 检测结构冒险是否发生,从而判断是否需要阻塞流水线
 *      3. 将CPU传来的数据与控制信号传递给对应SRAM
 *      4. 判断是否启用UART控制器
 *      5. 判断传入的SRAM数据传给INST还是DATA
 *  考虑到时序问题,需要在模块中加入同步触发器以确保选择信号能够持续至访存完毕且数据传递
 */
module path_sel(
    input   logic                  CLK,
    input   logic                  RST,
    /* INST */
    input   logic                  INST_WE,
    input   logic [`SRAM_BSEL_BUS] INST_BE,
    input   logic [`SRAM_DATA_BUS] INST_WDATA,
    input   logic [`SRAM_ADDR_BUS] INST_PADDR,
    input   logic [           2:0] INST_SRAM_SEL,
    output  logic [`SRAM_DATA_BUS] INST,
    /* DATA */
    input   logic                  DATA_WE,
    input   logic [`SRAM_BSEL_BUS] DATA_BE,
    input   logic [`SRAM_DATA_BUS] DATA_WDATA,
    input   logic [ `CPU_ADDR_BUS] DATA_VADDR,
    input   logic [`SRAM_ADDR_BUS] DATA_PADDR,
    input   logic [           2:0] DATA_SRAM_SEL,
    output  logic [`SRAM_DATA_BUS] DATA,
    /* BASE_SRAM */
    input   logic [`SRAM_DATA_BUS] BASE_SRAM_RDATA,
    output  logic                  BASE_SRAM_CE,
    output  logic                  BASE_SRAM_WE,
    output  logic [`SRAM_BSEL_BUS] BASE_SRAM_BE,
    output  logic [`SRAM_DATA_BUS] BASE_SRAM_WDATA,
    output  logic [`SRAM_ADDR_BUS] BASE_SRAM_PADDR,
    /* EXT_SRAM */
    input   logic [`SRAM_DATA_BUS] EXT_SRAM_RDATA,
    output  logic                  EXT_SRAM_CE,
    output  logic                  EXT_SRAM_WE,
    output  logic [`SRAM_BSEL_BUS] EXT_SRAM_BE,
    output  logic [`SRAM_DATA_BUS] EXT_SRAM_WDATA,
    output  logic [`SRAM_ADDR_BUS] EXT_SRAM_PADDR,
    /* UART */
    input   logic [`SRAM_DATA_BUS] UART_RDATA,
    output  logic                  UART_CE,
    output  logic                  UART_WE,
    output  logic                  UART_BE,
    output  logic [`DATA_BYTE_BUS] UART_WDATA,
    output  logic [ `CPU_ADDR_BUS] UART_VADDR,
    /* STALL */
    output  logic                  STALL_STR
);
/********************************* SEQUENTIAL CIRCUIT BEGIN  *********************************/
    /* 
    * 访存对象选择器
    * 问题: 如果直接将EX级的访存对象选择器传给SRAM控制器,在访存指令的下一条指令到来时选择信号会被覆盖,也即无法将读出的指令传递
    * 策略: 对选择器引入单独的寄存器,以时序电路保存一个周期,在指令读出后仍能生效即可
    * 注解：IF级实际上不需要这么做，因为IF一定是一直使能的，但为了展示思路我也这么做了。
    */
    logic [2:0] inst_sram_sel;
    logic [2:0] data_sram_sel;
    always_ff @( posedge CLK ) begin : SELECT_SIGNAL_REGISTER
        if (RST == `RST_EN) begin
            inst_sram_sel <= {3{~`SELECTED}};
            data_sram_sel <= {3{~`SELECTED}};
        end else begin
            inst_sram_sel <= INST_SRAM_SEL;
            data_sram_sel <= DATA_SRAM_SEL;
        end
    end
/********************************** SEQUENTIAL CIRCUIT END  **********************************/

/********************************* COMBINATIONAL CIRCUIT BEGIN *********************************/
    /* 
     * 阻塞信号 
     * 逻辑: 若在两个SRAM_SEL信号的相同bit上出现同时为0(SELECTED)的情况,则代表出现结构冒险
     * 注解1: 不论哪个位上出现了相同都算结构冒险,所以使用归约计算(|data),有任意一位为1则为1
     * 注解2: uart只会被data访问,不需要担心会在此位上出现冒险
     * 注解2: ~inst_sram_sel & ~data_sram_sel判断是否有重叠为0,如~01&~10,结果为00则无冒险,如10和10结果为01则有冒险
     */
    assign STALL_STR = (|(~INST_SRAM_SEL[1:0] & ~DATA_SRAM_SEL[1:0]));
    /* 
     * 片选信号
     * 逻辑: INST或DATA的SRAM_SEL中的任一一个只要在任意位上为SELECTED,就将选中对应外设 
     * 注解: inst_sram_sel & data_sram_sel判断两个选择信号每个位是否有一个为0,如果有则输出片选信号为0(CE),如101&110=100,表示访问EXT_SRAM和BASE_SRAM
    */
    assign {UART_CE, EXT_SRAM_CE, BASE_SRAM_CE} = INST_SRAM_SEL & DATA_SRAM_SEL;
    /* 
     * 写使能信号
     * 逻辑: 未出现结构冒险时,INST或DATA的写使能均能生效并传递到对应外设,出现结构冒险时仅有DATA的写使能生效,这样实现数据访存优先
     * 注解1: inst_sram_sel | {3{INST_WE}}判断写使能,中间的&号用以在未产生冒险时,对信号进行选择,如(110| 111) & (101|000),产生101,即对EXT_SRAM写
     * 注解2: 虽然INST恒不写,下面的判断式完全可以简化成DATA_WE直接赋值,但为了展示思路保留,不影响功能
     */
    assign {UART_WE, EXT_SRAM_WE, BASE_SRAM_WE} = STALL_STR == ~`STOP
                                                ? (INST_SRAM_SEL | {3{INST_WE}}) & (DATA_SRAM_SEL | {3{DATA_WE}})
                                                : (DATA_SRAM_SEL | {3{DATA_WE}});
    /* 
     * 字节使能信号
     * 逻辑: 类似写使能,不多赘述,只是要对BE的4个bit都检查是否有效,此外UART只检查最低位的BE信号即可,因为UART写串口时只写最低有效字节
     */
    assign BASE_SRAM_BE = STALL_STR == ~`STOP
                        ? ({4{INST_SRAM_SEL[0]}} | INST_BE) & ({4{DATA_SRAM_SEL[0]}} | DATA_BE)
                        : ({4{DATA_SRAM_SEL[0]}} | DATA_BE);
    assign EXT_SRAM_BE  = STALL_STR == ~`STOP
                        ? ({4{INST_SRAM_SEL[1]}} | INST_BE) & ({4{DATA_SRAM_SEL[1]}} | DATA_BE)
                        : ({4{DATA_SRAM_SEL[1]}} | DATA_BE);    
    assign UART_BE      = STALL_STR == ~`STOP
                        ? (INST_SRAM_SEL[2] | INST_BE[0]) & (DATA_SRAM_SEL[2] | DATA_BE[0])
                        : (DATA_SRAM_SEL[2] | DATA_BE[0]);
    /* 
     * 写数据
     * 逻辑: 对INST和DATA传入的写数据使用选择信号进行位与以确定是否要写数据
     * 注解1: 选择信号低有效,需要取反再位与,这样才能对不应该写入的数据进行屏蔽
     * 注解2: 中间的位或|符号用以确定写数据,比如INST不写但DATA有可能写
     * 注解3: 与写使能类似的,INST恒为不写与给出零字,下式可以简化为DATA_WDATA的直接赋值
     */
    assign BASE_SRAM_WDATA = STALL_STR == ~`STOP
                           ? ({32{~INST_SRAM_SEL[0]}} & INST_WDATA) | ({32{~DATA_SRAM_SEL[0]}} & DATA_WDATA) 
                           : ({32{~DATA_SRAM_SEL[0]}} & DATA_WDATA);
    assign EXT_SRAM_WDATA  = STALL_STR == ~`STOP
                           ? ({32{~INST_SRAM_SEL[1]}} & INST_WDATA) | ({32{~DATA_SRAM_SEL[1]}} & DATA_WDATA) 
                           : ({32{~DATA_SRAM_SEL[1]}} & DATA_WDATA);
    assign UART_WDATA      = STALL_STR == ~`STOP
                           ? ({ 8{~INST_SRAM_SEL[2]}} & INST_WDATA[7:0]) | ({8{~DATA_SRAM_SEL[2]}} & DATA_WDATA[7:0])  
                           : ({ 8{~DATA_SRAM_SEL[2]}} & DATA_WDATA[7:0]);

    /* 
     * 地址分配
     */
    assign BASE_SRAM_PADDR  = STALL_STR == ~`STOP
                            ? ({32{~INST_SRAM_SEL[0]}} & INST_PADDR) | ({32{~DATA_SRAM_SEL[0]}} & DATA_PADDR)
                            : ({32{~DATA_SRAM_SEL[0]}} & DATA_PADDR);
    assign EXT_SRAM_PADDR   = STALL_STR == ~`STOP
                            ? ({32{~INST_SRAM_SEL[1]}} & INST_PADDR) | ({32{~DATA_SRAM_SEL[1]}} & DATA_PADDR)
                            : ({32{~DATA_SRAM_SEL[1]}} & DATA_PADDR);
    assign UART_VADDR       = ({32{~DATA_SRAM_SEL[2]}} & DATA_VADDR);
    /* 
     * 数据分配
     */
    assign INST = {32{~inst_sram_sel[0]}} & BASE_SRAM_RDATA;
    assign DATA = {32{~data_sram_sel[0]}} & BASE_SRAM_RDATA
                | {32{~data_sram_sel[1]}} & EXT_SRAM_RDATA
                | {32{~data_sram_sel[2]}} & UART_RDATA;
/********************************** COMBINATIONAL CIRCUIT END **********************************/
endmodule