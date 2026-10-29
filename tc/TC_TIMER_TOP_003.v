// ============================================================================
// TC_TIMER_TOP_003 - TCR error response
// Objective: forbidden TCR writes give tim_pslverr = 1 in the last
//            access cycle and the whole transfer is discarded.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TCR error response test --");
    apb_wr(ADDR_TCR, 32'h0000_0101, 4'b0011);              // 1: TIM_EN = 1
    mark_e0;
    apb_write(ADDR_TCR, 32'h0000_0901, 4'b0011, 1'b1);     // 2: DIV_VAL = 9
    apb_write(ADDR_TCR, 32'h0000_0103, 4'b0001, 1'b1);     // 3: DIV_EN change
    apb_write(ADDR_TCR, 32'h0000_0201, 4'b0010, 1'b1);     // 4: DIV_VAL change
    apb_write(ADDR_TCR, 32'h0000_0200, 4'b0011, 1'b1);     // 5: TIM_EN clear discarded
    apb_rd(ADDR_TCR,  32'h0000_0101);                      // 6
    apb_rd(ADDR_TDR0, 32'h0000_0011);                      // 7: e0+17, still counting
    apb_wr(ADDR_TCR, 32'h0000_0100, 4'b0011);              // 8: clear TIM_EN only
    apb_write(ADDR_TCR, 32'h0000_0F00, 4'b0010, 1'b1);     // 9: DIV_VAL = 15
    apb_wr(ADDR_TCR, 32'h0000_0302, 4'b0011);              // 10
    apb_rd(ADDR_TCR,  32'h0000_0302);                      // 11
    apb_rd(ADDR_TDR0, 32'h0);
    end_test;
  end
