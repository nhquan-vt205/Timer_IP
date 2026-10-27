// ============================================================================
// TC_CNT_CTRL_001 - Reset value check
// Objective: cnt_en, cnt_clr and halt_ack are 0 during and after reset
//            (div_cnt = 0 and tim_en_d = 0 while reset is held).
// Copied to sim/run_test.v and included inside tb_cnt_ctrl.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset value check test --");
    // 1. Reset held 2 cycles: limit = 3 with tim_en = 1, then tim_en = 0
    assert_reset_mid;
    drive_in_reset(1'b1, 1'b1, 4'd2, 1'b0, 1'b0);
    drive_in_reset(1'b0, 1'b1, 4'd2, 1'b0, 1'b0);
    // 2. Release with the default inputs, then 2 idle cycles
    drive(1'b0, 1'b0, 4'd1, 1'b0, 1'b0);
    idle_n(2);
    end_test;
  end
