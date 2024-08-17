`timescale 1ns / 1ps
`include "defines.vh"

module stall_ctrl(
    input   logic              RST,
    input   logic              STALL_REQ_ID,
    input   logic              STALL_REQ_STR,
    output  logic [`STALL_BUS] STALL
);
    /*
     * 逻辑: ID级的暂停请求和外部的暂停请求均代表结构冒险
     * 策略: 结构冒险时将IF,IC,ID级阻塞,优先进行数据访问
     * 注解: `STALL_X中"X"的含义为将X级与其之前的流水级阻塞
     */
    always_comb begin : STALL_HANDLE
        if (RST == `RST_EN) begin
            STALL = `NO_STALL;
        end else if (STALL_REQ_ID == `STOP || STALL_REQ_STR == `STOP) begin
            STALL = `STALL_ID;
        end else begin
            STALL = `NO_STALL;
        end
    end
endmodule
