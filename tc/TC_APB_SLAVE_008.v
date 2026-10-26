// ============================================================================
// TC_APB_SLAVE_008 - Reset during transfer
// Objective: the asynchronous reset clears tim_pready/tim_pslverr and the
//            strobes at once, in the middle of a transfer; the next write
//            after release behaves normally.
// Copied to sim/run_test.v and included inside tb_apb_slave.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reset during transfer test --");
    // Erroneous write; c2 shows pready = 1, pslverr = 1
    apb_transfer(1'b1, 1'b1, 1'b1, 1'b1, 32'h0000_0000, "write_err");
    // Async reset mid-cycle in c2, APB inputs still held
    rst_n = 1'b0;
    ref_reset;
    #1;
    check_outputs("write_err_c2_async_reset");
    // Hold reset for 2 cycles
    idle_cycle("in_reset_cyc0");
    idle_cycle("in_reset_cyc1");
    release_reset;
    // Normal write after release
    apb_transfer(1'b1, 1'b0, 1'b0, 1'b0, 32'h0000_0000, "write_after_reset");
    idle_cycle("write_after_reset_c3_idle");
    end_test;
  end
