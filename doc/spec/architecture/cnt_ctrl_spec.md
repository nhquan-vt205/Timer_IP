# cnt_ctrl – Specification / Đặc tả
Type: leaf · Parent: timer_top · Level: L2

## Function / Chức năng

Generates the count enable `cnt_en` for `counter`: every cycle when DIV_EN = 0, or one pulse every 2^DIV_VAL cycles when DIV_EN = 1 (the whole IP stays on `sys_clk`; this is not a clock divider). Handles debug halt (`halted` = `dbg_mode & halt_req`), which freezes both the divider `div_cnt` and the counter, and produces `cnt_clr` on a TIM_EN 1 → 0 transition.

_VI:_ Tạo tín hiệu cho phép đếm `cnt_en` cho `counter`: mọi chu kỳ khi DIV_EN = 0, hoặc một xung sau mỗi 2^DIV_VAL chu kỳ khi DIV_EN = 1 (toàn IP vẫn chạy `sys_clk`; không phải bộ chia clock). Xử lý halt debug (`halted` = `dbg_mode & halt_req`), làm dừng cả bộ chia `div_cnt` và bộ đếm, và tạo `cnt_clr` khi TIM_EN chuyển 1 → 0.

## Interface

| Port name | Direction | Width | Type | Connects to | Description |
| --- | --- | --- | --- | --- | --- |
| `sys_clk` | in | 1 | CLK/RST | timer_top.sys_clk | Clock |
| `sys_rst_n` | in | 1 | CLK/RST | timer_top.sys_rst_n | Async active-low reset |
| `tim_en` | in | 1 | CTRL | register.tim_en | TCR.TIM_EN |
| `div_en` | in | 1 | CTRL | register.div_en | TCR.DIV_EN |
| `div_val` | in | 4 | CTRL | register.div_val | TCR.DIV_VAL, 0..8 (values > 8 cannot be written) |
| `halt_req` | in | 1 | CTRL | register.halt_req | THCSR.HALT_REQ |
| `dbg_mode` | in | 1 | CTRL | timer_top.dbg_mode | Debug mode |
| `halt_ack` | out | 1 | STATUS | register.halt_ack | = `halted` |
| `cnt_en` | out | 1 | CTRL | counter.cnt_en | Count enable |
| `cnt_clr` | out | 1 | CTRL | counter.cnt_clr | 1-cycle pulse on TIM_EN H→L |

## Structure / Cấu trúc

| Signal | Width | Kind | Equation |
| --- | --- | --- | --- |
| `halted` | 1 | comb | `dbg_mode & halt_req`; `halt_ack` = `halted` |
| `limit` | 8 | comb | `(1 << div_val) - 1`, computed on 9 bits, low 8 bits kept → 0, 1, 3, …, 255 for `div_val` 0..8 |
| `match` | 1 | comb | `div_cnt == limit` |
| `div_clr` | 1 | comb | `~tim_en \| ~div_en` |
| `div_cnt` | 8 | FF, reset 8'h0 | D = `div_clr ? 8'h0 : (halted ? div_cnt : (match ? 8'h0 : div_cnt + 8'd1))` |
| `cnt_en` | 1 | comb | `tim_en & ~halted & (~div_en \| match)` |
| `tim_en_d` | 1 | FF, reset 1'b0 | D = `tim_en` (previous-cycle TIM_EN; name from input) |
| `cnt_clr` | 1 | comb | `tim_en_d & ~tim_en` |

`div_cnt` next-value mux priority (closest to the FF = highest): `div_clr` > `halted` > `match`.

_VI:_ Thứ tự ưu tiên mux giá trị kế tiếp của `div_cnt` (gần FF nhất = cao nhất): `div_clr` > `halted` > `match`.

## Behavior / Hành vi

- DIV_EN = 0: `cnt_en` = `tim_en & ~halted` every cycle; `div_cnt` held at 0.
  - _VI:_ DIV_EN = 0: `cnt_en` = `tim_en & ~halted` ở mọi chu kỳ; `div_cnt` giữ ở 0.
- DIV_EN = 1, TIM_EN = 1: `div_cnt` counts 0 → `limit` and wraps; `cnt_en` pulses for one cycle when `div_cnt` == `limit`, i.e. once every 2^DIV_VAL cycles (DIV_VAL = 0 → every cycle). After enabling, the first `cnt_en` occurs in the 2^DIV_VAL-th cycle.
  - _VI:_ DIV_EN = 1, TIM_EN = 1: `div_cnt` đếm 0 → `limit` rồi quay vòng; `cnt_en` là xung một chu kỳ khi `div_cnt` == `limit`, tức một lần mỗi 2^DIV_VAL chu kỳ (DIV_VAL = 0 → mọi chu kỳ). Sau khi bật, `cnt_en` đầu tiên ở chu kỳ thứ 2^DIV_VAL.
- Halt (`dbg_mode` = 1 and HALT_REQ = 1): `cnt_en` = 0 and `div_cnt` holds, so counting resumes from exactly the same position (including the divider phase) when halt ends; elapsed count time excludes the halt time.
  - _VI:_ Halt (`dbg_mode` = 1 và HALT_REQ = 1): `cnt_en` = 0 và `div_cnt` giữ nguyên, nên khi hết halt việc đếm tiếp tục từ đúng vị trí (kể cả pha của bộ chia); thời gian đếm không tính thời gian halt.
- TIM_EN = 0 or DIV_EN = 0 clears `div_cnt` (highest priority), so each re-enable starts a fresh division period.
  - _VI:_ TIM_EN = 0 hoặc DIV_EN = 0 xóa `div_cnt` (ưu tiên cao nhất), nên mỗi lần bật lại bắt đầu một chu kỳ chia mới.
- `cnt_clr` = 1 for exactly one cycle, the first cycle in which `tim_en` = 0 after being 1.
  - _VI:_ `cnt_clr` = 1 đúng một chu kỳ, là chu kỳ đầu tiên `tim_en` = 0 sau khi đang bằng 1.

## Reset

`div_cnt` = 8'h0, `tim_en_d` = 0.
