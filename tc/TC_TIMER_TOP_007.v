// ============================================================================
// TC_TIMER_TOP_007 - TDR write with divider
// Objective: a TDR write while DIV_EN = 1 overwrites cnt and keeps
//            the divider phase div_cnt (no reset).
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TDR write with divider test --");
    apb_wr(ADDR_TCR, 32'h0000_0202, 4'b0011);              // 1: DIV_VAL = 2, /4
    apb_wr(ADDR_TCR, 32'h0000_0203, 4'b0011);
    mark_e0;
    apb_wr(ADDR_TDR0, 32'h0000_0100, 4'hF);                // 2: e0+2, div_cnt = 2
    apb_rd(ADDR_TDR0, 32'h0000_0101);                      // 3: e0+5
    apb_rd(ADDR_TDR0, 32'h0000_0102);                      // e0+8
    apb_wr(ADDR_TDR0, 32'h0000_0200, 4'hF);                // 4: e0+11, div_cnt = 3
    apb_rd(ADDR_TDR0, 32'h0000_0200);                      // 5: e0+14
    apb_rd(ADDR_TDR0, 32'h0000_0201);                      // e0+17
    apb_wr(ADDR_TDR1, 32'h0000_0001, 4'hF);                // 6: e0+20
    apb_rd(ADDR_TDR1, 32'h0000_0001);                      // 7: e0+23
    apb_rd(ADDR_TDR0, 32'h0000_0203);                      // e0+26
    end_test;
  end
