// ============================================================================
// TC_INTERRUPT_002 - Compare match set
// Objective: a match in cycle T sets INT_ST from T+1; INT_ST holds after cnt
//            leaves the compare value.
// Copied to sim/run_test.v and included inside tb_interrupt.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Compare match set test --");
    drive(64'h0E, TCMP_DEF, 1'b1, 1'b0);  // c0
    drive(64'h0F, TCMP_DEF, 1'b1, 1'b0);  // c1
    drive(64'h10, TCMP_DEF, 1'b1, 1'b0);  // c2: match
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);  // c3: INT_ST = 1
    drive(64'h12, TCMP_DEF, 1'b1, 1'b0);  // c4
    drive(64'h13, TCMP_DEF, 1'b1, 1'b0);  // c5
    drive(64'h14, TCMP_DEF, 1'b1, 1'b0);  // c6
    end_test;
  end
