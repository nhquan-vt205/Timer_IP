# interrupt – Specification / Đặc tả
Type: leaf · Parent: timer_top · Level: L2

## Function / Chức năng

Compares `cnt` with the 64-bit compare value `tcmp` = {`tcmp1`, `tcmp0`} every cycle, holds the pending bit INT_ST (TISR, RW1C) and drives the maskable, level-sensitive interrupt `tim_int` = INT_ST & INT_EN.

_VI:_ So sánh `cnt` với giá trị so sánh 64-bit `tcmp` = {`tcmp1`, `tcmp0`} ở mọi chu kỳ, giữ bit chờ ngắt INT_ST (TISR, RW1C) và tạo ngắt theo mức, có thể che `tim_int` = INT_ST & INT_EN.

## Interface

| Port name | Direction | Width | Type | Connects to | Description |
| --- | --- | --- | --- | --- | --- |
| `sys_clk` | in | 1 | CLK/RST | timer_top.sys_clk | Clock |
| `sys_rst_n` | in | 1 | CLK/RST | timer_top.sys_rst_n | Async active-low reset |
| `cnt` | in | 64 | DATA | counter.cnt | Counter value |
| `tcmp0` | in | 32 | DATA | register.tcmp0 | Compare value [31:0] |
| `tcmp1` | in | 32 | DATA | register.tcmp1 | Compare value [63:32] |
| `int_en` | in | 1 | CTRL | register.int_en | TIER.INT_EN |
| `int_st_clr` | in | 1 | CTRL | register.int_st_clr | Clear INT_ST |
| `int_st` | out | 1 | STATUS | register.int_st | TISR.INT_ST |
| `tim_int` | out | 1 | STATUS | timer_top.tim_int | Timer interrupt |

## Structure / Cấu trúc

| Signal | Width | Kind | Equation |
| --- | --- | --- | --- |
| `tcmp` | 64 | comb | `{tcmp1, tcmp0}` |
| `cnt_match` | 1 | comb | `cnt == tcmp` |
| `int_st` (TISR.INT_ST) | 1 | FF, reset 1'b0 | D = `int_st_clr ? 1'b0 : (cnt_match ? 1'b1 : int_st)` |
| `tim_int` | 1 | comb | `int_st & int_en` |

## Behavior / Hành vi

- `cnt_match` in cycle T sets INT_ST from T+1; INT_ST then stays 1 until software clears it (`int_st_clr`). If set and clear happen in the same cycle, clear wins.
  - _VI:_ `cnt_match` ở chu kỳ T làm INT_ST = 1 từ T+1; sau đó INT_ST giữ 1 tới khi phần mềm xóa (`int_st_clr`). Set và xóa cùng chu kỳ thì xóa thắng.
- The comparison is continuous: while `cnt` stays equal to `tcmp` (e.g. timer stopped or halted on the compare value), INT_ST is set again in the cycle after a clear.
  - _VI:_ So sánh là liên tục: khi `cnt` vẫn bằng `tcmp` (vd. timer dừng hoặc halt đúng tại giá trị so sánh), INT_ST được set lại ngay chu kỳ sau khi xóa.
- INT_EN = 0 only masks `tim_int`; INT_ST is kept, and `tim_int` reappears when INT_EN is set again if INT_ST is still 1.
  - _VI:_ INT_EN = 0 chỉ che `tim_int`; INT_ST được giữ, và `tim_int` xuất hiện lại khi bật INT_EN nếu INT_ST vẫn bằng 1.

## Reset

`int_st` = 0 (so `tim_int` = 0).
