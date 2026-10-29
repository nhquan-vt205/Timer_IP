// ============================================================================
// TC_TIMER_TOP_012 - Reset during operation
// Objective: asynchronous reset while counting with a pending
//            interrupt returns every output and register to its reset value.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset during operation test --");
    apb_wr(ADDR_TCMP0, 32'h2, 4'hF);                       // 1
    apb_wr(ADDR_TCMP1, 32'h0, 4'hF);
    apb_wr(ADDR_TIER,  32'h1, 4'hF);
    apb_wr(ADDR_TCR,   32'h0000_0001, 4'b0001);
    mark_e0;
    idle_n(5);                                             // 2: e0 .. e0+4
    for (i = 0; i <= 4; i = i + 1) begin
      check_int_at(i, (i >= 3));
    end
    assert_reset_mid;                                      // 3: mid-cycle in e0+4
    hold_reset(2);
    read_reset_values;                                     // 4
    idle_n(4);                                             // 5
    apb_rd(ADDR_TDR0, 32'h0);
    end_test;
  end
