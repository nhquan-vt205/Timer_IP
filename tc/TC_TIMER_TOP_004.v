// ============================================================================
// TC_TIMER_TOP_004 - reg_1hot_chk
// Objective: every bit of every RW field written and read alone (walking
//            one), back-to-back transfers
//   TDR0, TDR1, TCMP0, TCMP1, Control bits
// Stimulus : the Test sequence of the VPLAN; no expected value here - u_chk
//            checks every transfer and every sample against u_model. The
//            loop index i is declared in tb_timer_top.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_004",
              "walking one through TDR0, TDR1, TCMP0, TCMP1 and every control bit of TCR, TIER, THCSR");
    u_log.item("reg_1hot_chk");
    begin : tdr0
      u_log.sub1("TDR0");
      u_log.goal("walking one in TDR0 (TIM_EN = 0), back-to-back: each read shows only the written bit; TDR1 not changed");
      reset_dut;
      for (i = 0; i < 32; i = i + 1) begin
        apb_write(ADDR_TDR0, 32'h0000_0001 << i, 4'b1111);
        apb_read(ADDR_TDR0);
      end
      apb_read(ADDR_TDR1);
    end
    begin : tdr1
      u_log.sub1("TDR1");
      u_log.goal("walking one in TDR1 (TIM_EN = 0), back-to-back: each read shows only the written bit; TDR0 not changed");
      reset_dut;
      for (i = 0; i < 32; i = i + 1) begin
        apb_write(ADDR_TDR1, 32'h0000_0001 << i, 4'b1111);
        apb_read(ADDR_TDR1);
      end
      apb_read(ADDR_TDR0);
    end
    begin : tcmp0
      u_log.sub1("TCMP0");
      u_log.goal("walking one in TCMP0, back-to-back: each read shows only the written bit; TCMP1 not changed");
      reset_dut;
      for (i = 0; i < 32; i = i + 1) begin
        apb_write(ADDR_TCMP0, 32'h0000_0001 << i, 4'b1111);
        apb_read(ADDR_TCMP0);
      end
      apb_read(ADDR_TCMP1);
    end
    begin : tcmp1
      u_log.sub1("TCMP1");
      u_log.goal("walking one in TCMP1, back-to-back: each read shows only the written bit; TCMP0 not changed");
      reset_dut;
      for (i = 0; i < 32; i = i + 1) begin
        apb_write(ADDR_TCMP1, 32'h0000_0001 << i, 4'b1111);
        apb_read(ADDR_TCMP1);
      end
      apb_read(ADDR_TCMP0);
    end
    begin : control_bits
      u_log.sub1("Control bits");
      u_log.goal("each DIV_VAL bit alone (byte 1), then DIV_EN, TIM_EN (byte 0, TIM_EN = 0 before: no error), INT_EN, HALT_REQ");
      reset_dut;
      for (i = 0; i < 4; i = i + 1) begin
        apb_write(ADDR_TCR, 32'h0000_0100 << i, 4'b0010);
        apb_read(ADDR_TCR);
      end
      apb_write(ADDR_TCR,   32'h0000_0002, 4'b0001);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR,   32'h0000_0001, 4'b0001);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TIER,  32'h0000_0001, 4'b1111);
      apb_read(ADDR_TIER);
      apb_write(ADDR_THCSR, 32'h0000_0001, 4'b1111);
      apb_read(ADDR_THCSR);
    end
    end_test;
  end
