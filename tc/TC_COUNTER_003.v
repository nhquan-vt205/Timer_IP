// ============================================================================
// TC_COUNTER_003 - Byte write
// Objective: per-byte software write of TDR0 and TDR1; bytes not
//            enabled keep their value.
// Copied to sim/run_test.v and included inside tb_counter.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Byte write test --");
    drive(1'b0, 1'b0, 4'b0001, 4'h0, 32'hA1B2_C3D4);     // c0
    drive(1'b0, 1'b0, 4'b0010, 4'h0, 32'h1122_3344);     // c1
    drive(1'b0, 1'b0, 4'b0100, 4'h0, 32'h5566_7788);     // c2
    drive(1'b0, 1'b0, 4'b1000, 4'h0, 32'h99AA_BBCC);     // c3
    drive(1'b0, 1'b0, 4'hF,    4'h0, 32'hDEAD_BEEF);     // c4
    drive(1'b0, 1'b0, 4'h0,    4'h0, 32'hDEAD_BEEF);     // c5
    drive(1'b0, 1'b0, 4'h0, 4'b0101, 32'h1234_5678);     // c6
    drive(1'b0, 1'b0, 4'h0, 4'b1010, 32'hCAFE_F00D);     // c7
    drive(1'b0, 1'b0, 4'h0, 4'hF,    32'hFFFF_FFFF);     // c8
    drive(1'b0, 1'b0, 4'h0, 4'h0,    32'hFFFF_FFFF);     // c9
    drive(1'b0, 1'b0, 4'b0011, 4'b1100, 32'h0123_4567);  // c10: both
    drive(1'b0, 1'b0, 4'h0, 4'h0, 32'h0123_4567);        // c11
    idle;                                                // c12
    end_test;
  end
