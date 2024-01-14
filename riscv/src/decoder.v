`ifndef DECODER
`define DECODER
`include "Mydefine.v"
        module Decoder(
                // input wire clk,
                input wire rst,
                input wire rdy,

                input wire rollback,

                //from IFetch
                input wire [31:0] inst,
                input wire inst_rdy,
                input wire [31:0] inst_pc,//指令地址
                input wire inst_pred_jump,//预测跳转
                //处理指令
                output reg issue,//

                output reg [`ROB_POS_WID] rob_pos,//ROB位置
                output reg [`OP_WID] opcode,//操作码
                output reg [`FUNCT3_WID]funct3,//功能码
                // output reg [`FUNCT7_WID]funct7,//功能码
                output reg funct7,
                output reg [31:0] rs1_val,
                output reg [31:0] rs2_val,
                output reg [`ROB_ID_WID] rs1_rob_id,
                output reg [`ROB_ID_WID] rs2_rob_id,
                output reg [31:0]imm,//立即数
                output reg  [`REG_POS_WID]rd,//目标寄存器位置
                output reg [31:0]  pc,//指令地址
                output reg pred_jump,//预测跳转
                output reg is_ready,


                // output wire [`ROB_POS_WID] rob_id,//ROB位置
                // output wire [`OP_WID] op,//操作码
                // output wire [`DATA_WID] rs1_val,//寄存器1的值
                // output wire [`DATA_WID] rs2_val,//寄存器2的值
                // output wire [`ROB_ID_WID] rs1_rob_id,//寄存器1的ROB ID
                // output wire [`ROB_ID_WID] rs2_rob_id,//寄存器2的ROB ID
                // output wire [`DATA_WID]imm,//立即数
                // output reg  [`REG_POS_WID]rd,//目标寄存器位置
                // output wire [31:0]  pc,//指令地址


                //here are *** query in Register File****
                output wire [`REG_POS_WID] reg_rs1,
                // input wire [31:0] reg_val1,
                // input wire [`ROB_ID_WID]  reg_rob_id1,
                input wire[31:0] reg_rs1_val,
                input wire [`ROB_ID_WID]reg_rs1_rob_id,
                output wire [`REG_POS_WID] reg_rs2,
                // input wire [31:0]   reg_val2,
                // input wire [`ROB_ID_WID]reg_rob_id2,
                input wire[31:0] reg_rs2_val,
                input wire [`ROB_ID_WID]reg_rs2_rob_id,


                //写入Reg File
                // output reg reg_en,

                //qr in ROB

                output wire[`ROB_POS_WID]rob_rs1_pos,
                input wire rob_rs1_ready,
                input wire [31:0]rob_rs1_val,
                output wire[`ROB_POS_WID]rob_rs2_pos,
                input wire rob_rs2_ready,
                input wire [31:0]rob_rs2_val,

                //RS
                // input wire rs_nxt_full,
                output reg rs_en,

                //LSB
                // input wire lsb_nxt_full,
                output reg lsb_en,


                //ROB
                // input wire rob_nxt_full,
                input wire [`ROB_POS_WID] nxt_rob_pos,
                // output reg  rob_en,

                // handle the broadcast
                // from Reservation Station
                input wire alu_result,
                input wire [`ROB_POS_WID] alu_result_rob_pos,
                input wire [31:0] alu_result_val,
                // from Load Store Buffer
                input wire lsb_result,
                input wire [`ROB_POS_WID] lsb_result_rob_pos,
                input wire [`DATA_WID] lsb_result_val

            );


            assign reg_rs1=inst[19:15];
            assign reg_rs2=inst[24:20];
            // assign reg_rd=inst[11:7];
            // assign reg_imm=inst[31:20];
            // assign reg_opcode=inst[6:0];
            // assign reg_funct3=inst[14:12];
            // assign reg_funct7=inst[31:25];
            // assign reg_pc=inst_pc;
            // assign reg_issue=inst_rdy;
            // assign reg_rob_pos=rob_pos;
            // assign reg_rs1_val=rs1_val;
            // assign reg_rs2_val=rs2_val;
            // assign reg_rs1_rob_id=rs1_rob_id;
            // assign reg_rs2_rob_id=rs2_rob_id;
            // assign reg_imm=imm;
            // assign reg_rd=rd;

            assign rob_rs1_pos=reg_rs1_rob_id[`ROB_POS_WID];
            assign rob_rs2_pos=reg_rs2_rob_id[`ROB_POS_WID];



            always@(*) begin
                if(rst||!inst_rdy||rollback) begin
                    opcode = inst[`OPCODE_RANGE];
                    funct3 = inst[`FUNCT3_RANGE];
                    funct7 = inst[30];
                    rd = inst[`RD_RANGE];
                    imm = 0;
                    pc = inst_pc;
                    pred_jump = inst_pred_jump;

                    rob_pos = nxt_rob_pos;

                    issue  = 0;
                    lsb_en = 0;
                    rs_en  = 0;
                    is_ready = 0;

                    rs1_val = 0;
                    rs1_rob_id = 0;
                    rs2_val = 0;
                    rs2_rob_id = 0;
                end
                else if(!rdy) begin
                    opcode = inst[`OPCODE_RANGE];
                    funct3 = inst[`FUNCT3_RANGE];
                    funct7 = inst[30];
                    rd = inst[`RD_RANGE];
                    imm = 0;
                    pc = inst_pc;
                    pred_jump = inst_pred_jump;

                    rob_pos = nxt_rob_pos;

                    issue  = 0;
                    lsb_en = 0;
                    rs_en  = 0;
                    is_ready = 0;

                    rs1_val = 0;
                    rs1_rob_id = 0;
                    rs2_val = 0;
                    rs2_rob_id = 0;
                end

                else begin
                    opcode = inst[`OPCODE_RANGE];
                    funct3 = inst[`FUNCT3_RANGE];
                    funct7 = inst[30];
                    rd = inst[`RD_RANGE];
                    imm = 0;
                    pc = inst_pc;
                    pred_jump = inst_pred_jump;
                    rob_pos = nxt_rob_pos;
                    lsb_en = 0;
                    rs_en  = 0;
                    is_ready = 0;
                    issue=1;



                    rs1_rob_id=0;
                    if(reg_rs1_rob_id[4]==0||rob_rs1_ready) begin
                        // flag: 0 = ready, 1 = renamed
                        rs1_val=reg_rs1_val;
                    end
                    else if(alu_result&&rob_rs1_pos==alu_result_rob_pos) begin
                        rs1_val=alu_result_val;
                    end
                    else if(lsb_result&&(lsb_result_rob_pos==rob_rs1_pos)) begin
                        rs1_val=lsb_result_val;
                    end
                    else begin
                        rs1_val=0;
                        rs1_rob_id=reg_rs1_rob_id;
                    end



                    rs2_rob_id=0;
                    if(reg_rs2_rob_id[4]==0||rob_rs2_ready) begin
                        // flag: 0 = ready, 1 = renamed
                        rs2_val=reg_rs2_val;
                    end
                    else if(alu_result&&rob_rs2_pos==alu_result_rob_pos) begin
                        rs2_val=alu_result_val;
                    end
                    else if(lsb_result&&(lsb_result_rob_pos==rob_rs2_pos)) begin
                        rs2_val=lsb_result_val;
                    end
                    else begin
                        rs2_val=0;
                        rs2_rob_id=reg_rs2_rob_id;
                    end





                    // lsb_en<=0;
                    // rs_en<=0;
                    // rob_en<=0;


                    case(opcode)
                        7'b0100011: begin
                            //store
                            lsb_en=1;
                            is_ready=1;
                            rd=0;

                            imm={{21{inst[31]}},inst[30:25],inst[11:7]};
                        end
                        7'b0000011: begin
                            //load
                            rs2_rob_id=0;
                            rs2_val=0;
                            lsb_en=1
                            // lsb_en<=1;
                            imm={{21{inst[31]}},inst[30:20]};
                        end
                        7'b0010011: begin
                            //ARITHI
                            //算术立即数
                            rs_en      = 1;
                            rs2_rob_id = 0;
                            rs2_val    = 0;
                            imm        = {{21{inst[31]}}, inst[30:20]};
                        end
                        7'b0110011: begin
                            //ARITH
                            //算术
                            rs_en=1;
                        end
                        7'b1101111: begin
                            //跳转
                            //jal
                            rs_en      = 1;
                            rs1_rob_id = 0;
                            rs1_val    = 0;
                            rs2_rob_id = 0;
                            rs2_val    = 0;
                            imm        = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
                        end
                        7'b1100011: begin
                            //branch
                            //分支
                            rs_en = 1;
                            rd    = 0;
                            imm   = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
                        end
                        7'b1100111: begin
                            //jalr
                            //跳转
                            rs_en      = 1;
                            rs2_rob_id = 0;
                            rs2_val    = 0;
                            imm        = {{21{inst[31]}}, inst[30:20]};
                        end
                        7'b0110111: begin
                            //lui
                            //立即数
                            rs_en      = 1;
                            rs1_rob_id = 0;
                            rs1_val    = 0;
                            rs2_rob_id = 0;
                            rs2_val    = 0;
                            imm        = {inst[31:12], 12'b0};
                        end
                        7'b0010111: begin
                            //auipc
                            //立即数
                            rs_en      = 1;
                            rs1_rob_id = 0;
                            rs1_val    = 0;
                            rs2_rob_id = 0;
                            rs2_val    = 0;
                            imm        = {inst[31:12], 12'b0};
                        end
                    endcase


                end
            end






        endmodule
`endif
