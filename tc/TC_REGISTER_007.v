// ============================================================================
// TC_REGISTER_007 - Read data path
// Objective: TDR0/TDR1 read cnt, TISR reads int_st, rdata is 0 when
//            rd_en = 0, and continuous reads follow the address each cycle.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Read data path test --");
    // 1-2. TDR0 / TDR1 from cnt
    nxt_cnt = 64'h1234_5678_9ABC_DEF0;
    reg_read(12'h004);
    reg_read(12'h008);
    nxt_cnt = 64'hFFFF_FFFF_FFFF_FFFF;
    reg_read(12'h004);
    reg_read(12'h008);
    // 3. TISR from int_st
    nxt_int_st = 1'b1;
    reg_read(12'h018);
    nxt_int_st = 1'b0;
    reg_read(12'h018);
    // 4. rd_en gating at TCMP0
    no_write(12'h00C, 32'h0000_0000, 4'b0000);
    reg_read(12'h00C);
    // 5. Continuous read, then rd_en = 0
    nxt_cnt = 64'h0000_0000_0000_00AB;
    reg_read(12'h00C);
    reg_read(12'h000);
    reg_read(12'h004);
    no_write(12'h00C, 32'h0000_0000, 4'b0000);
    idle_cycle;
    end_test;
  end
