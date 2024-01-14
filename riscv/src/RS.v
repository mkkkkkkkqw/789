`ifndef RESERVATION_STATION
`define RESERVATION_STATION
`include "Mydefine.v"
        module RS
            (
                input wire clk,
                input wire rst,
                // input wire [31:0] rs1_data,
                input wire rdy

                input wire rollback,

                output reg rs_nxt_full,


                // from ISSUE
                input wire issue,
                input wire [31:0] issue_rs1_val,
                input wire [31:0] issue_rs2_val,//
                input wire [31:0] issue_imm,
                input wire [`ROB_POS_WID] issue_rob_pos,
                input wire [`OP_WID] issue_opcode,
                input wire [`FUNCT3_WID] issue_funct3,
                input wire  issue_funct7,
                input wire [31:0] issue_pc,
                input wire[`ROB_ID_WID] issue_rs1_rob_id,
                input wire[`ROB_ID_WID] issue_rs2_rob_id,



                //alu

                output reg alu_en,
                output reg [31:0] alu_val1,
                output reg [31:0] alu_val2,
                output reg [31:0] alu_imm,
                output reg [31:0] alu_pc,
                output reg[`OP_WID] alu_opcode,
                output reg[`FUNCT3_WID] alu_funct3,
                output reg alu_funct7,
                output reg[`ROB_POS_WID] alu_rob_pos,

                //RS

                input wire alu_result,
                input wire [31:0] alu_result_val,
                input wire [`ROB_POS_WID] alu_result_rob_pos,

                //LSb

                input wire lsb_result,
                input wire [31:0] lsb_result_val,
                input wire [`ROB_POS_WID] lsb_result_rob_pos,


            );




            integer i;

            reg busy[`RS_SIZE-1:0];
            reg [`OP_CODE] opcode[`RS_SIZE-1:0];
            reg [`FUNCT3_WID] funct3[`RS_SIZE-1:0];
            reg funct7[`RS_SIZE-1:0];
            reg [`ROB_POS_WID] rob_pos[`RS_SIZE-1:0];
            reg [`ROB_ID_WID] rs1_rob_id[`RS_SIZE-1:0];
            reg [`ROB_ID_WID] rs2_rob_id[`RS_SIZE-1:0];
            // reg [`ROB_ID_WID] rd_rob_id[`RS_SIZE-1:0];
            reg [31:0] rs1_val[`RS_SIZE-1:0];
            reg [31:0] rs2_val[`RS_SIZE-1:0];
            reg [31:0] imm[`RS_SIZE-1:0];
            reg [31:0] pc[`RS_SIZE-1:0];

            reg ready[`RS_SIZE-1:0];
            reg[`RS_ID_WID]ready_pos,free_pos;

`define RS_SIZE 16
  `define RS_POS_WID 3:0
  `define RS_ID_WID 4:0
  `define RS_NPOS 5'd16

            always @(*) begin
                free_pos=`RS_NPOS;
                for(i=0;i<`RS_SIZE;i=i+1) begin
                    if(busy[i]==0) begin
                        free_pos=i;
                        // break;
                    end
                end
                for (i = 0; i < `RS_SIZE; i++) begin
                    if (busy[i]==1 && rs1_rob_id[i][4] == 0 && rs2_rob_id[i][4] == 0)
                        ready[i] = 1;
                    else
                        ready[i] = 0;
                end
                ready_pos = `RS_NPOS;
                for (i = 0; i < `RS_SIZE; i++) begin
                    if (ready[i])
                        ready_pos = i;
                end

            end


            reg rs_nxt_full_helper[`RS_SIZE-1:0];
            always @(*) begin
                rs_nxt_full_helper[0] = busy[0];
                for (i = 1; i < `RS_SIZE; i++) begin
                    rs_nxt_full_helper[i] = (busy[i]||issue&&i==free_pos)&rs_nxt_full_helper[i-1];
                end
                rs_nxt_full = rs_nxt_full_helper[`RS_SIZE-1];
            end

            always@(posedge clk) begin
                if(rst||rollback) begin
                    for(i=0;i<`RS_SIZE;i=i+1) begin
                        busy[i]<=0;

                    end
                end
                else if(!rdy) begin

                end
                else begin
                    alu_en<=0;
                    if(ready_pos!=`RS_NPOS) begin
                        alu_en<=1;
                        alu_val1<=rs1_val[ready_pos];
                        alu_val2<=rs2_val[ready_pos];
                        alu_imm<=imm[ready_pos];
                        alu_pc<=pc[ready_pos];
                        alu_opcode<=opcode[ready_pos];
                        alu_funct3<=funct3[ready_pos];
                        alu_funct7<=funct7[ready_pos];
                        alu_rob_pos<=rob_pos[ready_pos];
                        busy[ready_pos]<=0;
                    end

                    if(alu_result) begin
                        for(i=0;i<`RS_SIZE;i=i+1) begin
                            // if(busy[i]==1)begin
                            if(rs1_rob_id[i]=={1'b1, alu_result_rob_pos}) begin
                                rs1_val[i]<=alu_result_val;
                                rs1_rob_id[i]<=0;
                            end
                            if(rs2_rob_id[i]=={1'b1, alu_result_rob_pos}) begin
                                rs2_val[i]<=alu_result_val;
                                rs2_rob_id[i]<=0;
                            end
                            // end
                        end
                    end


                    if(lsb_result) begin
                        for(i=0;i<`RS_SIZE;i=i+1) begin
                            // if(busy[i]==1)begin
                            if(rs1_rob_id[i]=={1'b1, lsb_result_rob_pos}) begin
                                rs1_val[i]<=lsb_result_val;
                                rs1_rob_id[i]<=0;
                            end
                            if(rs2_rob_id[i]=={1'b1, lsb_result_rob_pos}) begin
                                rs2_val[i]<=lsb_result_val;
                                rs2_rob_id[i]<=0;
                            end
                            // end
                        end
                    end

                    if(issue) begin
                        busy[free_pos]<=1;
                        opcode[free_pos]<=issue_opcode;
                        funct3[free_pos]<=issue_funct3;
                        funct7[free_pos]<=issue_funct7;
                        rob_pos[free_pos]<=issue_rob_pos;
                        rs1_rob_id[free_pos]<=issue_rs1_rob_id;
                        rs2_rob_id[free_pos]<=issue_rs2_rob_id;
                        imm[free_pos]<=issue_imm;
                        rs1_val[free_pos]<=issue_rs1_val;
                        rs2_val[free_pos]<=issue_rs2_val;
                        pc[free_pos]<=issue_pc;
                        // case(issue_opcode)
                        //     `OP_R_TYPE: begin
                        //         rs1_val[free_pos]<=issue_rs1_val;
                        //         rs2_val[free_pos]<=issue_rs2_val;
                        //     end
                        //     `OP_I_TYPE: begin
                        //         rs1_val[free_pos]<=issue_rs1_val;
                        //         rs2_val[free_pos]<=issue_imm;
                        //     end
                        //     `OP_S_TYPE: begin
                        //         rs1_val[free_pos]<=issue_rs1_val;
                        //         rs2_val[free_pos]<=issue_rs2_val;
                        //     end
                        //     `OP_SB_TYPE: begin
                        //         rs1_val[free_pos]<=issue_rs1_val;
                        //         rs2_val[free_pos]<=issue_rs2_val;
                        //     end
                        //     `OP_U_TYPE: begin
                        //         rs1_val[free_pos]<=issue_imm;
                        //         rs2_val[free_pos]<=issue_imm;
                        //     end
                        //     `OP_UJ_TYPE: begin
                        //         rs1_val[free_pos]<=issue_imm;
                        //         rs2_val[free_pos]<=issue_imm;
                        //     end
                        //     `OP_L_TYPE: begin
                        //         rs1_val[free_pos]<=issue_imm;
                        //         rs2_val[free_pos]<=issue_imm;
                        //     end
                        //     `OP_AUIPC_TYPE: begin
                        //         rs1_val[free_pos]<=issue_imm;
                        //         rs2_val[free_pos]<=issue_imm;
                        //     end
                        //     `OP_LUI_TYPE: begin
                        //         rs1_val[free_pos]<=issue_imm;
                        //         rs2_val[free_pos]<=issue_imm;
                        //     end
                        //     `OP_JALR_TYPE: begin
                        //         rs1_val[free_pos]<=issue_imm;
                        //         rs2_val[free_pos]<=issue_imm;
                        //     end
                        //     `OP_ECALL_TYPE: begin
                        //         rs1_val[free_pos]<=issue_imm;
                        //         rs2_val[free_pos]<=issue_imm;
                        //     end
                        //     `OP_EBREAK_TYPE: begin
                        //         rs1_val[free_pos]<=issue_imm;
                        //     end
                        // endcase
                    end


                end
            end


        endmodule
`endif // RESERVATION_STATION
