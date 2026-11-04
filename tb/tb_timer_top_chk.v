// ============================================================================
// Component : tb_timer_top_chk - checker of tb_timer_top
// Inputs    : expected outputs from u_model, sampled pins from u_mon
// Results   : every comparison goes to tb_timer_top.u_log.result
// Timing    : handles each valid monitor sample at falling edge + CHK_DLY
//             (sample and model outputs stable; stimulus only changes at
//             posedge + #1), in this order:
//   - sample index smp_cnt + 1 and tim_int history (for expect_int_at)
//   - automatic check: every sample while enabled, the four outputs
//     tim_pready, tim_pslverr, tim_prdata, tim_int (model vs DUT)
//   - directed check : expect_prdata / expect_pslverr / expect_reset_out
//                      compare VPLAN values with the next sample (the last
//                      sample of a driver task that returned at this falling
//                      edge) and return after the comparison
// Cycle reference: mark_e0 / mark_now store the sample index of the VPLAN
//             reference cycle (e0 = cycle after the current one, c1 = the
//             current one); expect_int_at(n, exp) compares the tim_int
//             sample of reference + n from the history, after that sample
//             has been processed.
// Ownership : auto_en (enable), dir_* request fields and dir_req
//             (expect_*), dir_ack, smp_cnt and int_hist (compare process),
//             ref_idx (mark_e0 / mark_now)
// ============================================================================
`timescale 1ns/1ps

module tb_timer_top_chk #(
  parameter CHK_DLY    = 1,
  parameter HIST_DEPTH = 4096
) (
  input  wire        clk_i,
  input  wire        s_rst_n_i,
  input  wire        s_psel_i,
  input  wire        s_penable_i,
  input  wire        s_pwrite_i,
  input  wire [11:0] s_paddr_i,
  input  wire [31:0] s_pwdata_i,
  input  wire [3:0]  s_pstrb_i,
  input  wire [31:0] s_prdata_i,
  input  wire        s_pready_i,
  input  wire        s_pslverr_i,
  input  wire        s_tim_int_i,
  input  wire        s_vld_i,
  input  wire [31:0] exp_prdata_i,
  input  wire        exp_pready_i,
  input  wire        exp_pslverr_i,
  input  wire        exp_tim_int_i
);

  // Directed check kinds
  localparam [1:0] K_PRDATA  = 2'd0;
  localparam [1:0] K_PSLVERR = 2'd1;
  localparam [1:0] K_RESET   = 2'd2;

  reg             auto_en;
  integer         dir_req;
  integer         dir_ack;
  reg  [1:0]      dir_kind;
  reg  [31:0]     dir_exp;
  reg  [8*64-1:0] dir_name;
  integer         smp_cnt;
  integer         ref_idx;
  reg             int_hist [0:HIST_DEPTH-1];
  reg  [8*64-1:0] base;
  reg  [8*64-1:0] cname;
  reg  [8*64-1:0] exp_s;
  reg  [8*64-1:0] act_s;

  initial begin
    auto_en = 1'b0;
    dir_req = 0;
    dir_ack = 0;
    smp_cnt = 0;
    ref_idx = 0;
  end

  // Turn the automatic per-cycle check on or off
  task enable;
    input on;
    begin
      auto_en = on;
    end
  endtask

  // Directed checks of VPLAN values against the next monitor sample
  task expect_prdata;
    input [8*64-1:0] name;
    input [31:0]     exp;
    begin
      dir_name = name;
      dir_kind = K_PRDATA;
      dir_exp  = exp;
      dir_req  = dir_req + 1;
      wait (dir_ack == dir_req);
    end
  endtask

  task expect_pslverr;
    input [8*64-1:0] name;
    input            exp;
    begin
      dir_name = name;
      dir_kind = K_PSLVERR;
      dir_exp  = {31'h0, exp};
      dir_req  = dir_req + 1;
      wait (dir_ack == dir_req);
    end
  endtask

  // All four outputs at their reset value 0
  task expect_reset_out;
    input [8*64-1:0] name;
    begin
      dir_name = name;
      dir_kind = K_RESET;
      dir_exp  = 32'h0;
      dir_req  = dir_req + 1;
      wait (dir_ack == dir_req);
    end
  endtask

  // Reference cycle: e0 = the cycle after the current one (call right
  // after the TCR write that sets TIM_EN), or the current cycle (c1)
  task mark_e0;
    begin
      ref_idx = smp_cnt + 1;
    end
  endtask

  task mark_now;
    begin
      ref_idx = smp_cnt;
    end
  endtask

  // tim_int sampled in cycle reference + n against the VPLAN value; waits
  // until the compare process has stored that sample (a driver task returns
  // at the falling edge, before the sample of that edge is processed)
  task expect_int_at;
    input integer n;
    input         exp;
    begin
      wait (smp_cnt >= ref_idx + n);
      $sformat(cname, "ref_plus_%0d_vplan_tim_int", n);
      if (smp_cnt - (ref_idx + n) >= HIST_DEPTH) begin
        tb_timer_top.u_log.error_msg("[LOG ERROR] expect_int_at: cycle not in history");
      end
      else begin
        cmp_bit(cname, exp, int_hist[(ref_idx + n) % HIST_DEPTH]);
      end
    end
  endtask

  // === comparison: X/Z in actual or expected is a FAIL
  task cmp_word;
    input [8*64-1:0] name;
    input [31:0]     exp;
    input [31:0]     act;
    begin
      $sformat(exp_s, "%h", exp);
      $sformat(act_s, "%h", act);
      tb_timer_top.u_log.result(name, (act === exp), exp_s, act_s);
    end
  endtask

  task cmp_bit;
    input [8*64-1:0] name;
    input            exp;
    input            act;
    begin
      $sformat(exp_s, "%h", exp);
      $sformat(act_s, "%h", act);
      tb_timer_top.u_log.result(name, (act === exp), exp_s, act_s);
    end
  endtask

  // Case name of the automatic checks from the sampled inputs
  task make_base;
    begin
      if (s_rst_n_i !== 1'b1) begin
        $sformat(base, "rst_n_0");
      end
      else if (s_psel_i !== 1'b1) begin
        $sformat(base, "idle");
      end
      else if (s_penable_i !== 1'b1) begin
        if (s_pwrite_i) begin
          $sformat(base, "setup_wr_%h_%h_s%h", s_paddr_i, s_pwdata_i, s_pstrb_i);
        end
        else begin
          $sformat(base, "setup_rd_%h", s_paddr_i);
        end
      end
      else begin
        if (s_pwrite_i) begin
          $sformat(base, "access_wr_%h_%h_s%h", s_paddr_i, s_pwdata_i, s_pstrb_i);
        end
        else begin
          $sformat(base, "access_rd_%h", s_paddr_i);
        end
      end
    end
  endtask

  always @(negedge clk_i) begin
    #(CHK_DLY);
    if (s_vld_i) begin
      smp_cnt = smp_cnt + 1;
      int_hist[smp_cnt % HIST_DEPTH] = s_tim_int_i;
      if (auto_en) begin
        make_base;
        $sformat(cname, "%0s_pready", base);
        cmp_bit(cname, exp_pready_i, s_pready_i);
        $sformat(cname, "%0s_pslverr", base);
        cmp_bit(cname, exp_pslverr_i, s_pslverr_i);
        $sformat(cname, "%0s_prdata", base);
        cmp_word(cname, exp_prdata_i, s_prdata_i);
        $sformat(cname, "%0s_tim_int", base);
        cmp_bit(cname, exp_tim_int_i, s_tim_int_i);
      end
      if (dir_ack != dir_req) begin
        case (dir_kind)
          K_PRDATA: begin
            cmp_word(dir_name, dir_exp, s_prdata_i);
          end
          K_PSLVERR: begin
            cmp_bit(dir_name, dir_exp[0], s_pslverr_i);
          end
          default: begin
            $sformat(cname, "%0s_pready", dir_name);
            cmp_bit(cname, 1'b0, s_pready_i);
            $sformat(cname, "%0s_pslverr", dir_name);
            cmp_bit(cname, 1'b0, s_pslverr_i);
            $sformat(cname, "%0s_prdata", dir_name);
            cmp_word(cname, 32'h0, s_prdata_i);
            $sformat(cname, "%0s_tim_int", dir_name);
            cmp_bit(cname, 1'b0, s_tim_int_i);
          end
        endcase
        dir_ack = dir_req;
      end
    end
  end

endmodule
