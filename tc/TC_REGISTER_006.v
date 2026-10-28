// ============================================================================
// TC_REGISTER_006 - TIER THCSR access
// Objective: TIER.INT_EN and THCSR.HALT_REQ are written through byte 0 only;
//            THCSR.HALT_ACK is read-only and follows halt_ack.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TIER THCSR access test --");
    // 1-3. TIER
    reg_write(12'h014, 32'hFFFF_FFFF, 4'b1111);
    reg_read(12'h014);
    reg_write(12'h014, 32'h0000_0000, 4'b1111);
    reg_read(12'h014);
    reg_write(12'h014, 32'h0000_0001, 4'b1110);
    reg_read(12'h014);
    // 4. THCSR: HALT_REQ = 1, read with halt_ack = 0 then 1
    reg_write(12'h01C, 32'hFFFF_FFFF, 4'b1111);
    reg_read(12'h01C);
    nxt_halt_ack = 1'b1;
    reg_read(12'h01C);
    // 5. HALT_REQ = 0, halt_ack = 1
    reg_write(12'h01C, 32'h0000_0000, 4'b1111);
    reg_read(12'h01C);
    // 6. Byte 0 not strobed, halt_ack = 0
    nxt_halt_ack = 1'b0;
    reg_write(12'h01C, 32'h0000_0001, 4'b1110);
    reg_read(12'h01C);
    idle_cycle;
    end_test;
  end
