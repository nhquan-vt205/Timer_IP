// ============================================================================
// Testbench : tb_timer_top - self-checking direct integration testbench of
//             timer_top (apb_slave, register, cnt_ctrl, counter, interrupt)
// Spec      : doc/spec/architecture/timer_top_spec.md
//             doc/spec/register_file/register_map.md
// Vplan     : doc/vplan/timer_top_vplan.md
// Test cases: tc/TC_TIMER_TOP_<NNN>.v, one per VPLAN Item, copied to
//             sim/run_test.v by "make build" and included in section 9
// Components (tb/, listed in sim/tb.f before this file):
//   u_clk_rst tb_timer_top_clk_rst clock/reset generator -> clk, rst_n
//   u_drv     tb_timer_top_drv     APB master + dbg_mode -> tim_p*, dbg_mode
//   u_mon     tb_timer_top_mon     monitor               -> s_* samples
//   u_model   tb_timer_top_model   golden reference model-> exp_*
//   u_chk     tb_timer_top_chk     checker               -> u_log.result
//   u_log     tb_timer_top_log     logger, owns pass_count / fail_count
// Dataflow  : tc -> u_drv -> u_dut -> u_mon -> u_model -> u_chk -> u_log
//                                     u_mon --------------> u_chk
//             u_dut tim_pready -> u_drv (APB handshake)
// ============================================================================
`timescale 1ns/1ps

module tb_timer_top;

  // ============================================================
  // 1. Declaration
  // ============================================================
  parameter CLK_PERIOD   = 20;
  parameter RESET_CYCLES = 2;
  parameter TIMEOUT_NS   = 200000;
  // Checker sample point: falling edge + CHK_DLY
  parameter CHK_DLY      = 1;
  // tim_int history depth of the checker (samples)
  parameter HIST_DEPTH   = 4096;
  // Log columns: time digits, case-name width, value digits (32-bit %h)
  parameter TIME_W       = 8;
  parameter NAME_W       = 40;
  parameter VAL_W        = 8;

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

  wire            clk;           // u_clk_rst
  wire            rst_n;         // u_clk_rst
  wire            tim_psel;      // u_drv
  wire            tim_penable;   // u_drv
  wire            tim_pwrite;    // u_drv
  wire [11:0]     tim_paddr;     // u_drv
  wire [31:0]     tim_pwdata;    // u_drv
  wire [3:0]      tim_pstrb;     // u_drv
  wire            dbg_mode;      // u_drv
  wire [31:0]     tim_prdata;    // u_dut
  wire            tim_pready;    // u_dut
  wire            tim_pslverr;   // u_dut
  wire            tim_int;       // u_dut
  wire            s_rst_n;       // u_mon
  wire            s_psel;        // u_mon
  wire            s_penable;     // u_mon
  wire            s_pwrite;      // u_mon
  wire [11:0]     s_paddr;       // u_mon
  wire [31:0]     s_pwdata;      // u_mon
  wire [3:0]      s_pstrb;       // u_mon
  wire            s_dbg_mode;    // u_mon
  wire [31:0]     s_prdata;      // u_mon
  wire            s_pready;      // u_mon
  wire            s_pslverr;     // u_mon
  wire            s_tim_int;     // u_mon
  wire            s_vld;         // u_mon
  wire [31:0]     exp_prdata;    // u_model
  wire            exp_pready;    // u_model
  wire            exp_pslverr;   // u_model
  wire            exp_tim_int;   // u_model

  // Variables of the test cases and of the sequence tasks
  integer         i;
  reg  [8*64-1:0] case_name;
  reg  [8*64-1:0] msg;

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
  tb_timer_top_clk_rst #(
    .CLK_PERIOD (CLK_PERIOD)
  ) u_clk_rst (
    .clk_o   (clk),
    .rst_n_o (rst_n)
  );

  // ============================================================
  // 4. Init Reset
  // ============================================================
  // Bus idle and dbg_mode = 0 now, asynchronous reset for RESET_CYCLES
  // edges, release at posedge + #1. DUT and model reset (model follows
  // rst_n); log counters are kept
  task reset_dut;
    begin
      u_drv.drive_idle;
      u_clk_rst.apply_reset(RESET_CYCLES);
    end
  endtask

  // ============================================================
  // 5. Golden Reference Model
  // ============================================================
  tb_timer_top_model u_model (
    .clk_i         (clk),
    .rst_n_i       (rst_n),
    .s_psel_i      (s_psel),
    .s_penable_i   (s_penable),
    .s_pwrite_i    (s_pwrite),
    .s_paddr_i     (s_paddr),
    .s_pwdata_i    (s_pwdata),
    .s_pstrb_i     (s_pstrb),
    .s_dbg_mode_i  (s_dbg_mode),
    .exp_prdata_o  (exp_prdata),
    .exp_pready_o  (exp_pready),
    .exp_pslverr_o (exp_pslverr),
    .exp_tim_int_o (exp_tim_int)
  );

  // ============================================================
  // 6. Checker
  // ============================================================
  // Monitor -> checker (with model) -> logger
  tb_timer_top_mon u_mon (
    .clk_i        (clk),
    .rst_n_i      (rst_n),
    .psel_i       (tim_psel),
    .penable_i    (tim_penable),
    .pwrite_i     (tim_pwrite),
    .paddr_i      (tim_paddr),
    .pwdata_i     (tim_pwdata),
    .pstrb_i      (tim_pstrb),
    .dbg_mode_i   (dbg_mode),
    .prdata_i     (tim_prdata),
    .pready_i     (tim_pready),
    .pslverr_i    (tim_pslverr),
    .tim_int_i    (tim_int),
    .s_rst_n_o    (s_rst_n),
    .s_psel_o     (s_psel),
    .s_penable_o  (s_penable),
    .s_pwrite_o   (s_pwrite),
    .s_paddr_o    (s_paddr),
    .s_pwdata_o   (s_pwdata),
    .s_pstrb_o    (s_pstrb),
    .s_dbg_mode_o (s_dbg_mode),
    .s_prdata_o   (s_prdata),
    .s_pready_o   (s_pready),
    .s_pslverr_o  (s_pslverr),
    .s_tim_int_o  (s_tim_int),
    .s_vld_o      (s_vld)
  );

  tb_timer_top_chk #(
    .CHK_DLY    (CHK_DLY),
    .HIST_DEPTH (HIST_DEPTH)
  ) u_chk (
    .clk_i         (clk),
    .s_rst_n_i     (s_rst_n),
    .s_psel_i      (s_psel),
    .s_penable_i   (s_penable),
    .s_pwrite_i    (s_pwrite),
    .s_paddr_i     (s_paddr),
    .s_pwdata_i    (s_pwdata),
    .s_pstrb_i     (s_pstrb),
    .s_prdata_i    (s_prdata),
    .s_pready_i    (s_pready),
    .s_pslverr_i   (s_pslverr),
    .s_tim_int_i   (s_tim_int),
    .s_vld_i       (s_vld),
    .exp_prdata_i  (exp_prdata),
    .exp_pready_i  (exp_pready),
    .exp_pslverr_i (exp_pslverr),
    .exp_tim_int_i (exp_tim_int)
  );

  tb_timer_top_log #(
    .TIME_W (TIME_W),
    .NAME_W (NAME_W),
    .VAL_W  (VAL_W)
  ) u_log ();

  // ============================================================
  // 7. Helper Functions
  // ============================================================

  // ============================================================
  // 8. Tasks
  // ============================================================
  // Stimulus driver, called by the test case and the tasks below
  tb_timer_top_drv u_drv (
    .clk_i      (clk),
    .pready_i   (tim_pready),
    .psel_o     (tim_psel),
    .penable_o  (tim_penable),
    .pwrite_o   (tim_pwrite),
    .paddr_o    (tim_paddr),
    .pwdata_o   (tim_pwdata),
    .pstrb_o    (tim_pstrb),
    .dbg_mode_o (dbg_mode)
  );

  // APB write; tim_pslverr of the last access cycle against the VPLAN
  // value exp_err
  task apb_write;
    input [11:0] addr;
    input [31:0] wdata;
    input [3:0]  strb;
    input        exp_err;
    begin
      u_drv.apb_write(addr, wdata, strb);
      $sformat(case_name, "wr_%h_%h_s%h_vplan_pslverr", addr, wdata, strb);
      u_chk.expect_pslverr(case_name, exp_err);
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

  // APB read; tim_prdata of the last access cycle against the VPLAN value
  task apb_rd;
    input [11:0] addr;
    input [31:0] exp;
    begin
      u_drv.apb_read(addr);
      $sformat(case_name, "rd_%h_vplan_prdata", addr);
      u_chk.expect_prdata(case_name, exp);
    end
  endtask

  // Read the eight registers and compare with the register-map reset values
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

  // Once per Item, before its first header
  task init_test;
    begin
      u_log.init;
      u_chk.enable(1'b1);
    end
  endtask

  // Once per Item: summary, Test_result, end of simulation
  task end_test;
    begin
      u_log.summary;
      $finish;
    end
  endtask

  // ============================================================
  // 9. Main Program Body
  // ============================================================
  // Test sequence of the selected Item (tc/<ID>.v)
`include "run_test.v"

  initial begin
    #(TIMEOUT_NS);
    $sformat(msg, "[TIMEOUT] simulation exceeded %0d ns", TIMEOUT_NS);
    u_log.error_msg(msg);
    end_test;
  end

endmodule
