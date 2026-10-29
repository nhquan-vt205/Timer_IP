// ============================================================================
// TC_TIMER_TOP_008 - TIM_EN clear
// Objective: TIM_EN H->L clears TDR0/TDR1; a value written while
//            TIM_EN = 0 is kept and counting resumes from it.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TIM_EN clear test --");
    apb_wr(ADDR_TCR,  32'h0000_0001, 4'b0001);             // 1: e0 follows
    mark_e0;
    apb_rd(ADDR_TDR0, 32'h2);                              // 2: e0+2
    apb_wr(ADDR_TCR,  32'h0000_0000, 4'b0001);             // 3: e0+5
    apb_rd(ADDR_TDR0, 32'h0);                              // 4: e0+8
    apb_rd(ADDR_TDR1, 32'h0);                              // e0+11
    apb_wr(ADDR_TDR0, 32'h0000_0055, 4'hF);                // 5
    idle_n(5);                                             // 6
    apb_rd(ADDR_TDR0, 32'h0000_0055);
    apb_wr(ADDR_TCR,  32'h0000_0001, 4'b0001);             // 7: e1 follows
    apb_rd(ADDR_TDR0, 32'h0000_0057);                      // e1+2
    end_test;
  end
