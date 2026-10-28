// ============================================================================
// TC_INTERRUPT_006 - Interrupt mask
// Objective: tim_int = INT_ST & INT_EN; masking with INT_EN = 0 keeps INT_ST.
// Copied to sim/run_test.v and included inside tb_interrupt.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Interrupt mask test --");
    drive(64'h10, TCMP_DEF, 1'b0, 1'b0);  // c0: match, masked
    drive(64'h11, TCMP_DEF, 1'b0, 1'b0);  // c1
    drive(64'h11, TCMP_DEF, 1'b0, 1'b0);  // c2
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);  // c3
    drive(64'h11, TCMP_DEF, 1'b0, 1'b0);  // c4
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);  // c5
    drive(64'h11, TCMP_DEF, 1'b1, 1'b1);  // c6: clear
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);  // c7
    drive(64'h11, TCMP_DEF, 1'b0, 1'b0);  // c8: INT_ST = 0
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);  // c9
    end_test;
  end
