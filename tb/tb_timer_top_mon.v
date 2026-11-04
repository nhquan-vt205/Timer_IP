// ============================================================================
// Component : tb_timer_top_mon - monitor of tb_timer_top
// Observes  : every DUT pin (inputs as really applied, outputs as produced)
// Drives    : s_*_o samples -> u_model (inputs), u_chk (inputs and outputs)
// Timing    : samples at every falling edge, half a cycle after the stimulus
//             of posedge + #1 and after the outputs have settled; the X->0
//             initialization of clk at time 0 is not an edge (s_vld_o = 0)
// ============================================================================
`timescale 1ns/1ps

module tb_timer_top_mon (
  input  wire        clk_i,
  input  wire        rst_n_i,
  input  wire        psel_i,
  input  wire        penable_i,
  input  wire        pwrite_i,
  input  wire [11:0] paddr_i,
  input  wire [31:0] pwdata_i,
  input  wire [3:0]  pstrb_i,
  input  wire        dbg_mode_i,
  input  wire [31:0] prdata_i,
  input  wire        pready_i,
  input  wire        pslverr_i,
  input  wire        tim_int_i,
  output reg         s_rst_n_o,
  output reg         s_psel_o,
  output reg         s_penable_o,
  output reg         s_pwrite_o,
  output reg  [11:0] s_paddr_o,
  output reg  [31:0] s_pwdata_o,
  output reg  [3:0]  s_pstrb_o,
  output reg         s_dbg_mode_o,
  output reg  [31:0] s_prdata_o,
  output reg         s_pready_o,
  output reg         s_pslverr_o,
  output reg         s_tim_int_o,
  output reg         s_vld_o
);

  initial begin
    s_vld_o = 1'b0;
  end

  always @(negedge clk_i) begin
    if ($time > 0) begin
      s_vld_o      <= 1'b1;
      s_rst_n_o    <= rst_n_i;
      s_psel_o     <= psel_i;
      s_penable_o  <= penable_i;
      s_pwrite_o   <= pwrite_i;
      s_paddr_o    <= paddr_i;
      s_pwdata_o   <= pwdata_i;
      s_pstrb_o    <= pstrb_i;
      s_dbg_mode_o <= dbg_mode_i;
      s_prdata_o   <= prdata_i;
      s_pready_o   <= pready_i;
      s_pslverr_o  <= pslverr_i;
      s_tim_int_o  <= tim_int_i;
    end
  end

endmodule
