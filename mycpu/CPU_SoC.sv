`timescale 1ns / 1ps
`include "defines.vh"

/* SoP */
module CPU_SoC(
    input logic CLK,
    input logic RST
    );

    logic[`INST_ADDR_BUS]   ROM_ADDR;
    logic[`INST_DATA_BUS]   ROM_INST;
    logic                   ROM_CEN;
    logic[`REG_DATA_BUS]    RAM_ADDR;
    logic[`REG_DATA_BUS]    RAM_LDATA;
    logic[`REG_DATA_BUS]    RAM_SDATA;
    logic[3:0]              RAM_BYTE_SEL;
    logic                   RAM_CEN;
    logic                   RAM_WEN;
    logic[`REG_DATA_BUS]    HI_DATA;
    logic[`REG_DATA_BUS]    LO_DATA;
    logic                   ERROR_ID;
    logic                   ERROR_EX;
    logic[`REG_DATA_BUS]    REGS[`REG_NUM];
    logic[`DATA_BUS]    	RAM[`DATA_MEM_NUM];


    data_ram u_data_ram(
    .CLK      (CLK          ),
    .CEN      (RAM_CEN      ),
    .WEN      (RAM_WEN      ),
    .ADDR     (RAM_ADDR     ),
    .BYTE_SEL (RAM_BYTE_SEL ),
    .SDATA    (RAM_SDATA    ),
    .LDATA    (RAM_LDATA    ),
    .RAM      (RAM          )
    );

    inst_rom u_inst_rom(
        .CEN  (ROM_CEN  ),
        .ADDR (ROM_ADDR ),
        .INST (ROM_INST )
    );

    CPU AWM_MIPS(
        .CLK          (CLK          ),
        .RST          (RST          ),
        .ROM_INST     (ROM_INST     ),
        .RAM_LDATA    (RAM_LDATA    ),
        .ROM_ADDR     (ROM_ADDR     ),
        .ROM_CEN      (ROM_CEN      ),
        .RAM_LSADDR   (RAM_ADDR     ),
        .RAM_SDATA    (RAM_SDATA    ),
        .RAM_BYTE_SEL (RAM_BYTE_SEL ),
        .RAM_CEN      (RAM_CEN      ),
        .RAM_WEN      (RAM_WEN      ),
        .HI_DATA	  (HI_DATA		),
		.LO_DATA	  (LO_DATA		),
        .ERROR_ID     (ERROR_ID     ),
        .ERROR_EX     (ERROR_EX     ),
        .REGS         (REGS         )
    );   
endmodule

