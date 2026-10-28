// ============================================================================
// TC_INTERRUPT_003 - 64-bit compare
// Objective: every bit of cnt and {tcmp1, tcmp0} is compared; partial
//            matches do not set INT_ST.
// Copied to sim/run_test.v and included inside tb_interrupt.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- 64-bit compare test --");
    // tcmp = 64'h0000_0001_0000_0000
    drive(64'h0000_0000_0000_0000, 64'h0000_0001_0000_0000, 1'b1, 1'b0);  // c0
    drive(64'h0000_0001_0000_0001, 64'h0000_0001_0000_0000, 1'b1, 1'b0);  // c1
    drive(64'h0000_0000_FFFF_FFFF, 64'h0000_0001_0000_0000, 1'b1, 1'b0);  // c2
    drive(64'h8000_0001_0000_0000, 64'h0000_0001_0000_0000, 1'b1, 1'b0);  // c3
    drive(64'h0000_0001_0000_0000, 64'h0000_0001_0000_0000, 1'b1, 1'b0);  // c4: match
    drive(64'h0000_0000_0000_0000, 64'h0000_0001_0000_0000, 1'b1, 1'b0);  // c5
    drive(64'h0000_0000_0000_0000, 64'h0000_0001_0000_0000, 1'b1, 1'b1);  // c6: clear
    drive(64'h0000_0000_0000_0000, 64'h0000_0001_0000_0000, 1'b1, 1'b0);  // c7
    // tcmp = all ones
    drive(64'h7FFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF, 1'b1, 1'b0);  // c8
    drive(64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF, 1'b1, 1'b0);  // c9: match
    drive(64'h0000_0000_0000_0000, 64'hFFFF_FFFF_FFFF_FFFF, 1'b1, 1'b0);  // c10
    end_test;
  end
