`timescale 1ns / 1ps
`include "defines.vh"

module ic_id(
    input   logic                  CLK,
    input   logic                  RST,
    input   logic [           1:0] STALL,
    input   logic                  IV,
    input   logic [ `CPU_ADDR_BUS] IC_PC,
    input   logic [`SRAM_DATA_BUS] IC_INST, 
    output  logic [ `CPU_ADDR_BUS] ID_PC,
    output  logic [`SRAM_DATA_BUS] ID_INST
);
    /* 
     * 问题: 在传统的五级流水线中,延迟槽无需被特别设计,会自然而然的实现,但是在本CPU中,由于长流水问题,如果跳转请求与流水线阻塞同时发生则会出现问题
     *       在跳转生效且阻塞时,由于ID级与IF级相隔两级,跳转指令后的第二条指令会被取出传递到此寄存器,在阻塞结束后该条指令会被传出,原本需要执行的指令反而会被"吞掉"
     * 策略: 引入寄存器de_slot在流水线阻塞时存储下一条需要译码的指令,并且用IV信号指示当前指令是否应该被执行,IV信号在IF级被赋值,如果需要跳转则无效,反之有效
     *       若流水线被暂停且延迟槽未被激活,则将指令放入延迟槽并激活延迟槽,这样能够屏蔽掉延迟槽指令后的指令,ds_flag用以指示de_slot是否被激活
    */
    logic                  ds_flag;
    logic [`SRAM_DATA_BUS] de_slot; 
    logic [ `CPU_ADDR_BUS] id_pc;
    logic [`SRAM_DATA_BUS] id_inst;
    
    always_ff @( posedge CLK ) begin : REGISTER_MAINTENANCE
        if (RST == `RST_EN) begin
            ds_flag  <= ~`IN_DESLOT;
            de_slot  <= `ZERO_WORD;
            id_pc    <= `ZERO_WORD;
            id_inst  <= `ZERO_WORD;
        end else if (STALL[0] == ~`STOP) begin
            id_pc <= IC_PC;
            if (ds_flag == `IN_DESLOT) begin
                ds_flag <= ~`IN_DESLOT;
                de_slot <= `ZERO_WORD;
                id_inst <= de_slot;
            end else if (IV == `INST_VALID) begin
                ds_flag <= ds_flag;
                de_slot <= de_slot;
                id_inst <= IC_INST;
            end else begin
                ds_flag <= ds_flag;
                de_slot <= de_slot;
                id_inst <= `INST_NOOP;
            end
        end else if (STALL[1] == ~`STOP) begin
            ds_flag  <= ~`IN_DESLOT;
            de_slot  <= `ZERO_WORD;
            id_pc    <= `ZERO_WORD;
            id_inst  <= `ZERO_WORD;
        end else if (ds_flag == ~`IN_DESLOT) begin 
            ds_flag <= `IN_DESLOT;
            de_slot <= IC_INST;
            id_pc   <= id_pc;
            id_inst <= id_inst;
        end else begin
            ds_flag <= ds_flag;
            de_slot <= de_slot;
            id_pc   <= id_pc;
            id_inst <= id_inst;
        end
    end
    assign ID_PC   = id_pc;
    assign ID_INST = id_inst;
endmodule

