// ============================================================================
// Module   : register
// Function : Register file of the Timer IP. Decodes tim_paddr[11:2], holds
//            TCR (TIM_EN, DIV_EN, DIV_VAL), TCMP0, TCMP1, TIER.INT_EN and
//            THCSR.HALT_REQ with byte-strobe writes, flags forbidden TCR
//            writes (wr_err), forwards TDR0/TDR1 byte write enables and the
//            TISR clear pulse, and drives the read mux rdata.
// Spec     : doc/spec/architecture/register_spec.md
//            doc/spec/register_file/register_map.md
// Diagram  : doc/diagram/register/register.svg (L1)
// Revision : 1.0 - initial version
// ============================================================================
`default_nettype none

module register (
  input  wire        sys_clk,      // system clock, rising edge
  input  wire        sys_rst_n,    // asynchronous active-low reset
  input  wire        wr_en,        // register write strobe
  input  wire        rd_en,        // register read strobe
  input  wire [11:0] tim_paddr,    // APB address
  input  wire [31:0] tim_pwdata,   // APB write data
  input  wire [3:0]  tim_pstrb,    // APB byte strobes
  input  wire [63:0] cnt,          // counter value, read as TDR0/TDR1
  input  wire        int_st,       // TISR.INT_ST
  input  wire        halt_ack,     // THCSR.HALT_ACK
  output wire        wr_err,       // forbidden TCR write (combinational)
  output wire [31:0] rdata,        // read data, 0 when rd_en = 0
  output reg         tim_en,       // TCR.TIM_EN
  output reg         div_en,       // TCR.DIV_EN
  output reg  [3:0]  div_val,      // TCR.DIV_VAL
  output reg         halt_req,     // THCSR.HALT_REQ
  output wire [3:0]  tdr0_wr_en,   // TDR0 byte write enables
  output wire [3:0]  tdr1_wr_en,   // TDR1 byte write enables
  output reg  [31:0] tcmp0,        // TCMP0
  output reg  [31:0] tcmp1,        // TCMP1
  output reg         int_en,       // TIER.INT_EN
  output wire        int_st_clr    // 1-cycle pulse: write 1 to TISR.INT_ST
);

  // --------------------------------------------------------------------------
  // Word addresses (tim_paddr[11:2])
  // --------------------------------------------------------------------------
  localparam ADDR_TCR   = 10'h000;
  localparam ADDR_TDR0  = 10'h001;
  localparam ADDR_TDR1  = 10'h002;
  localparam ADDR_TCMP0 = 10'h003;
  localparam ADDR_TCMP1 = 10'h004;
  localparam ADDR_TIER  = 10'h005;
  localparam ADDR_TISR  = 10'h006;
  localparam ADDR_THCSR = 10'h007;

  // --------------------------------------------------------------------------
  // Combinational signals
  // --------------------------------------------------------------------------
  wire [9:0]  word_addr;
  wire        sel_tcr;
  wire        sel_tdr0;
  wire        sel_tdr1;
  wire        sel_tcmp0;
  wire        sel_tcmp1;
  wire        sel_tier;
  wire        sel_tisr;
  wire        sel_thcsr;

  wire        tcr_we0;      // TCR byte 0 write (TIM_EN, DIV_EN)
  wire        tcr_we1;      // TCR byte 1 write (DIV_VAL)
  wire        tcmp0_we;
  wire        tcmp1_we;
  wire [3:0]  tcmp0_bwe;    // TCMP0 byte write enables
  wire [3:0]  tcmp1_bwe;    // TCMP1 byte write enables
  wire        tier_we;
  wire        thcsr_we;
  wire        tdr0_we;
  wire        tdr1_we;

  wire        div_val_bad;  // DIV_VAL > 8
  wire        div_val_chg;  // DIV_VAL changes
  wire        div_en_chg;   // DIV_EN changes
  wire        div_chg;      // divider change while TIM_EN = 1

  reg  [31:0] tcmp0_d;
  reg  [31:0] tcmp1_d;
  reg  [31:0] rdata_mux;
  integer     k;

  // --------------------------------------------------------------------------
  // Address decode
  // --------------------------------------------------------------------------
  assign word_addr = tim_paddr[11:2];
  assign sel_tcr   = (word_addr == ADDR_TCR);
  assign sel_tdr0  = (word_addr == ADDR_TDR0);
  assign sel_tdr1  = (word_addr == ADDR_TDR1);
  assign sel_tcmp0 = (word_addr == ADDR_TCMP0);
  assign sel_tcmp1 = (word_addr == ADDR_TCMP1);
  assign sel_tier  = (word_addr == ADDR_TIER);
  assign sel_tisr  = (word_addr == ADDR_TISR);
  assign sel_thcsr = (word_addr == ADDR_THCSR);

  // --------------------------------------------------------------------------
  // Write enables
  // --------------------------------------------------------------------------
  assign tcr_we0   = wr_en & sel_tcr & tim_pstrb[0];
  assign tcr_we1   = wr_en & sel_tcr & tim_pstrb[1];
  assign tcmp0_we  = wr_en & sel_tcmp0;
  assign tcmp1_we  = wr_en & sel_tcmp1;
  assign tcmp0_bwe = {4{tcmp0_we}} & tim_pstrb;
  assign tcmp1_bwe = {4{tcmp1_we}} & tim_pstrb;
  assign tier_we   = wr_en & sel_tier & tim_pstrb[0];
  assign thcsr_we  = wr_en & sel_thcsr & tim_pstrb[0];
  assign tdr0_we   = wr_en & sel_tdr0;
  assign tdr1_we   = wr_en & sel_tdr1;

  // TDR0/TDR1 are stored in counter; TISR.INT_ST is stored in interrupt
  assign tdr0_wr_en = tdr0_we ? tim_pstrb : 4'h0;
  assign tdr1_wr_en = tdr1_we ? tim_pstrb : 4'h0;
  assign int_st_clr = wr_en & sel_tisr & tim_pstrb[0] & tim_pwdata[0];

  // --------------------------------------------------------------------------
  // Forbidden TCR write: DIV_VAL > 8, or divider change while TIM_EN = 1
  // --------------------------------------------------------------------------
  assign div_val_bad = tim_pstrb[1] & (tim_pwdata[11:8] > 4'd8);
  assign div_val_chg = tim_pstrb[1] & (tim_pwdata[11:8] != div_val);
  assign div_en_chg  = tim_pstrb[0] & (tim_pwdata[1] != div_en);
  assign div_chg     = tim_en & (div_val_chg | div_en_chg);
  assign wr_err      = sel_tcr & (div_val_bad | div_chg);

  // --------------------------------------------------------------------------
  // TCR, TIER, THCSR registers
  // --------------------------------------------------------------------------
  always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      tim_en <= 1'b0;
      div_en <= 1'b0;
    end
    else if (tcr_we0) begin
      tim_en <= tim_pwdata[0];
      div_en <= tim_pwdata[1];
    end
  end

  always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      div_val <= 4'h1;
    end
    else if (tcr_we1) begin
      div_val <= tim_pwdata[11:8];
    end
  end

  always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      int_en <= 1'b0;
    end
    else if (tier_we) begin
      int_en <= tim_pwdata[0];
    end
  end

  always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      halt_req <= 1'b0;
    end
    else if (thcsr_we) begin
      halt_req <= tim_pwdata[0];
    end
  end

  // --------------------------------------------------------------------------
  // TCMP0 / TCMP1: per-byte hold mux + register
  // --------------------------------------------------------------------------
  always @(*) begin
    tcmp0_d = tcmp0;
    tcmp1_d = tcmp1;
    for (k = 0; k < 4; k = k + 1) begin
      if (tcmp0_bwe[k]) begin
        tcmp0_d[8*k +: 8] = tim_pwdata[8*k +: 8];
      end
      if (tcmp1_bwe[k]) begin
        tcmp1_d[8*k +: 8] = tim_pwdata[8*k +: 8];
      end
    end
  end

  always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      tcmp0 <= 32'hFFFF_FFFF;
      tcmp1 <= 32'hFFFF_FFFF;
    end
    else begin
      tcmp0 <= tcmp0_d;
      tcmp1 <= tcmp1_d;
    end
  end

  // --------------------------------------------------------------------------
  // Read mux (reserved addresses read 0)
  // --------------------------------------------------------------------------
  always @(*) begin
    case (word_addr)
      ADDR_TCR   : rdata_mux = {20'h0_0000, div_val, 6'b00_0000, div_en, tim_en};
      ADDR_TDR0  : rdata_mux = cnt[31:0];
      ADDR_TDR1  : rdata_mux = cnt[63:32];
      ADDR_TCMP0 : rdata_mux = tcmp0;
      ADDR_TCMP1 : rdata_mux = tcmp1;
      ADDR_TIER  : rdata_mux = {31'h0, int_en};
      ADDR_TISR  : rdata_mux = {31'h0, int_st};
      ADDR_THCSR : rdata_mux = {30'h0, halt_ack, halt_req};
      default    : rdata_mux = 32'h0;
    endcase
  end

  assign rdata = rd_en ? rdata_mux : 32'h0;

endmodule

`default_nettype wire
