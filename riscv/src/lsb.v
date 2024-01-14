`ifndef LSB
`define LSB
`include "Mydefine.v"
        module LSB
            (
                input wire clk,
                input wire rst,
                input wire rdy,

                input wire rollback,

                output reg lsb_nxt_full,

                //指令处理


                input wire issue,
                input wire [`ROB_POS_WID] issue_rob_pos,
                input wire [`OP_WID] issue_opcode,
                input wire [`FUNCT3_WID]issue_funct3,
                input wire issue_funct7,
                input wire [31:0] issue_rs1_val,
                input wire [31:0] issue_rs2_val,
                input wire [`ROB_ID_WID] issue_rs1_rob_id,
                input wire [`ROB_ID_WID] issue_rs2_rob_id,
                input wire [31:0]issue_imm,
                input wire  [`REG_POS_WID]issue_rd,
                input wire [31:0]  issue_pc,

                // output wire [`ROB_POS_WID] rob_id,//ROB位置
                // output wire [`OP_WID] op,//操作码


                //
                //memctrl
                output reg mc_en,
                output reg mc_wr,//1=write,0=read
                output reg [31:0] mc_pc,
                // output reg [31:0] mc_addr,
                output reg[2:0]mc_len,
                output reg [31:0] mc_w_data,
                input wire mc_done,
                input wire[31:0] mc_r_data,





                //here are *** query in Register File****
                input wire alu_result,
                input wire [`ROB_POS_WID] alu_result_rob_pos,
                // input wire [`OP_WID] alu_result_opcode,
                // input wire [`FUNCT3_WID]alu_result_funct3,
                // input wire alu_result_funct7,
                input wire [31:0]   alu_result_val,



                //qr in LSB
                input wire lsb_result,
                input wire [`ROB_POS_WID] lsb_result_rob_pos,
                // input wire [`OP_WID] lsb_result_opcode,
                // input wire [`FUNCT3_WID]lsb_result_funct3,
                // input wire lsb_result_funct7,
                input wire [31:0]   lsb_result_val,

                //qr in ROB
                input wire commit_store,
                input wire [`ROB_POS_WID]commit_rob_pos


            );



            integer i;

            reg busy [`LSB_SIZE-1:0];
            reg [`OP_WID] opcode [`LSB_SIZE-1:0];
            reg [`FUNCT3_WID] funct3 [`LSB_SIZE-1:0];
            reg funct7 [`LSB_SIZE-1:0];
            reg [31:0] rs1_val [`LSB_SIZE-1:0];
            reg [31:0] rs2_val [`LSB_SIZE-1:0];
            reg [`ROB_ID_WID] rs1_rob_id [`LSB_SIZE-1:0];
            reg [`ROB_ID_WID] rs2_rob_id [`LSB_SIZE-1:0];
            reg [31:0] imm [`LSB_SIZE-1:0];
            // reg [`REG_POS_WID] rd [`LSB_SIZE-1:0];
            reg [31:0] pc [`LSB_SIZE-1:0];
            reg[`ROB_POS_WID] rob_pos [`LSB_SIZE-1:0];
            reg committed[`LSB_SIZE-1:0];



            reg [`LSB_POS_WID] head,tail;
            reg [`LSB_ID_WID]last_commit_pos;
            reg empty;


            wire exec_head = !empty && rs1_rob_id[head][4] == 0&& rs2_rob_id[head][4] == 0 && (opcode[head] == `OPCODE_L || committed[head]);
            wire pop=status==WAIT_MEM&&mc_done;
            wire [`LSB_POS_WID] nxt_head = head+pop;
            wire [`LSB_POS_WID] nxt_tail = tail+issue;
            reg nxt_empty ;



            always @(*) begin
                if(nxt_head==nxt_tail) begin
                    nxt_empty=empty||!issue;
                    lsb_nxt_full=!empty;
                end
                else begin
                    nxt_empty<=0;
                    ;
                    lsb_nxt_full<=0;
                end
            end


            localparam IDLE = 0;
            localparam WAIT_MEM = 3;

            reg [1:0]status;

            always@(posedge clk) begin
                if(rst||(rollback&&last_commit_pos==`LSB_NPOS)) begin
                    head<=0;
                    tail<=0;
                    last_commit_pos<=0;
                    empty<=1;
                    status<=IDLE;
                    mc_en<=0;
                    for(i=0;i<`LSB_SIZE;i=i+1) begin
                        busy[i]<=0;
                        opcode[i]<=0;
                        funct3[i]<=0;
                        funct7[i]<=0;
                        rs1_val[i]<=0;
                        rs2_val[i]<=0;
                        rs1_rob_id[i]<=0;
                        rs2_rob_id[i]<=0;
                        imm[i]<=0;
                        pc[i]<=0;
                        rob_pos[i]<=0;
                        committed[i]<=0;
                    end
                end
                else if(rollback) begin
                    tail<=last_commit_pos+1;
                    for(i=0;i<`LSB_SIZE;i++) begin
                        if(!committed[i]) begin
                            busy[i]<=0;
                        end
                    end
                end
                else if (!rdy) begin

                end
                else begin
                    mc_en<=0;
                    result<=0;
                    if(status==WAIT_MEM) begin
                        if(mc_done) begin
                            busy[head]<=0;
                            committed[head]<=0;
                            if(opcode[head]==`OPCODE_L) begin
                                result<=1;
                                result_val<=mc_r_data;
                                result_rob_pos<=rob_pos[head];
                            end
                            if(last_commit_pos[`LSB_POS_WID]==head) begin
                                last_commit_pos<=`LSB_NPOS;
                            end
                            status<=IDLE;
                        end
                    end
                    else begin


                        if(exec_head) begin
                            mc_en<=1;
                            mc_pc<=rs1_val[head]+imm[head];
                            if(opcode[head]==`OPCODE_S) begin
                                mc_w_data<=rs2_val[head];
                                case(funct3[head])
                                    `FUNCT3_SB: begin
                                        mc_len<=3'd1;
                                    end
                                    `FUNCT3_SH: begin
                                        mc_len<=3'd2;
                                    end
                                    `FUNCT3_SW: begin
                                        mc_len<=3'd4;
                                    end
                                endcase
                                mc_wr<=1;
                            end
                            else begin
                                case(funct3[head])
                                    `FUNCT3_LB: begin
                                        mc_len<=3'd1;
                                    end
                                    `FUNCT3_LH: begin
                                        mc_len<=3'd2;
                                    end
                                    `FUNCT3_LW: begin
                                        mc_len<=3'd4;
                                    end
                                    `FUNCT3_LBU: begin
                                        mc_len<=3'd1;
                                    end
                                    `FUNCT3_LHU: begin
                                        mc_len<=3'd2;
                                    end
                                endcase
                                mc_wr<=0;
                            end
                            status<=WAIT_MEM;
                        end
                    end




                    //广播

                    if(alu_result) begin
                        for(i=0;i<`LSB_SIZE;i=i+1) begin
                            if(rs1_rob_id[i]=={1'b1,alu_result_rob_pos}) begin
                                rs1_val[i]<=alu_result_val;
                                rs1_rob_id[i]<=0;
                            end
                            if(rs2_rob_id[i]=={1'b1,alu_result_rob_pos}) begin
                                rs2_val[i]<=alu_result_val;
                                rs2_rob_id[i]<=0;
                            end
                        end

                    end


                    if(lsb_result) begin
                        for(i=0;i<`LSB_SIZE;i=i+1) begin
                            if(rs1_rob_id[i]=={1'b1,lsb_result_rob_pos}) begin
                                rs1_val[i]<=lsb_result_val;
                                rs1_rob_id[i]<=0;
                            end
                            if(rs2_rob_id[i]=={1'b1,lsb_result_rob_pos}) begin
                                rs2_val[i]<=lsb_result_val;
                                rs2_rob_id[i]<=0;
                            end
                        end

                    end


                    // end



                    if(commit_store) begin
                        for(i=0;i<`LSB_SIZE;i=i+1) begin
                            if(busy[i]&&rob_pos[i]==commit_rob_pos&&!committed[i]) begin
                                committed[i]<=1;
                                last_commit_pos<={1'b0,i};
                            end
                        end
                    end


                    if(issue) begin
                        busy[tail]<=1;
                        opcode[tail]<=issue_opcode;
                        funct3[tail]<=issue_funct3;
                        funct7[tail]<=issue_funct7;
                        rs1_val[tail]<=issue_rs1_val;
                        rs2_val[tail]<=issue_rs2_val;
                        rs1_rob_id[tail]<=issue_rs1_rob_id;
                        rs2_rob_id[tail]<=issue_rs2_rob_id;
                        imm[tail]<=issue_imm;
                        pc[tail]<=issue_pc;
                        rob_pos[tail]<=issue_rob_pos;
                    end

                    empty<=nxt_empty;
                    head<=nxt_head;
                    tail<=nxt_tail;


                end
            end


        endmodule
`endif // MYLSB
