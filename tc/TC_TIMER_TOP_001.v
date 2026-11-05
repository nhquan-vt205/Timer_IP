// ============================================================================
// TC_TIMER_TOP_001 - reg_init_chk
// Objective: reset value of every register and output, and the asynchronous
//            reset while counting with a pending interrupt
//   Reset value check      : reset, every register, no counting
//   Reset during operation : counting with tim_int = 1, reset asserted
//                            mid-cycle (no clock edge before the sample),
//                            every register back to its reset value
// Stimulus : the Test sequence of the VPLAN; no expected value here - u_chk
//            checks every transfer and every sample against u_model.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_001",
              "reset value of every register and output, asynchronous reset while counting with a pending interrupt");
    u_log.item("reg_init_chk");
    begin : reset_value_check
      u_log.sub1("Reset value check");
      u_log.goal("sys_rst_n = 0 for 2 cycles: outputs 0 in reset, every register reads its reset value, no counting with TIM_EN = 0");
      reset_dut;
      read_all_regs;
      wait_cycles(4);
      apb_read(ADDR_TDR0);
    end
    begin : reset_during_operation
      u_log.sub1("Reset during operation");
      u_log.goal("counting up to the compare value 2 with INT_EN = 1, then sys_rst_n = 0 mid-cycle: outputs 0 without a clock edge, registers back to reset values");
      reset_dut;
      apb_write(ADDR_TCMP0, 32'h0000_0002, 4'b1111);
      apb_write(ADDR_TCMP1, 32'h0000_0000, 4'b1111);
      apb_write(ADDR_TIER,  32'h0000_0001, 4'b1111);
      apb_write(ADDR_TCR,   32'h0000_0001, 4'b0001);    // TIM_EN = 1, e0 follows
      wait_cycles(5);                                   // e0 .. e0+4
      u_chk.checkpoint("before the reset");
      reset_mid_cycle;
      u_chk.checkpoint("right after sys_rst_n = 0, no rising edge");
      release_reset;
      read_all_regs;
      wait_cycles(4);
      apb_read(ADDR_TDR0);
    end
    end_test;
  end
