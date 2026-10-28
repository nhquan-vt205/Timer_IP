// ============================================================================
// TC_COUNTER_005 - Clear priority
// Objective: cnt_clr clears cnt with priority over write and count.
// Copied to sim/run_test.v and included inside tb_counter.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Clear priority test --");
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'h0);           // c0: cnt_en = 1
    idle_n(2);                                      // c1-c2
    drive(1'b1, 1'b1, 4'h0, 4'h0, 32'h0);           // c3: clear + count
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'h0);           // c4
    idle;                                           // c5
    drive(1'b1, 1'b1, 4'hF, 4'hF, 32'h5555_5555);   // c6: clear + write + count
    drive(1'b1, 1'b0, 4'h0, 4'h0, 32'h5555_5555);   // c7
    drive(1'b0, 1'b1, 4'h0, 4'h0, 32'h5555_5555);   // c8: clear only
    drive(1'b0, 1'b0, 4'h0, 4'h0, 32'h5555_5555);   // c9
    idle;                                           // c10
    end_test;
  end
