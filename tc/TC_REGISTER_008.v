// ============================================================================
// TC_REGISTER_008 - TDR write enable
// Objective: TDR0/TDR1 writes are forwarded as byte write enables only in
//            the cycle with wr_en = 1 at the TDR address.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TDR write enable test --");
    reg_write(12'h004, 32'h0000_0000, 4'b1111);
    idle_cycle;
    reg_write(12'h004, 32'h0000_0000, 4'b0101);
    idle_cycle;
    reg_write(12'h008, 32'h0000_0000, 4'b0011);
    idle_cycle;
    reg_write(12'h008, 32'h0000_0000, 4'b1000);
    idle_cycle;
    no_write(12'h004, 32'h0000_0000, 4'b1111);
    idle_cycle;
    reg_write(12'h00C, 32'h0000_0000, 4'b1111);
    idle_cycle;
    end_test;
  end
