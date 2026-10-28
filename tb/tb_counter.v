// ============================================================================
// Testbench : tb_counter
// Function  : Self-checking direct testbench for counter. Acts as cnt_ctrl,
//             register and timer_top (drives cnt_en, cnt_clr, tdr0_wr_en,
//             tdr1_wr_en, tim_pwdata) and checks cnt in every cycle against
//             a golden model of the spec.
// Spec      : doc/spec/architecture/counter_spec.md
// Vplan     : doc/vplan/counter_vplan.md
// Test cases: tc/TC_COUNTER_<NNN>.v, copied to sim/run_test.v by
//             "make build" and included in section 9.
// ============================================================================
`timescale 1ns/1ps

module tb_counter;

  // ============================================================
  // 1. Declaration
  // ============================================================
  parameter CLK_PERIOD   = 20;
  parameter RESET_CYCLES = 2;
  parameter TIMEOUT_NS   = 100000;

  // DUT signals
  reg            clk;
  reg            rst_n;
  reg            cnt_en;
  reg            cnt_clr;
  reg  [3:0]     tdr0_wr_en;
  reg  [3:0]     tdr1_wr_en;
  reg  [31:0]    tim_pwdata;
  wire [63:0]    cnt;

  // Golden model state
  reg  [63:0]    ref_cnt;

  // Counters and log names
  integer        pass_count;
  integer        fail_count;
  reg  [8*64-1:0] cyc_name;

  // ============================================================
  // 2. DUT Instance
  // ============================================================
  counter u_dut (
    .sys_clk    (clk),
    .sys_rst_n  (rst_n),
    .cnt_en     (cnt_en),
    .cnt_clr    (cnt_clr),
    .tdr0_wr_en (tdr0_wr_en),
    .tdr1_wr_en (tdr1_wr_en),
    .tim_pwdata (tim_pwdata),
    .cnt        (cnt)
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
  // Default inputs (all 0), assert async reset now, release at posedge + #1
  task reset_dut;
    begin
      cnt_en     = 1'b0;
      cnt_clr    = 1'b0;
      tdr0_wr_en = 4'h0;
      tdr1_wr_en = 4'h0;
      tim_pwdata = 32'h0;
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
  // Reset state (spec: cnt = 64'h0)
  task ref_reset;
    begin
      ref_cnt = 64'h0;
    end
  endtask

  // Rising clock edge: update the state from the inputs held in the last
  // cycle. Priority: clear > byte write > count.
  task ref_clock;
    begin
      if (!rst_n) begin
        ref_reset;
      end
      else if (cnt_clr) begin
        ref_cnt = 64'h0;
      end
      else if ({tdr1_wr_en, tdr0_wr_en} != 8'h0) begin
        ref_cnt = byte_merge(ref_cnt, tdr1_wr_en, tdr0_wr_en, tim_pwdata);
      end
      else if (cnt_en) begin
        ref_cnt = ref_cnt + 64'd1;
      end
    end
  endtask

  // ============================================================
  // 6. Checker
  // ============================================================
  task check_val;
    input [8*64-1:0] name;
    input [63:0]     exp;
    input [63:0]     act;
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

  // ============================================================
  // 7. Helper Functions
  // ============================================================
  // Per-byte write: enabled bytes from wdata, the others keep the old value
  function [63:0] byte_merge;
    input [63:0] old;
    input [3:0]  en1;
    input [3:0]  en0;
    input [31:0] wdata;
    integer      i;
    begin
      byte_merge = old;
      for (i = 0; i < 4; i = i + 1) begin
        if (en0[i]) begin
          byte_merge[8*i +: 8] = wdata[8*i +: 8];
        end
        if (en1[i]) begin
          byte_merge[32 + 8*i +: 8] = wdata[8*i +: 8];
        end
      end
    end
  endfunction

  // ============================================================
  // 8. Tasks
  // ============================================================
  // One clock cycle: update the model at the edge, drive all inputs (reset
  // included) at posedge + #1, check cnt at the falling edge.
  // The case name is built from the driven inputs.
  task tick;
    input        c_rst_n;
    input        c_cnt_en;
    input        c_cnt_clr;
    input [3:0]  c_tdr0_wr_en;
    input [3:0]  c_tdr1_wr_en;
    input [31:0] c_tim_pwdata;
    begin
      @(posedge clk);
      #1;
      ref_clock;
      rst_n      = c_rst_n;
      cnt_en     = c_cnt_en;
      cnt_clr    = c_cnt_clr;
      tdr0_wr_en = c_tdr0_wr_en;
      tdr1_wr_en = c_tdr1_wr_en;
      tim_pwdata = c_tim_pwdata;
      if (!c_rst_n) begin
        ref_reset;
      end
      if (c_rst_n) begin
        $sformat(cyc_name, "en%0d_clr%0d_wr0_%h_wr1_%h_wdata_%h_cnt",
                 c_cnt_en, c_cnt_clr, c_tdr0_wr_en, c_tdr1_wr_en, c_tim_pwdata);
      end
      else begin
        $sformat(cyc_name, "rst0_en%0d_clr%0d_wr0_%h_wr1_%h_wdata_%h_cnt",
                 c_cnt_en, c_cnt_clr, c_tdr0_wr_en, c_tdr1_wr_en, c_tim_pwdata);
      end
      @(negedge clk);
      check_val(cyc_name, ref_cnt, cnt);
    end
  endtask

  // Normal cycle (reset released)
  task drive;
    input        c_cnt_en;
    input        c_cnt_clr;
    input [3:0]  c_tdr0_wr_en;
    input [3:0]  c_tdr1_wr_en;
    input [31:0] c_tim_pwdata;
    begin
      tick(1'b1, c_cnt_en, c_cnt_clr, c_tdr0_wr_en, c_tdr1_wr_en, c_tim_pwdata);
    end
  endtask

  // Normal cycle with every input unchanged
  task idle;
    begin
      tick(1'b1, cnt_en, cnt_clr, tdr0_wr_en, tdr1_wr_en, tim_pwdata);
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
    input        c_cnt_en;
    input        c_cnt_clr;
    input [3:0]  c_tdr0_wr_en;
    input [3:0]  c_tdr1_wr_en;
    input [31:0] c_tim_pwdata;
    begin
      tick(1'b0, c_cnt_en, c_cnt_clr, c_tdr0_wr_en, c_tdr1_wr_en, c_tim_pwdata);
    end
  endtask

  // Call right after a cycle check (falling edge): assert the async reset
  // before the next rising edge and check cnt without a clock edge
  task assert_reset_mid;
    begin
      #(CLK_PERIOD / 4);
      rst_n = 1'b0;
      ref_reset;
      #1;
      check_val("rst_asserted_mid_cycle_cnt", ref_cnt, cnt);
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
