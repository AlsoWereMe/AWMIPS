`timescale 1ns / 1ps
`include "defines.vh"
module awmips(
    input   logic                  CLK,
    input   logic                  RST,
    // BASE_SRAM
    input   logic [`SRAM_DATA_BUS] BASE_SRAM_RDATA,
    output  logic                  BASE_SRAM_CE,
    output  logic                  BASE_SRAM_WE,
    output  logic [`SRAM_BSEL_BUS] BASE_SRAM_BE,
    output  logic [`SRAM_ADDR_BUS] BASE_SRAM_PADDR,
    output  logic [`SRAM_DATA_BUS] BASE_SRAM_WDATA,
    // EXT_SRAM
    input   logic [`SRAM_DATA_BUS] EXT_SRAM_RDATA,
    output  logic                  EXT_SRAM_CE,
    output  logic                  EXT_SRAM_WE,
    output  logic [`SRAM_BSEL_BUS] EXT_SRAM_BE,
    output  logic [`SRAM_ADDR_BUS] EXT_SRAM_PADDR,
    output  logic [`SRAM_DATA_BUS] EXT_SRAM_WDATA,
    // UART
    input   logic                  RXD,
    output  logic                  TXD
); 
    /* CPU核 */
    logic                  stall_str;
    logic                  sram_inst_ce;
    logic                  sram_inst_we;
    logic [`SRAM_BSEL_BUS] sram_inst_be;
    logic [ `CPU_ADDR_BUS] sram_inst_vaddr;
    logic [`SRAM_DATA_BUS] sram_inst_wdata;
    logic [           2:0] inst_sram_sel;
    logic                  sram_data_ce;
    logic                  sram_data_we;
    logic [`SRAM_BSEL_BUS] sram_data_be;
    logic [ `CPU_ADDR_BUS] sram_data_vaddr;
    logic [`SRAM_DATA_BUS] sram_data_wdata;
    logic [`SRAM_DATA_BUS] inst;
    logic [`SRAM_DATA_BUS] data;
    /* MMU */
    logic [`SRAM_ADDR_BUS] sram_inst_paddr;
    logic [`SRAM_ADDR_BUS] sram_data_paddr;
    logic [           2:0] data_sram_sel;
    /* UART控制器 */
    logic                  uart_ce   ;
    logic                  uart_we   ;
    logic                  uart_be   ;
    logic [ `CPU_ADDR_BUS] uart_vaddr;
    logic [`DATA_BYTE_BUS] uart_wdata;
    logic [`SRAM_DATA_BUS] uart_rdata;

    awmips_core u_AWMIPS_core(
        .CLK             (CLK            ),
        .RST             (RST            ),
        .INST            (inst           ),
        .DATA            (data           ),
        .STALL_STR       (stall_str      ),
        .SRAM_INST_CE    (sram_inst_ce   ),
        .SRAM_INST_WE    (sram_inst_we   ),
        .SRAM_INST_BE    (sram_inst_be   ),
        .SRAM_INST_VADDR (sram_inst_vaddr),
        .SRAM_INST_WDATA (sram_inst_wdata),
        .SRAM_DATA_CE    (sram_data_ce   ),
        .SRAM_DATA_WE    (sram_data_we   ),
        .SRAM_DATA_BE    (sram_data_be   ),
        .SRAM_DATA_VADDR (sram_data_vaddr),
        .SRAM_DATA_WDATA (sram_data_wdata)
    );
    
    mmu inst_mmu(
        .VADDR    (sram_inst_vaddr),
        .PADDR    (sram_inst_paddr),
        .SRAM_SEL (inst_sram_sel  )
    );
    
    mmu data_mmu(
        .VADDR    (sram_data_vaddr),
        .PADDR    (sram_data_paddr),
        .SRAM_SEL (data_sram_sel  )
    );
    
    uart_ctrl u_uart(
        .CLK        (CLK       ),
        .RST        (RST       ),
        .RXD        (RXD       ),
        .TXD        (TXD       ),
        .UART_CE    (uart_ce   ),
        .UART_WE    (uart_we   ),
        .UART_BE    (uart_be   ),
        .UART_VADDR (uart_vaddr),
        .UART_WDATA (uart_wdata),

        .UART_RDATA (uart_rdata)
    );

    path_sel u_path_sel(
        .CLK             (CLK            ),
        .RST             (RST            ),
        .INST_WE         (sram_inst_we   ),
        .INST_BE         (sram_inst_be   ),
        .INST_WDATA      (sram_inst_wdata),
        .INST_PADDR      (sram_inst_paddr),
        .INST_SRAM_SEL   (inst_sram_sel  ),
        .INST            (inst           ),
        .DATA_WE         (sram_data_we   ),
        .DATA_BE         (sram_data_be   ),
        .DATA_WDATA      (sram_data_wdata),
        .DATA_VADDR      (sram_data_vaddr),
        .DATA_PADDR      (sram_data_paddr),
        .DATA_SRAM_SEL   (data_sram_sel  ),
        .DATA            (data           ),
        .BASE_SRAM_RDATA (BASE_SRAM_RDATA),
        .BASE_SRAM_CE    (BASE_SRAM_CE   ),
        .BASE_SRAM_WE    (BASE_SRAM_WE   ),
        .BASE_SRAM_BE    (BASE_SRAM_BE   ),
        .BASE_SRAM_WDATA (BASE_SRAM_WDATA),
        .BASE_SRAM_PADDR (BASE_SRAM_PADDR),
        .EXT_SRAM_RDATA  (EXT_SRAM_RDATA ),
        .EXT_SRAM_CE     (EXT_SRAM_CE    ),
        .EXT_SRAM_WE     (EXT_SRAM_WE    ),
        .EXT_SRAM_BE     (EXT_SRAM_BE    ),
        .EXT_SRAM_WDATA  (EXT_SRAM_WDATA ),
        .EXT_SRAM_PADDR  (EXT_SRAM_PADDR ),
        .UART_RDATA      (uart_rdata     ),
        .UART_CE         (uart_ce        ),
        .UART_WE         (uart_we        ),
        .UART_BE         (uart_be        ),
        .UART_WDATA      (uart_wdata     ),
        .UART_VADDR      (uart_vaddr     ),
        .STALL_STR       (stall_str      )
    );
endmodule
