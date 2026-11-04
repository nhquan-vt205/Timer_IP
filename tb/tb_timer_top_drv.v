// ============================================================================
// Component : tb_timer_top_drv - APB master and debug controller of
//             tb_timer_top
// Drives    : psel_o, penable_o, pwrite_o, paddr_o, pwdata_o, pstrb_o,
//             dbg_mode_o -> DUT inputs (only driver of these nets)
// Receives  : clk_i, pready_i (APB handshake, read at the falling edge)
// Timing    : every change at posedge + #1. Each task covers whole cycles and
//             returns at the falling edge of its last cycle, so the next call
//             starts with the next cycle: transfers are back-to-back
//             (tim_psel stays 1). An APB transfer is setup (psel = 1,
//             penable = 0), then access (penable = 1) until pready_i = 1.
//             set_idle_x(1) makes idle cycles drive X on the bus (master
//             that leaves the bus undriven); reset_dut turns it off.
// Called by : the test case and the sequence tasks of tb_timer_top
// ============================================================================
`timescale 1ns/1ps

module tb_timer_top_drv (
  input  wire        clk_i,
  input  wire        pready_i,
  output reg         psel_o,
  output reg         penable_o,
  output reg         pwrite_o,
  output reg  [11:0] paddr_o,
  output reg  [31:0] pwdata_o,
  output reg  [3:0]  pstrb_o,
  output reg         dbg_mode_o
);

  // Idle cycles drive X on every bus input when set (undriven-bus
  // scenario); written only by drive_idle and set_idle_x (test sequence)
  reg idle_x;

  // Idle values and dbg_mode = 0 without waiting for an edge (reset only)
  task drive_idle;
    begin
      idle_x     = 1'b0;
      psel_o     = 1'b0;
      penable_o  = 1'b0;
      pwrite_o   = 1'b0;
      paddr_o    = 12'h0;
      pwdata_o   = 32'h0;
      pstrb_o    = 4'h0;
      dbg_mode_o = 1'b0;
    end
  endtask

  // One APB transfer; returns at the falling edge of the last access cycle
  task apb_xfer;
    input        wr;
    input [11:0] addr;
    input [31:0] wdata;
    input [3:0]  strb;
    begin
      @(posedge clk_i);
      #1;
      psel_o    = 1'b1;
      penable_o = 1'b0;
      pwrite_o  = wr;
      paddr_o   = addr;
      pwdata_o  = wdata;
      pstrb_o   = strb;
      @(posedge clk_i);
      #1;
      penable_o = 1'b1;
      @(negedge clk_i);
      while (pready_i !== 1'b1) begin
        @(posedge clk_i);
        #1;
        @(negedge clk_i);
      end
    end
  endtask

  task apb_write;
    input [11:0] addr;
    input [31:0] wdata;
    input [3:0]  strb;
    begin
      apb_xfer(1'b1, addr, wdata, strb);
    end
  endtask

  task apb_read;
    input [11:0] addr;
    begin
      apb_xfer(1'b0, addr, 32'h0, 4'h0);
    end
  endtask

  // n idle cycles: psel = 0, penable = 0, or every bus input X (idle_x)
  task idle;
    input integer n;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1) begin
        @(posedge clk_i);
        #1;
        if (idle_x) begin
          psel_o    = 1'bx;
          penable_o = 1'bx;
          pwrite_o  = 1'bx;
          paddr_o   = 12'hxxx;
          pwdata_o  = 32'hxxxx_xxxx;
          pstrb_o   = 4'hx;
        end
        else begin
          psel_o    = 1'b0;
          penable_o = 1'b0;
          pwrite_o  = 1'b0;
          paddr_o   = 12'h0;
          pwdata_o  = 32'h0;
          pstrb_o   = 4'h0;
        end
        @(negedge clk_i);
      end
    end
  endtask

  // Undriven-bus idle cycles on (1) or off (0); no clock cycle
  task set_idle_x;
    input v;
    begin
      idle_x = v;
    end
  endtask

  // dbg_mode for the following cycles; takes one cycle, bus unchanged
  task set_dbg_mode;
    input v;
    begin
      @(posedge clk_i);
      #1;
      dbg_mode_o = v;
      @(negedge clk_i);
    end
  endtask

endmodule
