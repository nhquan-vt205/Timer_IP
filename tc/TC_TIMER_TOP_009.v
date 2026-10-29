// ============================================================================
// TC_TIMER_TOP_009 - Interrupt generation
// Objective: compare match sets INT_ST and tim_int; INT_EN masks
//            tim_int without losing INT_ST; writing 1 to TISR clears it.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Interrupt generation test --");
    apb_wr(ADDR_TCMP0, 32'h0000_0010, 4'hF);               // 1
    apb_wr(ADDR_TCMP1, 32'h0,         4'hF);
    apb_wr(ADDR_TIER,  32'h1,         4'hF);
    apb_wr(ADDR_TCR,   32'h0000_0001, 4'b0001);            // 2: e0 follows
    mark_e0;
    idle_n(20);                                            // 3: e0 .. e0+19
    apb_rd(ADDR_TISR,  32'h1);                             // 4: e0+22
    apb_rd(ADDR_TDR0,  32'h0000_0019);                     // e0+25
    apb_wr(ADDR_TIER,  32'h0, 4'hF);                       // 5: e0+28
    apb_rd(ADDR_TISR,  32'h1);                             // e0+31
    apb_wr(ADDR_TIER,  32'h1, 4'hF);                       // 6: e0+34
    apb_wr(ADDR_TISR,  32'h0, 4'b0001);                    // 7: e0+37
    apb_rd(ADDR_TISR,  32'h1);                             // e0+40
    apb_wr(ADDR_TISR,  32'h1, 4'b0001);                    // 8: e0+43
    apb_rd(ADDR_TISR,  32'h0);                             // e0+46
    // tim_int in every cycle e0 .. e0+46
    for (i = 0; i <= 46; i = i + 1) begin
      check_int_at(i, ((i >= 17) && (i <= 28)) || ((i >= 35) && (i <= 43)));
    end
    end_test;
  end
