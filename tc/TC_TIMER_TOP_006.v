// ============================================================================
// TC_TIMER_TOP_006 - TDR software write
// Objective: software load and byte write of TDR0/TDR1, carry from
//            TDR0 into TDR1, and a write while counting.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TDR software write test --");
    apb_wr(ADDR_TDR0, 32'hFFFF_FFF0, 4'hF);                // 1
    apb_wr(ADDR_TDR1, 32'h0000_0001, 4'hF);
    apb_rd(ADDR_TDR0, 32'hFFFF_FFF0);
    apb_rd(ADDR_TDR1, 32'h0000_0001);
    apb_wr(ADDR_TDR0, 32'h0000_00AB, 4'b0001);             // 2
    apb_rd(ADDR_TDR0, 32'hFFFF_FFAB);
    apb_wr(ADDR_TDR0, 32'hFFFF_FFFE, 4'hF);                // 3
    apb_wr(ADDR_TDR1, 32'h0,         4'hF);
    apb_wr(ADDR_TCR,  32'h0000_0001, 4'b0001);             // 4: e0 follows
    mark_e0;
    apb_rd(ADDR_TDR0, 32'h0000_0000);                      // e0+2: carry
    apb_rd(ADDR_TDR1, 32'h0000_0001);                      // e0+5
    apb_wr(ADDR_TDR0, 32'h0000_1000, 4'hF);                // 5: last access e0+8
    apb_rd(ADDR_TDR0, 32'h0000_1002);                      // e0+11
    apb_rd(ADDR_TDR1, 32'h0000_0001);                      // e0+14
    end_test;
  end
