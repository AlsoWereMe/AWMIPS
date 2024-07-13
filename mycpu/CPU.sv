`timescale 1ns / 1ps
`include "defines.vh"

module CPU(
    input   logic                 CLK,
    input   logic                 RST,
    input   logic[`SRAM_DATA_BUS] INST,
    input   logic[`SRAM_DATA_BUS] DATA,

    output  logic                 IRAM_CE,
    output  logic[`SRAM_ADDR_BUS] IRAM_VADDR,
    output  logic                 DRAM_CE,
    output  logic                 DRAM_WE,
    output  logic[`SRAM_BSEL_BUS] DRAM_BE,
    output  logic[`SRAM_ADDR_BUS] DRAM_VADDR,
    output  logic[`SRAM_DATA_BUS] DRAM_WDATA,
    output  logic                 ERROR
    );
    /* STALL */
    logic [           5:0] stall;
    /* ID */
    logic                  stall_req_id;
    logic                  id_cur_inst_ds_flag_i;
    logic [`SRAM_ADDR_BUS] id_pc_i;
    logic [`SRAM_DATA_BUS] id_inst_i;
    logic [ `REG_DATA_BUS] id_reg1_data_i;
    logic [ `REG_DATA_BUS] id_reg2_data_i;
    logic                  id_error;
    logic                  id_reg1_re_o;
    logic                  id_reg2_re_o;
    logic                  id_branch_flag;
    logic                  id_cur_inst_ds_flag_o;
    logic                  id_next_inst_in_ds_flag_o;
    logic                  id_gpr_we_o;
    logic [`SRAM_ADDR_BUS] id_branch_tar_addr;
    logic [`SRAM_ADDR_BUS] id_branch_link_addr;
    logic [`SRAM_DATA_BUS] id_inst_o;
    logic [ `REG_ADDR_BUS] id_reg1_addr_o;
    logic [ `REG_ADDR_BUS] id_reg2_addr_o;
    logic [   `ALU_OP_BUS] id_alu_op_o;
    logic [  `ALU_SEL_BUS] id_alu_sel_o;
    logic [ `REG_DATA_BUS] id_reg1_data_o;
    logic [ `REG_DATA_BUS] id_reg2_data_o;
    logic [ `REG_ADDR_BUS] id_gpr_waddr_o;
    /* EX */
    logic                  stall_req_ex;
    logic                  mul_ready;
    logic [`DREG_DATA_BUS] mul_result;
    logic                  ex_cur_inst_ds_flag;
    logic                  ex_gpr_we_i;
    logic [ `REG_DATA_BUS] ex_inst_i;
    logic [   `ALU_OP_BUS] ex_alu_op_i;
    logic [  `ALU_SEL_BUS] ex_alu_sel_i;
    logic [ `REG_ADDR_BUS] ex_gpr_waddr_i;
    logic [ `REG_DATA_BUS] ex_reg1_data_i;
    logic [ `REG_DATA_BUS] ex_reg2_data_i;
    logic [ `REG_DATA_BUS] ex_branch_link_addr;
    logic                  ex_error;
    logic                  signed_mul;
    logic                  mul_start;
    logic                  mul_cancel;
    logic [ `REG_DATA_BUS] multiplicand;
    logic [ `REG_DATA_BUS] multiplier;
    logic [   `ALU_OP_BUS] ex_alu_op_o;
    logic                  ex_gpr_we_o;
    logic [ `REG_ADDR_BUS] ex_gpr_waddr_o;
    logic [ `REG_DATA_BUS] ex_gpr_wdata_o;
    logic [`SRAM_DATA_BUS] ex_sram_addr_o;
    logic [`SRAM_DATA_BUS] ex_sram_wdata_o;
    /* MEM */
    logic [   `ALU_OP_BUS] mem_alu_op_i;
    logic [ `REG_ADDR_BUS] mem_gpr_waddr_i;
    logic [ `REG_DATA_BUS] mem_gpr_wdata_i;
    logic [`SRAM_DATA_BUS] mem_sram_addr_i;
    logic [`SRAM_DATA_BUS] mem_sram_wdata_i;
    logic                  mem_gpr_we_o;
    logic [ `REG_ADDR_BUS] mem_gpr_waddr_o;
    logic [ `REG_DATA_BUS] mem_gpr_wdata_o;
    logic [`SRAM_DATA_BUS] mem_sram_addr_o;
    logic [`SRAM_DATA_BUS] mem_sram_wdata_o;
    /* WB */
    logic                  wb_gpr_we;
    logic [ `REG_ADDR_BUS] wb_gpr_waddr;
    logic [ `REG_DATA_BUS] wb_gpr_wdata;

    assign ERROR = id_error | ex_error;
    stall_ctrl u_stall_ctrl(
        .RST           (RST          ),
        .STALL_REQ_ID  (stall_req_id ),
        .STALL_REQ_EX  (stall_req_ex ),
        .STALL_REQ_MEM (stall_req_mem),
        .STALL         (stall        )
    );
    
    pc u_pc(
        .CLK             (CLK               ),
        .RST             (RST               ),
        .STALL           (stall[0]          ),
        .BRANCH_FLAG     (id_branch_flag    ),
        .BRANCH_TAR_ADDR (id_branch_tar_addr),
        .PC              (IRAM_VADDR        ),
        .CE              (IRAM_CE           )
    );
    
    if_id u_if_id(
        .CLK     (CLK       ),
        .RST     (RST       ),
        .STALL   (stall[2:1]),
        .IF_PC   (IRAM_VADDR),
        .IF_INST (INST      ),
        .ID_PC   (id_pc_i   ),
        .ID_INST (id_inst_i )
    );

    id u_id(
        .RST                 (RST                      ),
        .PC_I                (id_pc_i                  ),
        .INST_I              (id_inst_i                ),
        .CUR_INST_DS_FLAG_I  (id_cur_inst_ds_flag_i    ),
        .REG1_DATA_I         (id_reg1_data_i           ),
        .REG2_DATA_I         (id_reg2_data_i           ),
        .EX_GPR_WE_I         (ex_gpr_we_o              ),
        .EX_ALU_OP_I         (ex_alu_op_o              ),
        .EX_GPR_WADDR_I      (ex_gpr_waddr_o           ),
        .EX_GPR_WDATA_I      (ex_gpr_wdata_o           ),
        .MEM_GPR_WE_I        (mem_gpr_we_o             ),
        .MEM_GPR_WADDR_I     (mem_gpr_waddr_o          ),
        .MEM_GPR_WDATA_I     (mem_gpr_wdata_o          ),

        .REG1_RE_O           (id_reg1_re_o             ),
        .REG2_RE_O           (id_reg2_re_o             ),
        .REG1_ADDR_O         (id_reg1_addr_o           ),
        .REG2_ADDR_O         (id_reg2_addr_o           ),
        .ALU_OP_O            (id_alu_op_o              ),
        .ALU_SEL_O           (id_alu_sel_o             ),
        .REG1_DATA_O         (id_reg1_data_o           ),
        .REG2_DATA_O         (id_reg2_data_o           ),
        .INST_O              (id_inst_o                ),
        .GPR_WADDR_O         (id_gpr_waddr_o           ),
        .GPR_WE_O            (id_gpr_we_o              ),
        .STALL_REQ           (stall_req_id             ),
        .CUR_INST_DS_FLAG_O  (id_cur_inst_ds_flag_o    ),
        .NEXT_INST_DS_FLAG_O (id_next_inst_in_ds_flag_o),
        .BRANCH_FLAG         (id_branch_flag           ),
        .BRANCH_TAR_ADDR     (id_branch_tar_addr       ),
        .BRANCH_LINK_ADDR    (id_branch_link_addr      ),
        .ERROR               (id_error                 )
    );  
    
    id_ex u_id_ex(
        .CLK                 (CLK                      ),
        .RST                 (RST                      ),
        .STALL               (stall[3:2]               ),
        .ID_NINST_DS_FLAG_I  (id_next_inst_in_ds_flag_o),
        .ID_CINST_DS_FLAG    (id_cur_inst_ds_flag_o    ),
        .ID_BRANCH_LINK_ADDR (id_branch_link_addr      ),
        .ID_ALU_OP           (id_alu_op_o              ),
        .ID_ALU_SEL          (id_alu_sel_o             ),
        .ID_REG1_DATA        (id_reg1_data_o           ),
        .ID_REG2_DATA        (id_reg2_data_o           ),
        .ID_INST             (id_inst_o                ),
        .ID_GPR_WADDR        (id_gpr_waddr_o           ),
        .ID_GPR_WE           (id_gpr_we_o              ),
        .ID_NINST_DS_FLAG_O  (id_cur_inst_ds_flag_i    ),
        .EX_CINST_DS_FLAG    (ex_cur_inst_ds_flag      ),
        .EX_BRANCH_LINK_ADDR (ex_branch_link_addr      ),
        .EX_ALU_OP           (ex_alu_op_i              ),
        .EX_ALU_SEL          (ex_alu_sel_i             ),
        .EX_REG1_DATA        (ex_reg1_data_i           ),
        .EX_REG2_DATA        (ex_reg2_data_i           ),
        .EX_INST             (ex_inst_i                ),
        .EX_GPR_WADDR        (ex_gpr_waddr_i           ),
        .EX_GPR_WE           (ex_gpr_we_i              )
    );
    
    ex u_ex(
        .RST              (RST                  ),
        .ALU_OP_I         (ex_alu_op_i          ),
        .ALU_SEL_I        (ex_alu_sel_i         ),
        .REG1_DATA_I      (ex_reg1_data_i       ),
        .REG2_DATA_I      (ex_reg2_data_i       ),
        .INST_I           (ex_inst_i            ),
        .GPR_WADDR_I      (ex_gpr_waddr_i       ),
        .GPR_WE_I         (ex_gpr_we_i          ),
        .CUR_INST_DS_FLAG (ex_cur_inst_ds_flag  ),
        .BRANCH_LINK_ADDR (ex_branch_link_addr  ),
        .MUL_READY        (mul_ready            ),
        .MUL_RESULT       (mul_result           ),

        .STALL_REQ        (stall_req_ex         ),
        .SIGNED_MUL       (signed_mul           ),
        .MUL_START        (mul_start            ),
        .MUL_CANCEL       (mul_cancel           ),
        .MULTIPLICAND     (multiplicand         ),
        .MULTIPLIER       (multiplier           ),
        .ALU_OP_O         (ex_alu_op_o          ),
        .SRAM_ADDR_O      (ex_sram_addr_o       ),
        .SRAM_WDATA_O     (ex_sram_wdata_o      ),
        .GPR_WDATA_O      (ex_gpr_wdata_o       ),
        .GPR_WADDR_O      (ex_gpr_waddr_o       ),
        .GPR_WE_O         (ex_gpr_we_o          ),
        .ERROR            (ex_error             )
    );

    mul u_mul(
        .RST          (RST         ),
        .CLK          (CLK         ),
        .SIGNED_MUL   (signed_mul  ),
        .MULTIPLIER   (multiplier  ),
        .MULTIPLICAND (multiplicand),
        .START        (mul_start   ),
        .CANCEL       (mul_cancel  ),
        .RESULT       (mul_result  ),
        .READY        (mul_ready   )
    );

    ex_mem u_ex_mem(
        .CLK            (CLK             ),
        .RST            (RST             ),
        .STALL          (stall[4:3]      ),
        .EX_ALU_OP      (ex_alu_op_o     ),
        .EX_SRAM_WDATA  (ex_sram_wdata_o ),
        .EX_SRAM_ADDR   (ex_sram_addr_o  ),
        .EX_GPR_WDATA   (ex_gpr_wdata_o  ),
        .EX_GPR_WADDR   (ex_gpr_waddr_o  ),
        .EX_GPR_WE      (ex_gpr_we_o     ),
        .MEM_ALU_OP     (mem_alu_op_i    ),
        .MEM_SRAM_WDATA (mem_sram_wdata_i),
        .MEM_SRAM_ADDR  (mem_sram_addr_i ),
        .MEM_GPR_WDATA  (mem_gpr_wdata_i ),
        .MEM_GPR_WADDR  (mem_gpr_waddr_i ),
        .MEM_GPR_WE     (mem_gpr_we_o    )
    );

    mem u_mem(
        .RST          (RST             ),
        .SRAM_RDATA   (DATA            ),
        .ALU_OP_I     (mem_alu_op_i    ),
        .SRAM_ADDR_I  (mem_sram_addr_i ),
        .SRAM_WDATA_I (mem_sram_wdata_i),
        .GPR_WADDR_I  (mem_gpr_waddr_i ),
        .GPR_WDATA_I  (mem_gpr_wdata_i ),
        .GPR_WE_I     (mem_gpr_we_o    ),
        .GPR_WADDR_O  (mem_gpr_waddr_o ),
        .GPR_WDATA_O  (mem_gpr_wdata_o ),
        .GPR_WE_O     (mem_gpr_we_o    ),
        .STALL_REQ    (stall_req_mem   ),
        .SRAM_WDATA_O (DRAM_WDATA      ),
        .SRAM_ADDR_O  (DRAM_VADDR      ),
        .SRAM_WE_O    (DRAM_WE         ),
        .SRAM_CE_O    (DRAM_CE         ),
        .SRAM_BE_O    (DRAM_BE         )
    );

    mem_wb u_mem_wb(
        .RST           (RST            ),
        .CLK           (CLK            ),
        .STALL         (stall[5:4]     ),
        .MEM_GPR_WDATA (mem_gpr_wdata_o),
        .MEM_GPR_WADDR (mem_gpr_waddr_o),
        .MEM_GPR_WE    (mem_gpr_we_o   ),
        .WB_GPR_WDATA  (wb_gpr_wdata   ),
        .WB_GPR_WADDR  (wb_gpr_waddr   ),
        .WB_GPR_WE     (wb_gpr_we      )
    );
    
    gprs u_gprs(
        .CLK    (CLK           ),
        .RST    (RST           ),
        .WEN    (wb_gpr_we     ),
        .WADDR  (wb_gpr_waddr  ),
        .WDATA  (wb_gpr_wdata  ),
        .REN1   (id_reg1_re_o  ),
        .RADDR1 (id_reg1_addr_o),
        .RDATA1 (id_reg1_data_i),
        .REN2   (id_reg2_re_o  ),
        .RADDR2 (id_reg2_addr_o),
        .RDATA2 (id_reg2_data_i)
    );
endmodule
