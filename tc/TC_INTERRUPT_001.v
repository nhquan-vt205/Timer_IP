// ============================================================================
// TC_INTERRUPT_001 - Reset value check
// Objective: INT_ST and tim_int are 0 during and after reset, even with a
//            compare match and int_en = 1 while reset is held.
// Copied to sim/run_test.v and included inside tb_interrupt.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset value check test --");
    // 1. Reset held 2 cycles with cnt = tcmp = all ones (match), int_en = 1
    assert_reset_mid;
    drive_in_reset(64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF, 1'b1, 1'b0);
    drive_in_reset(64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF, 1'b1, 1'b0);
    // 2. Release with cnt = 0, then 2 idle cycles
    drive(64'h0, 64'hFFFF_FFFF_FFFF_FFFF, 1'b1, 1'b0);
    drive(64'h0, 64'hFFFF_FFFF_FFFF_FFFF, 1'b1, 1'b0);
    drive(64'h0, 64'hFFFF_FFFF_FFFF_FFFF, 1'b1, 1'b0);
    end_test;
  end
