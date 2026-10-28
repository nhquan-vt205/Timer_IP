// ============================================================================
// Testbench : tb_interrupt
// Function  : Self-checking direct testbench for interrupt. Acts as the
//             counter and register blocks (drives cnt, tcmp0, tcmp1, int_en,
//             int_st_clr) and checks int_st and tim_int in every cycle
//             against a golden model of the spec.
// Spec      : doc/spec/architecture/interrupt_spec.md
// Vplan     : doc/vplan/interrupt_vplan.md
// Test cases: tc/TC_INTERRUPT_<NNN>.v, copied to sim/run_test.v by
//             "make build" and included in section 9.
// ============================================================================
`timescale 1ns/1ps

module tb_interrupt;

  // ============================================================
  // 1. Declaration
  // ============================================================
  parameter CLK_PERIOD   = 20;
  parameter RESET_CYCLES = 2;
  parameter TIMEOUT_NS   = 100000;

  // Default compare value of the vplan
  parameter [63:0] TCMP_DEF = 64'h0000_0000_0000_0010;

  // DUT signals
  reg            clk;
  reg            rst_n;
  reg  [63:0]    cnt;
  reg  [31:0]    tcmp0;
  reg  [31:0]    tcmp1;
  reg            int_en;
  reg            int_st_clr;
  wire           int_st;
  wire           tim_int;

  // Golden model state and expected outputs
  reg            ref_int_st;
  reg            exp_tim_int;

  // Counters and log names
  integer        pass_count;
  integer        fail_count;
  reg  [8*72-1:0] cyc_name;
  reg  [8*88-1:0] case_name;

  // ============================================================
  // 2. DUT Instance
  // ============================================================
  interrupt u_dut (
    .sys_clk    (clk),
    .sys_rst_n  (rst_n),
    .cnt        (cnt),
    .tcmp0      (tcmp0),
    .tcmp1      (tcmp1),
    .int_en     (int_en),
    .int_st_clr (int_st_clr),
    .int_st     (int_st),
    .tim_int    (tim_int)
  );

  // ============================================================
  // 3. Clock Generation
  // ============================================================
  initial begin
    clk = 1'b0;
  end

  always #(CLK_PERIOD / 2) clk = ~clk;

  // ============================================================
  // 4. Init Reset
  // ============================================================
  // Default inputs, assert async reset now, release at posedge + #1
  task reset_dut;
    begin
      cnt        = 64'h0;
      {tcmp1, tcmp0} = TCMP_DEF;
      int_en     = 1'b1;
      int_st_clr = 1'b0;
      rst_n      = 1'b0;
      ref_reset;
      repeat (RESET_CYCLES) @(posedge clk);
      #1;
      rst_n = 1'b1;
    end
  endtask

  // ============================================================
  // 5. Golden Reference Model
  // ============================================================
  // Reset state (spec: int_st = 0)
  task ref_reset;
    begin
      ref_int_st = 1'b0;
    end
  endtask

  // Rising clock edge: update INT_ST from the inputs held in the last cycle.
  // Clear has priority over a match; otherwise INT_ST holds.
  task ref_clock;
    begin
      if (!rst_n) begin
        ref_reset;
      end
      else if (int_st_clr) begin
        ref_int_st = 1'b0;
      end
      else if (cnt == {tcmp1, tcmp0}) begin
        ref_int_st = 1'b1;
      end
    end
  endtask

  // Expected combinational output: tim_int = INT_ST & INT_EN
  task ref_outputs;
    begin
      exp_tim_int = ref_int_st & int_en;
    end
  endtask

  // ============================================================
  // 6. Checker
  // ============================================================
  task check_bit;
    input [8*88-1:0] name;
    input            exp;
    input            act;
    begin
      if (act === exp) begin
        pass_count = pass_count + 1;
        $display("[%0d] %0s PASS | expected: %h | actual: %h", $time, name, exp, act);
      end
      else begin
        fail_count = fail_count + 1;
        $display("[%0d] %0s FAIL | expected: %h | actual: %h", $time, name, exp, act);
      end
    end
  endtask

  // Compare every DUT output with the golden model
  task check_outputs;
    input [8*72-1:0] name;
    begin
      ref_outputs;
      $sformat(case_name, "%0s_int_st", name);
      check_bit(case_name, ref_int_st, int_st);
      $sformat(case_name, "%0s_tim_int", name);
      check_bit(case_name, exp_tim_int, tim_int);
    end
  endtask

  // ============================================================
  // 7. Helper Functions
  // ============================================================

  // ============================================================
  // 8. Tasks
  // ============================================================
  // One clock cycle: update the model at the edge, drive all inputs (reset
  // included) at posedge + #1, check all outputs at the falling edge.
  // The case name is built from the driven inputs.
  task tick;
    input        c_rst_n;
    input [63:0] c_cnt;
    input [63:0] c_tcmp;
    input        c_int_en;
    input        c_clr;
    begin
      @(posedge clk);
      #1;
      ref_clock;
      rst_n          = c_rst_n;
      cnt            = c_cnt;
      {tcmp1, tcmp0} = c_tcmp;
      int_en         = c_int_en;
      int_st_clr     = c_clr;
      if (!c_rst_n) begin
        ref_reset;
      end
      if (c_rst_n) begin
        $sformat(cyc_name, "cnt_%h_tcmp_%h_en%0d_clr%0d", c_cnt, c_tcmp, c_int_en, c_clr);
      end
      else begin
        $sformat(cyc_name, "rst0_cnt_%h_tcmp_%h_en%0d_clr%0d", c_cnt, c_tcmp, c_int_en, c_clr);
      end
      @(negedge clk);
      check_outputs(cyc_name);
    end
  endtask

  // Normal cycle (reset released)
  task drive;
    input [63:0] c_cnt;
    input [63:0] c_tcmp;
    input        c_int_en;
    input        c_clr;
    begin
      tick(1'b1, c_cnt, c_tcmp, c_int_en, c_clr);
    end
  endtask

  // Cycle with sys_rst_n held at 0
  task drive_in_reset;
    input [63:0] c_cnt;
    input [63:0] c_tcmp;
    input        c_int_en;
    input        c_clr;
    begin
      tick(1'b0, c_cnt, c_tcmp, c_int_en, c_clr);
    end
  endtask

  // Call right after a cycle check (falling edge): assert the async reset
  // before the next rising edge and check the outputs without a clock edge
  task assert_reset_mid;
    begin
      #(CLK_PERIOD / 4);
      rst_n = 1'b0;
      ref_reset;
      #1;
      check_outputs("rst_asserted_mid_cycle");
    end
  endtask

  // Counters; call first in every test case
  task init_test;
    begin
      pass_count = 0;
      fail_count = 0;
    end
  endtask

  // Summary and overall result (read by sim/report.csh); ends the simulation
  task end_test;
    begin
      $display("[SUMMARY] PASS=%0d FAIL=%0d", pass_count, fail_count);
      if (fail_count == 0 && pass_count > 0) begin
        $display("Test_result: PASSED");
      end
      else begin
        $display("Test_result: FAILED");
      end
      $finish;
    end
  endtask

  // ============================================================
  // 9. Main Program Body
  // ============================================================
  // Test sequence of the selected test case (tc/<ID>.v)
`include "run_test.v"

  initial begin
    #(TIMEOUT_NS);
    $display("[TIMEOUT] simulation exceeded %0d ns", TIMEOUT_NS);
    fail_count = fail_count + 1;
    end_test;
  end

endmodule
