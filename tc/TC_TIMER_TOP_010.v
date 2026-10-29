// ============================================================================
// TC_TIMER_TOP_010 - Interrupt while matched
// Objective: the compare is continuous: INT_ST is set again right
//            after a clear while cnt still equals {TCMP1, TCMP0}.
// Copied to sim/run_test.v and included inside tb_timer_top.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- Interrupt while matched test --");
    // TIM_EN stays 0, cnt stays 0
    apb_wr(ADDR_TIER,  32'h1, 4'hF);                       // 1
    apb_wr(ADDR_TCMP0, 32'h0, 4'hF);
    apb_wr(ADDR_TCMP1, 32'h0, 4'hF);                       // last access c1
    mark_now;
    apb_rd(ADDR_TISR,  32'h1);                             // 2: c1+3
    apb_wr(ADDR_TISR,  32'h1, 4'b0001);                    // 3: c2 = c1+6
    apb_rd(ADDR_TISR,  32'h1);                             // c1+9
    apb_wr(ADDR_TCMP0, 32'h0000_0010, 4'hF);               // 4
    apb_rd(ADDR_TISR,  32'h1);                             // c1+15
    apb_wr(ADDR_TISR,  32'h1, 4'b0001);                    // 5: c3 = c1+18
    apb_rd(ADDR_TISR,  32'h0);                             // c1+21
    // tim_int in every cycle c1 .. c1+21
    for (i = 0; i <= 21; i = i + 1) begin
      check_int_at(i, ((i >= 2) && (i <= 6)) || ((i >= 8) && (i <= 18)));
    end
    end_test;
  end
