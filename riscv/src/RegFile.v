`ifndef REGFILE
`define REGFILE
`include "Mydefine.v"

module RegFile(
    input wire clk,
    input wire rst,
    input wire rdy,

    //qr from **DECODER**** 

    input wire [`REG_POS_WID] rs1,//寄存器1位置
    output reg [31:0] val1,//寄存器1的值
    output reg [`ROB_ID_WID] rob_id1,//寄存器1的ROB ID
    input wire [`REG_POS_WID] rs2,//寄存器2位置
    output reg [31:0] val2,//寄存器2的值
    output reg [`ROB_ID_WID] rob_id2,//寄存器2的ROB ID


    // qr from **ROB****

    // input wire [`ROB_POS_WID] rob_id1,
    // 这个信号携带目标寄存器（destination register）的地址。
    // 当一个新的指令被发出时，这个地址用于指定将结果写入哪个寄存器。
    input wire   issue,
    input wire[`REH_POS_WID] issue_rd,
    input wire [`ROB_POS_WID] issue_rob_pos,

    //ROB commit

    input wire commit,
    input wire[`REG_POS_WID]commit_rd,//目标寄存器位置
    input wire[31:0]commit_val//目标寄存器值

);

    reg [31:0] val [`REG_SIZE-1:0];//寄存器值
    reg[`ROB_ID_WID]rob_id[`REG_SIZE-1:0];//ROB ID
    //{flag, rob_id}; flag: 0=ready, 1=renamed
//这个数组存储与每个寄存器相关联的重排序缓冲区（ROB）ID。
//每个寄存器的ROB ID用于跟踪该寄存器的值是否已经准备好（ready）
//或者是否被重命名（renamed）。


    always@(*)begin
        if(commit&&rs1==commit_rd)begin
            rob_id1=5'b0;
            val1=commit_val;

        end
        else begin
            rob_id1=rob_id[rs1];
            val1=val[rs1];
        end

        if(commit&&rs2==commit_rd)begin
            rob_id2=5'b0;
            val2=commit_val;
        end
        else begin
            rob_id2=rob_id[rs2];
            val2=val[rs2];
        end
        
    end


    interger i;
    always @(posedge clk) begin
        if(rst)begin
            for(i=0;i<32;i=i+1)begin
                val[i]<=32'b0;
                rob_id[i]<=5'b0;
            end
        end
        else if (rdy) begin
            if(commit)begin
                val[commit_rd]<=commit_val;
                rob_id[commit_rd]<=5'b0;
            end
            if(issue)begin
                rob_id[issue_rd]<={1'b1,issue_rob_pos};
            end
        end
    end







endmodule // RegFile




`endif 

 // MYREGFILE