// ============================================================================
// Testbench : tb_register
// Function  : Self-checking direct testbench for register. Acts as apb_slave
//             (drives wr_en, rd_en, tim_paddr, tim_pwdata, tim_pstrb) and as
//             the counter / interrupt / cnt_ctrl blocks (drives cnt, int_st,
//             halt_ack), and checks every DUT output in every cycle against
//             a golden model of the spec and register map.
// Spec      : doc/spec/architecture/register_spec.md
//             doc/spec/register_file/register_map.md
// Vplan     : doc/vplan/register_vplan.md
// Test cases: tc/TC_REGISTER_<NNN>.v, copied to sim/run_test.v by
//             "make build" and included in section 9.
// ============================================================================
`timescale 1ns/1ps

module tb_register;

  // ============================================================
  // 1. Declaration
  // ============================================================
  parameter CLK_PERIOD   = 20;
  parameter RESET_CYCLES = 2;
  parameter TIMEOUT_NS   = 100000;

  // DUT signals
  reg            clk;
  reg            rst_n;
  reg            wr_en;
  reg            rd_en;
  reg  [11:0]    paddr;
  reg  [31:0]    pwdata;
  reg  [3:0]     pstrb;
  reg  [63:0]    cnt;
  reg            int_st;
  reg            halt_ack;
  wire           wr_err;
  wire [31:0]    rdata;
  wire           tim_en;
  wire           div_en;
  wire [3:0]     div_val;
  wire           halt_req;
  wire [3:0]     tdr0_wr_en;
  wire [3:0]     tdr1_wr_en;
  wire [31:0]    tcmp0;
  wire [31:0]    tcmp1;
  wire           int_en;
  wire           int_st_clr;

  // Status input values applied by the next driven cycle
  reg  [63:0]    nxt_cnt;
  reg            nxt_int_st;
  reg            nxt_halt_ack;

  // Golden model state
  reg            ref_tim_en;
  reg            ref_div_en;
  reg  [3:0]     ref_div_val;
  reg  [31:0]    ref_tcmp0;
  reg  [31:0]    ref_tcmp1;
  reg            ref_int_en;
  reg            ref_halt_req;

  // Golden model expected outputs
  reg            exp_wr_err;
  reg  [31:0]    exp_rdata;
  reg  [3:0]     exp_tdr0_wr_en;
  reg  [3:0]     exp_tdr1_wr_en;
  reg            exp_int_st_clr;

  // Counters and log names
  integer        pass_count;
  integer        fail_count;
  reg  [8*48-1:0] cyc_name;
  reg  [8*64-1:0] case_name;

  // Test case variables
  integer        i;
  reg  [31:0]    pattern;

  // ============================================================
  // 2. DUT Instance
  // ============================================================
  register u_dut (
    .sys_clk    (clk),
    .sys_rst_n  (rst_n),
    .wr_en      (wr_en),
    .rd_en      (rd_en),
    .tim_paddr  (paddr),
    .tim_pwdata (pwdata),
    .tim_pstrb  (pstrb),
    .cnt        (cnt),
    .int_st     (int_st),
    .halt_ack   (halt_ack),
    .wr_err     (wr_err),
    .rdata      (rdata),
    .tim_en     (tim_en),
    .div_en     (div_en),
    .div_val    (div_val),
    .halt_req   (halt_req),
    .tdr0_wr_en (tdr0_wr_en),
    .tdr1_wr_en (tdr1_wr_en),
    .tcmp0      (tcmp0),
    .tcmp1      (tcmp1),
    .int_en     (int_en),
    .int_st_clr (int_st_clr)
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
      wr_en        = 1'b0;
      rd_en        = 1'b0;
      paddr        = 12'h000;
      pwdata       = 32'h0000_0000;
      pstrb        = 4'b0000;
      cnt          = 64'h0;
      int_st       = 1'b0;
      halt_ack     = 1'b0;
      nxt_cnt      = 64'h0;
      nxt_int_st   = 1'b0;
      nxt_halt_ack = 1'b0;
      rst_n        = 1'b0;
      ref_reset;
      repeat (RESET_CYCLES) @(posedge clk);
      #1;
      rst_n = 1'b1;
    end
  endtask

  // ============================================================
  // 5. Golden Reference Model
  // ============================================================
  // Reset values (register map)
  task ref_reset;
    begin
      ref_tim_en   = 1'b0;
      ref_div_en   = 1'b0;
      ref_div_val  = 4'h1;
      ref_tcmp0    = 32'hFFFF_FFFF;
      ref_tcmp1    = 32'hFFFF_FFFF;
      ref_int_en   = 1'b0;
      ref_halt_req = 1'b0;
    end
  endtask

  // Rising clock edge: apply the write held in the last cycle.
  // Only strobed bytes of the addressed register change.
  task ref_clock;
    integer k;
    begin
      if (!rst_n) begin
        ref_reset;
      end
      else if (wr_en) begin
        case (paddr[11:2])
          10'h000 : begin
            if (pstrb[0]) begin
              ref_tim_en = pwdata[0];
              ref_div_en = pwdata[1];
            end
            if (pstrb[1]) begin
              ref_div_val = pwdata[11:8];
            end
          end
          10'h003 : begin
            for (k = 0; k < 4; k = k + 1) begin
              if (pstrb[k]) begin
                ref_tcmp0[8*k +: 8] = pwdata[8*k +: 8];
              end
            end
          end
          10'h004 : begin
            for (k = 0; k < 4; k = k + 1) begin
              if (pstrb[k]) begin
                ref_tcmp1[8*k +: 8] = pwdata[8*k +: 8];
              end
            end
          end
          10'h005 : begin
            if (pstrb[0]) begin
              ref_int_en = pwdata[0];
            end
          end
          10'h007 : begin
            if (pstrb[0]) begin
              ref_halt_req = pwdata[0];
            end
          end
          default : begin
            // TDR0/TDR1/TISR are stored outside; reserved: write ignored
          end
        endcase
      end
    end
  endtask

  // Expected combinational outputs for the current state and inputs
  task ref_outputs;
    reg is_tcr;
    begin
      is_tcr = (paddr[11:2] == 10'h000);

      // Forbidden TCR write (register map, Error response)
      exp_wr_err = is_tcr &
                   ((pstrb[1] & (pwdata[11:8] > 4'd8)) |
                    (ref_tim_en & pstrb[1] & (pwdata[11:8] != ref_div_val)) |
                    (ref_tim_en & pstrb[0] & (pwdata[1] != ref_div_en)));

      exp_tdr0_wr_en = (wr_en && paddr[11:2] == 10'h001) ? pstrb : 4'h0;
      exp_tdr1_wr_en = (wr_en && paddr[11:2] == 10'h002) ? pstrb : 4'h0;
      exp_int_st_clr = wr_en & (paddr[11:2] == 10'h006) & pstrb[0] & pwdata[0];

      if (rd_en) begin
        exp_rdata = read_word(paddr[11:2]);
      end
      else begin
        exp_rdata = 32'h0000_0000;
      end
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

  task check_nib;
    input [8*64-1:0] name;
    input [3:0]      exp;
    input [3:0]      act;
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
      $sformat(case_name, "%0s_rdata", name);
      check_word(case_name, exp_rdata, rdata);
      $sformat(case_name, "%0s_wr_err", name);
      check_bit(case_name, exp_wr_err, wr_err);
      $sformat(case_name, "%0s_tim_en", name);
      check_bit(case_name, ref_tim_en, tim_en);
      $sformat(case_name, "%0s_div_en", name);
      check_bit(case_name, ref_div_en, div_en);
      $sformat(case_name, "%0s_div_val", name);
      check_nib(case_name, ref_div_val, div_val);
      $sformat(case_name, "%0s_tcmp0", name);
      check_word(case_name, ref_tcmp0, tcmp0);
      $sformat(case_name, "%0s_tcmp1", name);
      check_word(case_name, ref_tcmp1, tcmp1);
      $sformat(case_name, "%0s_int_en", name);
      check_bit(case_name, ref_int_en, int_en);
      $sformat(case_name, "%0s_halt_req", name);
      check_bit(case_name, ref_halt_req, halt_req);
      $sformat(case_name, "%0s_tdr0_wr_en", name);
      check_nib(case_name, exp_tdr0_wr_en, tdr0_wr_en);
      $sformat(case_name, "%0s_tdr1_wr_en", name);
      check_nib(case_name, exp_tdr1_wr_en, tdr1_wr_en);
      $sformat(case_name, "%0s_int_st_clr", name);
      check_bit(case_name, exp_int_st_clr, int_st_clr);
    end
  endtask

  // ============================================================
  // 7. Helper Functions
  // ============================================================
  // Register map read value of a word address (reserved: 0)
  function [31:0] read_word;
    input [9:0] word;
    begin
      case (word)
        10'h000 : read_word = {20'h0, ref_div_val, 6'h0, ref_div_en, ref_tim_en};
        10'h001 : read_word = cnt[31:0];
        10'h002 : read_word = cnt[63:32];
        10'h003 : read_word = ref_tcmp0;
        10'h004 : read_word = ref_tcmp1;
        10'h005 : read_word = {31'h0, ref_int_en};
        10'h006 : read_word = {31'h0, int_st};
        10'h007 : read_word = {30'h0, halt_ack, ref_halt_req};
        default : read_word = 32'h0000_0000;
      endcase
    end
  endfunction

  // ============================================================
  // 8. Tasks
  // ============================================================
  // One clock cycle: update the model at the edge, drive all inputs at
  // posedge + #1, check all outputs at the falling edge (inputs still held).
  // The case name is built from the driven inputs.
  task bus_cycle;
    input        c_wr_en;
    input        c_rd_en;
    input [11:0] c_addr;
    input [31:0] c_wdata;
    input [3:0]  c_strb;
    begin
      @(posedge clk);
      #1;
      ref_clock;
      wr_en    = c_wr_en;
      rd_en    = c_rd_en;
      paddr    = c_addr;
      pwdata   = c_wdata;
      pstrb    = c_strb;
      cnt      = nxt_cnt;
      int_st   = nxt_int_st;
      halt_ack = nxt_halt_ack;
      if (c_wr_en) begin
        $sformat(cyc_name, "wr_a%h_d%h_s%h", c_addr, c_wdata, c_strb);
      end
      else if (c_rd_en) begin
        case (c_addr[11:2])
          10'h001, 10'h002 : $sformat(cyc_name, "rd_a%h_cnt%h", c_addr, nxt_cnt);
          10'h006          : $sformat(cyc_name, "rd_a%h_int_st%0d", c_addr, nxt_int_st);
          10'h007          : $sformat(cyc_name, "rd_a%h_halt_ack%0d", c_addr, nxt_halt_ack);
          default          : $sformat(cyc_name, "rd_a%h", c_addr);
        endcase
      end
      else if (c_addr != 12'h000 || c_wdata != 32'h0 || c_strb != 4'h0) begin
        $sformat(cyc_name, "nowr_a%h_d%h_s%h", c_addr, c_wdata, c_strb);
      end
      else begin
        $sformat(cyc_name, "idle");
      end
      @(negedge clk);
      check_outputs(cyc_name);
    end
  endtask

  // Register write with byte strobes (one cycle, wr_en = 1)
  task reg_write;
    input [11:0] addr;
    input [31:0] wdata;
    input [3:0]  strb;
    begin
      bus_cycle(1'b1, 1'b0, addr, wdata, strb);
    end
  endtask

  // Register read (one cycle, rd_en = 1)
  task reg_read;
    input [11:0] addr;
    begin
      bus_cycle(1'b0, 1'b1, addr, 32'h0000_0000, 4'b0000);
    end
  endtask

  // Inputs applied without wr_en / rd_en (combinational checks only)
  task no_write;
    input [11:0] addr;
    input [31:0] wdata;
    input [3:0]  strb;
    begin
      bus_cycle(1'b0, 1'b0, addr, wdata, strb);
    end
  endtask

  // Idle cycle
  task idle_cycle;
    begin
      bus_cycle(1'b0, 1'b0, 12'h000, 32'h0000_0000, 4'b0000);
    end
  endtask

  // Read all eight registers
  task read_all;
    begin
      for (i = 0; i < 8; i = i + 1) begin
        reg_read(i * 4);
      end
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
