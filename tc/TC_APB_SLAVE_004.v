// ============================================================================
// TC_APB_SLAVE_004 - Write error
// Objective: wr_err is sampled only in the wait cycle; an erroneous write
//            sets tim_pslverr in the last cycle and never produces wr_en.
// Copied to sim/run_test.v and included inside tb_apb_slave.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Write error test --");
    // Case 1: wr_err = 1 in c0-c2
    apb_transfer(1'b1, 1'b1, 1'b1, 1'b1, 32'h0000_0000, "write_err_c0c1c2");
    idle_cycle("write_err_c0c1c2_c3_idle");
    // Case 2: wr_err = 1 in the wait cycle only
    apb_transfer(1'b1, 1'b0, 1'b1, 1'b0, 32'h0000_0000, "write_err_c1");
    idle_cycle("write_err_c1_c3_idle");
    // Case 3: wr_err = 1 after the sampling cycle -> no error
    apb_transfer(1'b1, 1'b0, 1'b0, 1'b1, 32'h0000_0000, "write_err_c2");
    idle_cycle("write_err_c2_c3_idle");
    end_test;
  end
