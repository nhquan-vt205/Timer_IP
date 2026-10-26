// ============================================================================
// TC_APB_SLAVE_005 - Read without error
// Objective: wr_err is ignored on reads; tim_pslverr stays 0.
// Copied to sim/run_test.v and included inside tb_apb_slave.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Read without error test --");
    apb_transfer(1'b0, 1'b1, 1'b1, 1'b1, 32'h1234_5678, "read_wr_err_1");
    idle_cycle("read_wr_err_1_c3_idle");
    end_test;
  end
