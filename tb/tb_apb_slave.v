// ============================================================================
// Testbench : tb_apb_slave
// Function  : Self-checking direct testbench for apb_slave. Acts as the APB
//             master and as the register block (drives wr_err and rdata),
//             and checks every DUT output in every cycle against a golden
//             model of the spec.
// Spec      : doc/spec/architecture/apb_slave_spec.md
// Vplan     : doc/vplan/apb_slave_vplan.md
// Test cases: tc/TC_APB_SLAVE_<NNN>.v, copied to sim/run_test.v by
//             "make build" and included in section 9.
// ============================================================================
`timescale 1ns/1ps

module tb_apb_slave;

  // ============================================================
  // 1. Declaration
  // ============================================================
  parameter CLK_PERIOD   = 20;
  parameter RESET_CYCLES = 5;
  parameter TIMEOUT_NS   = 100000;

  // DUT signals
  reg            clk;
  reg            rst_n;
  reg            psel;
  reg            penable;
  reg            pwrite;
  reg            wr_err;
  reg  [31:0]    rdata;
  wire [31:0]    prdata;
  wire           pready;
  wire           pslverr;
  wire           wr_en;
  wire           rd_en;

  // Golden model state and expected outputs
  reg            ref_pready;
  reg            ref_pslverr;
  reg            exp_pready;
  reg            exp_pslverr;
  reg            exp_wr_en;
  reg            exp_rd_en;
  reg  [31:0]    exp_prdata;

  // Counters and log names
  integer        pass_count;
  integer        fail_count;
  reg  [8*48-1:0] cyc_name;
  reg  [8*64-1:0] case_name;

  // Test case variables
  integer        i;
  reg  [31:0]    rd_pattern;

  // ============================================================
  // 2. DUT Instance
  // ============================================================
  apb_slave u_dut (
    .sys_clk     (clk),
    .sys_rst_n   (rst_n),
    .tim_psel    (psel),
    .tim_penable (penable),
    .tim_pwrite  (pwrite),
    .wr_err      (wr_err),
    .rdata       (rdata),
    .tim_prdata  (prdata),
    .tim_pready  (pready),
    .tim_pslverr (pslverr),
    .wr_en       (wr_en),
    .rd_en       (rd_en)
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
  // Idle inputs, assert async reset now, release at posedge + #1
  task reset_dut;
    begin
      psel    = 1'b0;
      penable = 1'b0;
      pwrite  = 1'b0;
      wr_err  = 1'b0;
      rdata   = 32'h0000_0000;
      rst_n   = 1'b0;
      ref_reset;
      repeat (RESET_CYCLES) @(posedge clk);
      #1;
      rst_n = 1'b1;
    end
  endtask

  // ============================================================
  // 5. Golden Reference Model
  // ============================================================
  // Reset state (spec: pready_q = 0, pslverr_q = 0)
  task ref_reset;
    begin
      ref_pready  = 1'b0;
      ref_pslverr = 1'b0;
    end
  endtask

  // Rising clock edge: update state from the inputs held in the last cycle.
  // The wait cycle is the first access cycle (pready = 0); it sets pready and
  // samples wr_err of a write into pslverr. Both clear one cycle later.
  task ref_clock;
    reg acc;
    reg wait_cyc;
    begin
      if (!rst_n) begin
        ref_reset;
      end
      else begin
        acc         = psel & penable;
        wait_cyc    = acc & ~ref_pready;
        ref_pslverr = wait_cyc & pwrite & wr_err;
        ref_pready  = wait_cyc;
      end
    end
  endtask

  // Expected outputs for the current state and inputs.
  // Strobes only in the last access cycle; no wr_en on an erroneous write.
  task ref_outputs;
    reg last_acc;
    begin
      last_acc    = psel & penable & ref_pready;
      exp_pready  = ref_pready;
      exp_pslverr = ref_pslverr;
      exp_wr_en   = last_acc & pwrite & ~ref_pslverr;
      exp_rd_en   = last_acc & ~pwrite;
      exp_prdata  = rdata;
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

  task check_word;
    input [8*64-1:0] name;
    input [31:0]     exp;
    input [31:0]     act;
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
      $sformat(case_name, "%0s_pready", name);
      check_bit(case_name, exp_pready, pready);
      $sformat(case_name, "%0s_pslverr", name);
      check_bit(case_name, exp_pslverr, pslverr);
      $sformat(case_name, "%0s_wr_en", name);
      check_bit(case_name, exp_wr_en, wr_en);
      $sformat(case_name, "%0s_rd_en", name);
      check_bit(case_name, exp_rd_en, rd_en);
      $sformat(case_name, "%0s_prdata", name);
      check_word(case_name, exp_prdata, prdata);
    end
  endtask

  // ============================================================
  // 7. Helper Functions
  // ============================================================

  // ============================================================
  // 8. Tasks
  // ============================================================
  // One clock cycle: update the model at the edge, drive the inputs at
  // posedge + #1, check all outputs at the falling edge (inputs still held)
  task apb_cycle;
    input            c_psel;
    input            c_penable;
    input            c_pwrite;
    input            c_wr_err;
    input [31:0]     c_rdata;
    input [8*48-1:0] name;
    begin
      @(posedge clk);
      #1;
      ref_clock;
      psel    = c_psel;
      penable = c_penable;
      pwrite  = c_pwrite;
      wr_err  = c_wr_err;
      rdata   = c_rdata;
      @(negedge clk);
      check_outputs(name);
    end
  endtask

  // Idle bus cycle
  task idle_cycle;
    input [8*48-1:0] name;
    begin
      apb_cycle(1'b0, 1'b0, 1'b0, 1'b0, 32'h0000_0000, name);
    end
  endtask

  // Full APB transfer: c0 setup, c1 wait, c2 last access.
  // wr_err is given per cycle; rdata is held for the whole transfer.
  task apb_transfer;
    input            t_pwrite;
    input            err_c0;
    input            err_c1;
    input            err_c2;
    input [31:0]     t_rdata;
    input [8*32-1:0] tag;
    begin
      $sformat(cyc_name, "%0s_c0_setup", tag);
      apb_cycle(1'b1, 1'b0, t_pwrite, err_c0, t_rdata, cyc_name);
      $sformat(cyc_name, "%0s_c1_wait", tag);
      apb_cycle(1'b1, 1'b1, t_pwrite, err_c1, t_rdata, cyc_name);
      $sformat(cyc_name, "%0s_c2_access", tag);
      apb_cycle(1'b1, 1'b1, t_pwrite, err_c2, t_rdata, cyc_name);
    end
  endtask

  // Release the async reset at posedge + #1
  task release_reset;
    begin
      @(posedge clk);
      #1;
      ref_clock;
      rst_n = 1'b1;
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
