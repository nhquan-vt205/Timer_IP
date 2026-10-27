// ============================================================================
// Testbench : tb_cnt_ctrl
// Function  : Self-checking direct testbench for cnt_ctrl. Acts as the
//             register block and timer_top (drives tim_en, div_en, div_val,
//             halt_req, dbg_mode) and checks halt_ack, cnt_en and cnt_clr in
//             every cycle against a golden model of the spec.
// Spec      : doc/spec/architecture/cnt_ctrl_spec.md
// Vplan     : doc/vplan/cnt_ctrl_vplan.md
// Test cases: tc/TC_CNT_CTRL_<NNN>.v, copied to sim/run_test.v by
//             "make build" and included in section 9.
// ============================================================================
`timescale 1ns/1ps

module tb_cnt_ctrl;

  // ============================================================
  // 1. Declaration
  // ============================================================
  parameter CLK_PERIOD   = 20;
  parameter RESET_CYCLES = 2;
  parameter TIMEOUT_NS   = 100000;

  // DUT signals
  reg            clk;
  reg            rst_n;
  reg            tim_en;
  reg            div_en;
  reg  [3:0]     div_val;
  reg            halt_req;
  reg            dbg_mode;
  wire           halt_ack;
  wire           cnt_en;
  wire           cnt_clr;

  // Golden model state and expected outputs
  reg  [7:0]     ref_div_cnt;
  reg            ref_tim_en_d;
  reg            exp_halt_ack;
  reg            exp_cnt_en;
  reg            exp_cnt_clr;

  // Counters and log names
  integer        pass_count;
  integer        fail_count;
  reg  [8*48-1:0] cyc_name;
  reg  [8*64-1:0] case_name;

  // ============================================================
  // 2. DUT Instance
  // ============================================================
  cnt_ctrl u_dut (
    .sys_clk   (clk),
    .sys_rst_n (rst_n),
    .tim_en    (tim_en),
    .div_en    (div_en),
    .div_val   (div_val),
    .halt_req  (halt_req),
    .dbg_mode  (dbg_mode),
    .halt_ack  (halt_ack),
    .cnt_en    (cnt_en),
    .cnt_clr   (cnt_clr)
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
  // Default inputs (TCR/THCSR reset values), assert async reset now,
  // release at posedge + #1
  task reset_dut;
    begin
      tim_en   = 1'b0;
      div_en   = 1'b0;
      div_val  = 4'h1;
      halt_req = 1'b0;
      dbg_mode = 1'b0;
      rst_n    = 1'b0;
      ref_reset;
      repeat (RESET_CYCLES) @(posedge clk);
      #1;
      rst_n = 1'b1;
    end
  endtask

  // ============================================================
  // 5. Golden Reference Model
  // ============================================================
  // Reset state (spec: div_cnt = 8'h0, tim_en_d = 0)
  task ref_reset;
    begin
      ref_div_cnt  = 8'h0;
      ref_tim_en_d = 1'b0;
    end
  endtask

  // Rising clock edge: update the state from the inputs held in the last
  // cycle. div_cnt priority: clear (TIM_EN = 0 or DIV_EN = 0) > halt > wrap.
  task ref_clock;
    begin
      if (!rst_n) begin
        ref_reset;
      end
      else begin
        if (!tim_en || !div_en) begin
          ref_div_cnt = 8'h0;
        end
        else if (dbg_mode && halt_req) begin
          ref_div_cnt = ref_div_cnt;
        end
        else if (ref_div_cnt == div_limit(div_val)) begin
          ref_div_cnt = 8'h0;
        end
        else begin
          ref_div_cnt = ref_div_cnt + 8'd1;
        end
        ref_tim_en_d = tim_en;
      end
    end
  endtask

  // Expected combinational outputs from the current inputs and state
  task ref_outputs;
    begin
      exp_halt_ack = dbg_mode & halt_req;
      exp_cnt_en   = tim_en & ~exp_halt_ack &
                     (~div_en | (ref_div_cnt == div_limit(div_val)));
      exp_cnt_clr  = ref_tim_en_d & ~tim_en;
    end
  endtask

  // ============================================================
  // 6. Checker
  // ============================================================
  task check_bit;
    input [8*64-1:0] name;
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
    input [8*48-1:0] name;
    begin
      ref_outputs;
      $sformat(case_name, "%0s_halt_ack", name);
      check_bit(case_name, exp_halt_ack, halt_ack);
      $sformat(case_name, "%0s_cnt_en", name);
      check_bit(case_name, exp_cnt_en, cnt_en);
      $sformat(case_name, "%0s_cnt_clr", name);
      check_bit(case_name, exp_cnt_clr, cnt_clr);
    end
  endtask

  // ============================================================
  // 7. Helper Functions
  // ============================================================
  // Divider limit (1 << div_val) - 1, computed on 9 bits, low 8 bits kept
  function [7:0] div_limit;
    input [3:0] val;
    reg   [8:0] full;
    begin
      full      = (9'd1 << val) - 9'd1;
      div_limit = full[7:0];
    end
  endfunction

  // ============================================================
  // 8. Tasks
  // ============================================================
  // One clock cycle: update the model at the edge, drive all inputs (reset
  // included) at posedge + #1, check all outputs at the falling edge.
  // The case name is built from the driven inputs.
  task tick;
    input       c_rst_n;
    input       c_tim_en;
    input       c_div_en;
    input [3:0] c_div_val;
    input       c_halt_req;
    input       c_dbg_mode;
    begin
      @(posedge clk);
      #1;
      ref_clock;
      rst_n    = c_rst_n;
      tim_en   = c_tim_en;
      div_en   = c_div_en;
      div_val  = c_div_val;
      halt_req = c_halt_req;
      dbg_mode = c_dbg_mode;
      if (!c_rst_n) begin
        ref_reset;
      end
      if (c_rst_n) begin
        $sformat(cyc_name, "ten%0d_den%0d_dval%0d_hreq%0d_dbg%0d",
                 c_tim_en, c_div_en, c_div_val, c_halt_req, c_dbg_mode);
      end
      else begin
        $sformat(cyc_name, "rst0_ten%0d_den%0d_dval%0d_hreq%0d_dbg%0d",
                 c_tim_en, c_div_en, c_div_val, c_halt_req, c_dbg_mode);
      end
      @(negedge clk);
      check_outputs(cyc_name);
    end
  endtask

  // Normal cycle (reset released)
  task drive;
    input       c_tim_en;
    input       c_div_en;
    input [3:0] c_div_val;
    input       c_halt_req;
    input       c_dbg_mode;
    begin
      tick(1'b1, c_tim_en, c_div_en, c_div_val, c_halt_req, c_dbg_mode);
    end
  endtask

  // Normal cycle with every input unchanged
  task idle;
    begin
      tick(1'b1, tim_en, div_en, div_val, halt_req, dbg_mode);
    end
  endtask

  // n normal cycles with every input unchanged
  task idle_n;
    input integer n;
    integer i;
    begin
      for (i = 0; i < n; i = i + 1) begin
        idle;
      end
    end
  endtask

  // Cycle with sys_rst_n held at 0
  task drive_in_reset;
    input       c_tim_en;
    input       c_div_en;
    input [3:0] c_div_val;
    input       c_halt_req;
    input       c_dbg_mode;
    begin
      tick(1'b0, c_tim_en, c_div_en, c_div_val, c_halt_req, c_dbg_mode);
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
