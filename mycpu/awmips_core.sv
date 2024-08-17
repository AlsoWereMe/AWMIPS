`timescale 1ns / 1ps
`include "defines.vh"

module awmips_core(
    input   logic                  CLK,
    input   logic                  RST,
    /* 通路选择器数据 */
    input   logic                  STALL_STR,
    input   logic [`SRAM_DATA_BUS] INST,
    input   logic [`SRAM_DATA_BUS] DATA,
    /* IF级访存控制信号与数据 */
    output  logic                  SRAM_INST_CE,    
    output  logic                  SRAM_INST_WE, 
    output  logic [`SRAM_BSEL_BUS] SRAM_INST_BE,
    output  logic [ `CPU_ADDR_BUS] SRAM_INST_VADDR,
    output  logic [`SRAM_DATA_BUS] SRAM_INST_WDATA,
    /* EX级访存控制信号与数据 */
    output  logic                  SRAM_DATA_CE,    
    output  logic                  SRAM_DATA_WE,
    output  logic [`SRAM_BSEL_BUS] SRAM_DATA_BE,    
    output  logic [ `CPU_ADDR_BUS] SRAM_DATA_VADDR,
    output  logic [`SRAM_DATA_BUS] SRAM_DATA_WDATA
);

/*************** WIRE DECLARATION BEGIN ***************/
    /* STALL */
    logic [    `STALL_BUS] stall;
    /* IC */
    logic [ `CPU_ADDR_BUS] ic_pc_i;
    logic                  ic_iv_i;
    logic [ `CPU_ADDR_BUS] ic_pc_o;
    logic                  ic_iv_o;
    /* ID */
    logic [ `CPU_ADDR_BUS] id_pc_i;
    logic [`SRAM_DATA_BUS] id_inst_i;
    logic [ `REG_DATA_BUS] id_reg1_data_i;
    logic [ `REG_DATA_BUS] id_reg2_data_i;
    logic                  stall_req_id;
    logic                  id_reg1_re_o;
    logic                  id_reg2_re_o;
    logic [ `REG_ADDR_BUS] id_reg1_addr_o;
    logic [ `REG_ADDR_BUS] id_reg2_addr_o;
    logic                  id_gpr_we_o;
    logic [ `REG_ADDR_BUS] id_gpr_waddr_o;
    logic [ `REG_DATA_BUS] id_reg1_data_o;
    logic [ `REG_DATA_BUS] id_reg2_data_o;
    logic [          15:0] id_imm;
    logic [   `ALU_OP_BUS] id_alu_op_o;
    logic [  `ALU_SEL_BUS] id_alu_sel_o;
    logic                  id_branch_flag;
    logic [ `CPU_ADDR_BUS] id_branch_tar_addr;
    logic [ `CPU_ADDR_BUS] id_branch_link_addr;
    /* EX */
    logic                  ex_gpr_we_i;
    logic [          15:0] ex_imm;
    logic [   `ALU_OP_BUS] ex_alu_op_i;
    logic [  `ALU_SEL_BUS] ex_alu_sel_i;
    logic [ `REG_ADDR_BUS] ex_gpr_waddr_i;
    logic [ `REG_DATA_BUS] ex_reg1_data_i;
    logic [ `REG_DATA_BUS] ex_reg2_data_i;
    logic [ `REG_DATA_BUS] ex_branch_link_addr;
    logic [   `ALU_OP_BUS] ex_alu_op_o;
    logic                  ex_gpr_we_o;
    logic [ `REG_DATA_BUS] ex_gpr_wdata_o;
    logic [ `REG_ADDR_BUS] ex_gpr_waddr_o;
    /* DF */
    logic [   `ALU_OP_BUS] df_alu_op_i;      
    logic                  df_gpr_we_i;     
    logic [ `REG_DATA_BUS] df_gpr_wdata_i;   
    logic [ `REG_ADDR_BUS] df_gpr_waddr_i;   
    logic [`SRAM_BSEL_BUS] df_sram_data_be_i;
    logic [   `ALU_OP_BUS] df_alu_op_o;      
    logic                  df_gpr_we_o;     
    logic [ `REG_DATA_BUS] df_gpr_wdata_o;   
    logic [ `REG_ADDR_BUS] df_gpr_waddr_o;   
    logic [`SRAM_BSEL_BUS] df_sram_data_be_o;
    /* MEM */     
    logic [   `ALU_OP_BUS] mem_alu_op_i;
    logic                  mem_gpr_we_i;
    logic [ `REG_ADDR_BUS] mem_gpr_waddr_i;
    logic [ `REG_DATA_BUS] mem_gpr_wdata_i;
    logic [`SRAM_BSEL_BUS] mem_sram_data_be_i;
    logic [`SRAM_DATA_BUS] mem_sram_data_i;
    logic                  mem_gpr_we_o;
    logic [ `REG_DATA_BUS] mem_gpr_wdata_o;
    logic [ `REG_ADDR_BUS] mem_gpr_waddr_o;
    /* WB */
    logic                  wb_gpr_we;
    logic [ `REG_ADDR_BUS] wb_gpr_waddr;
    logic [ `REG_DATA_BUS] wb_gpr_wdata;
