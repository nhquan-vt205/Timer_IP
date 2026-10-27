// ============================================================================
// TC_REGISTER_003 - TCMP byte strobe
// Objective: only the bytes selected by tim_pstrb are written in TCMP0/TCMP1.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TCMP byte strobe test --");
    // 1. Byte 0 only -> 32'hFFFF_FF44
    reg_write(12'h00C, 32'h1122_3344, 4'b0001);
    reg_read(12'h00C);
    // 2. Byte 2 only -> 32'hFF22_FF44
    reg_write(12'h00C, 32'h1122_3344, 4'b0100);
    reg_read(12'h00C);
    // 3. No strobe -> unchanged
    reg_write(12'h00C, 32'h0000_0000, 4'b0000);
    reg_read(12'h00C);
    // 4. Bytes 1 and 3 -> 32'h1122_3344
    reg_write(12'h00C, 32'h1122_3344, 4'b1010);
    reg_read(12'h00C);
    // 5. TCMP1 bytes 1 and 2 -> 32'hFFB2_C3FF, TCMP0 unchanged
    reg_write(12'h010, 32'hA1B2_C3D4, 4'b0110);
    reg_read(12'h010);
    reg_read(12'h00C);
    idle_cycle;
    end_test;
  end
