// ============================================================================
// TC_TIMER_TOP_005 - reg_byte_access
// Objective: byte strobes write only the strobed bytes, no strobe writes
//            nothing
//   TCMP0, TDR0, TCR, TIER and THCSR
// Stimulus : the Test sequence of the VPLAN; no expected value here - u_chk
//            checks every transfer and every sample against u_model.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_005",
              "byte-strobe writes change only the strobed bytes of TCMP0, TDR0, TCR, TIER and THCSR; strobe 0b0000 writes nothing");
    u_log.item("reg_byte_access");
    begin : tcmp0
      u_log.sub1("TCMP0");
      u_log.goal("one byte at a time from the reset value, then bytes 0 and 2, then no strobe");
      reset_dut;
      apb_write(ADDR_TCMP0, 32'h1122_3344, 4'b0001);
      apb_read(ADDR_TCMP0);
      apb_write(ADDR_TCMP0, 32'h1122_3344, 4'b0010);
      apb_read(ADDR_TCMP0);
      apb_write(ADDR_TCMP0, 32'h1122_3344, 4'b0100);
      apb_read(ADDR_TCMP0);
      apb_write(ADDR_TCMP0, 32'h1122_3344, 4'b1000);
      apb_read(ADDR_TCMP0);
      apb_write(ADDR_TCMP0, 32'hAABB_CCDD, 4'b0101);
      apb_read(ADDR_TCMP0);
      apb_write(ADDR_TCMP0, 32'h0000_0000, 4'b0000);
      apb_read(ADDR_TCMP0);
    end
    begin : tdr0
      u_log.sub1("TDR0");
      u_log.goal("TIM_EN = 0: one byte at a time from 0, then bytes 1 and 3, then no strobe; TDR1 not changed");
      reset_dut;
      apb_write(ADDR_TDR0, 32'h1122_3344, 4'b0001);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TDR0, 32'h1122_3344, 4'b0010);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TDR0, 32'h1122_3344, 4'b0100);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TDR0, 32'h1122_3344, 4'b1000);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TDR0, 32'hAABB_CCDD, 4'b1010);
      apb_read(ADDR_TDR0);
      apb_write(ADDR_TDR0, 32'h0000_0000, 4'b0000);
      apb_read(ADDR_TDR0);
      apb_read(ADDR_TDR1);
    end
    begin : tcr
      u_log.sub1("TCR");
      u_log.goal("byte 1 writes only DIV_VAL, byte 0 only DIV_EN / TIM_EN, bytes 2 and 3 hold no field (no error)");
      reset_dut;
      apb_write(ADDR_TCR, 32'h0000_0302, 4'b0010);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR, 32'h0000_0802, 4'b0001);
      apb_read(ADDR_TCR);
      apb_write(ADDR_TCR, 32'hFFFF_FFFF, 4'b1100);
      apb_read(ADDR_TCR);
    end
    begin : tier_and_thcsr
      u_log.sub1("TIER and THCSR");
      u_log.goal("INT_EN and HALT_REQ are written only when byte 0 is strobed");
      reset_dut;
      apb_write(ADDR_TIER,  32'hFFFF_FFFF, 4'b1110);
      apb_read(ADDR_TIER);
      apb_write(ADDR_TIER,  32'h0000_0001, 4'b0001);
      apb_read(ADDR_TIER);
      apb_write(ADDR_THCSR, 32'hFFFF_FFFF, 4'b1110);
      apb_read(ADDR_THCSR);
      apb_write(ADDR_THCSR, 32'h0000_0001, 4'b0001);
      apb_read(ADDR_THCSR);
    end
    end_test;
  end
