// ============================================================================
// TC_TIMER_TOP_003 - reg_reserved_chk
// Objective: reserved addresses are RAZ/WI without error and do not alias
//            any register (one level)
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("reg_reserved_chk");
    reset_dut;
    apb_wr(12'h020, 32'hFFFF_FFFF, 4'hF);                  // 1: first reserved
    apb_rd(12'h020, 32'h0);
    apb_wr(12'h400, 32'hFFFF_FFFF, 4'hF);                  // 2
    apb_rd(12'h400, 32'h0);
    apb_wr(12'hFFC, 32'hFFFF_FFFF, 4'hF);                  // 3: last reserved
    apb_rd(12'hFFC, 32'h0);
    read_reset_values;                                     // 4
    end_test;
  end
