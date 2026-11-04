// ============================================================================
// TC_TIMER_TOP_006 - cnt_ctrl_chk
// Objective: TIM_EN start/stop with hardware clear, count speed by DIV_EN /
//            DIV_VAL, and no TDR write while the timer runs
//   Timer enable, Divider setting, TDR write while counting (two levels)
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("cnt_ctrl_chk");
    begin : timer_enable
      u_log.sub1("Timer enable");
      reset_dut;
      apb_wr(ADDR_TCR,  32'h0000_0001, 4'b0001);           // 1: e0 follows
      apb_rd(ADDR_TDR0, 32'h2);                            // 2: e0+2
      apb_wr(ADDR_TCR,  32'h0000_0000, 4'b0001);           // 3: e0+5
      apb_rd(ADDR_TDR0, 32'h0);                            // 4: e0+8
      apb_rd(ADDR_TDR1, 32'h0);                            // e0+11
      apb_wr(ADDR_TDR0, 32'h0000_0055, 4'hF);              // 5
      u_drv.idle(5);                                       // 6
      apb_rd(ADDR_TDR0, 32'h0000_0055);
      apb_wr(ADDR_TCR,  32'h0000_0001, 4'b0001);           // 7: e1 follows
      apb_rd(ADDR_TDR0, 32'h0000_0057);                    // e1+2
    end
    begin : divider_setting
      u_log.sub1("Divider setting");
      reset_dut;
      // Part A: DIV_VAL = 0
      apb_wr(ADDR_TCR, 32'h0000_0002, 4'b0011);
      apb_wr(ADDR_TCR, 32'h0000_0003, 4'b0011);            // e0 follows
      apb_rd(ADDR_TDR0, 32'h2);                            // e0+2
      apb_rd(ADDR_TDR0, 32'h5);                            // e0+5
      apb_rd(ADDR_TDR0, 32'h8);                            // e0+8
      // Part B: DIV_VAL = 2, /4
      apb_wr(ADDR_TCR, 32'h0000_0002, 4'b0001);            // TIM_EN = 0, clears cnt
      apb_wr(ADDR_TCR, 32'h0000_0202, 4'b0011);
      apb_wr(ADDR_TCR, 32'h0000_0203, 4'b0011);            // e0 follows
      apb_rd(ADDR_TDR0, 32'h0);                            // e0+2
      apb_rd(ADDR_TDR0, 32'h1);                            // e0+5
      apb_rd(ADDR_TDR0, 32'h2);                            // e0+8
      apb_rd(ADDR_TDR0, 32'h2);                            // e0+11
      apb_rd(ADDR_TDR0, 32'h3);                            // e0+14
      // Part C: DIV_VAL = 8, /256
      apb_wr(ADDR_TCR, 32'h0000_0202, 4'b0001);
      apb_wr(ADDR_TCR, 32'h0000_0802, 4'b0011);
      apb_wr(ADDR_TCR, 32'h0000_0803, 4'b0011);            // e0 follows
      u_drv.idle(253);
      apb_rd(ADDR_TDR0, 32'h0);                            // e0+255
      apb_rd(ADDR_TDR0, 32'h1);                            // e0+258
    end
    begin : tdr_write_while_counting
      u_log.sub1("TDR write while counting");
      reset_dut;
      apb_wr(ADDR_TCR,  32'h0000_0202, 4'b0011);           // 1: DIV_VAL = 2, /4
      apb_wr(ADDR_TCR,  32'h0000_0203, 4'b0011);           // e0 follows
      apb_wr(ADDR_TDR0, 32'h0000_0100, 4'hF);              // 2: e0+2, ignored
      apb_rd(ADDR_TDR0, 32'h1);                            // 3: e0+5
      apb_rd(ADDR_TDR0, 32'h2);                            // e0+8
      apb_wr(ADDR_TDR0, 32'h0000_0200, 4'hF);              // 4: e0+11, ignored
      apb_rd(ADDR_TDR0, 32'h3);                            // 5: e0+14
      apb_rd(ADDR_TDR0, 32'h4);                            // e0+17
      apb_wr(ADDR_TDR1, 32'h0000_0001, 4'hF);              // 6: e0+20, ignored
      apb_rd(ADDR_TDR1, 32'h0);                            // 7: e0+23
      apb_rd(ADDR_TDR0, 32'h6);                            // e0+26
      apb_wr(ADDR_TCR,  32'h0000_0202, 4'b0001);           // 8: e0+29, TIM_EN = 0
      apb_wr(ADDR_TDR0, 32'h0000_0055, 4'hF);              // 9: accepted
      apb_rd(ADDR_TDR0, 32'h0000_0055);
    end
    end_test;
  end
