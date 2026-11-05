// ============================================================================
// TC_TIMER_TOP_007 - apb_protocol_chk
// Objective: APB write and read with one wait state, read data only in the
//            last access cycle, and an undriven (X) bus while idle
//   Write transfer, Read transfer, Undriven bus while idle
// Stimulus : the Test sequence of the VPLAN; no expected value here - u_chk
//            checks every transfer and every sample (tim_pready,
//            tim_pslverr, tim_prdata, tim_int) against u_model.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_007",
              "APB transfer = setup, one wait cycle, last access; tim_prdata only in the last access of a read; an X bus while idle starts no transfer");
    u_log.item("apb_protocol_chk");
    begin : write_transfer
      u_log.sub1("Write transfer");
      u_log.goal("tim_pready 0 in setup and wait, 1 in the last access; tim_prdata 0 during a write; the write takes effect at the end of its last access");
      reset_dut;
      apb_write(ADDR_TCMP0, 32'h1234_5678, 4'b1111);
      wait_cycles(2);
      apb_read(ADDR_TCMP0);
    end
    begin : read_transfer
      u_log.sub1("Read transfer");
      u_log.goal("tim_prdata 0 in setup and wait, the register value in the last access with tim_pready 1, 0 again while idle");
      reset_dut;
      apb_read(ADDR_TCMP1);
      wait_cycles(1);
      apb_read(ADDR_TCR);
    end
    begin : undriven_bus_while_idle
      u_log.sub1("Undriven bus while idle");
      u_log.goal("X on every APB input in each idle cycle: outputs stay 0, no transfer starts, no X is loaded into a register");
      reset_dut;
      wait_undriven(3);
      apb_read(ADDR_TCR);
      wait_undriven(2);
      apb_read(ADDR_TDR0);
      wait_undriven(2);
      apb_read(ADDR_TDR1);
      wait_undriven(2);
      apb_read(ADDR_TISR);
      wait_undriven(2);
      apb_write(ADDR_TDR0, 32'h1111_1111, 4'b0001);
      wait_undriven(2);
      apb_read(ADDR_TDR0);
      wait_undriven(2);
      apb_write(ADDR_TCMP0, 32'h5555_5555, 4'b1111);
      wait_undriven(2);
      apb_write(ADDR_TCMP1, 32'h6666_6666, 4'b1111);
      wait_undriven(2);
      apb_read(ADDR_TCMP0);
      wait_undriven(2);
      apb_read(ADDR_TCMP1);
    end
    end_test;
  end
