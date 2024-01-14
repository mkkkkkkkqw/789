`ifndef alu
`define alu
`include "Mydefine.v"
module ALU(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire rollback,
    
    
    //from RS

    input wire alu_en,
    input wire [`OP_WID]opcode,
    input wire [`FUNCT3_WID]funct3,
    input wire funct7,
    input wire [31:0]val1,
    input wire [31:0]val2,
    input wire [31:0]imm,//立即数
    input wire [31:0]pc,//指令地址
    input wire [`ROB_POS_WID]rob_pos,//在ROB所属位置

    //发送结果

    output reg result,
    output reg [`ROB_POS_WID] result_rob_pos,
    output reg [31:0] result_val,
    output reg result_jump,
    output reg[31:0]result_pc,

);



wire [31:0]arith_op1=val1;
wire [31:0]arith_op2=(opcode==7'b0110011)?val2:imm;//判断是否是计算
reg [31:0] arith_res;
always @(*)begin
    case(funct3)
        3'b000:begin//add
            if(funct7==0)begin
                arith_res=arith_op1+arith_op2;
            end
            else begin
                arith_res=arith_op1-arith_op2;
            end
            // arith_res=arith_op1+arith_op2;
        end
        3'b001:begin//sll
            arith_res=arith_op1<<arith_op2;
        end
        3'b010:begin//slt
            arith_res=(arith_op1<arith_op2)?1:0;
        end
        3'b011:begin//sltu
            arith_res=(arith_op1<arith_op2)?1:0;
        end
        3'b100:begin//xor
            arith_res=arith_op1^arith_op2;
        end
        3'b101:begin//srl or sra
            if(funct7==0)begin  //逻辑右移
                arith_res=arith_op1>>arith_op2[5:0];
            end
            else begin
                arith_res=arith_op1>>>arith_op2[5:0];//算术右移
            end
            // arith_res=arith_op1>>arith_op2[4:0];
        end
        3'b110:begin//or
            arith_res=arith_op1|arith_op2;
        end
        3'b111:begin//and
            arith_res=arith_op1&arith_op2;
        end
        default:begin
            arith_res=0;
        end
    endcase
end


reg jump;


always @(posedge clk)begin
    if(rst||rollback)begin
        result<=0;
        result_rob_pos<=0;
        result_val<=0;
    end
    else if(rdy==0)begin

    end
    else if (alu_en)begin
        result<=1;
        result_rob_pos<=rob_pos;
        case(opcode)
            7'b0110011:begin//计算
                result_val<=arith_res;
            end
            7'b0010011:begin//立即数
                result_val<=arith_res;
            end
            7'b1101111:begin//jal
                result_val<=pc+4;
                // result_jump=1;
                result_pc<=pc+imm;
            end
            7'b1100111:begin//jalr
                result_val<=pc+4;
                // result_jump=1;
                result_pc<=val1+imm;
            end
            7'b1100011:begin//branch
                if(jump)
                result_val=pc+4;
                result_jump<=1;
                result_pc=pc+imm;
            end
            7'b0110111:begin//lui
                result_val<=imm;
            end
            7'b0010111:begin//auipc
                result_val<=pc+imm;
            end
            // 7'b0000011:begin//load
            //     result_val<=arith_res;
            // end
            default:begin
                result_val=0;
            end
        endcase
    end
end

endmodule
`endif //ALU