// ============================================================================
// TC_TIMER_TOP_011 - interrupt_chk
// Objective: compare match sets INT_ST one cycle later, tim_int = INT_ST &
//            INT_EN, masking keeps INT_ST, write-1 clear, set again while the
//            compare stays true
//   Set, mask and clear : match while counting, mask / unmask, write 0 / 1
//   Continuous match    : TIM_EN = 0, cnt = 0 = {TCMP1, TCMP0}
// Stimulus : the Test sequence of the VPLAN; no expected value here - u_chk
//            watches tim_int in every sample and checks every transfer
//            against u_model; checkpoints mark the moments of the VPLAN.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_011",
              "interrupt through timer_top: INT_ST set one cycle after cnt == {TCMP1, TCMP0}, tim_int = INT_ST & INT_EN, RW1C clear, continuous match");
    u_log.item("interrupt_chk");
    begin : set_mask_and_clear
      u_log.sub1("Set, mask and clear");
      u_log.goal("compare value 16 while counting: INT_ST set, counter keeps counting; INT_EN 0 masks tim_int and keeps INT_ST; writing 0 does nothing, writing 1 clears");
      reset_dut;
      apb_write(ADDR_TCMP0, 32'h0000_0010, 4'b1111);
      apb_write(ADDR_TCMP1, 32'h0000_0000, 4'b1111);
      apb_write(ADDR_TIER,  32'h0000_0001, 4'b1111);
      apb_write(ADDR_TCR,   32'h0000_0001, 4'b0001);    // TIM_EN = 1, e0 follows
      wait_cycles(20);                                  // e0 .. e0+19
      u_chk.checkpoint("after the compare match");
      apb_read(ADDR_TISR);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TIER,  32'h0000_0000, 4'b1111);    // mask
      apb_read(ADDR_TISR);
      u_chk.checkpoint("masked by INT_EN = 0");
      apb_write(ADDR_TIER,  32'h0000_0001, 4'b1111);    // unmask
      apb_write(ADDR_TISR,  32'h0000_0000, 4'b0001);    // write 0
      apb_read(ADDR_TISR);
      u_chk.checkpoint("after writing 0 to INT_ST");
      apb_write(ADDR_TISR,  32'h0000_0001, 4'b0001);    // write 1
      apb_read(ADDR_TISR);
      u_chk.checkpoint("after writing 1 to INT_ST");
    end
    begin : continuous_match
      u_log.sub1("Continuous match");
      u_log.goal("TIM_EN = 0, cnt = 0: compare value 0 sets INT_ST, a clear is followed by a new set while cnt == compare; after the compare changes the clear holds");
      reset_dut;
      apb_write(ADDR_TIER,  32'h0000_0001, 4'b1111);
      apb_write(ADDR_TCMP0, 32'h0000_0000, 4'b1111);
      apb_write(ADDR_TCMP1, 32'h0000_0000, 4'b1111);    // c1
      apb_read(ADDR_TISR);
      apb_write(ADDR_TISR,  32'h0000_0001, 4'b0001);    // c2
      apb_read(ADDR_TISR);
      u_chk.checkpoint("compare still true after the clear");
      apb_write(ADDR_TCMP0, 32'h0000_0010, 4'b1111);
      apb_read(ADDR_TISR);
      apb_write(ADDR_TISR,  32'h0000_0001, 4'b0001);    // c3
      apb_read(ADDR_TISR);
      u_chk.checkpoint("cleared without a match");
    end
    end_test;
  end
