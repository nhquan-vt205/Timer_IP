// ============================================================================
// TC_TIMER_TOP_011 - interrupt_chk
// Objective: compare match sets INT_ST and tim_int; INT_EN masks tim_int
//            without losing INT_ST; writing 1 to TISR clears it; INT_ST is
//            set again while cnt still equals {TCMP1, TCMP0}
//   Set, mask and clear, Continuous match (two levels)
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("interrupt_chk");
    begin : set_mask_and_clear
      u_log.sub1("Set, mask and clear");
      reset_dut;
      apb_wr(ADDR_TCMP0, 32'h0000_0010, 4'hF);             // 1
      apb_wr(ADDR_TCMP1, 32'h0,         4'hF);
      apb_wr(ADDR_TIER,  32'h1,         4'hF);
      apb_wr(ADDR_TCR,   32'h0000_0001, 4'b0001);          // 2: e0 follows
      u_chk.mark_e0;
      u_drv.idle(20);                                      // 3: e0 .. e0+19
      apb_rd(ADDR_TISR,  32'h1);                           // 4: e0+22
      apb_rd(ADDR_TDR0,  32'h0000_0019);                   // e0+25
      apb_wr(ADDR_TIER,  32'h0, 4'hF);                     // 5: e0+28
      apb_rd(ADDR_TISR,  32'h1);                           // e0+31
      apb_wr(ADDR_TIER,  32'h1, 4'hF);                     // 6: e0+34
      apb_wr(ADDR_TISR,  32'h0, 4'b0001);                  // 7: e0+37
      apb_rd(ADDR_TISR,  32'h1);                           // e0+40
      apb_wr(ADDR_TISR,  32'h1, 4'b0001);                  // 8: e0+43
      apb_rd(ADDR_TISR,  32'h0);                           // e0+46
      // tim_int in every cycle e0 .. e0+46
      for (i = 0; i <= 46; i = i + 1) begin
        u_chk.expect_int_at(i, ((i >= 17) && (i <= 28)) || ((i >= 35) && (i <= 43)));
      end
    end
    begin : continuous_match
      u_log.sub1("Continuous match");
      reset_dut;
      // TIM_EN stays 0, cnt stays 0
      apb_wr(ADDR_TIER,  32'h1, 4'hF);                     // 1
      apb_wr(ADDR_TCMP0, 32'h0, 4'hF);
      apb_wr(ADDR_TCMP1, 32'h0, 4'hF);                     // last access c1
      u_chk.mark_now;
      apb_rd(ADDR_TISR,  32'h1);                           // 2: c1+3
      apb_wr(ADDR_TISR,  32'h1, 4'b0001);                  // 3: c2 = c1+6
      apb_rd(ADDR_TISR,  32'h1);                           // c1+9
      apb_wr(ADDR_TCMP0, 32'h0000_0010, 4'hF);             // 4
      apb_rd(ADDR_TISR,  32'h1);                           // c1+15
      apb_wr(ADDR_TISR,  32'h1, 4'b0001);                  // 5: c3 = c1+18
      apb_rd(ADDR_TISR,  32'h0);                           // c1+21
      // tim_int in every cycle c1 .. c1+21
      for (i = 0; i <= 21; i = i + 1) begin
        u_chk.expect_int_at(i, ((i >= 2) && (i <= 6)) || ((i >= 8) && (i <= 18)));
      end
    end
    end_test;
  end
