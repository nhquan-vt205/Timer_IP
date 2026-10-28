// ============================================================================
// TC_COUNTER_002 - Count up
// Objective: cnt increments by 1 when cnt_en = 1 and holds when 0.
// Copied to sim/run_test.v and included inside tb_counter.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Count up test --");
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'h0);  // c0: cnt_en = 1
    idle_n(9);                             // c1-c9
    drive(1'b0, 1'b0, 4'h0, 4'h0, 32'h0);  // c10: cnt_en = 0
    idle_n(2);                             // c11-c12
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'h0);  // c13: cnt_en = 1
    idle_n(2);                             // c14-c15
    end_test;
  end
