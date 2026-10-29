// ============================================================================
// TC_TIMER_TOP_002 - APB register access
// Objective: one wait state per transfer, byte strobe write and
//            RAZ/WI reserved address through the APB port.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- APB register access test --");
    // Step 1: bytes 0, 1 of TCMP0 only
    apb_wr(ADDR_TCMP0, 32'hAABB_CCDD, 4'b0011);
    apb_rd(ADDR_TCMP0, 32'hFFFF_CCDD);
    // Step 2
    idle_n(2);
    // Step 3
    apb_wr(ADDR_TCMP1, 32'h5555_5555, 4'hF);
    apb_rd(ADDR_TCMP1, 32'h5555_5555);
    apb_wr(ADDR_TIER,  32'hFFFF_FFFF, 4'hF);
    apb_rd(ADDR_TIER,  32'h0000_0001);
    apb_wr(ADDR_THCSR, 32'hFFFF_FFFF, 4'hF);
    apb_rd(ADDR_THCSR, 32'h0000_0001);        // HALT_ACK = 0, dbg_mode = 0
    // Step 4: reserved address
    apb_wr(ADDR_RSVD,  32'hFFFF_FFFF, 4'hF);
    apb_rd(ADDR_RSVD,  32'h0);
    apb_rd(ADDR_TCMP0, 32'hFFFF_CCDD);
    end_test;
  end
