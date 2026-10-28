// ============================================================================
// TC_COUNTER_007 - Reset during operation
// Objective: the asynchronous reset clears cnt immediately, without
//            a clock edge; counting restarts from 0 after release.
// Copied to sim/run_test.v and included inside tb_counter.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset during operation test --");
    // 1. Count to 5
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'h0);           // c0: cnt_en = 1
    idle_n(5);                                      // c1-c5
    // 2. Reset mid-cycle in c5, held 2 cycles with count and write requested
    assert_reset_mid;
    drive_in_reset(1'b1, 1'b0, 4'hF, 4'h0, 32'hFFFF_FFFF);
    drive_in_reset(1'b1, 1'b0, 4'hF, 4'h0, 32'hFFFF_FFFF);
    // 3. Release with cnt_en = 1 (r0), then r1-r3
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'hFFFF_FFFF);
    idle_n(3);
    end_test;
  end
