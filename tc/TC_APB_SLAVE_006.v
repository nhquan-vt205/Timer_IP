// ============================================================================
// TC_APB_SLAVE_006 - Back-to-back transfers
// Objective: four transfers without idle cycles; each has its own wait
//            state and strobe, and an error does not carry into the next
//            transfer.
// Copied to sim/run_test.v and included inside tb_apb_slave.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Back-to-back transfers test --");
    apb_transfer(1'b1, 1'b0, 1'b0, 1'b0, 32'h0000_0000, "b2b_write_ok0");
    apb_transfer(1'b1, 1'b1, 1'b1, 1'b1, 32'h0000_0000, "b2b_write_err");
    apb_transfer(1'b1, 1'b0, 1'b0, 1'b0, 32'h0000_0000, "b2b_write_ok1");
    apb_transfer(1'b0, 1'b0, 1'b0, 1'b0, 32'hCAFE_0001, "b2b_read");
    idle_cycle("b2b_c12_idle");
    end_test;
  end
