// ============================================================================
// TC_APB_SLAVE_003 - Read transfer
// Objective: a read takes one wait state, produces rd_en for exactly one
//            cycle, and tim_prdata follows rdata.
// Copied to sim/run_test.v and included inside tb_apb_slave.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Read transfer test --");
    for (i = 0; i < 5; i = i + 1) begin
      case (i)
        0: rd_pattern = 32'hA5A5_5A5A;
        1: rd_pattern = 32'h0000_0000;
        2: rd_pattern = 32'hFFFF_FFFF;
        3: rd_pattern = 32'h5555_5555;
        default: rd_pattern = 32'hAAAA_AAAA;
      endcase
      $sformat(cyc_name, "read_rdata_%h", rd_pattern);
      apb_transfer(1'b0, 1'b0, 1'b0, 1'b0, rd_pattern, cyc_name);
      $sformat(cyc_name, "read_rdata_%h_c3_idle", rd_pattern);
      idle_cycle(cyc_name);
    end
    end_test;
  end
