// ============================================================================
// TC_REGISTER_001 - Reset value check
// Objective: after reset all register outputs hold their reset values and
//            every register reads its register-map reset value.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset value check test --");
    // Outputs with rd_en = 0
    idle_cycle;
    idle_cycle;
    // TCR, TDR0, TDR1, TCMP0, TCMP1, TIER, TISR, THCSR
    read_all;
    idle_cycle;
    end_test;
  end
