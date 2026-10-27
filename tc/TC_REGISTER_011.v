// ============================================================================
// TC_REGISTER_011 - Write timing
// Objective: a write takes effect at the clock edge that ends its wr_en
//            cycle; back-to-back writes to different registers all land.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Write timing test --");
    reg_write(12'h00C, 32'h1111_1111, 4'b1111);  // c0
    reg_write(12'h010, 32'h2222_2222, 4'b1111);  // c1
    reg_write(12'h014, 32'h0000_0001, 4'b1111);  // c2
    reg_write(12'h01C, 32'h0000_0001, 4'b1111);  // c3
    reg_write(12'h000, 32'h0000_0503, 4'b1111);  // c4
    idle_cycle;                                  // c5
    reg_read(12'h00C);
    reg_read(12'h010);
    reg_read(12'h014);
    reg_read(12'h01C);
    reg_read(12'h000);
    idle_cycle;
    end_test;
  end
