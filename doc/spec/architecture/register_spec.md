# register – Specification / Đặc tả
Type: leaf · Parent: timer_top · Level: L1

## Function / Chức năng

Register file of the Timer IP. Decodes `tim_paddr[11:2]`, holds TCR (TIM_EN, DIV_EN, DIV_VAL), TCMP0, TCMP1, TIER.INT_EN and THCSR.HALT_REQ with byte-strobe writes, detects forbidden TCR writes (`wr_err`), produces byte write enables for TDR0/TDR1 (stored in `counter`) and the `int_st_clr` pulse for TISR (stored in `interrupt`), and drives the read mux `rdata` (0 when `rd_en` = 0). Field definitions and reset values: `doc/spec/register_file/register_map.md`.

_VI:_ Khối thanh ghi của Timer IP. Giải mã `tim_paddr[11:2]`, chứa TCR (TIM_EN, DIV_EN, DIV_VAL), TCMP0, TCMP1, TIER.INT_EN và THCSR.HALT_REQ với ghi theo byte strobe, phát hiện ghi TCR bị cấm (`wr_err`), tạo tín hiệu cho phép ghi theo byte cho TDR0/TDR1 (lưu trong `counter`) và xung `int_st_clr` cho TISR (lưu trong `interrupt`), và tạo mux đọc `rdata` (bằng 0 khi `rd_en` = 0). Định nghĩa field và giá trị reset: `doc/spec/register_file/register_map.md`.

## Interface

| Port name | Direction | Width | Type | Connects to | Description |
| --- | --- | --- | --- | --- | --- |
| `sys_clk` | in | 1 | CLK/RST | timer_top.sys_clk | Clock |
| `sys_rst_n` | in | 1 | CLK/RST | timer_top.sys_rst_n | Async active-low reset |
| `wr_en` | in | 1 | CTRL | apb_slave.wr_en | Write strobe |
| `rd_en` | in | 1 | CTRL | apb_slave.rd_en | Read strobe |
| `tim_paddr` | in | 12 | DATA | timer_top.tim_paddr | APB address |
| `tim_pwdata` | in | 32 | DATA | timer_top.tim_pwdata | APB write data |
| `tim_pstrb` | in | 4 | CTRL | timer_top.tim_pstrb | Byte strobes |
| `cnt` | in | 64 | DATA | counter.cnt | Counter value, read as TDR0/TDR1 |
| `int_st` | in | 1 | STATUS | interrupt.int_st | TISR.INT_ST, read only here |
| `halt_ack` | in | 1 | STATUS | cnt_ctrl.halt_ack | THCSR.HALT_ACK |
| `wr_err` | out | 1 | STATUS | apb_slave.wr_err | Forbidden TCR write (combinational) |
| `rdata` | out | 32 | DATA | apb_slave.rdata | Read data, 0 when `rd_en` = 0 |
| `tim_en` | out | 1 | CTRL | cnt_ctrl.tim_en | TCR.TIM_EN |
| `div_en` | out | 1 | CTRL | cnt_ctrl.div_en | TCR.DIV_EN |
| `div_val` | out | 4 | CTRL | cnt_ctrl.div_val | TCR.DIV_VAL |
| `halt_req` | out | 1 | CTRL | cnt_ctrl.halt_req | THCSR.HALT_REQ |
| `tdr0_wr_en` | out | 4 | CTRL | counter.tdr0_wr_en | Byte write enables of TDR0 |
| `tdr1_wr_en` | out | 4 | CTRL | counter.tdr1_wr_en | Byte write enables of TDR1 |
| `tcmp0` | out | 32 | DATA | interrupt.tcmp0 | TCMP0 |
| `tcmp1` | out | 32 | DATA | interrupt.tcmp1 | TCMP1 |
| `int_en` | out | 1 | CTRL | interrupt.int_en | TIER.INT_EN |
| `int_st_clr` | out | 1 | CTRL | interrupt.int_st_clr | 1-cycle pulse: write 1 to TISR.INT_ST |

## Structure / Cấu trúc

Storage (all clocked by `sys_clk`, async reset `sys_rst_n`), each bit/byte is a flip-flop behind a 2:1 hold mux (input 1 = new data when the write enable is 1, input 0 = current value):

_VI:_ Phần lưu trữ (clock `sys_clk`, reset bất đồng bộ `sys_rst_n`), mỗi bit/byte là một flip-flop sau mux 2:1 giữ giá trị (ngõ 1 = dữ liệu mới khi cho phép ghi = 1, ngõ 0 = giá trị hiện tại):

| Register | Width | Reset | Write enable | Data |
| --- | --- | --- | --- | --- |
| `tim_en` (TCR.TIM_EN) | 1 | 1'b0 | `tcr_we0` | `tim_pwdata[0]` |
| `div_en` (TCR.DIV_EN) | 1 | 1'b0 | `tcr_we0` | `tim_pwdata[1]` |
| `div_val` (TCR.DIV_VAL) | 4 | 4'h1 | `tcr_we1` | `tim_pwdata[11:8]` |
| `tcmp0[8k+7:8k]`, k = 0..3 | 4 × 8 | 8'hFF | `tcmp0_we & tim_pstrb[k]` | `tim_pwdata[8k+7:8k]` |
| `tcmp1[8k+7:8k]`, k = 0..3 | 4 × 8 | 8'hFF | `tcmp1_we & tim_pstrb[k]` | `tim_pwdata[8k+7:8k]` |
| `int_en` (TIER.INT_EN) | 1 | 1'b0 | `tier_we` | `tim_pwdata[0]` |
| `halt_req` (THCSR.HALT_REQ) | 1 | 1'b0 | `thcsr_we` | `tim_pwdata[0]` |

