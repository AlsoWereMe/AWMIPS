/* UART控制逻辑使用https://github.com/fluctlight001/cpu_for_nscscc2022_single/blob/main/thinpad_top.srcs/sources_1/new/Nova132A/confreg.v */
`timescale 1ns/1ps
`include "defines.vh"
module uart_ctrl(
    input   logic CLK,
    input   logic RST,
    // 主机写串口
    input   logic RXD,
    output  logic TXD,
    // CPU写串口
    input   logic                  UART_CE,
    input   logic                  UART_WE,
    input   logic                  UART_BE,     // UART只写一个Byte
    input   logic [ `CPU_ADDR_BUS] UART_VADDR,
    input   logic [`DATA_BYTE_BUS] UART_WDATA, 
    // 串口写CPU数据
    output  logic [`SRAM_DATA_BUS] UART_RDATA
);

    logic [`SRAM_DATA_BUS] uart_rdata;
    /* 访存所得串口数据 */
    logic [           1:0] uart_flag;
    logic [`DATA_BYTE_BUS] uart_data;
    /* uart_buffer控制信号 */
    wire                   ext_uart_ready;
    logic                  ext_uart_clear;
    logic                  ext_uart_busy;
    logic                  ext_uart_start;
    logic                  ext_uart_avai;
    logic [`DATA_BYTE_BUS] ext_uart_rx;
    logic [`DATA_BYTE_BUS] ext_uart_tx;
    logic [`DATA_BYTE_BUS] ext_uart_buffer;

    assign ext_uart_clear = ext_uart_ready; // 收到数据的同时，清除标志，因为数据已取到ext_uart_buffer
    assign uart_data      = ext_uart_buffer;
    assign uart_flag      = {ext_uart_avai,~ext_uart_busy};
    /* uart写串口控制信号 */
    logic                  write_uart_valid;
    logic [`DATA_BYTE_BUS] write_uart_data;
    assign write_uart_valid = UART_WE == `WE && UART_BE == `WE && (UART_VADDR == `UART_DATA_ADDR);

    always_ff @( posedge CLK ) begin : TX_BUFFER
        if (RST == `RST_EN) begin
            ext_uart_tx    <= `ZERO_BYTE;
            ext_uart_start <= ~`START;
        end else if (write_uart_valid == `VALID) begin
            ext_uart_tx    <= UART_WDATA;
            ext_uart_start <= `START;
        end else begin
            ext_uart_tx    <= ext_uart_tx;
            ext_uart_start <= ~`START;
        end
    end

    always_ff @( posedge CLK ) begin: RX_BUFFER
        if (RST == `RST_EN) begin
            ext_uart_buffer <= `ZERO_BYTE;
            ext_uart_avai   <= ~`AVAI;
        end else if (ext_uart_ready == `READY) begin
            ext_uart_buffer <= ext_uart_rx;
            ext_uart_avai   <= `AVAI;
        end else if (UART_VADDR == `UART_DATA_ADDR && UART_CE == `CE && UART_WE == ~`WE && ext_uart_avai == `AVAI) begin
            ext_uart_buffer <= ext_uart_buffer;
            ext_uart_avai   <= ~`AVAI;
        end else begin
            ext_uart_buffer <= ext_uart_buffer;
            ext_uart_avai   <= ext_uart_avai;
        end
    end

    always_ff @( posedge CLK ) begin : READ_PORT
        if (RST == `RST_EN) begin
            uart_rdata <= `ZERO_WORD;
        end else if (UART_CE == `CE) begin
            if (UART_VADDR == `UART_FLAG_ADDR) begin
                uart_rdata <= {30'b0, uart_flag};
            end else if (UART_VADDR == `UART_DATA_ADDR) begin
                uart_rdata <= {24'b0, uart_data};
            end else begin
                uart_rdata <= `ZERO_WORD;
            end
        end else begin
            uart_rdata <= uart_rdata;
        end
    end
    assign UART_RDATA = uart_rdata;

    async_transmitter #(
        .ClkFrequency(`CLK_FREQUENCY),
        .Baud(`UART_BAUD)
    )
    uart_tx (
        .clk       (CLK           ),
        .TxD_start (ext_uart_start),
        .TxD_data  (ext_uart_tx   ),
        .TxD       (TXD           ),
        .TxD_busy  (ext_uart_busy ) 
    );
    
    async_receiver #(
        .ClkFrequency(`CLK_FREQUENCY),
        .Baud(`UART_BAUD)
    )
    uart_rx (
        .clk            (CLK           ),
        .RxD            (RXD           ),
        .RxD_data_ready (ext_uart_ready),
        .RxD_clear      (ext_uart_clear),
        .RxD_data       (ext_uart_rx   )
    );
endmodule