// ============================================================================
// TC_REGISTER_005 - TCR write error
// Objective: wr_err is 1 exactly for the three forbidden TCR write
//            conditions; checked with wr_en = 0 so nothing is written.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TCR write error test --");
    // Part A: TIM_EN = 0, DIV_VAL = 1, DIV_EN = 0
    no_write(12'h000, 32'h0000_0900, 4'b0010);  // A1: 9 > 8
    no_write(12'h000, 32'h0000_0F00, 4'b0010);  // A2: 15 > 8
    no_write(12'h000, 32'h0000_0800, 4'b0010);  // A3: 8 legal
    no_write(12'h000, 32'h0000_0F00, 4'b0001);  // A4: byte 1 not strobed
    // Part B: TIM_EN = 1, DIV_VAL = 2, DIV_EN = 0
    reg_write(12'h000, 32'h0000_0201, 4'b1111);
    no_write(12'h000, 32'h0000_0301, 4'b0010);  // B1: DIV_VAL change
    no_write(12'h000, 32'h0000_0203, 4'b0001);  // B2: DIV_EN change
    no_write(12'h000, 32'h0000_0201, 4'b0011);  // B3: same value
    no_write(12'h000, 32'h0000_0200, 4'b0011);  // B4: clear TIM_EN only
    no_write(12'h000, 32'h0000_0F03, 4'b0000);  // B5: no strobe
    no_write(12'h00C, 32'h0000_0F03, 4'b1111);  // B6: not TCR
    no_write(12'h003, 32'h0000_0301, 4'b0010);  // B7: TCR word, paddr[1:0] = 3
    // Nothing written by the checks
    reg_read(12'h000);
    idle_cycle;
    end_test;
  end
