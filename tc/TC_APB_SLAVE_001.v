// ============================================================================
// TC_APB_SLAVE_001 - Reset value check
// Objective: all outputs are 0 during and after reset with an idle bus.
// Copied to sim/run_test.v and included inside tb_apb_slave.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset value check test --");
    // Hold reset for 2 cycles with all APB inputs at 0
    rst_n = 1'b0;
    ref_reset;
    idle_cycle("in_reset_cyc0");
    idle_cycle("in_reset_cyc1");
    release_reset;
    // Idle bus after release
    idle_cycle("after_reset_idle0");
    idle_cycle("after_reset_idle1");
    end_test;
  end
