// ============================================================================
// TC_TIMER_TOP_008 - apb_multiple_access
// Objective: back-to-back transfers (tim_psel held at 1); a write is visible
//            to the next read
//   Consecutive writes, Consecutive reads, Alternating write and read
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("apb_multiple_access");
    begin : consecutive_writes
      u_log.sub1("Consecutive writes");
      reset_dut;
      apb_wr(ADDR_TCMP0, 32'h1111_1111, 4'hF);             // 1
      apb_wr(ADDR_TCMP1, 32'h2222_2222, 4'hF);
      apb_wr(ADDR_TDR0,  32'h3333_3333, 4'hF);
      apb_wr(ADDR_TDR1,  32'h4444_4444, 4'hF);
      u_drv.idle(2);                                       // 2
      apb_rd(ADDR_TCMP0, 32'h1111_1111);                   // 3
      apb_rd(ADDR_TCMP1, 32'h2222_2222);
      apb_rd(ADDR_TDR0,  32'h3333_3333);
      apb_rd(ADDR_TDR1,  32'h4444_4444);
    end
    begin : consecutive_reads
      u_log.sub1("Consecutive reads");
      reset_dut;
      apb_wr(ADDR_TCMP0, 32'hA5A5_A5A5, 4'hF);             // 1
      apb_wr(ADDR_TIER,  32'h1, 4'hF);
      apb_rd(ADDR_TCR,   32'h0000_0100);                   // 2
      apb_rd(ADDR_TDR0,  32'h0);
      apb_rd(ADDR_TDR1,  32'h0);
      apb_rd(ADDR_TCMP0, 32'hA5A5_A5A5);
      apb_rd(ADDR_TCMP1, 32'hFFFF_FFFF);
      apb_rd(ADDR_TIER,  32'h1);
      apb_rd(ADDR_TISR,  32'h0);
      apb_rd(ADDR_THCSR, 32'h0);
    end
    begin : alternating_write_and_read
      u_log.sub1("Alternating write and read");
      reset_dut;
      apb_wr(ADDR_TCMP0, 32'h0000_00AA, 4'hF);
      apb_rd(ADDR_TCMP0, 32'h0000_00AA);
      apb_wr(ADDR_TCMP0, 32'h0000_0055, 4'hF);
      apb_rd(ADDR_TCMP0, 32'h0000_0055);
      apb_wr(ADDR_TCMP1, 32'h1234_5678, 4'hF);
      apb_rd(ADDR_TCMP0, 32'h0000_0055);
      apb_rd(ADDR_TCMP1, 32'h1234_5678);
    end
    end_test;
  end
