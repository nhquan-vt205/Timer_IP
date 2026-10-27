// ============================================================================
// Module   : interrupt
// Function : Compares cnt with {tcmp1, tcmp0} every cycle, holds the pending
//            bit TISR.INT_ST (set on match, cleared by int_st_clr with
//            priority) and drives the level interrupt tim_int = INT_ST & INT_EN.
// Spec     : doc/spec/architecture/interrupt_spec.md
// Diagram  : doc/diagram/interrupt/interrupt.svg (L2)
// Revision : 1.0 - initial version
// ============================================================================
`default_nettype none

module interrupt (
  input  wire        sys_clk,      // system clock, rising edge
  input  wire        sys_rst_n,    // asynchronous active-low reset
  input  wire [63:0] cnt,          // counter value
  input  wire [31:0] tcmp0,        // compare value [31:0]
  input  wire [31:0] tcmp1,        // compare value [63:32]
  input  wire        int_en,       // TIER.INT_EN
  input  wire        int_st_clr,   // clear INT_ST (write 1 to TISR.INT_ST)
  output reg         int_st,       // TISR.INT_ST, interrupt pending
  output wire        tim_int       // timer interrupt, level
);

  // --------------------------------------------------------------------------
  // Combinational signals
  // --------------------------------------------------------------------------
  wire [63:0] tcmp;
  wire        cnt_match;
  wire        int_st_set_d;   // set when cnt matches, otherwise hold
  wire        int_st_d;       // clear has priority over set

  // --------------------------------------------------------------------------
  // Compare
  // --------------------------------------------------------------------------
  assign tcmp      = {tcmp1, tcmp0};
  assign cnt_match = (cnt == tcmp);

  // --------------------------------------------------------------------------
  // INT_ST next value: set mux, then clear mux
  // --------------------------------------------------------------------------
  assign int_st_set_d = cnt_match ? 1'b1 : int_st;
  assign int_st_d     = int_st_clr ? 1'b0 : int_st_set_d;

  // --------------------------------------------------------------------------
  // TISR.INT_ST register
  // --------------------------------------------------------------------------
  always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      int_st <= 1'b0;
    end
    else begin
      int_st <= int_st_d;
    end
  end

  // --------------------------------------------------------------------------
  // Interrupt output (masked by INT_EN)
  // --------------------------------------------------------------------------
  assign tim_int = int_st & int_en;

endmodule

`default_nettype wire
