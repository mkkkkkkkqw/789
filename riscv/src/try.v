always @(posedge clk) begin
    if (rst || (rollback && last_commit_pos == `LSB_NPOS)) begin
      status <= IDLE;
      mc_en <= 0;
      head <= 0;
      tail <= 0;
      last_commit_pos <= 0;
      empty <= 1;
      for (i = 0; i < `LSB_SIZE; i++) begin
        busy[i]       <= 0;
        opcode[i]     <= 0;
        funct3[i]     <= 0;
        funct7[i]     <= 0;
        rs1_rob_id[i] <= 0;
        rs1_val[i]    <= 0;
        rs2_rob_id[i] <= 0;
        rs2_val[i]    <= 0;
        pc[i]         <= 0;
        imm[i]        <= 0;
        rob_pos[i]    <= 0;
        committed[i]  <= 0;
      end
    end else if (rollback) begin
      // clear uncommitted Load/Store
      tail <= last_commit_pos + 1;
      for (i = 0; i < `LSB_SIZE; i++) begin
        if (!committed[i]) begin
          busy[i] <= 0;
        end
      end
    end else if (!rdy) begin
      ;
    end else begin
      // execute Load or Store
      mc_en  <= 0;
      result <= 0;
      if (status == WAIT_MEM) begin
        if (mc_done) begin  // finish
          busy[head] <= 0;
          committed[head] <= 0;
          if (opcode[head] == `OPCODE_L) begin
            result <= 1;
            result_val <= mc_r_data;
            result_rob_pos <= rob_pos[head];
          end
          if (last_commit_pos[`LSB_POS_WID] == head) last_commit_pos <= `LSB_NPOS;
          status <= IDLE;
        end
      end else begin  // status == IDLE
        if (exec_head) begin
          mc_en <= 1;
          mc_pc <= rs1_val[head] + imm[head];
          if (opcode[head] == `OPCODE_S) begin
            mc_w_data <= rs2_val[head];
            case (funct3[head])
              `FUNCT3_SB: mc_len <= 3'd1;
              `FUNCT3_SH: mc_len <= 3'd2;
              `FUNCT3_SW: mc_len <= 3'd4;
            endcase
            mc_wr <= 1;
          end else begin
            case (funct3[head])
              `FUNCT3_LB, `FUNCT3_LBU: mc_len <= 3'd1;
              `FUNCT3_LH, `FUNCT3_LHU: mc_len <= 3'd2;
              `FUNCT3_LW: mc_len <= 3'd4;
            endcase
            mc_wr <= 0;
          end
          status <= WAIT_MEM;
        end
      end

      // handle broadcast, update values
      if (alu_result)
        for (i = 0; i < `LSB_SIZE; i++) begin
          if (rs1_rob_id[i] == {1'b1, alu_result_rob_pos}) begin
            rs1_rob_id[i] <= 0;
            rs1_val[i] <= alu_result_val;
          end
          if (rs2_rob_id[i] == {1'b1, alu_result_rob_pos}) begin
            rs2_rob_id[i] <= 0;
            rs2_val[i] <= alu_result_val;
          end
        end

      if (lsb_result)
        for (i = 0; i < `LSB_SIZE; i++) begin
          if (rs1_rob_id[i] == {1'b1, lsb_result_rob_pos}) begin
            rs1_rob_id[i] <= 0;
            rs1_val[i] <= lsb_result_val;
          end
          if (rs2_rob_id[i] == {1'b1, lsb_result_rob_pos}) begin
            rs2_rob_id[i] <= 0;
            rs2_val[i] <= lsb_result_val;
          end
        end
      // ROB commits store
      if (commit_store) begin
        for (i = 0; i < `LSB_SIZE; i++)
          if (busy[i] && rob_pos[i] == commit_rob_pos && !committed[i]) begin
            committed[i] = 1;
            last_commit_pos <= {1'b0, i};
          end
      end

      // add instruction
      if (issue) begin
        busy[tail]       <= 1;
        opcode[tail]     <= issue_opcode;
        funct3[tail]     <= issue_funct3;
        funct7[tail]     <= issue_funct7;
        rs1_rob_id[tail] <= issue_rs1_rob_id;
        rs1_val[tail]    <= issue_rs1_val;
        rs2_rob_id[tail] <= issue_rs2_rob_id;
        rs2_val[tail]    <= issue_rs2_val;
        pc[tail]         <= issue_pc;
        imm[tail]        <= issue_imm;
        rob_pos[tail]    <= issue_rob_pos;
      end

      empty <= nxt_empty;
      head  <= nxt_head;
      tail  <= nxt_tail;
    end
  end