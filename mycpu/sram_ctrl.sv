`timescale 1ns/1ps
`include "defines.vh"
module sram_ctrl(
    input   logic                  CLK,
    input   logic                  RST,
    input   logic                  IRAM_CE_I,
    input   logic [`SRAM_ADDR_BUS] IRAM_VADDR,
    input   logic [`SRAM_DATA_BUS] IRAM_RDATA,
    input   logic                  DRAM_CE_I,
    input   logic                  DRAM_WE_I,
    input   logic [`SRAM_BSEL_BUS] DRAM_BE_I,
    input   logic [`SRAM_ADDR_BUS] DRAM_VADDR,
    input   logic [`SRAM_DATA_BUS] DRAM_RDATA,
    input   logic [`SRAM_DATA_BUS] DRAM_WDATA_I,

    output  logic                  IRAM_CE_O,
    output  logic                  IRAM_OE_O,
    output  logic                  IRAM_WE_O,
    output  logic [`SRAM_BSEL_BUS] IRAM_BE_O,
    output  logic [          19:0] IRAM_PADDR,
    output  logic                  DRAM_CE_O,
    output  logic                  DRAM_OE_O,
    output  logic                  DRAM_WE_O,
    output  logic [`SRAM_BSEL_BUS] DRAM_BE_O,
    output  logic [`SRAM_DATA_BUS] DRAM_WDATA_O,
    output  logic [          19:0] DRAM_PADDR,

    output  logic [`SRAM_DATA_BUS] INST,
    output  logic [`SRAM_DATA_BUS] DATA
);
    assign IRAM_BE_O = 4'b0000;
    assign IRAM_WE_O = ~`WE;
    assign IRAM_OE_O = `RE;
    
endmodule
