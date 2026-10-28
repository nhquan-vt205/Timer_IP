// ============================================================================
// TC_INTERRUPT_004 - INT_ST clear
// Objective: int_st_clr clears INT_ST one cycle later (RW1C); a clear while
//            INT_ST = 0 has no effect.
// Copied to sim/run_test.v and included inside tb_interrupt.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- INT_ST clear test --");
    drive(64'h00, TCMP_DEF, 1'b1, 1'b1);  // c0: clear with INT_ST = 0
    drive(64'h00, TCMP_DEF, 1'b1, 1'b0);  // c1
    drive(64'h10, TCMP_DEF, 1'b1, 1'b0);  // c2: match
    drive(64'h11, TCMP_DEF, 1'b1, 1'b0);  // c3
    drive(64'h11, TCMP_DEF, 1'b1, 1'b1);  // c4: clear
    drive(64'h12, TCMP_DEF, 1'b1, 1'b0);  // c5
    drive(64'h12, TCMP_DEF, 1'b1, 1'b0);  // c6
    end_test;
  end
