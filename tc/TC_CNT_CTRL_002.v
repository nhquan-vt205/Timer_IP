// ============================================================================
// TC_CNT_CTRL_002 - Count every cycle
// Objective: with DIV_EN = 0, cnt_en follows tim_en every cycle and
//            DIV_VAL is ignored.
// Copied to sim/run_test.v and included inside tb_cnt_ctrl.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Count every cycle test --");
    drive(1'b1, 1'b0, 4'd1, 1'b0, 1'b0);  // c0: tim_en = 1
    idle_n(2);                            // c1-c2
    drive(1'b0, 1'b0, 4'd1, 1'b0, 1'b0);  // c3: tim_en = 0 (cnt_clr)
    drive(1'b0, 1'b0, 4'd8, 1'b0, 1'b0);  // c4: div_val = 8
    drive(1'b1, 1'b0, 4'd8, 1'b0, 1'b0);  // c5: tim_en = 1
    idle_n(2);                            // c6-c7
    end_test;
  end
