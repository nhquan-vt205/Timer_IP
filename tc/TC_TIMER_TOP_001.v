// ============================================================================
// TC_TIMER_TOP_001 - Reset value check
// Objective: outputs during reset and every register value after
//            reset; no counting while TIM_EN = 0.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset value check test --");
    // Step 1: reset again with checks during reset
    assert_reset_mid;
    hold_reset(2);
    // Step 2: read every register and one reserved address
    read_reset_values;
    apb_rd(ADDR_RSVD, 32'h0);
    // Step 3
    idle_n(4);
    apb_rd(ADDR_TDR0, 32'h0);
    end_test;
  end
