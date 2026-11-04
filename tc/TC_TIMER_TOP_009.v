// ============================================================================
// TC_TIMER_TOP_009 - apb_unaligned_chk
// Objective: decoding uses tim_paddr[11:2] only; tim_paddr[1:0] is ignored
//            for registers, reserved addresses and the TCR error (one level)
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    u_log.item("apb_unaligned_chk");
    reset_dut;
    apb_wr(12'h00D, 32'h1234_5678, 4'hF);                  // 1: TCMP0
    apb_rd(12'h00C, 32'h1234_5678);
    apb_rd(12'h00F, 32'h1234_5678);
    apb_wr(12'h016, 32'h1, 4'hF);                          // 2: TIER
    apb_rd(12'h015, 32'h1);
    apb_wr(12'h005, 32'h0000_0010, 4'hF);                  // 3: TDR0
    apb_rd(12'h007, 32'h0000_0010);
    apb_rd(12'h009, 32'h0);
    apb_wr(12'h021, 32'hFFFF_FFFF, 4'hF);                  // 4: reserved
    apb_rd(12'h023, 32'h0);
    apb_write(12'h002, 32'h0000_0901, 4'b0011, 1'b1);      // 5: TCR, DIV_VAL = 9
    apb_rd(12'h001, 32'h0000_0100);                        // 6
    end_test;
  end
