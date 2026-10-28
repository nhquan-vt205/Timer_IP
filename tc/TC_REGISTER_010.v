// ============================================================================
// TC_REGISTER_010 - Reserved address access
// Objective: reserved addresses are RAZ/WI and do not disturb any register;
//            tim_paddr[1:0] is ignored by the decoder.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Reserved address access test --");
    // 1. First, middle, last reserved address
    reg_write(12'h020, 32'hFFFF_FFFF, 4'b1111);
    reg_read(12'h020);
    reg_write(12'h400, 32'hFFFF_FFFF, 4'b1111);
    reg_read(12'h400);
    reg_write(12'hFFC, 32'hFFFF_FFFF, 4'b1111);
    reg_read(12'hFFC);
    // 2. All registers keep their reset values
    read_all;
    // 3. TCMP0 word with tim_paddr[1:0] = 3
    reg_write(12'h00F, 32'h1357_9BDF, 4'b1111);
    reg_read(12'h00C);
    idle_cycle;
    end_test;
  end
