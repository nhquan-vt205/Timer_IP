// ============================================================================
// TC_TIMER_TOP_012 - cnt_halt_chk
// Objective: debug halt seen through timer_top: halted = dbg_mode &
//            THCSR.HALT_REQ holds the counter and the divider position;
//            HALT_ACK reads the halt; no TDR write while halted (TIM_EN = 1)
//   Halt in debug mode      : dbg_mode = 1, HALT_REQ 1 halts, 0 resumes
//   Halt without debug mode : HALT_REQ = 1 with dbg_mode = 0 does not halt
//   TDR write while halted
// Stimulus : the Test sequence of the VPLAN (dbg_mode set in the cycle
//            after the reset release, before TIM_EN = 1, OPEN-001); no
//            expected value here - u_chk checks every transfer and every
//            sample against u_model.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_012",
              "cnt_ctrl debug halt through timer_top: dbg_mode & HALT_REQ holds counter and divider, HALT_ACK, TDR writes ignored while halted");
    u_log.item("cnt_halt_chk");
    begin : halt_in_debug_mode
      u_log.sub1("Halt in debug mode");
      u_log.goal("dbg_mode = 1, DIV_VAL 1 (1 step / 2 cycles): HALT_REQ = 1 halts (TDR0 and divider position held, HALT_ACK = 1); HALT_REQ = 0 resumes");
      reset_dut;
      set_dbg_mode(1'b1);
      apb_write(ADDR_TCR,   32'h0000_0102, 4'b0011);
      apb_write(ADDR_TCR,   32'h0000_0103, 4'b0011);   // TIM_EN = 1, e0 follows
      apb_write(ADDR_THCSR, 32'h0000_0001, 4'b1111);   // HALT_REQ = 1
      apb_read(ADDR_THCSR);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_THCSR, 32'h0000_0000, 4'b1111);   // HALT_REQ = 0
      apb_read(ADDR_TDR0);
      apb_read(ADDR_TDR0);
      apb_read(ADDR_THCSR);
    end
    begin : halt_without_debug_mode
      u_log.sub1("Halt without debug mode");
      u_log.goal("dbg_mode = 0: HALT_REQ = 1 is stored, HALT_ACK = 0 and the counter keeps counting (DIV_EN 1, DIV_VAL 1)");
      reset_dut;
      apb_write(ADDR_TCR,   32'h0000_0002, 4'b0001);   // DIV_EN = 1
      apb_write(ADDR_THCSR, 32'h0000_0001, 4'b1111);   // HALT_REQ = 1
      apb_write(ADDR_TCR,   32'h0000_0003, 4'b0001);   // TIM_EN = 1, e0 follows
      apb_read(ADDR_THCSR);
      apb_read(ADDR_TDR0);
    end
    begin : tdr_write_while_halted
      u_log.sub1("TDR write while halted");
      u_log.goal("dbg_mode = 1, DIV_EN 0: halted with TIM_EN = 1, a TDR0 write completes without error but is ignored");
      reset_dut;
      set_dbg_mode(1'b1);
      apb_write(ADDR_TCR,   32'h0000_0001, 4'b0001);   // TIM_EN = 1, e0 follows
      apb_write(ADDR_THCSR, 32'h0000_0001, 4'b1111);   // HALT_REQ = 1
      apb_write(ADDR_TDR0,  32'h0000_0077, 4'b1111);
      apb_read(ADDR_TDR0);
      apb_read(ADDR_THCSR);
    end
    end_test;
  end