Combinational logic:

_VI:_ Logic tổ hợp:

| Signal | Width | Equation |
| --- | --- | --- |
| `sel_tcr` … `sel_thcsr` | 1 each | `tim_paddr[11:2] == 10'h000` (TCR), `10'h001` (TDR0), `10'h002` (TDR1), `10'h003` (TCMP0), `10'h004` (TCMP1), `10'h005` (TIER), `10'h006` (TISR), `10'h007` (THCSR); at most one is 1 |
| `div_val_bad` | 1 | `tim_pstrb[1] & (tim_pwdata[11:8] > 4'd8)` |
| `div_val_chg` | 1 | `tim_pstrb[1] & (tim_pwdata[11:8] != div_val)` |
| `div_en_chg` | 1 | `tim_pstrb[0] & (tim_pwdata[1] != div_en)` |
| `div_chg` | 1 | `tim_en & (div_val_chg \| div_en_chg)` |
| `wr_err` | 1 | `sel_tcr & (div_val_bad \| div_chg)` |
| `tcr_we0` | 1 | `wr_en & sel_tcr & tim_pstrb[0]` |
| `tcr_we1` | 1 | `wr_en & sel_tcr & tim_pstrb[1]` |
| `tcmp0_we` / `tcmp1_we` | 1 | `wr_en & sel_tcmp0` / `wr_en & sel_tcmp1` |
| `tier_we` | 1 | `wr_en & sel_tier & tim_pstrb[0]` |
| `thcsr_we` | 1 | `wr_en & sel_thcsr & tim_pstrb[0]` |
| `tdr0_wr_en` | 4 | `(wr_en & sel_tdr0) ? tim_pstrb : 4'h0` |
| `tdr1_wr_en` | 4 | `(wr_en & sel_tdr1) ? tim_pstrb : 4'h0` |
| `int_st_clr` | 1 | `wr_en & sel_tisr & tim_pstrb[0] & tim_pwdata[0]` |
| `rdata_mux` | 32 | case `tim_paddr[11:2]`: `10'h000` → `{20'h0, div_val, 6'h0, div_en, tim_en}`; `10'h001` → `cnt[31:0]`; `10'h002` → `cnt[63:32]`; `10'h003` → `tcmp0`; `10'h004` → `tcmp1`; `10'h005` → `{31'h0, int_en}`; `10'h006` → `{31'h0, int_st}`; `10'h007` → `{30'h0, halt_ack, halt_req}`; default → `32'h0` |
| `rdata` | 32 | `rd_en ? rdata_mux : 32'h0` |

The repeated per-byte hold-mux structure of TCMP0/TCMP1 is the candidate for grouping into a block at S2 (L1).

_VI:_ Cấu trúc mux giữ giá trị lặp theo byte của TCMP0/TCMP1 là phần đề xuất gom thành khối ở S2 (L1).

## Behavior / Hành vi

- A write updates only the strobed bytes of the selected register, at the clock edge where `wr_en` = 1. Reserved bits and RO fields are not stored; writes to reserved addresses are ignored (no `sel_*`).
  - _VI:_ Ghi chỉ cập nhật các byte được strobe của thanh ghi được chọn, ở sườn clock có `wr_en` = 1. Bit reserved và field RO không được lưu; ghi vào địa chỉ reserved bị bỏ qua (không có `sel_*`).
- `wr_err` is purely combinational; `apb_slave` samples it in the wait cycle of a write and then withholds `wr_en`, so a rejected TCR write changes nothing.
  - _VI:_ `wr_err` thuần tổ hợp; `apb_slave` lấy mẫu trong chu kỳ chờ của giao dịch ghi rồi không tạo `wr_en`, nên ghi TCR bị từ chối không thay đổi gì.
- TDR0/TDR1 writes are forwarded as `tdr0_wr_en`/`tdr1_wr_en` byte enables; a TISR write with byte 0 strobed and bit 0 = 1 produces the `int_st_clr` pulse; writing 0 has no effect (RW1C).
  - _VI:_ Ghi TDR0/TDR1 được chuyển thành byte enable `tdr0_wr_en`/`tdr1_wr_en`; ghi TISR có byte 0 được strobe và bit 0 = 1 tạo xung `int_st_clr`; ghi 0 không tác dụng (RW1C).
- Reads: `rdata` = selected word during `rd_en`, otherwise 0; reserved addresses read 0.
  - _VI:_ Đọc: `rdata` = word được chọn khi `rd_en`, ngoài ra bằng 0; địa chỉ reserved đọc ra 0.

## Reset

`tim_en` = 0, `div_en` = 0, `div_val` = 4'h1, `tcmp0` = `tcmp1` = 32'hFFFF_FFFF, `int_en` = 0, `halt_req` = 0.
