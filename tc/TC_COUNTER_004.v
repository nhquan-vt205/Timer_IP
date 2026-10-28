// ============================================================================
// TC_COUNTER_004 - Write over count
// Objective: a write wins over counting; bytes not written keep cnt,
//            not cnt + 1.
// Copied to sim/run_test.v and included inside tb_counter.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Write over count test --");
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'h0);           // c0: cnt_en = 1
    idle_n(4);                                      // c1-c4
    drive(1'b1, 1'b0, 4'b0001, 4'h0, 32'h0000_00F0);  // c5
    drive(1'b1, 1'b0, 4'b0010, 4'h0, 32'h0000_AB00);  // c6
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'h0000_AB00);     // c7
    idle;                                           // c8
    drive(1'b1, 1'b0, 4'h0, 4'hF, 32'h0000_0001);     // c9: TDR1 write
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'h0000_0001);     // c10
    idle;                                           // c11
    end_test;
  end
