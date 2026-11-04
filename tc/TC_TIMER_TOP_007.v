// ============================================================================
// TC_TIMER_TOP_007 - apb_protocol_chk
// Objective: APB write/read with one wait state, read data only in the last
//            access cycle, and an undriven (X) bus while idle
//   Write transfer, Read transfer, Undriven bus while idle (two levels)
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("apb_protocol_chk");
    begin : write_transfer
      u_log.sub1("Write transfer");
      reset_dut;
      apb_wr(ADDR_TCMP0, 32'h1234_5678, 4'hF);             // 1
      u_drv.idle(2);                                       // 2
      apb_rd(ADDR_TCMP0, 32'h1234_5678);                   // 3
    end
    begin : read_transfer
      u_log.sub1("Read transfer");
      reset_dut;
      apb_rd(ADDR_TCMP1, 32'hFFFF_FFFF);                   // 1
      u_drv.idle(1);                                       // 2
      apb_rd(ADDR_TCR, 32'h0000_0100);                     // 3
    end
    begin : undriven_bus_while_idle
      u_log.sub1("Undriven bus while idle");
      reset_dut;
      u_drv.set_idle_x(1'b1);
      u_drv.idle(3);                                       // 1
      apb_rd(ADDR_TCR,  32'h0000_0100);                    // 2
      u_drv.idle(2);
      apb_rd(ADDR_TDR0, 32'h0);
      u_drv.idle(2);
      apb_rd(ADDR_TDR1, 32'h0);
      u_drv.idle(2);
      apb_rd(ADDR_TISR, 32'h0);
      u_drv.idle(2);                                       // 3
      apb_wr(ADDR_TDR0, 32'h1111_1111, 4'b0001);
      u_drv.idle(2);
      apb_rd(ADDR_TDR0, 32'h0000_0011);
      u_drv.idle(2);                                       // 4
      apb_wr(ADDR_TCMP0, 32'h5555_5555, 4'hF);
      u_drv.idle(2);
      apb_wr(ADDR_TCMP1, 32'h6666_6666, 4'hF);
      u_drv.idle(2);
      apb_rd(ADDR_TCMP0, 32'h5555_5555);
      u_drv.idle(2);
      apb_rd(ADDR_TCMP1, 32'h6666_6666);
    end
    end_test;
  end
