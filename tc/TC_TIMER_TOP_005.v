// ============================================================================
// TC_TIMER_TOP_005 - Count divided mode
// Objective: with DIV_EN = 1 the counter steps once every
//            2^DIV_VAL cycles (DIV_VAL = 0, 2, 8).
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Count divided mode test --");
    // Part A: DIV_VAL = 0
    apb_wr(ADDR_TCR, 32'h0000_0002, 4'b0011);
    apb_wr(ADDR_TCR, 32'h0000_0003, 4'b0011);
    mark_e0;
    apb_rd(ADDR_TDR0, 32'h2);                              // e0+2
    apb_rd(ADDR_TDR0, 32'h5);                              // e0+5
    apb_rd(ADDR_TDR0, 32'h8);                              // e0+8
    // Part B: DIV_VAL = 2, /4
    apb_wr(ADDR_TCR, 32'h0000_0002, 4'b0001);              // TIM_EN = 0, clears cnt
    apb_wr(ADDR_TCR, 32'h0000_0202, 4'b0011);
    apb_wr(ADDR_TCR, 32'h0000_0203, 4'b0011);
    mark_e0;
    apb_rd(ADDR_TDR0, 32'h0);                              // e0+2
    apb_rd(ADDR_TDR0, 32'h1);                              // e0+5
    apb_rd(ADDR_TDR0, 32'h2);                              // e0+8
    apb_rd(ADDR_TDR0, 32'h2);                              // e0+11
    apb_rd(ADDR_TDR0, 32'h3);                              // e0+14
    // Part C: DIV_VAL = 8, /256
    apb_wr(ADDR_TCR, 32'h0000_0202, 4'b0001);
    apb_wr(ADDR_TCR, 32'h0000_0802, 4'b0011);
    apb_wr(ADDR_TCR, 32'h0000_0803, 4'b0011);
    mark_e0;
    idle_n(253);
    apb_rd(ADDR_TDR0, 32'h0);                              // e0+255
    apb_rd(ADDR_TDR0, 32'h1);                              // e0+258
    end_test;
  end
