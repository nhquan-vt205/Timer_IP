// ============================================================================
// TC_CNT_CTRL_003 - Divide by 2^DIV_VAL
// Objective: with DIV_EN = 1, cnt_en pulses once every 2^DIV_VAL
//            cycles (DIV_VAL = 2: period 4; DIV_VAL = 0: every cycle).
// Copied to sim/run_test.v and included inside tb_cnt_ctrl.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Divide by 2^DIV_VAL test --");
    // 1. DIV_VAL = 2, limit = 3
    drive(1'b0, 1'b1, 4'd2, 1'b0, 1'b0);  // c0: configure
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b0);  // c1: tim_en = 1
    idle_n(11);                           // c2-c12
    // 2. DIV_VAL = 0, limit = 0
    drive(1'b0, 1'b1, 4'd2, 1'b0, 1'b0);  // c13: tim_en = 0
    drive(1'b0, 1'b1, 4'd0, 1'b0, 1'b0);  // c14: div_val = 0
    drive(1'b1, 1'b1, 4'd0, 1'b0, 1'b0);  // c15: tim_en = 1
    idle_n(2);                            // c16-c17
    end_test;
  end
