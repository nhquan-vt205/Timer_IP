// ============================================================================
// Module   : cnt_ctrl
// Function : Generates the count enable cnt_en (every cycle, or one pulse
//            every 2^DIV_VAL cycles through the divider div_cnt), freezes
//            divider and counter on debug halt, and pulses cnt_clr on a
//            TIM_EN 1 -> 0 transition.
// Spec     : doc/spec/architecture/cnt_ctrl_spec.md
// Diagram  : doc/diagram/cnt_ctrl/cnt_ctrl.svg (L2)
// Revision : 1.0 - initial version
// ============================================================================
`default_nettype none

module cnt_ctrl (
  input  wire       sys_clk,     // system clock, rising edge
  input  wire       sys_rst_n,   // asynchronous active-low reset
  input  wire       tim_en,      // TCR.TIM_EN
  input  wire       div_en,      // TCR.DIV_EN
  input  wire [3:0] div_val,     // TCR.DIV_VAL, 0..8
  input  wire       halt_req,    // THCSR.HALT_REQ
  input  wire       dbg_mode,    // debug mode
  output wire       halt_ack,    // THCSR.HALT_ACK
  output wire       cnt_en,      // count enable for counter
  output wire       cnt_clr      // 1-cycle pulse on TIM_EN H->L
);

  // --------------------------------------------------------------------------
  // Internal signals
  // --------------------------------------------------------------------------
  reg  [7:0] div_cnt;        // divider counter
  reg        tim_en_d;       // previous-cycle TIM_EN

  wire       halted;
  wire [8:0] limit_full;     // (1 << div_val) - 1 on 9 bits
  wire [7:0] limit;
  wire       match;
  wire       div_clr;
  wire       div_tick;       // ~div_en | match
  wire [7:0] div_cnt_inc;
  wire [7:0] div_cnt_wrap;   // wrap to 0 on match
  wire [7:0] div_cnt_run;    // hold while halted
  wire [7:0] div_cnt_d;      // clear has the highest priority

  // --------------------------------------------------------------------------
  // Debug halt
  // --------------------------------------------------------------------------
  assign halted   = dbg_mode & halt_req;
  assign halt_ack = halted;

  // --------------------------------------------------------------------------
  // Divider limit and compare
  // --------------------------------------------------------------------------
  assign limit_full = (9'd1 << div_val) - 9'd1;
  assign limit      = limit_full[7:0];
  assign match      = (div_cnt == limit);

  // --------------------------------------------------------------------------
  // div_cnt next value: wrap mux, halt mux, clear mux
  // --------------------------------------------------------------------------
  assign div_clr      = ~div_en | ~tim_en;
  assign div_cnt_inc  = div_cnt + 8'd1;
  assign div_cnt_wrap = match   ? 8'h0    : div_cnt_inc;
  assign div_cnt_run  = halted  ? div_cnt : div_cnt_wrap;
  assign div_cnt_d    = div_clr ? 8'h0    : div_cnt_run;

  // --------------------------------------------------------------------------
  // Registers: divider counter and previous TIM_EN
  // --------------------------------------------------------------------------
  always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      div_cnt  <= 8'h0;
      tim_en_d <= 1'b0;
    end
    else begin
      div_cnt  <= div_cnt_d;
      tim_en_d <= tim_en;
    end
  end

  // --------------------------------------------------------------------------
  // Outputs to counter
  // --------------------------------------------------------------------------
  assign div_tick = ~div_en | match;
  assign cnt_en   = tim_en & ~halted & div_tick;
  assign cnt_clr  = tim_en_d & ~tim_en;

endmodule

`default_nettype wire
