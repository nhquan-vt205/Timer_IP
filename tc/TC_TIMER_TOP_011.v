// ============================================================================
// TC_TIMER_TOP_011 - Debug halt
// Objective: dbg_mode & HALT_REQ freezes the counter and the
//            divider, HALT_ACK reads back; no halt when dbg_mode = 0.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Debug halt test --");
    // Part A: dbg_mode = 1 from the start
    dbg_val = 1'b1;
    apb_wr(ADDR_TCR,   32'h0000_0102, 4'b0011);            // 1: DIV_VAL = 1, /2
    apb_wr(ADDR_TCR,   32'h0000_0103, 4'b0011);
    mark_e0;
    apb_wr(ADDR_THCSR, 32'h1, 4'hF);                       // 2: e0+2
    apb_rd(ADDR_THCSR, 32'h0000_0003);                     // 3: e0+5
    apb_rd(ADDR_TDR0,  32'h1);                             // e0+8
    apb_wr(ADDR_THCSR, 32'h0, 4'hF);                       // 4: e0+11
    apb_rd(ADDR_TDR0,  32'h2);                             // 5: e0+14
    apb_rd(ADDR_TDR0,  32'h4);                             // e0+17
    apb_rd(ADDR_THCSR, 32'h0);                             // e0+20
    // Part B: no debug mode
    apb_wr(ADDR_TCR,   32'h0000_0102, 4'b0001);            // 6: TIM_EN = 0
    dbg_val = 1'b0;                                        // applied with step 7
    apb_wr(ADDR_THCSR, 32'h1, 4'hF);                       // 7
    apb_wr(ADDR_TCR,   32'h0000_0103, 4'b0001);            // 8: e1 follows
    apb_rd(ADDR_THCSR, 32'h0000_0001);                     // e1+2
    apb_rd(ADDR_TDR0,  32'h2);                             // e1+5
    end_test;
  end
