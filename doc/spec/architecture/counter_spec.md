# counter – Specification / Đặc tả
Type: leaf · Parent: timer_top · Level: L2

## Function / Chức năng

64-bit up counter `cnt` = {TDR1, TDR0}. Increments by 1 when `cnt_en` = 1 and wraps from 2^64 − 1 to 0; can be written by software per byte through TDR0/TDR1 (write has priority over counting); is cleared to 0 by `cnt_clr` (highest priority). `cnt` is unsigned.

_VI:_ Bộ đếm lên 64-bit `cnt` = {TDR1, TDR0}. Tăng 1 khi `cnt_en` = 1 và quay vòng từ 2^64 − 1 về 0; phần mềm ghi được theo byte qua TDR0/TDR1 (ghi ưu tiên hơn đếm); bị xóa về 0 bởi `cnt_clr` (ưu tiên cao nhất). `cnt` là số không dấu.

## Interface

| Port name | Direction | Width | Type | Connects to | Description |
| --- | --- | --- | --- | --- | --- |
| `sys_clk` | in | 1 | CLK/RST | timer_top.sys_clk | Clock |
| `sys_rst_n` | in | 1 | CLK/RST | timer_top.sys_rst_n | Async active-low reset |
| `cnt_en` | in | 1 | CTRL | cnt_ctrl.cnt_en | Count enable |
| `cnt_clr` | in | 1 | CTRL | cnt_ctrl.cnt_clr | Clear to 0 |
| `tdr0_wr_en` | in | 4 | CTRL | register.tdr0_wr_en | Byte write enables, `cnt[31:0]` |
| `tdr1_wr_en` | in | 4 | CTRL | register.tdr1_wr_en | Byte write enables, `cnt[63:32]` |
| `tim_pwdata` | in | 32 | DATA | timer_top.tim_pwdata | APB write data |
| `cnt` | out | 64 | DATA | register.cnt, interrupt.cnt | Counter value, unsigned |

## Structure / Cấu trúc

| Signal | Width | Kind | Equation |
| --- | --- | --- | --- |
| `cnt_wdata[8k+7:8k]`, k = 0..3 | 8 | comb | `tdr0_wr_en[k] ? tim_pwdata[8k+7:8k] : cnt[8k+7:8k]` |
| `cnt_wdata[32+8k+7:32+8k]`, k = 0..3 | 8 | comb | `tdr1_wr_en[k] ? tim_pwdata[8k+7:8k] : cnt[32+8k+7:32+8k]` |
| `tdr_wr_en` | 8 | comb | `{tdr1_wr_en, tdr0_wr_en}` |
| `cnt_wr` | 1 | comb | `tdr_wr_en != 8'h0` |
| `cnt` ({TDR1, TDR0}) | 64 | FF, reset 64'h0 | D = `cnt_clr ? 64'h0 : (cnt_wr ? cnt_wdata : (cnt_en ? cnt + 64'd1 : cnt))` |

Next-value mux priority (closest to the FF = highest): `cnt_clr` > `cnt_wr` > `cnt_en`. The adder wraps naturally (modulo 2^64).

_VI:_ Thứ tự ưu tiên mux giá trị kế tiếp (gần FF nhất = cao nhất): `cnt_clr` > `cnt_wr` > `cnt_en`. Bộ cộng tự quay vòng (modulo 2^64).

## Behavior / Hành vi

- A software write replaces only the enabled bytes; the other bytes keep the current `cnt` value (not `cnt + 1`), so writing TDR0 never alters TDR1 and vice versa. A count step coinciding with a write is lost (write wins).
  - _VI:_ Ghi phần mềm chỉ thay các byte được cho phép; các byte còn lại giữ giá trị `cnt` hiện tại (không phải `cnt + 1`), nên ghi TDR0 không bao giờ làm đổi TDR1 và ngược lại. Bước đếm trùng chu kỳ với ghi bị bỏ (ghi thắng).
- The counter keeps counting while an interrupt is pending; overflow wraps to 0 and continues.
  - _VI:_ Bộ đếm vẫn đếm khi đang có ngắt chờ; tràn thì quay về 0 và đếm tiếp.

## Reset

`cnt` = 64'h0.
