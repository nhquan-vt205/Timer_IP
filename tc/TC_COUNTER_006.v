// ============================================================================
// TC_COUNTER_006 - Carry and wrap
// Objective: carry across 32 bits into TDR1 and wrap from 2^64 - 1
//            to 0.
// Copied to sim/run_test.v and included inside tb_counter.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Carry and wrap test --");
    drive(1'b0, 1'b0, 4'hF, 4'h0, 32'hFFFF_FFFE);   // c0: TDR0 = FFFF_FFFE
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'hFFFF_FFFE);   // c1: cnt_en = 1
    idle_n(2);                                      // c2-c3
    drive(1'b0, 1'b0, 4'h0, 4'hF, 32'hFFFF_FFFF);   // c4: TDR1 = FFFF_FFFF
    drive(1'b0, 1'b0, 4'hF, 4'h0, 32'hFFFF_FFFE);   // c5: TDR0 = FFFF_FFFE
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'hFFFF_FFFE);   // c6: cnt_en = 1
    idle_n(3);                                      // c7-c9
    end_test;
  end
