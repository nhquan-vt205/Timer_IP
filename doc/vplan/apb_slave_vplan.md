# apb_slave – Direct Test VPLAN

DUT: `apb_slave` · Scope: leaf · Configuration: no parameters · Spec: `doc/spec/architecture/apb_slave_spec.md`

The testbench acts as the APB master and as the `register` block: it drives `tim_psel`, `tim_penable`, `tim_pwrite`, and the register-side inputs `wr_err` and `rdata`. It checks `tim_pready`, `tim_pslverr`, `tim_prdata`, `wr_en` and `rd_en` in every cycle of each transfer. Each APB transfer takes 3 cycles: setup, wait, then the last access cycle.

_VI:_ Testbench đóng vai APB master và khối `register`: lái `tim_psel`, `tim_penable`, `tim_pwrite` cùng các input phía register `wr_err` và `rdata`. Nó kiểm `tim_pready`, `tim_pslverr`, `tim_prdata`, `wr_en` và `rd_en` ở mọi chu kỳ của từng giao dịch. Mỗi giao dịch APB gồm 3 chu kỳ: setup, chờ, rồi chu kỳ access cuối.

Cycle notation: `cN` is the clock cycle after the N-th rising edge counted from the start of the sequence. Stimulus changes just after a rising edge; outputs are checked before the next rising edge. `c0` is the setup cycle (`tim_psel`=1, `tim_penable`=0), `c1` the wait cycle and `c2` the last access cycle (both with `tim_psel`=1, `tim_penable`=1). Unless stated otherwise, `wr_err`=0 and `rdata`=`32'h0000_0000`.

_VI:_ Ký hiệu chu kỳ: `cN` là chu kỳ clock sau sườn lên thứ N tính từ đầu chuỗi. Stimulus đổi ngay sau sườn lên; output được kiểm trước sườn lên kế tiếp. `c0` là chu kỳ setup (`tim_psel`=1, `tim_penable`=0), `c1` là chu kỳ chờ, `c2` là chu kỳ access cuối (cả hai đều có `tim_psel`=1, `tim_penable`=1). Nếu không nói khác thì `wr_err`=0 và `rdata`=`32'h0000_0000`.

## Checklist

