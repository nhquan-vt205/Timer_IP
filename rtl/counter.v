// ============================================================================
// Module   : counter
// Function : 64-bit up counter cnt = {TDR1, TDR0}. Counts when cnt_en = 1
//            (wraps modulo 2^64), takes per-byte software writes through
//            TDR0/TDR1 (write wins over counting) and is cleared by cnt_clr
//            (highest priority).
// Spec     : doc/spec/architecture/counter_spec.md
// Diagram  : doc/diagram/counter/counter.svg (L2)
// Revision : 1.0 - initial version
// ============================================================================
`default_nettype none

module counter (
  input  wire        sys_clk,      // system clock, rising edge
  input  wire        sys_rst_n,    // asynchronous active-low reset
  input  wire        cnt_en,       // count enable from cnt_ctrl
  input  wire        cnt_clr,      // clear to 0 from cnt_ctrl
  input  wire [3:0]  tdr0_wr_en,   // byte write enables, cnt[31:0]
  input  wire [3:0]  tdr1_wr_en,   // byte write enables, cnt[63:32]
  input  wire [31:0] tim_pwdata,   // APB write data
  output reg  [63:0] cnt           // counter value {TDR1, TDR0}, unsigned
);

  // --------------------------------------------------------------------------
  // Internal signals
  // --------------------------------------------------------------------------
  wire [7:0]  tdr_wr_en;     // {tdr1_wr_en, tdr0_wr_en}, one bit per byte
  wire        cnt_wr;        // any byte written
  wire [63:0] cnt_wdata;     // written bytes from tim_pwdata, others from cnt
  wire [63:0] cnt_inc;
  wire [63:0] cnt_run;       // count or hold
  wire [63:0] cnt_wsel;      // write wins over counting
  wire [63:0] cnt_d;         // clear has the highest priority

  // --------------------------------------------------------------------------
  // Software write: per-byte merge of tim_pwdata into cnt
  // --------------------------------------------------------------------------
  assign tdr_wr_en = {tdr1_wr_en, tdr0_wr_en};
  assign cnt_wr    = (tdr_wr_en != 8'h0);

  // TDR0 bytes: cnt[31:0]
  assign cnt_wdata[7:0]   = tdr_wr_en[0] ? tim_pwdata[7:0]   : cnt[7:0];
  assign cnt_wdata[15:8]  = tdr_wr_en[1] ? tim_pwdata[15:8]  : cnt[15:8];
  assign cnt_wdata[23:16] = tdr_wr_en[2] ? tim_pwdata[23:16] : cnt[23:16];
  assign cnt_wdata[31:24] = tdr_wr_en[3] ? tim_pwdata[31:24] : cnt[31:24];

  // TDR1 bytes: cnt[63:32]
  assign cnt_wdata[39:32] = tdr_wr_en[4] ? tim_pwdata[7:0]   : cnt[39:32];
  assign cnt_wdata[47:40] = tdr_wr_en[5] ? tim_pwdata[15:8]  : cnt[47:40];
  assign cnt_wdata[55:48] = tdr_wr_en[6] ? tim_pwdata[23:16] : cnt[55:48];
  assign cnt_wdata[63:56] = tdr_wr_en[7] ? tim_pwdata[31:24] : cnt[63:56];

  // --------------------------------------------------------------------------
  // Next value: enable mux, write mux, clear mux
  // --------------------------------------------------------------------------
  assign cnt_inc  = cnt + 64'd1;   // wraps modulo 2^64
  assign cnt_run  = cnt_en  ? cnt_inc   : cnt;
  assign cnt_wsel = cnt_wr  ? cnt_wdata : cnt_run;
  assign cnt_d    = cnt_clr ? 64'h0     : cnt_wsel;

  // --------------------------------------------------------------------------
  // Counter register {TDR1, TDR0}
  // --------------------------------------------------------------------------
  always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      cnt <= 64'h0;
    end
    else begin
      cnt <= cnt_d;
    end
  end

endmodule

`default_nettype wire
