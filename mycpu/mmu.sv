`timescale 1ns/1ps
`include "defines.vh"

module mmu(
    input   logic [ `CPU_ADDR_BUS] VADDR,
    output  logic [`SRAM_ADDR_BUS] PADDR,
    output  logic [           2:0] SRAM_SEL
);
    /* 
     * 问题: 一个虚地址需要确认其映射后物理地址
     * 策略: 除了KSEG1和KSEG2需要覆盖高4位外,其余KSEG均可保持不变,KSEG1和KSEG2最高两位为10B,依据此判断即可
     */
    logic                 is_kseg_1_2;
    logic [`CPU_ADDR_BUS] tmp_paddr;
    assign is_kseg_1_2 = VADDR[31] & ~VADDR[30];
    assign tmp_paddr   = {{{4{~is_kseg_1_2}} & VADDR[31:28]}, VADDR[27:0]};
    assign PADDR       = tmp_paddr[21:2];

    /* 
     * 问题: 一个虚地址需要确认其访问对象,是BASE_RAM还是EXT_SRAM还是UART亦或者都不是
     * 策略: 通过将地址与掩码取位与,再将过滤后的数据与提前定义的标志地址比较,即可确认地址去处
     *       在本CPU中,若地址不访问BASE_RAM和EXT_RAM,认为其访问UART
     */
    logic base_ram_sel;
    logic ext_ram_sel;
    logic uart_sel;
    assign base_ram_sel  = (VADDR & `SRAM_SEL_MASK) == `BASE_RAM_FLAG ? `SELECTED : ~`SELECTED;
    assign ext_ram_sel   = (VADDR & `SRAM_SEL_MASK) == `EXT_RAM_FLAG  ? `SELECTED : ~`SELECTED;
    assign uart_sel      = base_ram_sel == ~`SELECTED && ext_ram_sel == ~`SELECTED 
                         ? `SELECTED
                         : ~`SELECTED;
    assign SRAM_SEL      = {uart_sel, ext_ram_sel, base_ram_sel};
endmodule