| ID | Item | Sub item 1 | Sub item 2 | Test sequence | Pass condition |
|---|---|---|---|---|---|
| TC_APB_SLAVE_001 | Reset value check | Reset | Output values after reset | 1. Hold `sys_rst_n`=0 for 2 cycles with all APB inputs at 0, then release. 2. Keep the bus idle (`tim_psel`=0) for 2 cycles and check outputs in every cycle. | During and after reset: `tim_pready`=0, `tim_pslverr`=0, `wr_en`=0, `rd_en`=0, `tim_prdata`=`32'h0000_0000`. |
| TC_APB_SLAVE_002 | Write transfer | APB write | One wait state, single `wr_en` | Write transfer, `tim_pwrite`=1, `wr_err`=0: c0 setup; c1 wait; c2 last access; c3 idle (`tim_psel`=0, `tim_penable`=0). | c0: `tim_pready`=0, `wr_en`=0. c1: `tim_pready`=0, `wr_en`=0. c2: `tim_pready`=1, `tim_pslverr`=0, `wr_en`=1, `rd_en`=0. c3: `tim_pready`=0, `wr_en`=0. `wr_en`=1 in exactly one cycle (c2). |
| TC_APB_SLAVE_003 | Read transfer | APB read | One wait state, single `rd_en`, read data path | 1. Read transfer, `tim_pwrite`=0, `rdata`=`32'hA5A5_5A5A`: c0 setup; c1 wait; c2 last access; c3 idle. 2. Repeat with `rdata` = `32'h0000_0000`, `32'hFFFF_FFFF`, `32'h5555_5555`, `32'hAAAA_AAAA`. | c0, c1: `tim_pready`=0, `rd_en`=0. c2: `tim_pready`=1, `tim_pslverr`=0, `rd_en`=1, `wr_en`=0, `tim_prdata` = `rdata` (e.g. `32'hA5A5_5A5A`). c3: `tim_pready`=0, `rd_en`=0. `tim_prdata` = `rdata` in every cycle. |
| TC_APB_SLAVE_004 | Write error | APB write | `wr_err` sampled in the wait cycle | 1. Write transfer with `wr_err`=1 during c0–c2; c3 idle. 2. Write transfer with `wr_err`=1 in c1 only (0 in c0, c2). 3. Write transfer with `wr_err`=1 in c2 only (0 in c0, c1). | Cases 1 and 2: c2 `tim_pready`=1, `tim_pslverr`=1, `wr_en`=0 in every cycle; c3 `tim_pslverr`=0. Case 3 (error after the sampling cycle): c2 `tim_pready`=1, `tim_pslverr`=0, `wr_en`=1. |
| TC_APB_SLAVE_005 | Read without error | APB read | `wr_err` ignored on reads | Read transfer, `tim_pwrite`=0, `wr_err`=1 during c0–c2, `rdata`=`32'h1234_5678`; c3 idle. | c2: `tim_pready`=1, `tim_pslverr`=0, `rd_en`=1, `wr_en`=0, `tim_prdata`=`32'h1234_5678`. `tim_pslverr`=0 in every cycle. |
| TC_APB_SLAVE_006 | Back-to-back transfers | APB sequence | Transfers without idle cycles | Four transfers with no idle cycle between them, each the setup–wait–access sequence (12 cycles, c0–c11): write OK (c0–c2), write with `wr_err`=1 (c3–c5), write OK (c6–c8), read (c9–c11, `rdata`=`32'hCAFE_0001`); c12 idle. | `tim_pready` = 1 only in c2, c5, c8, c11. `wr_en` = 1 only in c2 and c8. `rd_en` = 1 only in c11. `tim_pslverr` = 1 only in c5 (the error does not carry into c6–c8). c11: `tim_prdata`=`32'hCAFE_0001`. |
| TC_APB_SLAVE_007 | No access phase | APB protocol | No response without `tim_psel` & `tim_penable` | 1. `tim_psel`=1, `tim_penable`=0, `tim_pwrite`=1 for 4 cycles. 2. `tim_psel`=0, `tim_penable`=1, `tim_pwrite`=1 for 4 cycles. 3. Repeat 1 and 2 with `tim_pwrite`=0. `wr_err`=1 in all cases. | In every cycle: `tim_pready`=0, `tim_pslverr`=0, `wr_en`=0, `rd_en`=0. |
| TC_APB_SLAVE_008 | Reset during transfer | Reset | Asynchronous reset in a transfer | 1. Start a write transfer with `wr_err`=1; in c2 (`tim_pready`=1, `tim_pslverr`=1) assert `sys_rst_n`=0 mid-cycle, without a clock edge, and hold for 2 cycles. 2. Release reset, then run one normal write transfer. | Immediately after `sys_rst_n` falls (before the next edge): `tim_pready`=0, `tim_pslverr`=0, `wr_en`=0, `rd_en`=0. After release, the next write behaves as in TC_APB_SLAVE_002 (`wr_en`=1 only in its c2). |

## Function coverage

| Function (spec section) | Test |
| --- | --- |
| Reset: `pready_q`=0, `pslverr_q`=0 (Reset) | TC_APB_SLAVE_001, TC_APB_SLAVE_008 |
| One wait state per transfer, `tim_pready` from FF (Function, Behavior) | TC_APB_SLAVE_002, TC_APB_SLAVE_003, TC_APB_SLAVE_006 |
| Single-cycle `wr_en` in the last access cycle (Behavior) | TC_APB_SLAVE_002, TC_APB_SLAVE_006 |
| Single-cycle `rd_en` in the last access cycle (Behavior) | TC_APB_SLAVE_003, TC_APB_SLAVE_006 |
| `wr_err` sampled in the wait cycle into `tim_pslverr` (Behavior) | TC_APB_SLAVE_004, TC_APB_SLAVE_006 |
| Erroneous write produces no `wr_en` (Behavior) | TC_APB_SLAVE_004, TC_APB_SLAVE_006 |
| Reads never return an error (Behavior) | TC_APB_SLAVE_005 |
| `tim_prdata` = `rdata`, combinational (Behavior) | TC_APB_SLAVE_003, TC_APB_SLAVE_005 |
| No strobes outside the access phase (`apb_acc`) (Structure) | TC_APB_SLAVE_007 |

All main functions of the spec are covered. The register-side behavior (`rdata` forced to 0 outside `rd_en`, the source of `wr_err`) belongs to `register` and is not tested here.

_VI:_ Mọi chức năng chính của spec đều được phủ. Hành vi phía register (`rdata` bị ép về 0 ngoài `rd_en`, nguồn tạo `wr_err`) thuộc `register` và không được kiểm ở đây.
