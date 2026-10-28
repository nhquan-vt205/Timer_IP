// ============================================================================
// TC_COUNTER_001 - Reset value check
// Objective: cnt = 0 during reset (count and write ignored) and after
//            release.
// Copied to sim/run_test.v and included inside tb_counter.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset value check test --");
    // 1. Reset held 2 cycles with count and full write requested
    assert_reset_mid;
    drive_in_reset(1'b1, 1'b0, 4'hF, 4'hF, 32'hFFFF_FFFF);
    drive_in_reset(1'b1, 1'b0, 4'hF, 4'hF, 32'hFFFF_FFFF);
    // 2. Release with the default inputs, then 2 idle cycles
    drive(1'b0, 1'b0, 4'h0, 4'h0, 32'h0);
    idle_n(2);
    end_test;
  end
