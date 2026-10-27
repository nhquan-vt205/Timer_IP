// ============================================================================
// TC_INTERRUPT_007 - Reset during operation
// Objective: the asynchronous reset clears INT_ST immediately, without a
//            clock edge, while INT_ST = 1.
// Copied to sim/run_test.v and included inside tb_interrupt.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset during operation test --");
    // 1. Set INT_ST
    drive(64'h10, TCMP_DEF, 1'b1, 1'b0);  // c0: match
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);  // c1
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);  // c2
    // 2. Reset mid-cycle in c2, held 2 cycles
    assert_reset_mid;
    drive_in_reset(64'h11, TCMP_DEF, 1'b1, 1'b0);
    drive_in_reset(64'h11, TCMP_DEF, 1'b1, 1'b0);
    // 3. Release, then 2 idle cycles
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);
    end_test;
  end
