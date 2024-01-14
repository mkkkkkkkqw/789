`ifndef MEM_CTRL
`define MEM_CTRL
`include "Mydefine.v"

        module MemCtrl(
                input wire clk,
                input wire rst,
                input wire rdy,

                //向内存中读写
                input wire [7:0] mem_din,    //data input bus


                output reg [7:0] mem_dout,  //data output bus
                output reg [31:0] mem_a,  //address bus (only 17:0 is used)
                output reg        mem_wr  ,  //1 for write

                input wire io_buffer_full,    //1 if uart buffer is full

                //insfetch
                input wire if_en,
                input wire [31:0] if_pc,
                output reg [31:0] if_data,
                output reg if_done
                // input  wire             if_en,
                //     input  wire [`ADDR_WID] if_pc,
                //     output reg              if_done,
                //     output reg  [`DATA_WID] if_data


                //lsb

                input wire lsb_en,
                input wire [31:0] lsb_pc,
                input wire lsb_wr,//1 for write, 0 for read
                input wire [2:0]lsb_len,
                input wire [31:0] lsb_w_data,
                output reg [31:0] lsb_r_data,
                output reg lsb_done

            );


            localparam IDLE=0,IF=1,LOAD=2,STORE=3;
            reg[1:0]status;
            reg[2:0]stage;
            reg [2:0] len;


            always @(posedge clk) begin
                if(rst) begin
                    status<=IDLE;
                    if_done<=0;
                    mem_wr<=0;
                    mem_a<=0;
                    lsb_done<=0;
                end
                else if (!rdy) begin
                    if_done<=0;
                    mem_wr<=0;
                    mem_a<=0;
                    lsb_done<=0;
                end
                else begin
                    if(status!=IDLE) begin
                        if(stage==len) begin
                            stage<=3'h0;
                            status<=IDLE;
                            mem_wr<=0;
                            mem_a<=0;
                        end
                        else begin
                            stage<=stage+1;
                            // mem_wr<=0;
                            mem_a<=mem_a+1;
                        end
                    end
                    mem_wr<=0;
                    case (status)
                        IDLE: begin
                            if_done<=0;
                            lsb_done<=0;
                            if(lsb_en) begin
                                status<=lsb_wr?STORE:LOAD;
                                mem_a<=lsb_pc;
                                // mem_wr<=lsb_wr;
                                len<=lsb_len;
                                stage<=3'h1;
                            end
                            else if(if_en) begin
                                status<=IF;
                                mem_a<=if_pc;
                                // mem_wr<=0;
                                stage<=3'h1;
                                len<=3'd4
                            end
                        end
                        IF: begin
                            case(stage)
                                3'h1: begin
                                    if_data[7:0]<=mem_din;
                                end
                                3'h2: begin
                                    if_data[15:8]<=mem_din;
                                end
                                3'h3: begin
                                    if_data[23:16]<=mem_din;
                                end
                                3'h4: begin
                                    if_data[31:24]<=mem_din;
                                    if_done<=1;
                                end
                            endcase
                            if(stage==len) begin
                                lsb_done<=1;
                            end
                        end
                        STORE: begin
                            if(mem_a[17:16]!=2'b11||!io_buffer_full) begin
                                mem_wr<=1;
                                case(stage)
                                    3'h1: begin
                                        mem_dout<=lsb_w_data[7:0];
                                    end
                                    3'h2: begin
                                        mem_dout<=lsb_w_data[15:8];
                                    end
                                    3'h3: begin
                                        mem_dout<=lsb_w_data[23:16];
                                    end
                                    3'h4: begin
                                        mem_dout<=lsb_w_data[31:24];
                                        lsb_done<=1;
                                    end
                                endcase
                                if(stage==len) begin
                                    lsb_done<=1;
                                end
                            end


                        end

                    endcase
                end
            end

        endmodule

`endif
