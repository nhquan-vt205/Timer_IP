// ============================================================================
// TC_TIMER_TOP_009 - apb_unaligned_chk
// Objective: decoding on tim_paddr[11:2] only, tim_paddr[1:0] ignored
//   (one-level Item, no sub item)
// Stimulus : the Test sequence of the VPLAN (every address has
//            tim_paddr[1:0] != 0); no expected value here - u_chk checks
//            every transfer and every sample against u_model.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_009",
              "unaligned addresses decode on tim_paddr[11:2]: TCMP0, TIER, TDR0, reserved, and a rejected TCR write");
    u_log.item("apb_unaligned_chk");
    u_log.goal("tim_paddr[1:0] != 0 in every transfer: the word of tim_paddr[11:2] is accessed; DIV_VAL 9 through 0x002 is a TCR error");
    reset_dut;
    apb_write(12'h00D, 32'h1234_5678, 4'b1111);
    apb_read(12'h00C);
    apb_read(12'h00F);
    apb_write(12'h016, 32'h0000_0001, 4'b1111);
    apb_read(12'h015);
    apb_write(12'h005, 32'h0000_0010, 4'b1111);
    apb_read(12'h007);
    apb_read(12'h009);
    apb_write(12'h021, 32'hFFFF_FFFF, 4'b1111);
    apb_read(12'h023);
    apb_write(12'h002, 32'h0000_0901, 4'b0011);
    apb_read(12'h001);
    end_test;
  end
