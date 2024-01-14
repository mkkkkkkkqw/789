`ifndef myIFetch
`define myIFetch
`include "Mydefine.v"
        module IFetch(
                input wire clk,
                input wire rst,
                input wire rdy,

                //to Ins DEcoder
                output reg [31:0] inst,
                //    output reg [`INST_WID] inst,
                output reg        inst_rdy,
                output reg [31:0] inst_pc,
                output reg       inst_pred_jump,
                //to MemCtrl
                output reg  mc_en,
                output reg [31:0] mc_pc,
                input wire [31:0] mc_data,
                input wire mc_done,


                // output reg              mc_en,
                // output reg  [`ADDR_WID] mc_pc,
                // input  wire             mc_done,
                // input  wire [`DATA_WID] mc_data,


                //from ROB
                input wire rob_set_pc_en,
                input wire [31:0] rob_set_pc
                //     input wire [`ADDR_WID] rob_pc

                //判断是不是满了
                input wire rs_nxt_full,
                input wire lsb_nxt_full,
                input wire rob_nxt_full



                //set pc
                input wire rob_set_pc_en,
                input wire [31:0] rob_set_pc,
                input wire rob_br,
                input wire rob_br_jump,
                input wire [31:0] rob_br_pc
            );

            reg[31:0]pc;//(address wide)
            reg status;

            //instruction cache

            reg valid[`ICache_Block_NUM-1:0];//有效位
            reg [`TAG_WID] tag[`ICache_Block_NUM-1:0];//标记
            reg [`ICache_Block_WID]data[`ICache_Block_NUM-1:0];//每个块的数据
            //  reg [`DATA_WID] data[`ICACHE_SIZE-1:0];


            //分支预测
            reg [31:0]pred_pc;
            reg pred_jump;



            wire [`ICache_BlockOffset_WID] pc_blockOffset = pc[`ICache_BlockOffset_RANGE];
            wire [`ICache_Index_WID] pc_index = pc[`ICache_Index_RANGE];
            wire [`ICache_Tag_WID] pc_tag = pc[`ICache_Tag_RANGE];
            wire miss=!valid[pc_index]|| (tag[pc_index] != pc_tag);
            wire hit = ~miss;
            wire [`ICache_Index_WID] mc_pc_index = mc_pc[`ICache_Index_RANGE];
            wire [`ICache_Tag_WID] mc_pc_tag = mc_pc[`ICache_Tag_RANGE];

            wire [`ICache_Block_WID] cur_block_all = data[pc_index];  // 16 instructions in a block
            wire [`INST_WID] cur_block[15:0]; // 16 instructions in a block
            wire [`INST_WID] get_inst = cur_block[pc_blockOffset]; // get the instruction from the block

            // wire pc_index=pc[`INDEX_RANGE];//索引
            // wire pc_tag=pc[`TAG_RANGE];//标记


            // wire hit = valid[pc_index]&&(pc_tag==tag[pc_index]);//命中
            // wire miss=!hit;//未命中

            // wire mc_pc_index=mc_pc[`INDEX_RANGE];//索引
            // wire mc_pc_tag=mc_pc[`TAG_RANGE];//标记(主内存中读取指令并将其存储在缓存中。)

            //将cur_block_all中的32位指令分成16个32位指令
            assign cur_block[0] = cur_block_all[31:0];
            assign cur_block[1] = cur_block_all[63:32];
            assign cur_block[2] = cur_block_all[95:64];
            assign cur_block[3] = cur_block_all[127:96];
            assign cur_block[4] = cur_block_all[159:128];
            assign cur_block[5] = cur_block_all[191:160];
            assign cur_block[6] = cur_block_all[223:192];
            assign cur_block[7] = cur_block_all[255:224];
            assign cur_block[8] = cur_block_all[287:256];
            assign cur_block[9] = cur_block_all[319:288];
            assign cur_block[10] = cur_block_all[351:320];
            assign cur_block[11] = cur_block_all[383:352];
            assign cur_block[12] = cur_block_all[415:384];
            assign cur_block[13] = cur_block_all[447:416];
            assign cur_block[14] = cur_block_all[479:448];
            assign cur_block[15] = cur_block_all[511:480];





            integer i;
            always@(posedge clk) begin
                if(rst) begin
                    pc<=32'h0;
                    mc_pc<=32'h0;
                    mc_en<=0;
                    //将16个块的有效位、标记、数据都置为0
                    for(i=0;i<`ICache_Block_NUM;i=i+1) begin
                        valid[i]<=0;
                        // tag[i]<=0;
                        // data[i]<=0;
                    end
                    // status<=IDLE;
                    inst_rdy<=0;
                    status<=IDLE;//状态转换
                end


                else if(!rdy) begin
                    //wait
                end

                else begin
                    if(rob_set_pc_en) begin
                        inst_rdy<=0;
                        // mc_en<=0;
                        // status<=IDLE;
                        pc<=rob_set_pc;
                    end

                    else begin
                        if(miss) begin
                            inst_rdy <= 0;
                        end
                        else if(rs_nxt_full||lsb_nxt_full||rob_nxt_full) begin
                            inst_rdy<=0;
                        end
                        else  begin
                            //hit
                            inst_rdy<=1;
                            inst<=get_inst;
                            inst_pc <= pc;
                            pc<=pred_pc;
                            // status<=IDLE;
                            inst_pred_jump<=pred_jump;
                        end
                    end


                    if(status==IDLE) begin
                        if(miss) begin
                            mc_en<=1;
                            mc_pc<={pc[`ICache_Tag_RANGE], pc[`ICache_Index_RANGE], 6'b0};
                            status<=WAIT_MEM;
                        end
                    end
                    else begin
                        //now status==WAIT_MEM;
                        if(mc_done) begin
                            valid[mc_pc_index]<=1;
                            tag[mc_pc_index]<=mc_pc_tag;//标记
                            data[mc_pc_index]<=mc_data;//数据
                            mc_en<=0;//关闭mem_ctrl
                            status<=IDLE;   //状态转换
                        end
                    end
                end
            end


            //start bht

            reg [1:0] bht[`BHT_SIZE-1:0];
            wire [`BHT_Index_WID] bht_idx = rob_br_pc[`BHT_Index_RANGE];

            always@(posedge clk) begin
                if(rst) begin
                    for (i = 0; i < `BHT_SIZE; i = i + 1) begin
                        bht[i] <= 0;
                    end

                end

                else if(rdy) begin
                    if(rob_br) begin
                        if(rob_br_jump) begin
                            if(bht[bht_idx]<2'd3) begin
                                bht[bht_idx]<=bht[bht_idx]+1;
                            end
                        end
                        else begin
                            if(bht[bht_idx]>2'd0) begin
                                bht[bht_idx]<=bht[bht_idx]-1;
                            end
                        end
                    end
                end
            end




            //end bht

            //start branch prediction
            wire [`BHT_Index_WID] pc_bht_idx = pc[`BHT_Index_RANGE];
            always@(*) begin
                pred_pc=pc+4;
                pred_jump=0;
                if(get_inst[6:0]==7'b1101111) begin
                    //jal
                    pred_pc=pc + {{12{get_inst[31]}}, get_inst[19:12], get_inst[20], get_inst[30:21], 1'b0};
                    pred_jump=1;
                end
                else if(get_inst[6:0]== 7'b1100011) begin
                    //branch
                    if (bht[pc_bht_idx] >= 2'd2) begin
                        pred_pc   = pc + {{20{get_inst[31]}}, get_inst[7], get_inst[30:25], get_inst[11:8], 1'b0};
                        pred_jump = 1;
                    end
                end
            end





        endmodule
`endif
