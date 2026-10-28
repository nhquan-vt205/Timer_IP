// ============================================================================
// Module   : timer_top
// Function : Timer IP top (RISC-V CLINT-like). APB slave with 8 registers,
//            64-bit counter {TDR1, TDR0} with divider, halt and clear, and
//            compare interrupt tim_int. Instantiates and connects the five
//            sub-modules; no glue logic.
// Spec     : doc/spec/architecture/timer_top_spec.md
// Diagram  : doc/diagram/timer_top/timer_top.svg (L0)
// Revision : 1.0 - initial version
// ============================================================================
`default_nettype none

module timer_top (
  input  wire        sys_clk,      // system clock, rising edge
  input  wire        sys_rst_n,    // asynchronous active-low reset
  input  wire        tim_psel,     // APB select
  input  wire        tim_pwrite,   // 1: write, 0: read
  input  wire        tim_penable,  // APB enable (access phase)
  input  wire [11:0] tim_paddr,    // APB address
  input  wire [31:0] tim_pwdata,   // APB write data
  input  wire [3:0]  tim_pstrb,    // APB byte strobes
  output wire [31:0] tim_prdata,   // APB read data
  output wire        tim_pready,   // APB ready
  output wire        tim_pslverr,  // APB slave error
  output wire        tim_int,      // timer interrupt, level
  input  wire        dbg_mode      // debug mode, used for halt
);

  // --------------------------------------------------------------------------
  // Internal nets
  // --------------------------------------------------------------------------
  // apb_slave <-> register
  wire        wr_en;
  wire        rd_en;
  wire        wr_err;
  wire [31:0] rdata;

  // register <-> cnt_ctrl
  wire        tim_en;
  wire        div_en;
  wire [3:0]  div_val;
  wire        halt_req;
  wire        halt_ack;

  // register -> counter, cnt_ctrl -> counter
  wire [3:0]  tdr0_wr_en;
  wire [3:0]  tdr1_wr_en;
  wire        cnt_en;
  wire        cnt_clr;

  // counter -> register, interrupt
  wire [63:0] cnt;

  // register <-> interrupt
  wire [31:0] tcmp0;
  wire [31:0] tcmp1;
  wire        int_en;
  wire        int_st_clr;
  wire        int_st;

  // --------------------------------------------------------------------------
  // APB protocol
  // --------------------------------------------------------------------------
  apb_slave u_apb_slave (
    .sys_clk     (sys_clk),
    .sys_rst_n   (sys_rst_n),
    .tim_psel    (tim_psel),
    .tim_penable (tim_penable),
    .tim_pwrite  (tim_pwrite),
    .wr_err      (wr_err),
    .rdata       (rdata),
    .tim_prdata  (tim_prdata),
    .tim_pready  (tim_pready),
    .tim_pslverr (tim_pslverr),
    .wr_en       (wr_en),
    .rd_en       (rd_en)
  );

  // --------------------------------------------------------------------------
  // Register file
  // --------------------------------------------------------------------------
  register u_register (
    .sys_clk    (sys_clk),
    .sys_rst_n  (sys_rst_n),
    .wr_en      (wr_en),
    .rd_en      (rd_en),
    .tim_paddr  (tim_paddr),
    .tim_pwdata (tim_pwdata),
    .tim_pstrb  (tim_pstrb),
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

  // --------------------------------------------------------------------------
  // Counting control: divider, halt, clear on TIM_EN H->L
  // --------------------------------------------------------------------------
  cnt_ctrl u_cnt_ctrl (
    .sys_clk   (sys_clk),
    .sys_rst_n (sys_rst_n),
    .tim_en    (tim_en),
    .div_en    (div_en),
    .div_val   (div_val),
    .halt_req  (halt_req),
    .dbg_mode  (dbg_mode),
    .halt_ack  (halt_ack),
    .cnt_en    (cnt_en),
    .cnt_clr   (cnt_clr)
  );

  // --------------------------------------------------------------------------
  // 64-bit counter {TDR1, TDR0}
  // --------------------------------------------------------------------------
  counter u_counter (
    .sys_clk    (sys_clk),
    .sys_rst_n  (sys_rst_n),
    .cnt_en     (cnt_en),
    .cnt_clr    (cnt_clr),
    .tdr0_wr_en (tdr0_wr_en),
    .tdr1_wr_en (tdr1_wr_en),
    .tim_pwdata (tim_pwdata),
    .cnt        (cnt)
  );

  // --------------------------------------------------------------------------
  // Compare and interrupt
  // --------------------------------------------------------------------------
  interrupt u_interrupt (
    .sys_clk    (sys_clk),
    .sys_rst_n  (sys_rst_n),
    .cnt        (cnt),
    .tcmp0      (tcmp0),
    .tcmp1      (tcmp1),
    .int_en     (int_en),
    .int_st_clr (int_st_clr),
    .int_st     (int_st),
    .tim_int    (tim_int)
  );

endmodule

`default_nettype wire
