// ============================================================================
// TC_TIMER_TOP_010 - cnt_counting_chk
// Objective: counting every cycle with the default divider setting, software
//            load of TDR0/TDR1 and the carry from TDR0 into TDR1
//   Default mode, TDR load and carry
// Stimulus : the Test sequence of the VPLAN; no expected value here - u_chk
//            checks every transfer and every sample against u_model.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_010",
              "64-bit counter through timer_top: one count per cycle with DIV_EN 0, TDR load while stopped, carry TDR0 -> TDR1, TDR write ignored while counting");
    u_log.item("cnt_counting_chk");
    begin : default_mode
      u_log.sub1("Default mode");
      u_log.goal("TIM_EN = 1 with DIV_EN 0 (reset value): one count per cycle, the cycles of the APB reads included; DIV_VAL keeps its reset value");
      reset_dut;
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TCR, 32'h0000_0001, 4'b0001);      // TIM_EN = 1, e0 follows
      apb_read(ADDR_TDR0);
      apb_read(ADDR_TDR0);
      apb_read(ADDR_TDR0);
      apb_read(ADDR_TDR1);
      apb_read(ADDR_TCR);
    end
    begin : tdr_load_and_carry
      u_log.sub1("TDR load and carry");
      u_log.goal("TDR0/TDR1 loaded while TIM_EN = 0 (byte 0 only once), counting from 0xFFFFFFFE carries into TDR1; a TDR0 write while counting is ignored");
      reset_dut;
      apb_write(ADDR_TDR0, 32'hFFFF_FFF0, 4'b1111);
      apb_write(ADDR_TDR1, 32'h0000_0001, 4'b1111);
      apb_read(ADDR_TDR0);
      apb_read(ADDR_TDR1);
      apb_write(ADDR_TDR0, 32'h0000_00AB, 4'b0001);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TDR0, 32'hFFFF_FFFE, 4'b1111);
      apb_write(ADDR_TDR1, 32'h0000_0000, 4'b1111);
      apb_write(ADDR_TCR,  32'h0000_0001, 4'b0001);     // TIM_EN = 1, e0 follows
      apb_read(ADDR_TDR0);
      apb_read(ADDR_TDR1);
      apb_write(ADDR_TDR0, 32'h0000_1000, 4'b1111);     // TIM_EN = 1
      apb_read(ADDR_TDR0);
      apb_read(ADDR_TDR1);
    end
    end_test;
  end
