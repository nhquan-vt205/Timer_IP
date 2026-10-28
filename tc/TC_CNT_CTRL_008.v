// ============================================================================
// TC_CNT_CTRL_008 - Reset during operation
// Objective: the asynchronous reset clears div_cnt immediately, without
//            a clock edge, and clears tim_en_d (no cnt_clr after reset).
// Copied to sim/run_test.v and included inside tb_cnt_ctrl.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset during operation test --");
    // 1. Run the divider to d = 3 (limit = 3)
    drive(1'b0, 1'b1, 4'd2, 1'b0, 1'b0);  // c0: configure
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b0);  // c1: tim_en = 1
    idle_n(3);                            // c2-c4
    // 2. Reset mid-cycle in c4, held 2 cycles with tim_en = 1
    assert_reset_mid;
    drive_in_reset(1'b1, 1'b1, 4'd2, 1'b0, 1'b0);
    drive_in_reset(1'b1, 1'b1, 4'd2, 1'b0, 1'b0);
    // 3. Release with tim_en = 1 (r0), then r1-r3
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b0);
    idle_n(3);
    // 4. Reset mid-cycle in r3, held 2 cycles with tim_en = 0
    assert_reset_mid;
    drive_in_reset(1'b0, 1'b1, 4'd2, 1'b0, 1'b0);
    drive_in_reset(1'b0, 1'b1, 4'd2, 1'b0, 1'b0);
    // 5. Release with tim_en = 0, then 2 idle cycles
    drive(1'b0, 1'b1, 4'd2, 1'b0, 1'b0);
    idle_n(2);
    end_test;
  end
