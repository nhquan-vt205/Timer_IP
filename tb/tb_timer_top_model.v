// ============================================================================
// Component : tb_timer_top_model - golden reference model of timer_top
// Inputs    : clk, asynchronous reset, DUT inputs as sampled by u_mon
//             (never a DUT output; the APB wait state is fixed by the spec,
//             so the model computes tim_pready itself)
// Drives    : exp_prdata_o, exp_pready_o, exp_pslverr_o, exp_tim_int_o -> u_chk
// Behavior  : from doc/spec/architecture/timer_top_spec.md and
//             doc/spec/register_file/register_map.md:
//             - APB: one wait state; a write is applied in the last access
//               cycle unless it is a TCR error (error conditions 1-3), read
//               data only in the last access cycle of a read, else 0
//             - registers TCR, TCMP0/1, TIER, THCSR with byte strobes;
//               TISR.INT_ST is RW1C; reserved addresses RAZ/WI
//             - a transfer needs psel = penable = 1 (X on an idle bus is no
//               transfer)
//             - counter {TDR1, TDR0}: clear on TIM_EN H->L > software byte
//               write (only while TIM_EN = 0, else ignored without error,
//               OPEN-002) > count step; count every cycle (DIV_EN = 0) or every
//               2^DIV_VAL cycles (DIV_EN = 1); dbg_mode & HALT_REQ freezes
//               the counter and the divider
//             - INT_ST set one cycle after cnt == {TCMP1, TCMP0}, clear
//               wins; tim_int = INT_ST & INT_EN
//             The state moves at the rising edge with the inputs the monitor
//             sampled in the cycle that ends at that edge; the expected
//             outputs are combinational from the state and the current
//             sample.
// ============================================================================
`timescale 1ns/1ps

module tb_timer_top_model (
  input  wire        clk_i,
  input  wire        rst_n_i,
  input  wire        s_psel_i,
  input  wire        s_penable_i,
  input  wire        s_pwrite_i,
  input  wire [11:0] s_paddr_i,
  input  wire [31:0] s_pwdata_i,
  input  wire [3:0]  s_pstrb_i,
  input  wire        s_dbg_mode_i,
  output reg  [31:0] exp_prdata_o,
  output reg         exp_pready_o,
  output reg         exp_pslverr_o,
  output reg         exp_tim_int_o
);

  // Word offsets (paddr[11:2]) of the register map
  localparam [9:0] W_TCR   = 10'h000;
  localparam [9:0] W_TDR0  = 10'h001;
  localparam [9:0] W_TDR1  = 10'h002;
  localparam [9:0] W_TCMP0 = 10'h003;
  localparam [9:0] W_TCMP1 = 10'h004;
  localparam [9:0] W_TIER  = 10'h005;
  localparam [9:0] W_TISR  = 10'h006;
  localparam [9:0] W_THCSR = 10'h007;

  // State (registers of the IP)
  reg         pready_q;
  reg         pslverr_q;
  reg         tim_en_q;
  reg         div_en_q;
  reg  [3:0]  div_val_q;
  reg  [31:0] tcmp0_q;
  reg  [31:0] tcmp1_q;
  reg         int_en_q;
  reg         halt_req_q;
  reg  [63:0] cnt_q;
  reg  [7:0]  div_cnt_q;
  reg         tim_en_d_q;
  reg         int_st_q;

  // Combinational values of the current cycle
  reg         acc;
  reg         wr_en;
  reg         rd_en;
  reg         wr_err;
  reg  [8:0]  limit;
  reg         halted;
  reg         div_hit;
  reg         cnt_en;
  reg         cnt_clr;
  reg         cnt_match;
  reg         int_st_clr;
  reg         tdr_wr;

  // Software write of TDR0 (hi = 0) or TDR1 (hi = 1), strobed bytes only
  function [63:0] tdr_merge;
    input [63:0] old;
    input        hi;
    input [3:0]  strb;
    input [31:0] wdata;
    integer      k;
    begin
      tdr_merge = old;
      for (k = 0; k < 4; k = k + 1) begin
        if (strb[k]) begin
          tdr_merge[32 * hi + 8 * k +: 8] = wdata[8 * k +: 8];
        end
      end
    end
  endfunction

  // Strobed byte write of a 32-bit register
  function [31:0] byte_merge;
    input [31:0] old;
    input [3:0]  strb;
    input [31:0] wdata;
    integer      k;
    begin
      byte_merge = old;
      for (k = 0; k < 4; k = k + 1) begin
        if (strb[k]) begin
          byte_merge[8 * k +: 8] = wdata[8 * k +: 8];
        end
      end
    end
  endfunction

  // Expected outputs and internal enables from the state and the sample
  always @(*) begin
    // A transfer needs psel = penable = 1; an undriven (X) bus is idle
    acc        = (s_psel_i === 1'b1) & (s_penable_i === 1'b1);
    wr_en      = acc & pready_q & (s_pwrite_i === 1'b1) & ~pslverr_q;
    rd_en      = acc & pready_q & (s_pwrite_i === 1'b0);
    // TCR error conditions 1-3: DIV_VAL > 8; DIV_VAL or DIV_EN change
    // while TIM_EN = 1
    wr_err     = (s_paddr_i[11:2] == W_TCR) &
                 ((s_pstrb_i[1] & (s_pwdata_i[11:8] > 4'd8)) |
                  (tim_en_q & ((s_pstrb_i[1] & (s_pwdata_i[11:8] != div_val_q)) |
                               (s_pstrb_i[0] & (s_pwdata_i[1] != div_en_q)))));
    limit      = (9'd1 << div_val_q) - 9'd1;
    halted     = s_dbg_mode_i & halt_req_q;
    div_hit    = (div_cnt_q == limit[7:0]);
    cnt_en     = tim_en_q & ~halted & (~div_en_q | div_hit);
    cnt_clr    = tim_en_d_q & ~tim_en_q;
    cnt_match  = (cnt_q == {tcmp1_q, tcmp0_q});
    int_st_clr = wr_en & (s_paddr_i[11:2] == W_TISR) & s_pstrb_i[0] & s_pwdata_i[0];
    // TDR0/TDR1 writable only while TIM_EN = 0 (OPEN-002), no error
    tdr_wr     = wr_en & ~tim_en_q & (s_pstrb_i != 4'h0) &
                 ((s_paddr_i[11:2] == W_TDR0) | (s_paddr_i[11:2] == W_TDR1));

    exp_pready_o  = pready_q;
    exp_pslverr_o = pslverr_q;
    exp_tim_int_o = int_st_q & int_en_q;
    exp_prdata_o  = 32'h0;
    if (rd_en) begin
      case (s_paddr_i[11:2])
        W_TCR   : exp_prdata_o = {20'h0, div_val_q, 6'h0, div_en_q, tim_en_q};
        W_TDR0  : exp_prdata_o = cnt_q[31:0];
        W_TDR1  : exp_prdata_o = cnt_q[63:32];
        W_TCMP0 : exp_prdata_o = tcmp0_q;
        W_TCMP1 : exp_prdata_o = tcmp1_q;
        W_TIER  : exp_prdata_o = {31'h0, int_en_q};
        W_TISR  : exp_prdata_o = {31'h0, int_st_q};
        W_THCSR : exp_prdata_o = {30'h0, s_dbg_mode_i & halt_req_q, halt_req_q};
        default : exp_prdata_o = 32'h0;
      endcase
    end
  end

  // State update at the rising edge; asynchronous reset to the
  // register-map reset values
  always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
      pready_q   <= 1'b0;
      pslverr_q  <= 1'b0;
      tim_en_q   <= 1'b0;
      div_en_q   <= 1'b0;
      div_val_q  <= 4'h1;
      tcmp0_q    <= 32'hFFFF_FFFF;
      tcmp1_q    <= 32'hFFFF_FFFF;
      int_en_q   <= 1'b0;
      halt_req_q <= 1'b0;
      cnt_q      <= 64'h0;
      div_cnt_q  <= 8'h0;
      tim_en_d_q <= 1'b0;
      int_st_q   <= 1'b0;
    end
    else begin
      // APB: pready in the cycle after the first access cycle; the error
      // flag is decided in that first access cycle
      pready_q  <= acc & ~pready_q;
      pslverr_q <= acc & ~pready_q & s_pwrite_i & wr_err;

      // Interrupt status: clear > set > hold
      if (int_st_clr) begin
        int_st_q <= 1'b0;
      end
      else if (cnt_match) begin
        int_st_q <= 1'b1;
      end

      // Divider: cleared while TIM_EN = 0 or DIV_EN = 0, held while halted
      if (!tim_en_q || !div_en_q) begin
        div_cnt_q <= 8'h0;
      end
      else if (!halted) begin
        div_cnt_q <= div_hit ? 8'h0 : div_cnt_q + 8'd1;
      end

      // Counter: clear > software byte write > count step
      if (cnt_clr) begin
        cnt_q <= 64'h0;
      end
      else if (tdr_wr) begin
        cnt_q <= tdr_merge(cnt_q, s_paddr_i[3], s_pstrb_i, s_pwdata_i);
      end
      else if (cnt_en) begin
        cnt_q <= cnt_q + 64'd1;
      end
      tim_en_d_q <= tim_en_q;

      // Register writes (byte strobes)
      if (wr_en) begin
        case (s_paddr_i[11:2])
          W_TCR: begin
            if (s_pstrb_i[0]) begin
              tim_en_q <= s_pwdata_i[0];
              div_en_q <= s_pwdata_i[1];
            end
            if (s_pstrb_i[1]) begin
              div_val_q <= s_pwdata_i[11:8];
            end
          end
          W_TCMP0: begin
            tcmp0_q <= byte_merge(tcmp0_q, s_pstrb_i, s_pwdata_i);
          end
          W_TCMP1: begin
            tcmp1_q <= byte_merge(tcmp1_q, s_pstrb_i, s_pwdata_i);
          end
          W_TIER: begin
            if (s_pstrb_i[0]) begin
              int_en_q <= s_pwdata_i[0];
            end
          end
          W_THCSR: begin
            if (s_pstrb_i[0]) begin
              halt_req_q <= s_pwdata_i[0];
            end
          end
          default: begin
          end
        endcase
      end
    end
  end

endmodule
