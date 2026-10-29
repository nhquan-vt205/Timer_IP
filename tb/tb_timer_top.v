// ============================================================================
// Testbench : tb_timer_top
// Function  : Self-checking direct integration testbench for timer_top. Acts
//             as the APB master and the debug controller, drives only the
//             top-level ports and checks tim_pready, tim_pslverr, tim_prdata
//             and tim_int in every cycle against a cycle-accurate golden
//             model of the whole IP. Read data and error responses are also
//             checked against the values of the vplan.
// Spec      : doc/spec/architecture/timer_top_spec.md
//             doc/spec/register_file/register_map.md
// Vplan     : doc/vplan/timer_top_vplan.md
// Test cases: tc/TC_TIMER_TOP_<NNN>.v, copied to sim/run_test.v by
//             "make build" and included in section 9.
// ============================================================================
`timescale 1ns/1ps

module tb_timer_top;

  // ============================================================
  // 1. Declaration
  // ============================================================
  parameter CLK_PERIOD   = 20;
  parameter RESET_CYCLES = 2;
  parameter TIMEOUT_NS   = 200000;

  // Register offsets
  parameter ADDR_TCR   = 12'h000;
  parameter ADDR_TDR0  = 12'h004;
  parameter ADDR_TDR1  = 12'h008;
  parameter ADDR_TCMP0 = 12'h00C;
  parameter ADDR_TCMP1 = 12'h010;
  parameter ADDR_TIER  = 12'h014;
  parameter ADDR_TISR  = 12'h018;
  parameter ADDR_THCSR = 12'h01C;
  parameter ADDR_RSVD  = 12'h020;

  // DUT signals
  reg            clk;
  reg            rst_n;
  reg            tim_psel;
  reg            tim_pwrite;
  reg            tim_penable;
  reg  [11:0]    tim_paddr;
  reg  [31:0]    tim_pwdata;
  reg  [3:0]     tim_pstrb;
  reg            dbg_mode;
  wire [31:0]    tim_prdata;
  wire           tim_pready;
  wire           tim_pslverr;
  wire           tim_int;

  // Golden model state (registers of the IP)
  reg            ref_pready;
  reg            ref_pslverr;
  reg            ref_tim_en;
  reg            ref_div_en;
  reg  [3:0]     ref_div_val;
  reg  [31:0]    ref_tcmp0;
  reg  [31:0]    ref_tcmp1;
  reg            ref_int_en;
  reg            ref_halt_req;
  reg  [63:0]    ref_cnt;
  reg  [7:0]     ref_div_cnt;
  reg            ref_tim_en_d;
  reg            ref_int_st;

  // Golden model combinational values
  reg            ref_acc;
  reg            ref_wr_en;
  reg            ref_rd_en;
  reg            ref_wr_err;
  reg            ref_halted;
  reg            ref_match;
  reg            ref_cnt_en;
  reg            ref_cnt_clr;
  reg  [31:0]    ref_rdata;
  reg            ref_tim_int;

  // Next value of dbg_mode, applied with the next stimulus edge
  reg            dbg_val;

  // Counters, cycle index and log names
  integer        pass_count;
  integer        fail_count;
  integer        cycle;
  integer        e0;
  integer        i;
  reg  [8*64-1:0] tag;
  reg  [8*64-1:0] cyc_name;

  // tim_int sampled in every cycle, indexed by cycle (checked later against
  // the per-cycle vplan values)
  parameter HIST_DEPTH = 4096;
  reg            int_hist [0:HIST_DEPTH-1];

  // ============================================================
  // 2. DUT Instance
  // ============================================================
  timer_top u_dut (
    .sys_clk     (clk),
    .sys_rst_n   (rst_n),
    .tim_psel    (tim_psel),
    .tim_pwrite  (tim_pwrite),
    .tim_penable (tim_penable),
    .tim_paddr   (tim_paddr),
    .tim_pwdata  (tim_pwdata),
    .tim_pstrb   (tim_pstrb),
    .tim_prdata  (tim_prdata),
    .tim_pready  (tim_pready),
    .tim_pslverr (tim_pslverr),
    .tim_int     (tim_int),
    .dbg_mode    (dbg_mode)
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
  // Bus idle, dbg_mode = 0, assert async reset now, release at posedge + #1
  task reset_dut;
    begin
      bus_idle_now;
      dbg_val  = 1'b0;
      dbg_mode = 1'b0;
      rst_n    = 1'b0;
      ref_reset;
      repeat (RESET_CYCLES) @(posedge clk);
      #1;
      rst_n = 1'b1;
      cycle = 0;
    end
  endtask

  // ============================================================
  // 5. Golden Reference Model
  // ============================================================
  // Reset values (register map)
  task ref_reset;
    begin
      ref_pready   = 1'b0;
      ref_pslverr  = 1'b0;
      ref_tim_en   = 1'b0;
      ref_div_en   = 1'b0;
      ref_div_val  = 4'h1;
      ref_tcmp0    = 32'hFFFF_FFFF;
      ref_tcmp1    = 32'hFFFF_FFFF;
      ref_int_en   = 1'b0;
      ref_halt_req = 1'b0;
      ref_cnt      = 64'h0;
      ref_div_cnt  = 8'h0;
      ref_tim_en_d = 1'b0;
      ref_int_st   = 1'b0;
    end
  endtask

  // Combinational values from the state and the inputs of this cycle
  task ref_comb;
    reg       sel_tcr;
    reg [8:0] limit;
    begin
      // APB: one wait state, write only without error
      ref_acc    = tim_psel & tim_penable;
      ref_wr_en  = ref_acc & ref_pready & tim_pwrite & ~ref_pslverr;
      ref_rd_en  = ref_acc & ref_pready & ~tim_pwrite;
      // TCR error conditions 1-3
      sel_tcr    = (tim_paddr[11:2] == ADDR_TCR[11:2]);
      ref_wr_err = sel_tcr &
                   ((tim_pstrb[1] & (tim_pwdata[11:8] > 4'd8)) |
                    (ref_tim_en & ((tim_pstrb[1] & (tim_pwdata[11:8] != ref_div_val)) |
                                   (tim_pstrb[0] & (tim_pwdata[1] != ref_div_en)))));
      // Counter control: divide by 2^DIV_VAL, halt, clear on TIM_EN H->L
      limit       = (9'd1 << ref_div_val) - 9'd1;
      ref_halted  = dbg_mode & ref_halt_req;
      ref_match   = (ref_div_cnt == limit[7:0]);
      ref_cnt_en  = ref_tim_en & ~ref_halted & (~ref_div_en | ref_match);
      ref_cnt_clr = ref_tim_en_d & ~ref_tim_en;
      // Read data, 0 outside the read access cycle
      ref_rdata   = ref_rd_en ? read_word(tim_paddr) : 32'h0;
      ref_tim_int = ref_int_st & ref_int_en;
    end
  endtask

  // Rising clock edge: update the state from the inputs held in the last cycle
  task ref_clock;
    reg        nxt_pready;
    reg        nxt_pslverr;
    reg        cnt_match;
    reg        int_st_clr;
    reg        sel;
    begin
      if (!rst_n) begin
        ref_reset;
      end
      else begin
        ref_comb;
        nxt_pready  = ref_acc & ~ref_pready;
        nxt_pslverr = ref_acc & ~ref_pready & tim_pwrite & ref_wr_err;
        cnt_match   = (ref_cnt == {ref_tcmp1, ref_tcmp0});
        int_st_clr  = ref_wr_en & (tim_paddr[11:2] == ADDR_TISR[11:2]) &
                      tim_pstrb[0] & tim_pwdata[0];

        // Interrupt status: clear > set > hold
        if (int_st_clr) begin
          ref_int_st = 1'b0;
        end
        else if (cnt_match) begin
          ref_int_st = 1'b1;
        end

        // Divider: clear when TIM_EN = 0 or DIV_EN = 0, hold while halted
        if (!ref_tim_en || !ref_div_en) begin
          ref_div_cnt = 8'h0;
        end
        else if (!ref_halted) begin
          ref_div_cnt = ref_match ? 8'h0 : ref_div_cnt + 8'd1;
        end

        // Counter: clear > software byte write > count
        sel = ref_wr_en & ((tim_paddr[11:2] == ADDR_TDR0[11:2]) |
                           (tim_paddr[11:2] == ADDR_TDR1[11:2]));
        if (ref_cnt_clr) begin
          ref_cnt = 64'h0;
        end
        else if (sel && (tim_pstrb != 4'h0)) begin
          ref_cnt = tdr_merge(ref_cnt, tim_paddr[3], tim_pstrb, tim_pwdata);
        end
        else if (ref_cnt_en) begin
          ref_cnt = ref_cnt + 64'd1;
        end
        ref_tim_en_d = ref_tim_en;

        // Register writes (byte strobes)
        if (ref_wr_en) begin
          reg_write(tim_paddr, tim_pwdata, tim_pstrb);
        end

        ref_pready  = nxt_pready;
        ref_pslverr = nxt_pslverr;
      end
    end
  endtask

  // Register write of the golden model (TDR0/TDR1/TISR handled in ref_clock)
  task reg_write;
    input [11:0] addr;
    input [31:0] wdata;
    input [3:0]  strb;
    integer      k;
    begin
      case (addr[11:2])
        ADDR_TCR[11:2]: begin
          if (strb[0]) begin
            ref_tim_en = wdata[0];
            ref_div_en = wdata[1];
          end
          if (strb[1]) begin
            ref_div_val = wdata[11:8];
          end
        end
        ADDR_TCMP0[11:2]: begin
          for (k = 0; k < 4; k = k + 1) begin
            if (strb[k]) begin
              ref_tcmp0[8*k +: 8] = wdata[8*k +: 8];
            end
          end
        end
        ADDR_TCMP1[11:2]: begin
          for (k = 0; k < 4; k = k + 1) begin
            if (strb[k]) begin
              ref_tcmp1[8*k +: 8] = wdata[8*k +: 8];
            end
          end
        end
        ADDR_TIER[11:2]: begin
          if (strb[0]) begin
            ref_int_en = wdata[0];
          end
        end
        ADDR_THCSR[11:2]: begin
          if (strb[0]) begin
            ref_halt_req = wdata[0];
          end
        end
        default: begin
        end
      endcase
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

  // Every top-level output against the golden model
  task check_outputs;
    input [8*64-1:0] name;
    begin
      $sformat(cyc_name, "%0s_pready", name);
      check_val(cyc_name, ref_pready, tim_pready);
      $sformat(cyc_name, "%0s_pslverr", name);
      check_val(cyc_name, ref_pslverr, tim_pslverr);
      $sformat(cyc_name, "%0s_prdata", name);
      check_val(cyc_name, ref_rdata, tim_prdata);
      $sformat(cyc_name, "%0s_tim_int", name);
      check_val(cyc_name, ref_tim_int, tim_int);
    end
  endtask

  // ============================================================
  // 7. Helper Functions
  // ============================================================
  // Read mux of the register map (reserved addresses read 0)
  function [31:0] read_word;
    input [11:0] addr;
    begin
      case (addr[11:2])
        ADDR_TCR[11:2]   : read_word = {20'h0, ref_div_val, 6'h0, ref_div_en, ref_tim_en};
        ADDR_TDR0[11:2]  : read_word = ref_cnt[31:0];
        ADDR_TDR1[11:2]  : read_word = ref_cnt[63:32];
        ADDR_TCMP0[11:2] : read_word = ref_tcmp0;
        ADDR_TCMP1[11:2] : read_word = ref_tcmp1;
        ADDR_TIER[11:2]  : read_word = {31'h0, ref_int_en};
        ADDR_TISR[11:2]  : read_word = {31'h0, ref_int_st};
        ADDR_THCSR[11:2] : read_word = {30'h0, dbg_mode & ref_halt_req, ref_halt_req};
        default          : read_word = 32'h0;
      endcase
    end
  endfunction

  // Software write of TDR0 (hi = 0) or TDR1 (hi = 1), strobed bytes only
  function [63:0] tdr_merge;
    input [63:0] old;
    input        hi;
    input [3:0]  strb;
    input [31:0] wdata;
    integer      k;
    begin
      tdr_merge = old;
      for (k = 0; k < 4; k = k + 1) begin
        if (strb[k]) begin
          tdr_merge[32 * hi + 8 * k +: 8] = wdata[8 * k +: 8];
        end
      end
    end
  endfunction

  // ============================================================
  // 8. Tasks
  // ============================================================
  // Bus idle values without waiting for an edge (reset only)
  task bus_idle_now;
    begin
      tim_psel    = 1'b0;
      tim_penable = 1'b0;
      tim_pwrite  = 1'b0;
      tim_paddr   = 12'h0;
      tim_pwdata  = 32'h0;
      tim_pstrb   = 4'h0;
    end
  endtask

  // One clock cycle: update the model at the edge, drive every input at
  // posedge + #1 (dbg_mode from dbg_val), check all outputs at the falling edge
  task tick;
    input        c_rst_n;
    input        c_psel;
    input        c_penable;
    input        c_pwrite;
    input [11:0] c_paddr;
    input [31:0] c_pwdata;
    input [3:0]  c_pstrb;
    input [8*64-1:0] name;
    begin
      @(posedge clk);
      #1;
      ref_clock;
      rst_n       = c_rst_n;
      tim_psel    = c_psel;
      tim_penable = c_penable;
      tim_pwrite  = c_pwrite;
      tim_paddr   = c_paddr;
      tim_pwdata  = c_pwdata;
      tim_pstrb   = c_pstrb;
      dbg_mode    = dbg_val;
      if (!c_rst_n) begin
        ref_reset;
      end
      cycle = cycle + 1;
      @(negedge clk);
      ref_comb;
      check_outputs(name);
      if (cycle < HIST_DEPTH) begin
        int_hist[cycle] = tim_int;
      end
    end
  endtask

  // APB write: setup, wait, last access; tim_pslverr in the last access
  // cycle is also checked against the vplan value exp_err
  task apb_write;
    input [11:0] addr;
    input [31:0] wdata;
    input [3:0]  strb;
    input        exp_err;
    begin
      $sformat(tag, "wr_%h_%h_s%h", addr, wdata, strb);
      $sformat(cyc_name, "%0s_setup", tag);
      tick(1'b1, 1'b1, 1'b0, 1'b1, addr, wdata, strb, cyc_name);
      $sformat(cyc_name, "%0s_wait", tag);
      tick(1'b1, 1'b1, 1'b1, 1'b1, addr, wdata, strb, cyc_name);
      $sformat(cyc_name, "%0s_access", tag);
      tick(1'b1, 1'b1, 1'b1, 1'b1, addr, wdata, strb, cyc_name);
      $sformat(cyc_name, "%0s_vplan_pslverr", tag);
      check_val(cyc_name, exp_err, tim_pslverr);
    end
  endtask

  // APB write without error
  task apb_wr;
    input [11:0] addr;
    input [31:0] wdata;
    input [3:0]  strb;
    begin
      apb_write(addr, wdata, strb, 1'b0);
    end
  endtask

  // APB read; tim_prdata in the last access cycle is also checked against
  // the vplan value exp
  task apb_rd;
    input [11:0] addr;
    input [31:0] exp;
    begin
      $sformat(tag, "rd_%h", addr);
      $sformat(cyc_name, "%0s_setup", tag);
      tick(1'b1, 1'b1, 1'b0, 1'b0, addr, 32'h0, 4'h0, cyc_name);
      $sformat(cyc_name, "%0s_wait", tag);
      tick(1'b1, 1'b1, 1'b1, 1'b0, addr, 32'h0, 4'h0, cyc_name);
      $sformat(cyc_name, "%0s_access", tag);
      tick(1'b1, 1'b1, 1'b1, 1'b0, addr, 32'h0, 4'h0, cyc_name);
      $sformat(cyc_name, "%0s_vplan_prdata", tag);
      check_val(cyc_name, exp, tim_prdata);
    end
  endtask

  // n idle cycles (tim_psel = 0)
  task idle_n;
    input integer n;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1) begin
        tick(1'b1, 1'b0, 1'b0, 1'b0, 12'h0, 32'h0, 4'h0, "idle");
      end
    end
  endtask

  // tim_int sampled in cycle e0 + n against the vplan value
  task check_int_at;
    input integer n;
    input         exp;
    begin
      $sformat(cyc_name, "ref_plus_%0d_vplan_tim_int", n);
      check_val(cyc_name, exp, int_hist[e0 + n]);
    end
  endtask

  // Reference cycle e0: the cycle after the current one (call right after
  // the TCR write that sets TIM_EN)
  task mark_e0;
    begin
      e0 = cycle + 1;
    end
  endtask

  // Reference cycle: the current cycle (e.g. c1 of TC_TIMER_TOP_010)
  task mark_now;
    begin
      e0 = cycle;
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
      ref_comb;
      check_outputs("rst_asserted_mid_cycle");
    end
  endtask

  // n cycles with sys_rst_n held at 0, bus idle
  task hold_reset;
    input integer n;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1) begin
        tick(1'b0, 1'b0, 1'b0, 1'b0, 12'h0, 32'h0, 4'h0, "in_reset");
      end
    end
  endtask

  // Read all eight registers and compare with the reset values
  task read_reset_values;
    begin
      apb_rd(ADDR_TCR,   32'h0000_0100);
      apb_rd(ADDR_TDR0,  32'h0);
      apb_rd(ADDR_TDR1,  32'h0);
      apb_rd(ADDR_TCMP0, 32'hFFFF_FFFF);
      apb_rd(ADDR_TCMP1, 32'hFFFF_FFFF);
      apb_rd(ADDR_TIER,  32'h0);
      apb_rd(ADDR_TISR,  32'h0);
      apb_rd(ADDR_THCSR, 32'h0);
    end
  endtask

  // Counters; call first in every test case
  task init_test;
    begin
      pass_count = 0;
      fail_count = 0;
      cycle      = 0;
      e0         = 0;
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
