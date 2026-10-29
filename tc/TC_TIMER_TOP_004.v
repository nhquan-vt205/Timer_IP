// ============================================================================
// TC_TIMER_TOP_004 - Count default mode
// Objective: with DIV_EN = 0 the counter steps once per cycle.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Count default mode test --");
    apb_rd(ADDR_TDR0, 32'h0);                              // 1
    apb_wr(ADDR_TCR, 32'h0000_0001, 4'b0001);              // 2: e0 follows
    mark_e0;
    apb_rd(ADDR_TDR0, 32'h2);                              // 3: e0+2
    apb_rd(ADDR_TDR0, 32'h5);                              // e0+5
    apb_rd(ADDR_TDR0, 32'h8);                              // e0+8
    apb_rd(ADDR_TDR1, 32'h0);                              // e0+11
    apb_rd(ADDR_TCR,  32'h0000_0101);                      // e0+14
    end_test;
  end
