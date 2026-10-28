// ============================================================================
// TC_CNT_CTRL_007 - Counter clear pulse
// Objective: cnt_clr is 1 for exactly one cycle on each TIM_EN 1 -> 0
//            transition and never on 0 -> 1.
// Copied to sim/run_test.v and included inside tb_cnt_ctrl.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Counter clear pulse test --");
    drive(1'b1, 1'b0, 4'd1, 1'b0, 1'b0);  // c0: tim_en = 1
    idle;                                 // c1
    drive(1'b0, 1'b0, 4'd1, 1'b0, 1'b0);  // c2: tim_en = 0 (pulse)
    idle_n(2);                            // c3-c4
    drive(1'b1, 1'b0, 4'd1, 1'b0, 1'b0);  // c5: tim_en = 1 (no pulse)
    drive(1'b0, 1'b0, 4'd1, 1'b0, 1'b0);  // c6: tim_en = 0 (pulse)
    drive(1'b1, 1'b0, 4'd1, 1'b0, 1'b0);  // c7: tim_en = 1
    drive(1'b0, 1'b0, 4'd1, 1'b0, 1'b0);  // c8: tim_en = 0 (pulse)
    idle;                                 // c9
    end_test;
  end
