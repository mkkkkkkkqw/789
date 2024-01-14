`ifndef Mydefine
`define Mydefine


        //the following are constants

        // ICache
        // Instruction Cache

`define ICache_Block_NUM 16
`define ICache_Block_SIZE 64  // 16 instructions    (bites)
`define ICache_Block_WID 511:0  // ICACHE_BLK_SIZE*8 - 1 : 0    (bits)
`define ICache_BlockOffset_RANGE 5:2
`define ICache_BlockOffset_WID 3:0
`define ICache_Index_RANGE 9:6
`define ICache_Index_WID 3:0
`define ICache_Tag_RANGE 31:10
`define ICache_Tag_WID 21:0


        //BHT
`define BHT_SIZE 256
`define BHT_Index_RANGE 9:2
`define BHT_Index_WID 7:0


`define MEM_CTRL_LEN_WID 6:0
`define MEM_CTRL_IF_DATA_LEN 64
`define IF_DATA_WID 511:0
`define INST_SIZE 4



`define ICache_SIZE 256
`define INDEX_RANGE 9:2  //索引定义为地址的9:2位，这提供了256个可能的位置，适合于一个256槽的缓存
`define TAG_RANGE 31:10  //标记定义为地址的31:10位，这提供了22位的标记，适合于一个256槽的缓存
`define TAG_WID 21:0  //标记宽度
`define OPCODE_WID 6:0//操作码宽度
`define OPCODE_RANGE 6:0
`define OP_RANGE 6:0
`define FUNCT3_WID 2:0//功能码宽度

`define FUNCT7_WID 6:0//功能码宽度

`define REG_SIZE 32
        //寄存器数量
`define ROB_SIZE 16
        //ROB大小
`define RD_RANGE 11:7
`define FUNCT3_RANGE 14:12
`define RS1_RANGE 19:15
`define RS2_RANGE 24:20

`define INST_WID 31:0
        //指令宽度
`define DATA_WID 31:0
        //数据宽度
`define ADDR_WID 31:0
        //地址宽度

`define ROB_POS_WID 3:0
        //ROB位置宽度
`define REG_POS_WID 4:0
        //寄存器位置宽度

`define ROB_ID_WID 4:0
        //ROB ID宽度
        // rob_id = {flag, rob_pos}

`define OP_WID 6:0
        //操作码宽度


        //the following are OPCODES

`define OPCODE_L 7'b0000011
        //load
`define OPCODE_S 7'b0100011
        //store
`define OPCODE_ARITHI 7'b0010011
        //算术立即数
`define OPCODE_ARITH 7'b0110011
        //算术
`define OPCODE_BRANCH 7'b1100011
        //分支
`define OPCODE_JALR 7'b1100111
        //JALR
`define OPCODE_JAL 7'b1101111
        //JAL
`define OPCODE_LUI 7'b0110111
        //LUI 将立即数加载到上半字
`define OPCODE_AUIPC 7'b0010111
        //AUIPC 将立即数加到程序计数器
`define OPCODE_FENCE 7'b0001111
        //FENCE
`define OPCODE_SYSTEM 7'b1110011
        //系统调用


`define IDLE = 0
`define  WAIT_MEM=1;

        //end Mydefine

`define FUNCT3_ADD  3'h0
`define FUNCT3_SUB  3'h0
`define FUNCT3_XOR  3'h4
`define FUNCT3_OR   3'h6
`define FUNCT3_AND  3'h7
`define FUNCT3_SLL  3'h1
`define FUNCT3_SRL  3'h5
`define FUNCT3_SRA  3'h5
`define FUNCT3_SLT  3'h2
`define FUNCT3_SLTU 3'h3

`define FUNCT7_ADD 1'b0
`define FUNCT7_SUB 1'b1
`define FUNCT7_SRL 1'b0
`define FUNCT7_SRA 1'b1

`define FUNCT3_ADDI  3'h0
`define FUNCT3_XORI  3'h4
`define FUNCT3_ORI   3'h6
`define FUNCT3_ANDI  3'h7
`define FUNCT3_SLLI  3'h1
`define FUNCT3_SRLI  3'h5
`define FUNCT3_SRAI  3'h5
`define FUNCT3_SLTI  3'h2
`define FUNCT3_SLTUI 3'h3

`define FUNCT7_SRLI 1'b0
`define FUNCT7_SRAI 1'b1

`define FUNCT3_LB  3'h0
`define FUNCT3_LH  3'h1
`define FUNCT3_LW  3'h2
`define FUNCT3_LBU 3'h4
`define FUNCT3_LHU 3'h5

`define FUNCT3_SB 3'h0
`define FUNCT3_SH 3'h1
`define FUNCT3_SW 3'h2

`define FUNCT3_BEQ  3'h0
`define FUNCT3_BNE  3'h1
`define FUNCT3_BLT  3'h4
`define FUNCT3_BGE  3'h5
`define FUNCT3_BLTU 3'h6
`define FUNCT3_BGEU 3'h7



        //LSB

`define LSB_SIZE 16
  `define LSB_POS_WID 3:0
  `define LSB_ID_WID 4:0
  `define LSB_NPOS 5'd16

        //RS
`define RS_SIZE 16
  `define RS_POS_WID 3:0
  `define RS_ID_WID 4:0
  `define RS_NPOS 5'd16
