// ============================================================================
// TC_TIMER_TOP_001 - reg_init_chk
// Objective: reset value of every register and output, and the asynchronous
//            reset while counting with a pending interrupt
//   Reset value check, Reset during operation (two levels)
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("reg_init_chk");
    begin : reset_value_check
      u_log.sub1("Reset value check");
      reset_dut;
      // Step 1: 2 cycles in reset, outputs checked without a clock edge
      u_clk_rst.assert_reset;
      u_chk.expect_reset_out("rst_n_0_cycle_1");
      u_chk.expect_reset_out("rst_n_0_cycle_2");
      u_clk_rst.release_reset;
      // Step 2: every register
      read_reset_values;
      // Step 3: TIM_EN = 0, no counting
      u_drv.idle(4);
      apb_rd(ADDR_TDR0, 32'h0);
    end
    begin : reset_during_operation
      u_log.sub1("Reset during operation");
      reset_dut;
      // Step 1: compare value 2, interrupt enabled, counting
      apb_wr(ADDR_TCMP0, 32'h2, 4'hF);
      apb_wr(ADDR_TCMP1, 32'h0, 4'hF);
      apb_wr(ADDR_TIER,  32'h1, 4'hF);
      apb_wr(ADDR_TCR,   32'h0000_0001, 4'b0001);            // e0 follows
      u_chk.mark_e0;
      // Step 2: e0 .. e0+4, tim_int = 1 from e0+3
      u_drv.idle(5);
      for (i = 0; i <= 4; i = i + 1) begin
        u_chk.expect_int_at(i, (i >= 3));
      end
      // Step 3: asynchronous reset after the cycle e0+4, 2 cycles
      u_clk_rst.assert_reset;
      u_chk.expect_reset_out("rst_n_0_no_clock_edge");
      u_chk.expect_reset_out("rst_n_0_cycle_2");
      u_clk_rst.release_reset;
      // Step 4: reset values again
      read_reset_values;
      // Step 5
      u_drv.idle(4);
      apb_rd(ADDR_TDR0, 32'h0);
    end
    end_test;
  end
