// ============================================================================
// TC_TIMER_TOP_008 - apb_multiple_access
// Objective: back-to-back transfers (tim_psel kept 1), a write visible to the
//            next read
//   Consecutive writes, Consecutive reads, Alternating write and read
// Stimulus : the Test sequence of the VPLAN; no expected value here - u_chk
//            checks every transfer and every sample against u_model.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_008",
              "back-to-back APB writes and reads, each with one wait cycle; a read right after a write returns the new value");
    u_log.item("apb_multiple_access");
    begin : consecutive_writes
      u_log.sub1("Consecutive writes");
      u_log.goal("four back-to-back writes, one wait cycle each, then every register read back (TIM_EN = 0)");
      reset_dut;
      apb_write(ADDR_TCMP0, 32'h1111_1111, 4'b1111);
      apb_write(ADDR_TCMP1, 32'h2222_2222, 4'b1111);
      apb_write(ADDR_TDR0,  32'h3333_3333, 4'b1111);
      apb_write(ADDR_TDR1,  32'h4444_4444, 4'b1111);
      wait_cycles(2);
      apb_read(ADDR_TCMP0);
      apb_read(ADDR_TCMP1);
      apb_read(ADDR_TDR0);
      apb_read(ADDR_TDR1);
    end
    begin : consecutive_reads
      u_log.sub1("Consecutive reads");
      u_log.goal("eight back-to-back reads: each value only in the last access cycle of its read, 0 in setup and wait");
      reset_dut;
      apb_write(ADDR_TCMP0, 32'hA5A5_A5A5, 4'b1111);
      apb_write(ADDR_TIER,  32'h0000_0001, 4'b1111);
      read_all_regs;
    end
    begin : alternating_write_and_read
      u_log.sub1("Alternating write and read");
      u_log.goal("write / read back-to-back: the read returns the value just written; a TCMP1 write leaves TCMP0");
      reset_dut;
      apb_write(ADDR_TCMP0, 32'h0000_00AA, 4'b1111);
      apb_read(ADDR_TCMP0);
      apb_write(ADDR_TCMP0, 32'h0000_0055, 4'b1111);
      apb_read(ADDR_TCMP0);
      apb_write(ADDR_TCMP1, 32'h1234_5678, 4'b1111);
      apb_read(ADDR_TCMP0);
      apb_read(ADDR_TCMP1);
    end
    end_test;
  end
