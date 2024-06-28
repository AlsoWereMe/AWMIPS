`timescale 1ns / 1ps
`include "defines.vh"

/* CPU顶层模块,在这里将每个模块连接 */
module CPU(
    input   logic                   CLK,
    input   logic                   RST,
    input   logic[`REG_DATA_BUS]    ROM_INST,
    input   logic[`REG_DATA_BUS]    RAM_LDATA,
    output  logic[`REG_DATA_BUS]    ROM_ADDR,
    output  logic                   ROM_CEN,
    output  logic[`REG_DATA_BUS]    RAM_LSADDR,
    output  logic[`REG_DATA_BUS]    RAM_SDATA,
    output  logic[3:0]              RAM_BYTE_SEL,
    output  logic                   RAM_CEN,
    output  logic                   RAM_WEN,
    // 测试端口
    output  logic[`REG_DATA_BUS]    HI_DATA,
    output  logic[`REG_DATA_BUS]    LO_DATA,
    output  logic                   ERROR_ID,
    output  logic                   ERROR_EX,
    output  logic[`REG_DATA_BUS]    REGS[`REG_NUM]
    );
    // 控制信号
    logic[5:0] stall;
    logic stall_req_id, stall_req_ex, stall_req_mem;
    logic div_ready, mul_ready;
    logic signed_div, div_start, div_cancel;
    logic signed_mul, mul_start, mul_cancel;
    logic id_cur_inst_ds_flag, id_cur_inst_ds_flag_o, next_inst_in_ds_flag, ex_cur_inst_ds_flag_i;
    logic id_wen, ex_wen, ex_wen_o, mem_wen, mem_wen_o, wb_wen;
    logic ex_hilo_wen, mem_hilo_wen, mem_hilo_wen_o, wb_hilo_wen;
    logic reg1_ren, reg2_ren;
    logic branch_flag;
    // 分支地址
    logic [`REG_DATA_BUS] branch_tar;
    // ID阶段数据
    logic [`REG_DATA_BUS]   id_pc, id_inst, id_inst_o;
    logic [`REG_ADDR_BUS]   reg1_addr, reg2_addr;
    logic [`ALU_OP_BUS]     id_alu_op;
    logic [`ALU_SEL_BUS]    id_alu_sel;
    logic [`REG_DATA_BUS]   id_reg1_data, id_reg2_data;
    logic [`REG_ADDR_BUS]   id_waddr;
    logic [`REG_DATA_BUS]   id_branch_link_addr;
    // EX阶段数据
    logic [`REG_ADDR_BUS]   ex_waddr, ex_waddr_o;
    logic [`REG_DATA_BUS]   ex_wdata, ex_inst_i;
    logic [`REG_DATA_BUS]   ex_branch_link_addr;
    logic [`ALU_OP_BUS]     ex_alu_op, ex_alu_op_o;
    logic [`ALU_SEL_BUS]    ex_alu_sel;
    logic [`REG_DATA_BUS]   ex_reg1_data, ex_reg2_data;
    logic [`REG_DATA_BUS]   ex_hi_wdata, ex_lo_wdata;
    logic [`REG_DATA_BUS]   ex_ram_lsaddr, ex_ram_sdata;
    // MEM阶段数据
    logic [`REG_ADDR_BUS]   mem_waddr, mem_waddr_o;
    logic [`REG_DATA_BUS]   mem_wdata, mem_wdata_o;
    logic [`REG_DATA_BUS]   mem_hi_wdata, mem_lo_wdata, mem_hi_wdata_o, mem_lo_wdata_o;
    logic [`REG_DATA_BUS]   mem_ram_lsaddr, mem_ram_sdata;
    logic [`ALU_OP_BUS]     mem_alu_op;
    // WB阶段数据
    logic [`REG_ADDR_BUS]   wb_waddr;
    logic [`REG_DATA_BUS]   wb_wdata;
    logic [`REG_DATA_BUS]   wb_hi_wdata, wb_lo_wdata;
    // 高/低寄存器读数据
    // logic [`REG_DATA_BUS]   hi_rdata, lo_rdata;
    // 乘/除法器数据
    logic [`REG_DATA_BUS]   divisor, dividend;
    logic [`REG_DATA_BUS]   multiplicand, multiplier;
    logic [`DOUBLE_REG_DATA_BUS]   div_result;
    logic [`DOUBLE_REG_DATA_BUS]   mul_result;
    // 寄存器堆读数据
    logic [`REG_DATA_BUS]   reg1_data, reg2_data;

    ctrl u_ctrl(
        .RST           (RST           ),
        .STALL_REQ_ID  (stall_req_id  ),
        .STALL_REQ_EX  (stall_req_ex  ),
        .STALL_REQ_MEM (stall_req_mem ),
        .STALL         (stall         )
    );
    
    pc_reg u_pc_reg(
        .CLK         (CLK         ),
        .RST         (RST         ),
        .STALL       (stall[0]    ),
        .BRANCH_FLAG (branch_flag ),
        .BRANCH_TAR  (branch_tar  ),
        .PC          (ROM_ADDR    ),
        .CE          (ROM_CEN     )
    );
    
    if_id u_if_id(
        .CLK     (CLK       ),
        .RST     (RST       ),
        .STALL   (stall[2:1]),
        .IF_PC   (ROM_ADDR  ),
        .IF_INST (ROM_INST  ),
        .ID_PC   (id_pc     ),
        .ID_INST (id_inst   )
    );

    id u_id(
        .RST                 (RST                   ),
        .PC_I                (id_pc                 ),
        .INST_I              (id_inst               ),
        .CUR_INST_DS_FLAG_I  (id_cur_inst_ds_flag   ),
        .REG1_DATA_I         (reg1_data             ),
        .REG2_DATA_I         (reg2_data             ),
        .EX_WEN_I            (ex_wen_o              ),
        .EX_ALU_OP_I         (ex_alu_op_o           ),
        .EX_WADDR_I          (ex_waddr_o            ),
        .EX_WDATA_I          (ex_wdata              ),
        .MEM_WEN_I           (mem_wen_o             ),
        .MEM_WADDR_I         (mem_waddr_o           ),
        .MEM_WDATA_I         (mem_wdata_o           ),
        .REG1_REN_O          (reg1_ren              ),
        .REG2_REN_O          (reg2_ren              ),
        .REG1_ADDR_O         (reg1_addr             ),
        .REG2_ADDR_O         (reg2_addr             ),
        .ALU_OP_O            (id_alu_op             ),
        .ALU_SEL_O           (id_alu_sel            ),
        .REG1_DATA_O         (id_reg1_data          ),
        .REG2_DATA_O         (id_reg2_data          ),
        .INST_O              (id_inst_o             ),
        .WADDR_O             (id_waddr              ),
        .WEN_O               (id_wen                ),
        .STALL_REQ           (stall_req_id          ),
        .INST_ERR            (ERROR_ID              ),
        .BRANCH_FLAG         (branch_flag           ),
        .CUR_INST_DS_FLAG_O  (id_cur_inst_ds_flag_o ),
        .NEXT_INST_DS_FLAG_O (next_inst_in_ds_flag  ),
        .BRANCH_TAR_ADDR     (branch_tar            ),
        .BRANCH_LINK_ADDR    (id_branch_link_addr   )
    );  
    
    id_ex u_id_ex(
        .CLK                 (CLK                   ),
        .RST                 (RST                   ),
        .STALL               (stall[3:2]            ),
        .ID2_INST_DS_FLAG_I  (next_inst_in_ds_flag  ),
        .ID_CUR_INST_DS_FLAG (id_cur_inst_ds_flag_o ),
        .ID_BRANCH_LINK_ADDR (id_branch_link_addr   ),
        .ID_ALU_OP           (id_alu_op             ),
        .ID_ALU_SEL          (id_alu_sel            ),
        .ID_REG1_DATA        (id_reg1_data          ),
        .ID_REG2_DATA        (id_reg2_data          ),
        .ID_INST             (id_inst_o             ),
        .ID_WADDR            (id_waddr              ),
        .ID_WEN              (id_wen                ),
        .ID2_INST_DS_FLAG_O  (id_cur_inst_ds_flag   ),
        .EX_CUR_INST_DS_FLAG (ex_cur_inst_ds_flag_i ),
        .EX_BRANCH_LINK_ADDR (ex_branch_link_addr   ),
        .EX_ALU_OP           (ex_alu_op             ),
        .EX_ALU_SEL          (ex_alu_sel            ),
        .EX_REG1_DATA        (ex_reg1_data          ),
        .EX_REG2_DATA        (ex_reg2_data          ),
        .EX_INST             (ex_inst_i             ),
        .EX_WADDR            (ex_waddr              ),
        .EX_WEN              (ex_wen                )
    );
    
    ex u_ex(
        .RST              (RST                  ),
        .ALU_OP_I         (ex_alu_op            ),
        .ALU_SEL_I        (ex_alu_sel           ),
        .REG1_DATA_I      (ex_reg1_data         ),
        .REG2_DATA_I      (ex_reg2_data         ),
        .INST_I           (ex_inst_i            ),
        .WADDR_I          (ex_waddr             ),
        .WEN_I            (ex_wen               ),
        .CUR_INST_DS_FLAG (ex_cur_inst_ds_flag_i),
        .BRANCH_LINK_ADDR (ex_branch_link_addr  ),
        .DIV_READY        (div_ready            ),
        .DIV_RESULT       (div_result           ),
        .MUL_READY        (mul_ready            ),
        .MUL_RESULT       (mul_result           ),
        .HI_DATA_I        (HI_DATA             ),
        .LO_DATA_I        (LO_DATA             ),
        .WB_HI_DATA_I     (wb_hi_wdata          ),
        .WB_LO_DATA_I     (wb_lo_wdata          ),
        .WB_WEN_HILO_I    (wb_hilo_wen          ),
        .MEM_HI_DATA_I    (mem_hi_wdata_o       ),
        .MEM_LO_DATA_I    (mem_lo_wdata_o       ),
        .MEM_WEN_HILO_I   (mem_hilo_wen_o       ),
        .STALL_REQ        (stall_req_ex         ),
        .SIGNED_DIV       (signed_div           ),
        .DIV_START        (div_start            ),
        .DIV_CANCEL       (div_cancel           ),
        .DIVISOR          (divisor              ),
        .DIVIDEND         (dividend             ),
        .SIGNED_MUL       (signed_mul           ),
        .MUL_START        (mul_start            ),
        .MUL_CANCEL       (mul_cancel           ),
        .MULTIPLICAND     (multiplicand         ),
        .MULTIPLIER       (multiplier           ),
        .HI_DATA_O        (ex_hi_wdata          ),
        .LO_DATA_O        (ex_lo_wdata          ),
        .WEN_HILO_O       (ex_hilo_wen          ),
        .ALU_OP_O         (ex_alu_op_o          ),
        .MEM_LSADDR_O     (ex_ram_lsaddr        ),
        .MEM_SDATA_O      (ex_ram_sdata         ),
        .WDATA_O          (ex_wdata             ),
        .WADDR_O          (ex_waddr_o           ),
        .WEN_O            (ex_wen_o             ),
        .ERROR            (ERROR_EX             )
    );

    mul u_mul(
        .RST          (RST          ),
        .CLK          (CLK          ),
        .SIGNED_MUL   (signed_mul   ),
        .MULTIPLIER   (multiplier   ),
        .MULTIPLICAND (multiplicand ),
        .START        (mul_start    ),
        .CANCEL       (mul_cancel   ),
        .RESULT       (mul_result   ),
        .READY        (mul_ready    )
    );

    div u_div(
        .RST        (RST        ),
        .CLK        (CLK        ),
        .SIGNED_DIV (signed_div ),
        .DIVISOR    (divisor    ),
        .DIVIDEND   (dividend   ),
        .START      (div_start  ),
        .CANCEL     (div_cancel ),
        .RESULT     (div_result ),
        .READY      (div_ready  )
    );

    ex_mem u_ex_mem(
        .CLK          (CLK              ),
        .RST          (RST              ),
        .STALL        (stall[4:3]       ),
        .EX_ALU_OP    (ex_alu_op_o      ),
        .EX_SDATA     (ex_ram_sdata     ),
        .EX_LSADDR    (ex_ram_lsaddr    ),
        .EX_WDATA     (ex_wdata         ),
        .EX_WADDR     (ex_waddr_o       ),
        .EX_WEN       (ex_wen_o         ),
        .EX_HI        (ex_hi_wdata      ),
        .EX_LO        (ex_lo_wdata      ),
        .EX_WEN_HILO  (ex_hilo_wen      ),
        .MEM_ALU_OP   (mem_alu_op       ),
        .MEM_SDATA    (mem_ram_sdata    ),
        .MEM_LSADDR   (mem_ram_lsaddr   ),
        .MEM_WDATA    (mem_wdata        ),
        .MEM_WADDR    (mem_waddr        ),
        .MEM_WEN      (mem_wen          ),
        .MEM_HI       (mem_hi_wdata     ),
        .MEM_LO       (mem_lo_wdata     ),
        .MEM_WEN_HILO (mem_hilo_wen     )
    );

    mem u_mem(
        .RST        (RST            ),
        .LDATA_I    (RAM_LDATA      ),
        .ALU_OP_I   (mem_alu_op     ),
        .LSADDR_I   (mem_ram_lsaddr ),
        .SDATA_I    (mem_ram_sdata  ),
        .WADDR_I    (mem_waddr      ),
        .WDATA_I    (mem_wdata      ),
        .WEN_I      (mem_wen        ),
        .HI_DATA_I  (mem_hi_wdata   ),
        .LO_DATA_I  (mem_lo_wdata   ),
        .WEN_HILO_I (mem_hilo_wen   ),
        .WADDR_O    (mem_waddr_o    ),
        .WDATA_O    (mem_wdata_o    ),
        .WEN_O      (mem_wen_o      ),
        .HI_DATA_O  (mem_hi_wdata_o ),
        .LO_DATA_O  (mem_lo_wdata_o ),
        .WEN_HILO_O (mem_hilo_wen_o ),
        .STALL_REQ  (stall_req_mem  ),
        .SDATA_O    (RAM_SDATA      ),
        .LSADDR_O   (RAM_LSADDR     ),
        .MEM_WEN_O  (RAM_WEN        ),
        .MEM_CEN_O  (RAM_CEN        ),
        .BYTE_SEL_O (RAM_BYTE_SEL   )
    );

    mem_wb u_mem_wb(
        .RST          (RST              ),
        .CLK          (CLK              ),
        .STALL        (stall[5:4]       ),
        .MEM_WDATA    (mem_wdata_o      ),
        .MEM_WADDR    (mem_waddr_o      ),
        .MEM_WEN      (mem_wen_o        ),
        .MEM_HI       (mem_hi_wdata_o   ),
        .MEM_LO       (mem_lo_wdata_o   ),
        .MEM_WEN_HILO (mem_hilo_wen_o   ),
        .WB_WDATA     (wb_wdata         ),
        .WB_WADDR     (wb_waddr         ),
        .WB_WEN       (wb_wen           ),
        .WB_HI        (wb_hi_wdata      ),
        .WB_LO        (wb_lo_wdata      ),
        .WB_WEN_HILO  (wb_hilo_wen      )
    );
    
    regfile u_regfile(
        .CLK    (CLK        ),
        .RST    (RST        ),
        .WEN    (wb_wen     ),
        .WADDR  (wb_waddr   ),
        .WDATA  (wb_wdata   ),
        .REN1   (reg1_ren   ),
        .RADDR1 (reg1_addr  ),
        .RDATA1 (reg1_data  ),
        .REN2   (reg2_ren   ),
        .RADDR2 (reg2_addr  ),
        .RDATA2 (reg2_data  ),
        .REGS   (REGS)
    );
    
    hilo_reg u_hilo_reg(
        .CLK       (CLK         ),
        .RST       (RST         ),
        .WEN       (wb_hilo_wen ),
        .HI_DATA_I (wb_hi_wdata ),
        .LO_DATA_I (wb_lo_wdata ),
        .HI_DATA_O (HI_DATA    ),
        .LO_DATA_O (LO_DATA    )
    );
endmodule