/**************** WIRE DECLARATION END ****************/

/*************** CONNECTION BEGIN ***************/
    stall_ctrl u_stall_ctrl(
        /* I */
        .RST           (RST         ),
        .STALL_REQ_ID  (stall_req_id),
        .STALL_REQ_STR (STALL_STR   ),
        /* O */
        .STALL         (stall       )
    );
    
    pc u_pc(
        /* I */
        .CLK             (CLK               ),
        .RST             (RST               ),
        .STALL           (stall[0]          ),
        .BRANCH_FLAG     (id_branch_flag    ),
        .BRANCH_TAR_ADDR (id_branch_tar_addr),
        /* O */
        .SRAM_INST_CE    (SRAM_INST_CE      ),
        .SRAM_INST_WE    (SRAM_INST_WE      ),
        .SRAM_INST_BE    (SRAM_INST_BE      ),
        .SRAM_INST_WDATA (SRAM_INST_WDATA   ),
        .SRAM_INST_VADDR (SRAM_INST_VADDR   )
    );

    if_ic u_if_ic(
        /* I */
        .CLK         (CLK            ),
        .RST         (RST            ),
        .STALL       (stall[1:0]     ),
        .BRANCH_FLAG (id_branch_flag ),
        .IF_PC       (SRAM_INST_VADDR),
        /* O */
        .IC_IV       (ic_iv_i        ),
        .IC_PC       (ic_pc_i        )
    );
    
    ic u_ic(
        /* I */
        .RST  (RST    ),
        .PC_I (ic_pc_i),
        .IV_I (ic_iv_i),
        /* O */
        .PC_O (ic_pc_o),
        .IV_O (ic_iv_o)
    );
    
    ic_id u_ic_id(
        /* I */
        .CLK     (CLK       ),
        .RST     (RST       ),
        .STALL   (stall[2:1]),
        .IV      (ic_iv_o   ),
        .IC_PC   (ic_pc_o   ),
        .IC_INST (INST      ),
        /* O */
        .ID_PC   (id_pc_i   ),
        .ID_INST (id_inst_i )
    );

    id u_id(
        /* I */
        .RST              (RST                ),
        .PC_I             (id_pc_i            ),
        .INST_I           (id_inst_i          ),
        .REG1_DATA_I      (id_reg1_data_i     ),
        .REG2_DATA_I      (id_reg2_data_i     ),
        .EX_GPR_WE_I      (ex_gpr_we_o        ),
        .EX_GPR_WADDR_I   (ex_gpr_waddr_o     ),
        .EX_GPR_WDATA_I   (ex_gpr_wdata_o     ),
        .EX_ALU_OP_I      (ex_alu_op_o        ),
        .DF_GPR_WE_I      (df_gpr_we_o        ),
        .DF_GPR_WADDR_I   (df_gpr_waddr_o     ),
        .DF_GPR_WDATA_I   (df_gpr_wdata_o     ),
        .DF_ALU_OP_I      (df_alu_op_o        ),
        .MEM_GPR_WE_I     (mem_gpr_we_o       ),
        .MEM_GPR_WADDR_I  (mem_gpr_waddr_o    ),
        .MEM_GPR_WDATA_I  (mem_gpr_wdata_o    ),
        /* O */
        .STALL_REQ        (stall_req_id       ),
        .REG1_RE_O        (id_reg1_re_o       ),
        .REG2_RE_O        (id_reg2_re_o       ),
        .REG1_ADDR_O      (id_reg1_addr_o     ),
        .REG2_ADDR_O      (id_reg2_addr_o     ),
        .GPR_WE_O         (id_gpr_we_o        ),
        .GPR_WADDR_O      (id_gpr_waddr_o     ),
        .REG1_DATA_O      (id_reg1_data_o     ),
        .REG2_DATA_O      (id_reg2_data_o     ),
        .IMM              (id_imm             ),
        .ALU_OP_O         (id_alu_op_o        ),
        .ALU_SEL_O        (id_alu_sel_o       ),
        .BRANCH_FLAG      (id_branch_flag     ),
        .BRANCH_TAR_ADDR  (id_branch_tar_addr ),
        .BRANCH_LINK_ADDR (id_branch_link_addr)
    );
    
    id_ex u_id_ex(
        /* I */
        .CLK                 (CLK                ),
        .RST                 (RST                ),
        .STALL               (stall[3:2]         ),
        .ID_BRANCH_LINK_ADDR (id_branch_link_addr),
        .ID_ALU_OP           (id_alu_op_o        ),
        .ID_ALU_SEL          (id_alu_sel_o       ),
        .ID_REG1_DATA        (id_reg1_data_o     ),
        .ID_REG2_DATA        (id_reg2_data_o     ),
        .ID_IMM              (id_imm             ),
        .ID_GPR_WADDR        (id_gpr_waddr_o     ),
        .ID_GPR_WE           (id_gpr_we_o        ),
        /* O */
        .EX_BRANCH_LINK_ADDR (ex_branch_link_addr),
        .EX_ALU_OP           (ex_alu_op_i        ),
        .EX_ALU_SEL          (ex_alu_sel_i       ),
        .EX_REG1_DATA        (ex_reg1_data_i     ),
        .EX_REG2_DATA        (ex_reg2_data_i     ),
        .EX_IMM              (ex_imm             ),
        .EX_GPR_WADDR        (ex_gpr_waddr_i     ),
        .EX_GPR_WE           (ex_gpr_we_i        )
    );
    
    ex u_ex(
        /* I */
        .RST               (RST                ),
        .ALU_OP_I          (ex_alu_op_i        ),
        .ALU_SEL_I         (ex_alu_sel_i       ),
        .IMM               (ex_imm             ),
        .REG1_DATA_I       (ex_reg1_data_i     ),
        .REG2_DATA_I       (ex_reg2_data_i     ),
        .GPR_WADDR_I       (ex_gpr_waddr_i     ),
        .GPR_WE_I          (ex_gpr_we_i        ),
        .BRANCH_LINK_ADDR  (ex_branch_link_addr),
        /* O */
        .ALU_OP_O          (ex_alu_op_o        ),
        .GPR_WE_O          (ex_gpr_we_o        ),
        .GPR_WDATA_O       (ex_gpr_wdata_o     ),
        .GPR_WADDR_O       (ex_gpr_waddr_o     ),
        .SRAM_DATA_WE_O    (SRAM_DATA_WE       ),
        .SRAM_DATA_CE_O    (SRAM_DATA_CE       ),
        .SRAM_DATA_BE_O    (SRAM_DATA_BE       ),
        .SRAM_DATA_VADDR_O (SRAM_DATA_VADDR    ),
        .SRAM_DATA_WDATA_O (SRAM_DATA_WDATA    )

    );
    
    ex_df u_ex_df(
        /* I */
        .CLK             (CLK              ),
        .RST             (RST              ),
        .STALL           (stall[4:3]       ),
        .EX_ALU_OP       (ex_alu_op_o      ),
        .EX_GPR_WE       (ex_gpr_we_o      ),
        .EX_GPR_WDATA    (ex_gpr_wdata_o   ),
        .EX_GPR_WADDR    (ex_gpr_waddr_o   ),
        .EX_SRAM_DATA_BE (SRAM_DATA_BE     ),
        /* O */
        .DF_ALU_OP       (df_alu_op_i      ),
        .DF_GPR_WE       (df_gpr_we_i      ),
        .DF_GPR_WDATA    (df_gpr_wdata_i   ),
        .DF_GPR_WADDR    (df_gpr_waddr_i   ),
        .DF_SRAM_DATA_BE (df_sram_data_be_i)
    );
    
    df u_df(
        /* I */
        .RST            (RST              ),
        .ALU_OP_I       (df_alu_op_i      ),
        .GPR_WE_I       (df_gpr_we_i      ),
        .GPR_WADDR_I    (df_gpr_waddr_i   ),
        .GPR_WDATA_I    (df_gpr_wdata_i   ),
        .SRAM_DATA_BE_I (df_sram_data_be_i),
        /* O */
        .ALU_OP_O       (df_alu_op_o      ),
        .GPR_WE_O       (df_gpr_we_o      ),
        .GPR_WADDR_O    (df_gpr_waddr_o    ),
        .GPR_WDATA_O    (df_gpr_wdata_o  ),
        .SRAM_DATA_BE_O (df_sram_data_be_o)
    );

    df_mem u_df_mem(
        /* I */
        .CLK              (CLK               ),
        .RST              (RST               ),
        .STALL            (stall[5:4]        ),
        .DF_ALU_OP        (df_alu_op_o       ),
        .DF_GPR_WE        (df_gpr_we_o       ),
        .DF_GPR_WADDR     (df_gpr_waddr_o    ),
        .DF_GPR_WDATA     (df_gpr_wdata_o    ),
        .DF_SRAM_DATA_BE  (df_sram_data_be_o ),
        .SRAM_RDATA       (DATA              ),
        /* O */
        .MEM_ALU_OP       (mem_alu_op_i      ),
        .MEM_GPR_WE       (mem_gpr_we_i      ),
        .MEM_GPR_WADDR    (mem_gpr_waddr_i   ),
        .MEM_GPR_WDATA    (mem_gpr_wdata_i   ),
        .MEM_SRAM_DATA_BE (mem_sram_data_be_i),
        .MEM_SRAM_DATA    (mem_sram_data_i   )
    );
    
    mem u_mem(
        /* I */
        .RST         (RST               ),
        .ALU_OP      (mem_alu_op_i      ),
        .GPR_WE_I    (mem_gpr_we_i      ),
        .GPR_WDATA_I (mem_gpr_wdata_i   ),
        .GPR_WADDR_I (mem_gpr_waddr_i   ),
        .SRAM_BE     (mem_sram_data_be_i),
        .SRAM_RDATA  (mem_sram_data_i   ),
        /* O */
        .GPR_WE_O    (mem_gpr_we_o      ),
        .GPR_WDATA_O (mem_gpr_wdata_o   ),
        .GPR_WADDR_O (mem_gpr_waddr_o   )
    );
    
    mem_wb u_mem_wb(
        /* I */
        .RST           (RST            ),
        .CLK           (CLK            ),
        .STALL         (stall[6:5]     ),
        .MEM_GPR_WE    (mem_gpr_we_o   ),
        .MEM_GPR_WDATA (mem_gpr_wdata_o),
        .MEM_GPR_WADDR (mem_gpr_waddr_o),
        /* O */
        .WB_GPR_WE     (wb_gpr_we      ),
        .WB_GPR_WDATA  (wb_gpr_wdata   ),
        .WB_GPR_WADDR  (wb_gpr_waddr   )
    );
    
    gprs u_gprs(
        .CLK    (CLK           ),
        .RST    (RST           ),
        .WE     (wb_gpr_we     ),
        .WADDR  (wb_gpr_waddr  ),
        .WDATA  (wb_gpr_wdata  ),
        .RE1    (id_reg1_re_o  ),
        .RADDR1 (id_reg1_addr_o),
        .RDATA1 (id_reg1_data_i),
        .RE2    (id_reg2_re_o  ),
        .RADDR2 (id_reg2_addr_o),
        .RDATA2 (id_reg2_data_i)
    );
/**************** CONNECTION END ****************/
endmodule
