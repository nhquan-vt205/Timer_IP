# apb_slave – Specification / Đặc tả
Type: leaf · Parent: timer_top · Level: L2

## Function / Chức năng

Handles the APB slave protocol with exactly one wait state per transfer (setup – wait – access, 3 cycles). Generates single-cycle `wr_en`/`rd_en` strobes for `register` in the last access cycle, registers `tim_pready` and `tim_pslverr`, suppresses `wr_en` for erroneous writes, and passes `rdata` straight to `tim_prdata`.

_VI:_ Xử lý giao thức APB slave với đúng một chu kỳ chờ mỗi giao dịch (setup – wait – access, 3 chu kỳ). Tạo xung một chu kỳ `wr_en`/`rd_en` cho `register` ở chu kỳ access cuối, lấy `tim_pready` và `tim_pslverr` từ flip-flop, chặn `wr_en` khi giao dịch ghi lỗi, và nối thẳng `rdata` ra `tim_prdata`.

## Interface

| Port name | Direction | Width | Type | Connects to | Description |
| --- | --- | --- | --- | --- | --- |
| `sys_clk` | in | 1 | CLK/RST | timer_top.sys_clk | Clock |
| `sys_rst_n` | in | 1 | CLK/RST | timer_top.sys_rst_n | Async active-low reset |
| `tim_psel` | in | 1 | CTRL | timer_top.tim_psel | APB select |
| `tim_penable` | in | 1 | CTRL | timer_top.tim_penable | APB enable |
| `tim_pwrite` | in | 1 | CTRL | timer_top.tim_pwrite | 1: write, 0: read |
| `wr_err` | in | 1 | STATUS | register.wr_err | Combinational TCR write error |
| `rdata` | in | 32 | DATA | register.rdata | Read data from read mux |
| `tim_prdata` | out | 32 | DATA | timer_top.tim_prdata | = `rdata` |
| `tim_pready` | out | 1 | STATUS | timer_top.tim_pready | = `pready_q` |
| `tim_pslverr` | out | 1 | STATUS | timer_top.tim_pslverr | = `pslverr_q` |
| `wr_en` | out | 1 | CTRL | register.wr_en | Register write strobe (last cycle of a non-error write) |
| `rd_en` | out | 1 | CTRL | register.rd_en | Register read strobe (last cycle of a read) |

## Structure / Cấu trúc

| Signal | Kind | Equation |
| --- | --- | --- |
| `apb_acc` | comb | `tim_psel & tim_penable` |
| `pready_q` | FF, reset 1'b0 | D = `apb_acc & ~pready_q` |
| `pslverr_q` | FF, reset 1'b0 | D = `apb_acc & ~pready_q & tim_pwrite & wr_err` |
| `wr_en` | comb | `apb_acc & pready_q & tim_pwrite & ~pslverr_q` |
| `rd_en` | comb | `apb_acc & pready_q & ~tim_pwrite` |
| `tim_pready` | wire | `pready_q` |
| `tim_pslverr` | wire | `pslverr_q` |
| `tim_prdata` | wire | `rdata` |

## Behavior / Hành vi

- First access cycle (`apb_acc` = 1, `pready_q` = 0) is the wait cycle: `tim_pready` = 0; for a write, `wr_err` is sampled into `pslverr_q`.
  - _VI:_ Chu kỳ access đầu (`apb_acc` = 1, `pready_q` = 0) là chu kỳ chờ: `tim_pready` = 0; với giao dịch ghi, `wr_err` được lấy mẫu vào `pslverr_q`.
- Second access cycle: `tim_pready` = 1, `tim_pslverr` = `pslverr_q`; `wr_en` = 1 for a write without error, `rd_en` = 1 for a read. Both FFs return to 0 at the next edge (`pready_q` toggles off via `~pready_q`; `pslverr_q` D is 0 because `pready_q` = 1).
  - _VI:_ Chu kỳ access thứ hai: `tim_pready` = 1, `tim_pslverr` = `pslverr_q`; `wr_en` = 1 khi ghi không lỗi, `rd_en` = 1 khi đọc. Cả hai FF về 0 ở sườn kế tiếp (`pready_q` tự về 0 qua `~pready_q`; D của `pslverr_q` bằng 0 vì `pready_q` = 1).
- An erroneous write never produces `wr_en`, so no register bit changes. Reads never return an error (`tim_pslverr` = 0).
  - _VI:_ Giao dịch ghi lỗi không bao giờ tạo `wr_en`, nên không bit nào thay đổi. Đọc không bao giờ lỗi (`tim_pslverr` = 0).
- `tim_prdata` is combinational from `rdata`; `register` forces `rdata` = 0 outside `rd_en`.
  - _VI:_ `tim_prdata` là tổ hợp từ `rdata`; `register` ép `rdata` = 0 ngoài `rd_en`.

## Reset

`pready_q` = 0, `pslverr_q` = 0.
