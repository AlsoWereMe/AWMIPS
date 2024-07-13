`timescale 1ns / 1ps
`include "defines.vh"
module SoC(
    input   logic                  CLK,
    input   logic                  RST,
    input   logic [`SRAM_DATA_BUS] IRAM_RDATA,
    input   logic [`SRAM_DATA_BUS] DRAM_RDATA,
    output  logic                  ERROR,
    output  logic                  DRAM_CE,
    output  logic                  DRAM_WE,
    output  logic                  DRAM_OE,
    output  logic [`SRAM_BSEL_BUS] DRAM_BE,
    output  logic [          19:0] DRAM_PADDR,
    output  logic [`SRAM_DATA_BUS] DRAM_WDATA,
    output  logic                  IRAM_WE,
    output  logic                  IRAM_OE,
    output  logic [`SRAM_BSEL_BUS] IRAM_BE,
    output  logic [          19:0] IRAM_PADDR
); 
    logic [`SRAM_DATA_BUS] inst;
    logic [`SRAM_DATA_BUS] data;
    logic                  iram_ce_i;
    logic [`SRAM_ADDR_BUS] iram_vaddr;
    logic                  dram_ce_i;
    logic                  dram_we_i;
    logic [`SRAM_BSEL_BUS] dram_be_i;
    logic [`SRAM_ADDR_BUS] dram_vaddr;
    logic [`SRAM_DATA_BUS] dram_wdata_i;

    CPU AWMIPS(
        .CLK        (CLK         ),
        .RST        (RST         ),
        .INST       (inst        ),
        .DATA       (data        ),
        .IRAM_CE    (iram_ce_i   ),
        .IRAM_VADDR (iram_vaddr  ),
        .DRAM_CE    (dram_ce_i   ),
        .DRAM_WE    (dram_we_i   ),
        .DRAM_BE    (dram_be_i   ),
        .DRAM_VADDR (dram_vaddr  ),
        .DRAM_WDATA (dram_wdata_i),
        .ERROR      (ERROR       )
    );

    sram_ctrl u_sram_ctrl(
        .CLK          (CLK         ),
        .RST          (RST         ),
        .IRAM_CE_I    (iram_ce_i   ),
        .IRAM_VADDR   (iram_vaddr  ),
        .IRAM_RDATA   (IRAM_RDATA  ),
        .DRAM_CE_I    (dram_ce_i   ),
        .DRAM_WE_I    (dram_we_i   ),
        .DRAM_BE_I    (dram_be_i   ),
        .DRAM_VADDR   (dram_vaddr  ),
        .DRAM_RDATA   (DRAM_RDATA  ),
        .DRAM_WDATA_I (dram_wdata_i),
        .IRAM_CE_O    (IRAM_CE     ),
        .IRAM_OE_O    (IRAM_OE     ),
        .IRAM_WE_O    (IRAM_WE     ),
        .IRAM_BE_O    (IRAM_BE     ),
        .IRAM_PADDR   (IRAM_PADDR  ),
        .DRAM_CE_O    (DRAM_CE     ),
        .DRAM_OE_O    (DRAM_OE     ),
        .DRAM_WE_O    (DRAM_WE     ),
        .DRAM_BE_O    (DRAM_BE     ),
        .DRAM_WDATA_O (DRAM_WDATA  ),
        .DRAM_PADDR   (DRAM_PADDR  ),
        .INST         (inst        ),
        .DATA         (data        )
    );
    
endmodule


