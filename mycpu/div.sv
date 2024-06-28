`timescale 1ns / 1ps
`include "defines.vh"

/* 除法器模块 */
module div(
    input logic CLK,
    input logic RST,
    
    input logic START,
    input logic CANCEL,
    input logic SIGNED_DIV,
    input logic [`REG_DATA_BUS] DIVIDEND,
    input logic [`REG_DATA_BUS] DIVISOR,
    
    output logic READY,
    output logic [`DOUBLE_REG_DATA_BUS] RESULT    
);

    logic [32:0] div_temp;
    logic [5:0] cnt;
    logic [64:0] dividend;
    logic [1:0] state;
    logic [31:0] divisor;
    
    assign div_temp = {1'b0, dividend[63:32]} - {1'b0, divisor};
    always_ff @(posedge CLK) begin
        if (RST == `RST_EN) begin
            state <= `DIV_FREE;
            READY <= `RESULT_NOT_READY;
            RESULT <= {`ZERO_WORD, `ZERO_WORD};
        end else begin
            case (state)
                `DIV_FREE: begin
                    if (START == `DIV_START && CANCEL == 1'b0) begin
                        if (DIVISOR == `ZERO_WORD) begin
                            state <= `DIV_ZERO;
                        end else begin
                            state <= `DIV_BUSY;
                            cnt <= 6'b000000;
                            dividend[63:33] <= 31'b0;
                            dividend[0] <= 1'b0;
                            if (SIGNED_DIV == 1'b1 && DIVIDEND[31] == 1'b1) begin
                                dividend[32:1] <= ~DIVIDEND + 1;
                            end else begin
                                dividend[32:1] <= DIVIDEND;
                            end
                            if (SIGNED_DIV == 1'b1 && DIVISOR[31] == 1'b1) begin
                                divisor <= ~DIVISOR + 1;
                            end else begin
                                divisor <= DIVISOR;
                            end
                        end
                    end else begin
                        READY <= `RESULT_NOT_READY;
                        RESULT <= {`ZERO_WORD, `ZERO_WORD};
                    end
                end
                `DIV_ZERO: begin
                    dividend <= {1'b0, `ZERO_WORD, `ZERO_WORD};
                    state <= `DIV_DONE;
                end
                `DIV_BUSY: begin
                    if (CANCEL == 1'b0) begin
                        if (cnt != 6'b100000) begin
                            if (div_temp[32] == 1'b1) begin
                                dividend <= {dividend[63:0], 1'b0};
                            end else begin
                                dividend <= {div_temp[31:0], dividend[31:0], 1'b1};
                            end
                            cnt <= cnt + 1;
                        end else begin
                            if (SIGNED_DIV == 1'b1 && ((DIVIDEND[31] ^ DIVISOR[31]) == 1'b1)) begin
                                dividend[31:0] <= (~dividend[31:0] + 1);
                            end
                            if (SIGNED_DIV == 1'b1 && ((DIVIDEND[31] ^ dividend[64]) == 1'b1)) begin
                                dividend[64:33] <= (~dividend[64:33] + 1);
                            end
                            state <= `DIV_DONE;
                            cnt <= 6'b000000;
                        end
                    end else begin
                        state <= `DIV_FREE;
                    end
                end
                `DIV_DONE: begin
                    RESULT <= {dividend[64:33], dividend[31:0]};  
                    READY <= `RESULT_READY;
                    if (START == `DIV_STOP) begin
                        state <= `DIV_FREE;
                        READY <= `RESULT_NOT_READY;
                        RESULT <= {`ZERO_WORD, `ZERO_WORD};
                    end
                end
            endcase
        end
    end

endmodule
