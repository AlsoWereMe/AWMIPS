`timescale 1ns/1ps
`include "defines.vh"
module sram_ctrl(
    input   logic                  CLK,
    input   logic                  RST,
    // BASE_SRAM
    inout   logic [`SRAM_DATA_BUS] BASE_RAM_DATA,
    input   logic [`SRAM_ADDR_BUS] BASE_RAM_PADDR_I,
    input   logic [`SRAM_DATA_BUS] BASE_RAM_WDATA_I,
    input   logic                  BASE_RAM_CE_N_I,
    input   logic                  BASE_RAM_WE_N_I,
    input   logic [`SRAM_BSEL_BUS] BASE_RAM_BE_N_I,
    output  logic                  BASE_RAM_CE_N_O,
    output  logic                  BASE_RAM_OE_N_O,
    output  logic                  BASE_RAM_WE_N_O,
    output  logic [`SRAM_BSEL_BUS] BASE_RAM_BE_N_O,
    output  logic [`SRAM_ADDR_BUS] BASE_RAM_PADDR_O,
    output  logic [`SRAM_DATA_BUS] BASE_RAM_RDATA,
    // EXT_SRAM
    inout   logic [`SRAM_DATA_BUS] EXT_RAM_DATA,
    input   logic [`SRAM_ADDR_BUS] EXT_RAM_PADDR_I,
    input   logic [`SRAM_DATA_BUS] EXT_RAM_WDATA_I,
    input   logic                  EXT_RAM_CE_N_I,
    input   logic                  EXT_RAM_WE_N_I,
    input   logic [`SRAM_BSEL_BUS] EXT_RAM_BE_N_I,
    output  logic                  EXT_RAM_CE_N_O,
    output  logic                  EXT_RAM_OE_N_O,
    output  logic                  EXT_RAM_WE_N_O,
    output  logic [`SRAM_BSEL_BUS] EXT_RAM_BE_N_O,
    output  logic [`SRAM_ADDR_BUS] EXT_RAM_PADDR_O,
    output  logic [`SRAM_DATA_BUS] EXT_RAM_RDATA
);
/********************************* COMBINATIONAL CIRCUIT BEGIN *********************************/
    logic                  base_ram_ce_n;
    logic                  base_ram_oe_n;
    logic                  base_ram_we_n;
    logic [`SRAM_BSEL_BUS] base_ram_be_n;
    logic [`SRAM_DATA_BUS] base_ram_wdata;
    logic [`SRAM_ADDR_BUS] base_ram_paddr;
    logic                  ext_ram_ce_n;
    logic                  ext_ram_oe_n;
    logic                  ext_ram_we_n;
    logic [`SRAM_BSEL_BUS] ext_ram_be_n;
    logic [`SRAM_DATA_BUS] ext_ram_wdata;
    logic [`SRAM_ADDR_BUS] ext_ram_paddr;
    assign BASE_RAM_BE_N_O = base_ram_be_n;
    assign BASE_RAM_CE_N_O = base_ram_ce_n;
    assign BASE_RAM_WE_N_O = base_ram_we_n;
    assign BASE_RAM_OE_N_O = base_ram_oe_n;
    assign BASE_RAM_PADDR_O = base_ram_paddr;
    assign EXT_RAM_BE_N_O  = ext_ram_be_n;
    assign EXT_RAM_CE_N_O  = ext_ram_ce_n;
    assign EXT_RAM_OE_N_O  = ext_ram_oe_n;
    assign EXT_RAM_WE_N_O  = ext_ram_we_n;
    assign EXT_RAM_PADDR_O  = ext_ram_paddr;
    /* 
     * inout三态门
     * 等式左边被赋值方视作output,在写信号有效时,WDATA需要传数据,在无效时则为高阻抗Z
     * RDATA则相反
     */
    assign BASE_RAM_DATA  = base_ram_we_n == `WE ? base_ram_wdata : 32'bz;
    assign EXT_RAM_DATA   = ext_ram_we_n  == `WE ? ext_ram_wdata  : 32'bz;
    /* 
     * 访存输出
     * 任何一个RAM读出数据后直接返回值
     */
    assign BASE_RAM_RDATA = BASE_RAM_DATA;
    assign EXT_RAM_RDATA  = EXT_RAM_DATA;
/********************************** COMBINATIONAL CIRCUIT END **********************************/

/********************************* SEQUENTIAL CIRCUIT BEGIN  *********************************/
    /* 
     * BASE_RAM与EXT_RAM控制信号传递,用时序电路保持一个周期
     */
    always_ff @( posedge CLK ) begin : RAM_CONTROL_SIGNALS
        if (RST == `RST_EN) begin
            base_ram_ce_n  <= ~`CE;
            base_ram_we_n  <= ~`WE;
            base_ram_be_n  <= ~`BE;
            base_ram_oe_n  <= ~`OE;
            base_ram_wdata <= `ZERO_WORD;
            base_ram_paddr <= 19'b0;

            ext_ram_ce_n   <= ~`CE;
            ext_ram_we_n   <= ~`WE;
            ext_ram_oe_n   <= ~`OE;
            ext_ram_be_n   <= ~`BE;
            ext_ram_wdata  <= `ZERO_WORD;
            ext_ram_paddr  <= 19'b0;
        end else begin
            base_ram_ce_n  <= BASE_RAM_CE_N_I;
            base_ram_we_n  <= BASE_RAM_WE_N_I;
            base_ram_oe_n  <= BASE_RAM_CE_N_I | ~BASE_RAM_WE_N_I;  // OE信号在片选信号有效且WE信号无效时有效
            base_ram_be_n  <= BASE_RAM_BE_N_I;
            base_ram_paddr <= BASE_RAM_PADDR_I;
            base_ram_wdata <= BASE_RAM_WDATA_I;

            ext_ram_ce_n   <= EXT_RAM_CE_N_I;
            ext_ram_we_n   <= EXT_RAM_WE_N_I;
            ext_ram_oe_n   <= EXT_RAM_CE_N_I | ~EXT_RAM_WE_N_I;
            ext_ram_be_n   <= EXT_RAM_BE_N_I;
            ext_ram_paddr  <= EXT_RAM_PADDR_I; 
            ext_ram_wdata  <= EXT_RAM_WDATA_I;
        end
    end
/********************************** SEQUENTIAL CIRCUIT END  **********************************/
endmodule
