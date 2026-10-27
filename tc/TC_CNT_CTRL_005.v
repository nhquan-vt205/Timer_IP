// ============================================================================
// TC_CNT_CTRL_005 - Debug halt
// Objective: halted = dbg_mode & HALT_REQ masks cnt_en and freezes the
//            divider; counting resumes at the same phase.
// Copied to sim/run_test.v and included inside tb_cnt_ctrl.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Debug halt test --");
    // 1. dbg_mode = 0: HALT_REQ has no effect
    drive(1'b0, 1'b1, 4'd2, 1'b0, 1'b0);  // c0: configure, limit = 3
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b0);  // c1: tim_en = 1
    drive(1'b1, 1'b1, 4'd2, 1'b1, 1'b0);  // c2: halt_req = 1
    idle_n(2);                            // c3-c4
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b0);  // c5: halt_req = 0
    // 2. dbg_mode = 1: halt freezes div_cnt
    drive(1'b0, 1'b1, 4'd2, 1'b0, 1'b0);  // c6: tim_en = 0
    drive(1'b0, 1'b1, 4'd2, 1'b0, 1'b1);  // c7: dbg_mode = 1
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b1);  // c8: tim_en = 1
    idle;                                 // c9
    drive(1'b1, 1'b1, 4'd2, 1'b1, 1'b1);  // c10: halt_req = 1
    idle;                                 // c11
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b1);  // c12: halt_req = 0
    idle_n(4);                            // c13-c16
    drive(1'b1, 1'b1, 4'd2, 1'b1, 1'b1);  // c17: halt_req = 1 at the match
    idle;                                 // c18
    drive(1'b1, 1'b1, 4'd2, 1'b0, 1'b1);  // c19: halt_req = 0
    idle;                                 // c20
    // 3. Halt with DIV_EN = 0
    drive(1'b0, 1'b1, 4'd2, 1'b0, 1'b1);  // c21: tim_en = 0
    drive(1'b0, 1'b0, 4'd2, 1'b0, 1'b1);  // c22: div_en = 0
    drive(1'b1, 1'b0, 4'd2, 1'b0, 1'b1);  // c23: tim_en = 1
    drive(1'b1, 1'b0, 4'd2, 1'b1, 1'b1);  // c24: halt_req = 1
    drive(1'b1, 1'b0, 4'd2, 1'b0, 1'b1);  // c25: halt_req = 0
    end_test;
  end
