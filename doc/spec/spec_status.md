# Spec status

STATUS: PASS
Input: doc/spec/source/Timer_Design_Specification_Advanced_VI_preview.pdf, doc/spec/source/Final_Project_only.pdf (instructor requirement), doc/spec/source/spec_change_notes.md

## Module list
| Module | Parent | Type | Level | Function | Branch |
| --- | --- | --- | --- | --- | --- |
| `timer_top` | – | top | L0 | Timer IP top | `main` |
| `apb_slave` | `timer_top` | leaf | L2 | APB protocol: wait state, error response, wr_en/rd_en | `apb_slave` |
| `register` | `timer_top` | leaf | L1 | Address decode, configuration registers, wr_err, read mux | `register` |
| `cnt_ctrl` | `timer_top` | leaf | L2 | Count enable (divider), halt, TIM_EN falling-edge clear | `cnt_ctrl` |
| `counter` | `timer_top` | leaf | L2 | 64-bit up counter {TDR1, TDR0} | `counter` |
| `interrupt` | `timer_top` | leaf | L2 | Compare, INT_ST, tim_int | `interrupt` |

## OPEN
| ID | Description | Interim assumption | Impact |
| --- | --- | --- | --- |
| OPEN-001 | Input does not state whether `dbg_mode` is synchronous to `sys_clk` | `dbg_mode` is synchronous to `sys_clk`; no synchronizer is added. The input constraint "`dbg_mode` does not change while TIM_EN = 1" is an environment assumption, not checked by hardware | `cnt_ctrl` only (adding a 2-FF synchronizer would be a local change) |
| OPEN-002 | TDR0/TDR1 cannot be overwritten while TIM_EN = 1 (instructor's golden model; not stated in `Final_Project_only.pdf`, which lists only the two TCR error conditions). Input does not state the bus response | The write is ignored and the transfer completes without error (`tim_pslverr` = 0); the condition is the stored TIM_EN (also while halted). To confirm with the instructor's log | `register` (`tdr0_we`/`tdr1_we`); an error response instead would also change `wr_err` |
