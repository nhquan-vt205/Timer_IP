// ============================================================================
// TC_TIMER_TOP_002 - reg_rw_chk
// Objective: read/write of every RW register, reserved bits read 0, and a
//            rejected TCR write changes nothing
//   TCR, TDR0, TDR1, TCMP0, TCMP1, TIER, THCSR, Rejected write (two levels)
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("reg_rw_chk");
    begin : tcr
      u_log.sub1("TCR");
      reset_dut;
      apb_wr(ADDR_TCR, 32'h0000_0802, 4'hF);
      apb_rd(ADDR_TCR, 32'h0000_0802);
      apb_wr(ADDR_TCR, 32'h0000_0000, 4'hF);
      apb_rd(ADDR_TCR, 32'h0000_0000);
      apb_wr(ADDR_TCR, 32'hFFFF_F5FE, 4'hF);
      apb_rd(ADDR_TCR, 32'h0000_0502);
      apb_wr(ADDR_TCR, 32'h0000_0503, 4'hF);
      apb_rd(ADDR_TCR, 32'h0000_0503);
      apb_wr(ADDR_TCR, 32'h0000_0502, 4'hF);
      apb_rd(ADDR_TCR, 32'h0000_0502);
    end
    begin : tdr0
      u_log.sub1("TDR0");
      reset_dut;
      apb_wr(ADDR_TDR0, 32'h0000_0000, 4'hF);
      apb_rd(ADDR_TDR0, 32'h0000_0000);
      apb_wr(ADDR_TDR0, 32'hFFFF_FFFF, 4'hF);
      apb_rd(ADDR_TDR0, 32'hFFFF_FFFF);
      apb_wr(ADDR_TDR0, 32'h5555_5555, 4'hF);
      apb_rd(ADDR_TDR0, 32'h5555_5555);
      apb_wr(ADDR_TDR0, 32'hAAAA_AAAA, 4'hF);
      apb_rd(ADDR_TDR0, 32'hAAAA_AAAA);
      apb_rd(ADDR_TDR1, 32'h0);
    end
    begin : tdr1
      u_log.sub1("TDR1");
      reset_dut;
      apb_wr(ADDR_TDR1, 32'h0000_0000, 4'hF);
      apb_rd(ADDR_TDR1, 32'h0000_0000);
      apb_wr(ADDR_TDR1, 32'hFFFF_FFFF, 4'hF);
      apb_rd(ADDR_TDR1, 32'hFFFF_FFFF);
      apb_wr(ADDR_TDR1, 32'h5555_5555, 4'hF);
      apb_rd(ADDR_TDR1, 32'h5555_5555);
      apb_wr(ADDR_TDR1, 32'hAAAA_AAAA, 4'hF);
      apb_rd(ADDR_TDR1, 32'hAAAA_AAAA);
      apb_rd(ADDR_TDR0, 32'h0);
    end
    begin : tcmp0
      u_log.sub1("TCMP0");
      reset_dut;
      apb_wr(ADDR_TCMP0, 32'h0000_0000, 4'hF);
      apb_rd(ADDR_TCMP0, 32'h0000_0000);
      apb_wr(ADDR_TCMP0, 32'hFFFF_FFFF, 4'hF);
      apb_rd(ADDR_TCMP0, 32'hFFFF_FFFF);
      apb_wr(ADDR_TCMP0, 32'h5555_5555, 4'hF);
      apb_rd(ADDR_TCMP0, 32'h5555_5555);
      apb_wr(ADDR_TCMP0, 32'hAAAA_AAAA, 4'hF);
      apb_rd(ADDR_TCMP0, 32'hAAAA_AAAA);
      apb_rd(ADDR_TCMP1, 32'hFFFF_FFFF);
    end
    begin : tcmp1
      u_log.sub1("TCMP1");
      reset_dut;
      apb_wr(ADDR_TCMP1, 32'h0000_0000, 4'hF);
      apb_rd(ADDR_TCMP1, 32'h0000_0000);
      apb_wr(ADDR_TCMP1, 32'hFFFF_FFFF, 4'hF);
      apb_rd(ADDR_TCMP1, 32'hFFFF_FFFF);
      apb_wr(ADDR_TCMP1, 32'h5555_5555, 4'hF);
      apb_rd(ADDR_TCMP1, 32'h5555_5555);
      apb_wr(ADDR_TCMP1, 32'hAAAA_AAAA, 4'hF);
      apb_rd(ADDR_TCMP1, 32'hAAAA_AAAA);
      apb_rd(ADDR_TCMP0, 32'hFFFF_FFFF);
    end
    begin : tier
      u_log.sub1("TIER");
      reset_dut;
      apb_wr(ADDR_TIER, 32'hFFFF_FFFF, 4'hF);
      apb_rd(ADDR_TIER, 32'h0000_0001);
      apb_wr(ADDR_TIER, 32'h0000_0000, 4'hF);
      apb_rd(ADDR_TIER, 32'h0000_0000);
      apb_wr(ADDR_TIER, 32'h5555_5555, 4'hF);
      apb_rd(ADDR_TIER, 32'h0000_0001);
      apb_wr(ADDR_TIER, 32'hAAAA_AAAA, 4'hF);
      apb_rd(ADDR_TIER, 32'h0000_0000);
    end
    begin : thcsr
      u_log.sub1("THCSR");
      reset_dut;
      apb_wr(ADDR_THCSR, 32'hFFFF_FFFF, 4'hF);
      apb_rd(ADDR_THCSR, 32'h0000_0001);                  // HALT_ACK = 0
      apb_wr(ADDR_THCSR, 32'h0000_0000, 4'hF);
      apb_rd(ADDR_THCSR, 32'h0000_0000);
      apb_wr(ADDR_THCSR, 32'h5555_5555, 4'hF);
      apb_rd(ADDR_THCSR, 32'h0000_0001);
      apb_wr(ADDR_THCSR, 32'hAAAA_AAAA, 4'hF);
      apb_rd(ADDR_THCSR, 32'h0000_0000);
    end
    begin : rejected_write
      u_log.sub1("Rejected write");
      reset_dut;
      apb_write(ADDR_TCR, 32'h0000_0000, 4'hF, 1'b0);      // 1
      apb_rd(ADDR_TCR, 32'h0000_0000);
      apb_write(ADDR_TCR, 32'hFFFF_FFFF, 4'hF, 1'b1);      // 2: DIV_VAL = 15
      apb_rd(ADDR_TCR, 32'h0000_0000);
      apb_write(ADDR_TCR, 32'h5555_5555, 4'hF, 1'b0);      // 3: TIM_EN = 1
      apb_rd(ADDR_TCR, 32'h0000_0501);
      apb_write(ADDR_TCR, 32'hAAAA_AAAA, 4'hF, 1'b1);      // 4: DIV_VAL = 10
      apb_rd(ADDR_TCR, 32'h0000_0501);
      apb_write(ADDR_TCR, 32'h5A5A_5A55, 4'hF, 1'b1);      // 5: DIV_VAL = 10
      apb_rd(ADDR_TCR, 32'h0000_0501);
    end
    end_test;
  end
