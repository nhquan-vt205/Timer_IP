// ============================================================================
// TC_TIMER_TOP_003 - reg_reserved_chk
// Objective: reserved addresses are RAZ/WI without error response, and a
//            reserved write aliases no register
//   (one-level Item, no sub item)
// Stimulus : the Test sequence of the VPLAN; no expected value here - u_chk
//            checks every transfer and every sample against u_model.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test("TC_TIMER_TOP_003",
              "reserved addresses 0x020 .. 0xFFC read 0, writes ignored without error, no aliasing into a register");
    u_log.item("reg_reserved_chk");
    u_log.goal("all-1 writes to the first, a middle and the last reserved address: read 0, no error; every register keeps its reset value");
    reset_dut;
    apb_write(12'h020, 32'hFFFF_FFFF, 4'b1111);
    apb_read(12'h020);
    apb_write(12'h400, 32'hFFFF_FFFF, 4'b1111);
    apb_read(12'h400);
    apb_write(12'hFFC, 32'hFFFF_FFFF, 4'b1111);
    apb_read(12'hFFC);
    read_all_regs;
    end_test;
  end
