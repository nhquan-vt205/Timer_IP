// ============================================================================
// TC_TIMER_TOP_002 - reg_rw_chk
// Objective: read/write of every RW field through APB, reserved bits read 0,
//            TCR error response with the whole write discarded
//   TCR, TDR0, TDR1, TCMP0, TCMP1, TIER, THCSR, Rejected write
// Stimulus : the Test sequence of the VPLAN; no expected value here - u_chk
//            checks every transfer and every sample against u_model.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_002",
              "read/write of every RW register field, reserved bits read 0, rejected TCR writes change no bit");
    u_log.item("reg_rw_chk");
    begin : tcr
      u_log.sub1("TCR");
      u_log.goal("DIV_VAL, DIV_EN, TIM_EN read back as written, reserved bits 31:12 and 7:2 read 0; no error while DIV_VAL <= 8 and DIV_EN / DIV_VAL kept with TIM_EN = 1");
      reset_dut;
      apb_write(ADDR_TCR, 32'h0000_0802, 4'b1111);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR, 32'h0000_0000, 4'b1111);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR, 32'hFFFF_F5FE, 4'b1111);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR, 32'h0000_0503, 4'b1111);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR, 32'h0000_0502, 4'b1111);
      apb_read(ADDR_TCR);
    end
    begin : tdr0
      u_log.sub1("TDR0");
      u_log.goal("TDR0 (TIM_EN = 0) reads back all-0, all-1 and alternating patterns; TDR1 not changed");
      reset_dut;
      apb_write(ADDR_TDR0, 32'h0000_0000, 4'b1111);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TDR0, 32'hFFFF_FFFF, 4'b1111);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TDR0, 32'h5555_5555, 4'b1111);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TDR0, 32'hAAAA_AAAA, 4'b1111);
      apb_read(ADDR_TDR0);
      apb_read(ADDR_TDR1);
    end
    begin : tdr1
      u_log.sub1("TDR1");
      u_log.goal("TDR1 (TIM_EN = 0) reads back all-0, all-1 and alternating patterns; TDR0 not changed");
      reset_dut;
      apb_write(ADDR_TDR1, 32'h0000_0000, 4'b1111);
      apb_read(ADDR_TDR1);
      apb_write(ADDR_TDR1, 32'hFFFF_FFFF, 4'b1111);
      apb_read(ADDR_TDR1);
      apb_write(ADDR_TDR1, 32'h5555_5555, 4'b1111);
      apb_read(ADDR_TDR1);
      apb_write(ADDR_TDR1, 32'hAAAA_AAAA, 4'b1111);
      apb_read(ADDR_TDR1);
      apb_read(ADDR_TDR0);
    end
    begin : tcmp0
      u_log.sub1("TCMP0");
      u_log.goal("TCMP0 reads back all-0, all-1 and alternating patterns; TCMP1 not changed");
      reset_dut;
      apb_write(ADDR_TCMP0, 32'h0000_0000, 4'b1111);
      apb_read(ADDR_TCMP0);
      apb_write(ADDR_TCMP0, 32'hFFFF_FFFF, 4'b1111);
      apb_read(ADDR_TCMP0);
      apb_write(ADDR_TCMP0, 32'h5555_5555, 4'b1111);
      apb_read(ADDR_TCMP0);
      apb_write(ADDR_TCMP0, 32'hAAAA_AAAA, 4'b1111);
      apb_read(ADDR_TCMP0);
      apb_read(ADDR_TCMP1);
    end
    begin : tcmp1
      u_log.sub1("TCMP1");
      u_log.goal("TCMP1 reads back all-0, all-1 and alternating patterns; TCMP0 not changed");
      reset_dut;
      apb_write(ADDR_TCMP1, 32'h0000_0000, 4'b1111);
      apb_read(ADDR_TCMP1);
      apb_write(ADDR_TCMP1, 32'hFFFF_FFFF, 4'b1111);
      apb_read(ADDR_TCMP1);
      apb_write(ADDR_TCMP1, 32'h5555_5555, 4'b1111);
      apb_read(ADDR_TCMP1);
      apb_write(ADDR_TCMP1, 32'hAAAA_AAAA, 4'b1111);
      apb_read(ADDR_TCMP1);
      apb_read(ADDR_TCMP0);
    end
    begin : tier
      u_log.sub1("TIER");
      u_log.goal("only INT_EN (bit 0) is stored, bits 31:1 read 0");
      reset_dut;
      apb_write(ADDR_TIER, 32'hFFFF_FFFF, 4'b1111);
      apb_read(ADDR_TIER);
      apb_write(ADDR_TIER, 32'h0000_0000, 4'b1111);
      apb_read(ADDR_TIER);
      apb_write(ADDR_TIER, 32'h5555_5555, 4'b1111);
      apb_read(ADDR_TIER);
      apb_write(ADDR_TIER, 32'hAAAA_AAAA, 4'b1111);
      apb_read(ADDR_TIER);
    end
    begin : thcsr
      u_log.sub1("THCSR");
      u_log.goal("only HALT_REQ (bit 0) is stored, HALT_ACK = dbg_mode & HALT_REQ with dbg_mode = 0, bits 31:2 read 0");
      reset_dut;
      apb_write(ADDR_THCSR, 32'hFFFF_FFFF, 4'b1111);
      apb_read(ADDR_THCSR);
      apb_write(ADDR_THCSR, 32'h0000_0000, 4'b1111);
      apb_read(ADDR_THCSR);
      apb_write(ADDR_THCSR, 32'h5555_5555, 4'b1111);
      apb_read(ADDR_THCSR);
      apb_write(ADDR_THCSR, 32'hAAAA_AAAA, 4'b1111);
      apb_read(ADDR_THCSR);
    end
    begin : rejected_write
      u_log.sub1("Rejected write");
      u_log.goal("TCR write with DIV_VAL > 8, or a DIV_VAL / DIV_EN change while TIM_EN = 1: tim_pslverr = 1 and no bit written (TIM_EN of the same write included)");
      reset_dut;
      apb_write(ADDR_TCR, 32'h0000_0000, 4'b1111);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR, 32'hFFFF_FFFF, 4'b1111);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR, 32'h5555_5555, 4'b1111);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR, 32'hAAAA_AAAA, 4'b1111);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR, 32'h5A5A_5A55, 4'b1111);
      apb_read(ADDR_TCR);
    end
    end_test;
  end
