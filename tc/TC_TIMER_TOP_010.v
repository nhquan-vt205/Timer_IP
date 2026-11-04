// ============================================================================
// TC_TIMER_TOP_010 - cnt_counting_chk
// Objective: count every cycle; software load while stopped, carry TDR0 ->
//            TDR1, write while counting ignored
//   Default mode, TDR load and carry (two levels)
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("cnt_counting_chk");
    begin : default_mode
      u_log.sub1("Default mode");
      reset_dut;
      apb_rd(ADDR_TDR0, 32'h0);                            // 1
      apb_wr(ADDR_TCR, 32'h0000_0001, 4'b0001);            // 2: e0 follows
      apb_rd(ADDR_TDR0, 32'h2);                            // 3: e0+2
      apb_rd(ADDR_TDR0, 32'h5);                            // e0+5
      apb_rd(ADDR_TDR0, 32'h8);                            // e0+8
      apb_rd(ADDR_TDR1, 32'h0);                            // e0+11
      apb_rd(ADDR_TCR,  32'h0000_0101);                    // e0+14
    end
    begin : tdr_load_and_carry
      u_log.sub1("TDR load and carry");
      reset_dut;
      apb_wr(ADDR_TDR0, 32'hFFFF_FFF0, 4'hF);              // 1
      apb_wr(ADDR_TDR1, 32'h0000_0001, 4'hF);
      apb_rd(ADDR_TDR0, 32'hFFFF_FFF0);
      apb_rd(ADDR_TDR1, 32'h0000_0001);
      apb_wr(ADDR_TDR0, 32'h0000_00AB, 4'b0001);           // 2
      apb_rd(ADDR_TDR0, 32'hFFFF_FFAB);
      apb_wr(ADDR_TDR0, 32'hFFFF_FFFE, 4'hF);              // 3
      apb_wr(ADDR_TDR1, 32'h0,         4'hF);
      apb_wr(ADDR_TCR,  32'h0000_0001, 4'b0001);           // 4: e0 follows
      apb_rd(ADDR_TDR0, 32'h0000_0000);                    // e0+2: carry
      apb_rd(ADDR_TDR1, 32'h0000_0001);                    // e0+5
      apb_wr(ADDR_TDR0, 32'h0000_1000, 4'hF);              // 5: e0+8, ignored
      apb_rd(ADDR_TDR0, 32'h0000_0009);                    // e0+11
      apb_rd(ADDR_TDR1, 32'h0000_0001);                    // e0+14
    end
    end_test;
  end
