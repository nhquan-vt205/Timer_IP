// ============================================================================
// Module   : apb_slave
// Function : APB slave protocol of the Timer IP. Inserts exactly one wait
//            state per transfer (setup - wait - access), registers
//            tim_pready/tim_pslverr, generates single-cycle wr_en/rd_en for
//            the register block and passes rdata straight to tim_prdata.
// Spec     : doc/spec/architecture/apb_slave_spec.md
// Diagram  : doc/diagram/apb_slave/apb_slave.svg (L2)
// Revision : 1.0 - initial version
// ============================================================================
`default_nettype none

module apb_slave (
  input  wire        sys_clk,      // system clock, rising edge
  input  wire        sys_rst_n,    // asynchronous active-low reset
  input  wire        tim_psel,     // APB select
  input  wire        tim_penable,  // APB enable (access phase)
  input  wire        tim_pwrite,   // 1: write, 0: read
  input  wire        wr_err,       // combinational TCR write error
  input  wire [31:0] rdata,        // read data from the read mux
  output wire [31:0] tim_prdata,   // APB read data
  output wire        tim_pready,   // APB ready
  output wire        tim_pslverr,  // APB slave error
  output wire        wr_en,        // register write strobe
  output wire        rd_en         // register read strobe
);

  // --------------------------------------------------------------------------
  // State registers
  // --------------------------------------------------------------------------
  reg  pready_q;   // 1 in the last access cycle (end of the wait state)
  reg  pslverr_q;  // error captured in the wait cycle of a write

  // --------------------------------------------------------------------------
  // Combinational signals
  // --------------------------------------------------------------------------
  wire apb_acc;    // APB access phase
  wire pready_d;
  wire pslverr_d;

  assign apb_acc   = tim_psel & tim_penable;

  // Wait state: set in the first access cycle, self-clears one cycle later
  assign pready_d  = apb_acc & ~pready_q;

  // Error: sample wr_err in the wait cycle of a write transfer
  assign pslverr_d = apb_acc & ~pready_q & tim_pwrite & wr_err;

  always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      pready_q  <= 1'b0;
      pslverr_q <= 1'b0;
    end
    else begin
      pready_q  <= pready_d;
      pslverr_q <= pslverr_d;
    end
  end

  // --------------------------------------------------------------------------
  // Register access strobes (last access cycle only, no write on error)
  // --------------------------------------------------------------------------
  assign wr_en = ~pslverr_q & apb_acc & pready_q & tim_pwrite;
  assign rd_en = apb_acc & pready_q & ~tim_pwrite;

  // --------------------------------------------------------------------------
  // Outputs
  // --------------------------------------------------------------------------
  assign tim_pready  = pready_q;
  assign tim_pslverr = pslverr_q;
  assign tim_prdata  = rdata;

endmodule

`default_nettype wire
