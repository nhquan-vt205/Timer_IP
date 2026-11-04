// ============================================================================
// TC_TIMER_TOP_004 - reg_1hot_chk
// Objective: walking one over every bit of TDR0, TDR1, TCMP0, TCMP1 and the
//            single-bit control fields (no stuck or aliased bit)
//   TDR0, TDR1, TCMP0, TCMP1, Control bits (two levels)
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("reg_1hot_chk");
    begin : tdr0
      u_log.sub1("TDR0");
      reset_dut;
      for (i = 0; i < 32; i = i + 1) begin
        apb_wr(ADDR_TDR0, 32'h1 << i, 4'hF);
        apb_rd(ADDR_TDR0, 32'h1 << i);
      end
      apb_rd(ADDR_TDR1, 32'h0);
    end
    begin : tdr1
      u_log.sub1("TDR1");
      reset_dut;
      for (i = 0; i < 32; i = i + 1) begin
        apb_wr(ADDR_TDR1, 32'h1 << i, 4'hF);
        apb_rd(ADDR_TDR1, 32'h1 << i);
      end
      apb_rd(ADDR_TDR0, 32'h0);
    end
    begin : tcmp0
      u_log.sub1("TCMP0");
      reset_dut;
      for (i = 0; i < 32; i = i + 1) begin
        apb_wr(ADDR_TCMP0, 32'h1 << i, 4'hF);
        apb_rd(ADDR_TCMP0, 32'h1 << i);
      end
      apb_rd(ADDR_TCMP1, 32'hFFFF_FFFF);
    end
    begin : tcmp1
      u_log.sub1("TCMP1");
      reset_dut;
      for (i = 0; i < 32; i = i + 1) begin
        apb_wr(ADDR_TCMP1, 32'h1 << i, 4'hF);
        apb_rd(ADDR_TCMP1, 32'h1 << i);
      end
      apb_rd(ADDR_TCMP0, 32'hFFFF_FFFF);
    end
    begin : control_bits
      u_log.sub1("Control bits");
      reset_dut;
      for (i = 0; i < 4; i = i + 1) begin                  // 1: DIV_VAL 1, 2, 4, 8
        apb_wr(ADDR_TCR, 32'h0000_0100 << i, 4'b0010);
        apb_rd(ADDR_TCR, 32'h0000_0100 << i);
      end
      apb_wr(ADDR_TCR, 32'h0000_0002, 4'b0001);            // 2: DIV_EN
      apb_rd(ADDR_TCR, 32'h0000_0802);
      apb_wr(ADDR_TCR, 32'h0000_0001, 4'b0001);            // 3: TIM_EN
      apb_rd(ADDR_TCR, 32'h0000_0801);
      apb_wr(ADDR_TIER, 32'h1, 4'hF);                      // 4
      apb_rd(ADDR_TIER, 32'h0000_0001);
      apb_wr(ADDR_THCSR, 32'h1, 4'hF);                     // 5
      apb_rd(ADDR_THCSR, 32'h0000_0001);
    end
    end_test;
  end
