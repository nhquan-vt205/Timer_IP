// ============================================================================
// TC_CNT_CTRL_004 - Divider boundary values
// Objective: DIV_VAL = 8 gives one cnt_en every 256 cycles;
//            DIV_VAL = 1 gives one every 2 cycles.
// Copied to sim/run_test.v and included inside tb_cnt_ctrl.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Divider boundary values test --");
    // 1. DIV_VAL = 8, limit = 255
    drive(1'b0, 1'b1, 4'd8, 1'b0, 1'b0);  // c0: configure
    drive(1'b1, 1'b1, 4'd8, 1'b0, 1'b0);  // c1: tim_en = 1
    idle_n(511);                          // c2-c512
    // 2. DIV_VAL = 1, limit = 1
    drive(1'b0, 1'b1, 4'd8, 1'b0, 1'b0);  // c513: tim_en = 0
    drive(1'b0, 1'b1, 4'd1, 1'b0, 1'b0);  // c514: div_val = 1
    drive(1'b1, 1'b1, 4'd1, 1'b0, 1'b0);  // c515: tim_en = 1
    idle_n(3);                            // c516-c518
    end_test;
  end
