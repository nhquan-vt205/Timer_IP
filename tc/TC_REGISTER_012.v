// ============================================================================
// TC_REGISTER_012 - Reset during operation
// Objective: the asynchronous reset returns every register to its reset
//            value immediately, without a clock edge.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset during operation test --");
    // 1. Non-reset values in every register
    reg_write(12'h000, 32'h0000_0503, 4'b1111);
    reg_write(12'h00C, 32'h0000_0000, 4'b1111);
    reg_write(12'h010, 32'h0000_0000, 4'b1111);
    reg_write(12'h014, 32'h0000_0001, 4'b1111);
    reg_write(12'h01C, 32'h0000_0001, 4'b1111);
    idle_cycle;
    // 2. Reset mid-cycle, held for 2 cycles
    assert_reset_mid;
    idle_cycle;
    idle_cycle;
    // 3. Release and read back
    release_reset;
    read_all;
    idle_cycle;
    end_test;
  end
