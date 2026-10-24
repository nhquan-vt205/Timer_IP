# Spec status

STATUS: PASS
Input: doc/spec/source/Timer_Design_Specification_Advanced_VI_preview.pdf

## Module list
| Module | Parent | Type | Level | Function |
| --- | --- | --- | --- | --- |
| `timer_top` | – | top | L0 | Timer IP top |
| `apb_slave` | `timer_top` | leaf | L2 | APB protocol: wait state, error response, wr_en/rd_en |
| `register` | `timer_top` | leaf | L1 | Address decode, configuration registers, wr_err, read mux |
| `cnt_ctrl` | `timer_top` | leaf | L2 | Count enable (divider), halt, TIM_EN falling-edge clear |
| `counter` | `timer_top` | leaf | L2 | 64-bit up counter {TDR1, TDR0} |
| `interrupt` | `timer_top` | leaf | L2 | Compare, INT_ST, tim_int |

## OPEN
| ID | Description | Interim assumption | Impact |
| --- | --- | --- | --- |
| OPEN-001 | Input does not state whether `dbg_mode` is synchronous to `sys_clk` | `dbg_mode` is synchronous to `sys_clk`; no synchronizer is added. The input constraint "`dbg_mode` does not change while TIM_EN = 1" is an environment assumption, not checked by hardware | `cnt_ctrl` only (adding a 2-FF synchronizer would be a local change) |
