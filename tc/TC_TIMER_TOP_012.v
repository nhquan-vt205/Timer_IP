// ============================================================================
// TC_TIMER_TOP_012 - cnt_halt_chk
// Objective: dbg_mode & HALT_REQ freezes the counter and the divider and
//            HALT_ACK reads 1; HALT_REQ without dbg_mode does not halt; no
//            TDR write while halted (TIM_EN = 1)
//   Halt in debug mode, Halt without debug mode, TDR write while halted
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("cnt_halt_chk");
    begin : halt_in_debug_mode
      u_log.sub1("Halt in debug mode");
      reset_dut;
      u_drv.set_dbg_mode(1'b1);                            // first cycle after reset
      apb_wr(ADDR_TCR,   32'h0000_0102, 4'b0011);          // 1: DIV_VAL = 1, /2
      apb_wr(ADDR_TCR,   32'h0000_0103, 4'b0011);          // e0 follows
      apb_wr(ADDR_THCSR, 32'h1, 4'hF);                     // 2: e0+2
      apb_rd(ADDR_THCSR, 32'h0000_0003);                   // 3: e0+5
      apb_rd(ADDR_TDR0,  32'h1);                           // e0+8
      apb_wr(ADDR_THCSR, 32'h0, 4'hF);                     // 4: e0+11
      apb_rd(ADDR_TDR0,  32'h2);                           // 5: e0+14
      apb_rd(ADDR_TDR0,  32'h4);                           // e0+17
      apb_rd(ADDR_THCSR, 32'h0);                           // e0+20
    end
    begin : halt_without_debug_mode
      u_log.sub1("Halt without debug mode");
      reset_dut;                                           // dbg_mode = 0
      apb_wr(ADDR_TCR,   32'h0000_0002, 4'b0001);          // 1: DIV_EN = 1, DIV_VAL = 1
      apb_wr(ADDR_THCSR, 32'h1, 4'hF);                     // 2
      apb_wr(ADDR_TCR,   32'h0000_0003, 4'b0001);          // 3: e0 follows
      apb_rd(ADDR_THCSR, 32'h0000_0001);                   // 4: e0+2
      apb_rd(ADDR_TDR0,  32'h2);                           // e0+5
    end
    begin : tdr_write_while_halted
      u_log.sub1("TDR write while halted");
      reset_dut;
      u_drv.set_dbg_mode(1'b1);                            // first cycle after reset
      apb_wr(ADDR_TCR,   32'h0000_0001, 4'b0001);          // 1: e0 follows
      apb_wr(ADDR_THCSR, 32'h1, 4'hF);                     // 2: e0+2
      apb_wr(ADDR_TDR0,  32'h0000_0077, 4'hF);             // 3: e0+5, ignored
      apb_rd(ADDR_TDR0,  32'h0000_0003);                   // 4: e0+8
      apb_rd(ADDR_THCSR, 32'h0000_0003);                   // e0+11
    end
    end_test;
  end
