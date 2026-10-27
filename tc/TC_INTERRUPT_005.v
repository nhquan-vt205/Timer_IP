// ============================================================================
// TC_INTERRUPT_005 - Clear priority
// Objective: clear wins over a match in the same cycle; with cnt held at the
//            compare value INT_ST is set again in the cycle after a clear.
// Copied to sim/run_test.v and included inside tb_interrupt.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Clear priority test --");
    // cnt = tcmp in every cycle
    drive(64'h10, TCMP_DEF, 1'b1, 1'b1);  // c0: set and clear together
    drive(64'h10, TCMP_DEF, 1'b1, 1'b0);  // c1
    drive(64'h10, TCMP_DEF, 1'b1, 1'b0);  // c2
    drive(64'h10, TCMP_DEF, 1'b1, 1'b1);  // c3: clear with INT_ST = 1
    drive(64'h10, TCMP_DEF, 1'b1, 1'b0);  // c4
    drive(64'h10, TCMP_DEF, 1'b1, 1'b1);  // c5
    drive(64'h10, TCMP_DEF, 1'b1, 1'b1);  // c6
    drive(64'h10, TCMP_DEF, 1'b1, 1'b0);  // c7
    drive(64'h10, TCMP_DEF, 1'b1, 1'b0);  // c8
    end_test;
  end
