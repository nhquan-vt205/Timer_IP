// ============================================================================
// TC_APB_SLAVE_002 - Write transfer
// Objective: a write takes one wait state and produces wr_en for exactly one
//            cycle (the last access cycle).
// Copied to sim/run_test.v and included inside tb_apb_slave.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Write transfer test --");
    apb_transfer(1'b1, 1'b0, 1'b0, 1'b0, 32'h0000_0000, "write_ok");
    idle_cycle("write_ok_c3_idle");
    end_test;
  end
