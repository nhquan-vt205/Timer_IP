// ============================================================================
// TC_CNT_CTRL_006 - Divider restart
// Objective: TIM_EN = 0 or DIV_EN = 0 clears div_cnt, and the clear has
//            priority over halt.
// Copied to sim/run_test.v and included inside tb_cnt_ctrl.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Divider restart test --");
    // 1. TIM_EN = 0 clears the divider
    drive(1'b0, 1'b1, 4'd2, 1'b0, 1'b1);  // c0: configure, limit = 3, dbg_mode = 1
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b1);  // c1: tim_en = 1
    idle;                                 // c2
    drive(1'b0, 1'b1, 4'd2, 1'b0, 1'b1);  // c3: tim_en = 0 (d = 2)
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b1);  // c4: tim_en = 1
    idle_n(5);                            // c5-c9
    // 2. Clear wins over halt
    drive(1'b1, 1'b1, 4'd2, 1'b1, 1'b1);  // c10: halt_req = 1
    drive(1'b0, 1'b1, 4'd2, 1'b1, 1'b1);  // c11: tim_en = 0, halt_req = 1
    drive(1'b1, 1'b1, 4'd2, 1'b1, 1'b1);  // c12: tim_en = 1, halt_req = 1
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b1);  // c13: halt_req = 0
    idle_n(5);                            // c14-c18
    // 3. DIV_EN = 0 clears the divider (module level only)
    drive(1'b1, 1'b0, 4'd2, 1'b0, 1'b1);  // c19: div_en = 0
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b1);  // c20: div_en = 1
    idle_n(3);                            // c21-c23
    end_test;
  end
