// ============================================================================
// TC_TIMER_TOP_005 - reg_byte_access
// Objective: byte strobes write only the strobed bytes; strobe 0 writes
//            nothing
//   TCMP0, TDR0, TCR, TIER and THCSR (two levels)
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("reg_byte_access");
    begin : tcmp0
      u_log.sub1("TCMP0");
      reset_dut;
      apb_wr(ADDR_TCMP0, 32'h1122_3344, 4'b0001);
      apb_rd(ADDR_TCMP0, 32'hFFFF_FF44);
      apb_wr(ADDR_TCMP0, 32'h1122_3344, 4'b0010);
      apb_rd(ADDR_TCMP0, 32'hFFFF_3344);
      apb_wr(ADDR_TCMP0, 32'h1122_3344, 4'b0100);
      apb_rd(ADDR_TCMP0, 32'hFF22_3344);
      apb_wr(ADDR_TCMP0, 32'h1122_3344, 4'b1000);
      apb_rd(ADDR_TCMP0, 32'h1122_3344);
      apb_wr(ADDR_TCMP0, 32'hAABB_CCDD, 4'b0101);
      apb_rd(ADDR_TCMP0, 32'h11BB_33DD);
      apb_wr(ADDR_TCMP0, 32'h0, 4'b0000);
      apb_rd(ADDR_TCMP0, 32'h11BB_33DD);
    end
    begin : tdr0
      u_log.sub1("TDR0");
      reset_dut;                                           // TIM_EN = 0
      apb_wr(ADDR_TDR0, 32'h1122_3344, 4'b0001);
      apb_rd(ADDR_TDR0, 32'h0000_0044);
      apb_wr(ADDR_TDR0, 32'h1122_3344, 4'b0010);
      apb_rd(ADDR_TDR0, 32'h0000_3344);
      apb_wr(ADDR_TDR0, 32'h1122_3344, 4'b0100);
      apb_rd(ADDR_TDR0, 32'h0022_3344);
      apb_wr(ADDR_TDR0, 32'h1122_3344, 4'b1000);
      apb_rd(ADDR_TDR0, 32'h1122_3344);
      apb_wr(ADDR_TDR0, 32'hAABB_CCDD, 4'b1010);
      apb_rd(ADDR_TDR0, 32'hAA22_CC44);
      apb_wr(ADDR_TDR0, 32'h0, 4'b0000);
      apb_rd(ADDR_TDR0, 32'hAA22_CC44);
      apb_rd(ADDR_TDR1, 32'h0);
    end
    begin : tcr
      u_log.sub1("TCR");
      reset_dut;
      apb_wr(ADDR_TCR, 32'h0000_0302, 4'b0010);
      apb_rd(ADDR_TCR, 32'h0000_0300);
      apb_wr(ADDR_TCR, 32'h0000_0802, 4'b0001);
      apb_rd(ADDR_TCR, 32'h0000_0302);
      apb_wr(ADDR_TCR, 32'hFFFF_FFFF, 4'b1100);
      apb_rd(ADDR_TCR, 32'h0000_0302);
    end
    begin : tier_and_thcsr
      u_log.sub1("TIER and THCSR");
      reset_dut;
      apb_wr(ADDR_TIER, 32'hFFFF_FFFF, 4'b1110);
      apb_rd(ADDR_TIER, 32'h0);
      apb_wr(ADDR_TIER, 32'h1, 4'b0001);
      apb_rd(ADDR_TIER, 32'h1);
      apb_wr(ADDR_THCSR, 32'hFFFF_FFFF, 4'b1110);
      apb_rd(ADDR_THCSR, 32'h0);
      apb_wr(ADDR_THCSR, 32'h1, 4'b0001);
      apb_rd(ADDR_THCSR, 32'h1);
    end
    end_test;
  end
