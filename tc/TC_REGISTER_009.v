// ============================================================================
// TC_REGISTER_009 - TISR clear pulse
// Objective: int_st_clr pulses only for a TISR write with byte 0 strobed and
//            bit 0 = 1 (RW1C); writing 0 has no effect.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TISR clear pulse test --");
    reg_write(12'h018, 32'h0000_0001, 4'b0001);  // 1: pulse
    idle_cycle;
    reg_write(12'h018, 32'h0000_0000, 4'b0001);  // 2: write 0
    idle_cycle;
    reg_write(12'h018, 32'h0000_0001, 4'b1110);  // 3: byte 0 not strobed
    idle_cycle;
    reg_write(12'h018, 32'hFFFF_FFFE, 4'b1111);  // 4: bit 0 = 0
    idle_cycle;
    no_write(12'h018, 32'h0000_0001, 4'b0001);   // 5: wr_en = 0
    idle_cycle;
    reg_write(12'h01C, 32'h0000_0001, 4'b0001);  // 6: THCSR, not TISR
    idle_cycle;
    reg_write(12'h018, 32'hFFFF_FFFF, 4'b1111);  // 7: pulse
    idle_cycle;
    end_test;
  end
