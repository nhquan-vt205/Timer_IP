// ============================================================================
// TC_TIMER_TOP_013 - apb_pslverr_chk
// Objective: TCR error response (conditions 1-3 of the register map) only in
//            the last access cycle of a rejected write, whole write
//            discarded; TIM_EN clear with legal fields
//   (one-level Item, no sub item)
// Stimulus : the Test sequence of the VPLAN; no expected value here - u_chk
//            checks every response (tim_pslverr, wait cycles) and every
//            sample against u_model.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_013",
              "TCR error response: DIV_VAL > 8, DIV_VAL / DIV_EN change while TIM_EN = 1; the rejected write changes no bit, the counter keeps counting");
    u_log.item("apb_pslverr_chk");
    u_log.goal("tim_pslverr = 1 only in the last access of a rejected TCR write, never for a read; a legal write clears TIM_EN and the counter");
    reset_dut;
    apb_write(ADDR_TCR, 32'h0000_0101, 4'b0011);        // TIM_EN = 1, e0 follows
    apb_write(ADDR_TCR, 32'h0000_0901, 4'b0011);
    apb_write(ADDR_TCR, 32'h0000_0103, 4'b0001);
    apb_write(ADDR_TCR, 32'h0000_0201, 4'b0010);
    apb_write(ADDR_TCR, 32'h0000_0200, 4'b0011);
    apb_read(ADDR_TCR);
    apb_read(ADDR_TDR0);
    apb_write(ADDR_TCR, 32'h0000_0100, 4'b0011);
    apb_write(ADDR_TCR, 32'h0000_0F00, 4'b0010);
    apb_write(ADDR_TCR, 32'h0000_0302, 4'b0011);
    apb_read(ADDR_TCR);
    apb_read(ADDR_TDR0);
    end_test;
  end
