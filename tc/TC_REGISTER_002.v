// ============================================================================
// TC_REGISTER_002 - TCMP read write
// Objective: TCMP0 and TCMP1 store full-word writes and read them back.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TCMP read write test --");
    for (i = 0; i < 4; i = i + 1) begin
      case (i)
        0       : pattern = 32'h0000_0000;
        1       : pattern = 32'hFFFF_FFFF;
        2       : pattern = 32'h5555_5555;
        default : pattern = 32'hAAAA_AAAA;
      endcase
      reg_write(12'h00C, pattern, 4'b1111);
      reg_write(12'h010, ~pattern, 4'b1111);
      reg_read(12'h00C);
      reg_read(12'h010);
    end
    idle_cycle;
    end_test;
  end
