// ============================================================================
// TC_APB_SLAVE_007 - No access phase
// Objective: without tim_psel & tim_penable there is no tim_pready, no
//            tim_pslverr and no strobe.
// Copied to sim/run_test.v and included inside tb_apb_slave.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- No access phase test --");
    for (i = 0; i < 4; i = i + 1) begin
      $sformat(cyc_name, "psel_1_penable_0_write_cyc%0d", i);
      apb_cycle(1'b1, 1'b0, 1'b1, 1'b1, 32'h0000_0000, cyc_name);
    end
    for (i = 0; i < 4; i = i + 1) begin
      $sformat(cyc_name, "psel_0_penable_1_write_cyc%0d", i);
      apb_cycle(1'b0, 1'b1, 1'b1, 1'b1, 32'h0000_0000, cyc_name);
    end
    for (i = 0; i < 4; i = i + 1) begin
      $sformat(cyc_name, "psel_1_penable_0_read_cyc%0d", i);
      apb_cycle(1'b1, 1'b0, 1'b0, 1'b1, 32'h0000_0000, cyc_name);
    end
    for (i = 0; i < 4; i = i + 1) begin
      $sformat(cyc_name, "psel_0_penable_1_read_cyc%0d", i);
      apb_cycle(1'b0, 1'b1, 1'b0, 1'b1, 32'h0000_0000, cyc_name);
    end
    end_test;
  end
