// ============================================================================
// TC_REGISTER_004 - TCR control fields
// Objective: legal TCR writes update TIM_EN, DIV_EN, DIV_VAL; reserved bits
//            read 0; wr_err stays 0.
// Copied to sim/run_test.v and included inside tb_register.
// ============================================================================
  initial begin
    init_test;
    reset_dut;
    $display("-- TCR control fields test --");
    // 1. DIV_VAL = 3, DIV_EN = 1, TIM_EN = 0
    reg_write(12'h000, 32'h0000_0302, 4'b1111);
    reg_read(12'h000);
    // 2. DIV_VAL = 8 (max legal), byte 1 only
    reg_write(12'h000, 32'h0000_0800, 4'b0010);
    reg_read(12'h000);
    // 3. Reserved bits set, DIV_VAL = 8, DIV_EN = 0, TIM_EN = 0
    reg_write(12'h000, 32'hFFFF_F8FC, 4'b1111);
    reg_read(12'h000);
    // 4. TIM_EN = 1, byte 0 only
    reg_write(12'h000, 32'h0000_0001, 4'b0001);
    reg_read(12'h000);
    // 5. Clear TIM_EN only, other fields unchanged (legal)
    reg_write(12'h000, 32'h0000_0800, 4'b0011);
    reg_read(12'h000);
    idle_cycle;
    end_test;
  end
