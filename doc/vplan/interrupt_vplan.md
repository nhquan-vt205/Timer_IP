# interrupt – Direct Test VPLAN

DUT: `interrupt` · Scope: leaf · Configuration: no parameters · Spec: `doc/spec/architecture/interrupt_spec.md`, `doc/spec/register_file/register_map.md` (TISR, TIER)

The testbench acts as the `counter` and `register` blocks: it drives `cnt`, `tcmp0`, `tcmp1`, `int_en` and `int_st_clr`, and checks `int_st` and `tim_int` in every cycle.

_VI:_ Testbench đóng vai khối `counter` và `register`: lái `cnt`, `tcmp0`, `tcmp1`, `int_en` và `int_st_clr`, và kiểm `int_st` cùng `tim_int` ở mọi chu kỳ.

Cycle notation: `cN` is the clock cycle after the N-th rising edge counted from the start of the sequence. Stimulus changes just after a rising edge; outputs are checked before the next rising edge. `int_st` is a flip-flop, so a match or clear applied in `cN` is visible in `cN+1`; `tim_int` is combinational and follows `int_st` and `int_en` in the same cycle. Unless stated otherwise, `int_st_clr`=0, `int_en`=1, `{tcmp1, tcmp0}`=`64'h0000_0000_0000_0010` and every test starts right after reset with `cnt`=`64'h0`.

_VI:_ Ký hiệu chu kỳ: `cN` là chu kỳ clock sau sườn lên thứ N tính từ đầu chuỗi. Stimulus đổi ngay sau sườn lên; output được kiểm trước sườn lên kế tiếp. `int_st` là flip-flop nên match hoặc clear đặt ở `cN` sẽ thấy ở `cN+1`; `tim_int` là tổ hợp và theo `int_st`, `int_en` ngay trong chu kỳ đó. Nếu không nói khác thì `int_st_clr`=0, `int_en`=1, `{tcmp1, tcmp0}`=`64'h0000_0000_0000_0010` và mỗi test bắt đầu ngay sau reset với `cnt`=`64'h0`.

## Checklist

| ID | Item | Sub item 1 | Sub item 2 | Test sequence | Pass condition |
|---|---|---|---|---|---|
| TC_INTERRUPT_001 | Reset value check | Reset | INT_ST and tim_int after reset | 1. Hold `sys_rst_n`=0 for 2 cycles with `cnt`=`{tcmp1, tcmp0}`=`64'hFFFF_FFFF_FFFF_FFFF` (register reset value, compare matches) and `int_en`=1. 2. Release reset with `cnt`=`64'h0`, then 2 idle cycles. | During reset and after release: `int_st`=0, `tim_int`=0 in every cycle. |
| TC_INTERRUPT_002 | Compare match set | Compare | Set one cycle after the match, then hold | c0: `cnt`=`64'h0E`. c1: `64'h0F`. c2: `64'h10` (match). c3: `64'h11`. c4–c6: `cnt`=`64'h12`, `64'h13`, `64'h14`. | c0–c2: `int_st`=0, `tim_int`=0. c3–c6: `int_st`=1, `tim_int`=1 (set from T+1, held after `cnt` leaves `tcmp`). |
| TC_INTERRUPT_003 | 64-bit compare | Compare | Every bit of cnt and tcmp is compared | `{tcmp1, tcmp0}`=`64'h0000_0001_0000_0000`. c0: `cnt`=`64'h0000_0000_0000_0000`. c1: `64'h0000_0001_0000_0001`. c2: `64'h0000_0000_FFFF_FFFF`. c3: `64'h8000_0001_0000_0000`. c4: `64'h0000_0001_0000_0000` (match). c5: `cnt`=`64'h0`. c6: `int_st_clr`=1. c7: idle. Then `{tcmp1, tcmp0}`=`64'hFFFF_FFFF_FFFF_FFFF`: c8: `cnt`=`64'h7FFF_FFFF_FFFF_FFFF`. c9: `64'hFFFF_FFFF_FFFF_FFFF` (match). c10: `cnt`=`64'h0`. | c0–c4: `int_st`=0 (no partial match sets it). c5–c6: `int_st`=1. c7–c9: `int_st`=0. c10: `int_st`=1. |
| TC_INTERRUPT_004 | INT_ST clear | Clear | RW1C clear by int_st_clr | 1. c0: `int_st_clr`=1 with `int_st`=0 (no effect). c1: idle. 2. c2: `cnt`=`64'h10` (match). c3: `cnt`=`64'h11`. c4: `int_st_clr`=1. c5–c6: idle with `cnt`=`64'h12`. | c0–c2: `int_st`=0. c3–c4: `int_st`=1, `tim_int`=1. c5–c6: `int_st`=0, `tim_int`=0 (cleared one cycle after the pulse, stays 0 without a new match). |
| TC_INTERRUPT_005 | Clear priority | Clear | Clear wins over a match in the same cycle | `cnt`=`64'h10` held (match every cycle) from c0. 1. c0: `int_st_clr`=1 (set and clear together, `int_st`=0). c1–c2: `int_st_clr`=0. 2. c3: `int_st_clr`=1 (`int_st`=1). c4: `int_st_clr`=0. c5: `int_st_clr`=1. c6: `int_st_clr`=1. c7–c8: `int_st_clr`=0. | c0–c1: `int_st`=0 (clear wins in c0). c2–c3: `int_st`=1. c4: `int_st`=0 (cleared). c5: `int_st`=1 (set again by the continuous match). c6–c7: `int_st`=0. c8: `int_st`=1. |
| TC_INTERRUPT_006 | Interrupt mask | Mask | tim_int = INT_ST & INT_EN | 1. c0: `int_en`=0, `cnt`=`64'h10` (match). c1: `cnt`=`64'h11`, `int_en`=0. c2: `int_en`=0. c3: `int_en`=1. c4: `int_en`=0. c5: `int_en`=1. 2. c6: `int_st_clr`=1, `int_en`=1. c7: idle. 3. INT_ST = 0: c8: `int_en`=0. c9: `int_en`=1. | c0: `int_st`=0, `tim_int`=0. c1–c2: `int_st`=1, `tim_int`=0 (masked, INT_ST kept). c3: `tim_int`=1. c4: `tim_int`=0, `int_st`=1. c5–c6: `tim_int`=1. c7: `int_st`=0, `tim_int`=0. c8–c9: `tim_int`=0. |
| TC_INTERRUPT_007 | Reset during operation | Reset | Asynchronous reset while INT_ST = 1 | 1. c0: `cnt`=`64'h10` (match). c1: `cnt`=`64'h11` (`int_st`=1). 2. Mid-cycle in c2 (no clock edge) assert `sys_rst_n`=0 and hold 2 cycles. 3. Release reset with `cnt`=`64'h11`, then 2 idle cycles. | c1–c2 before reset: `int_st`=1, `tim_int`=1. Immediately after `sys_rst_n` falls and during reset: `int_st`=0, `tim_int`=0. After release: `int_st`=0, `tim_int`=0 (no match). |

## Function coverage

| Function (spec section) | Test |
| --- | --- |
| Reset: `int_st` = 0, `tim_int` = 0 (Reset) | TC_INTERRUPT_001, TC_INTERRUPT_007 |
| `cnt_match` = `cnt == {tcmp1, tcmp0}`, 64-bit (Structure) | TC_INTERRUPT_002, TC_INTERRUPT_003 |
| Match in cycle T sets INT_ST from T+1, held until clear (Behavior) | TC_INTERRUPT_002, TC_INTERRUPT_004 |
| `int_st_clr` clears INT_ST, no effect when INT_ST = 0 (Behavior, TISR RW1C) | TC_INTERRUPT_004 |
| Clear wins over set in the same cycle (Behavior) | TC_INTERRUPT_005 |
| Continuous compare: set again after clear while `cnt` = `tcmp` (Behavior) | TC_INTERRUPT_005 |
| `tim_int` = INT_ST & INT_EN; masking keeps INT_ST (Behavior, TIER) | TC_INTERRUPT_006 |

All main functions of the spec are covered. Generating `int_st_clr` from a TISR write and reading INT_ST through `rdata` belong to `register` and are not tested here.

_VI:_ Mọi chức năng chính của spec đều được phủ. Việc tạo `int_st_clr` từ lần ghi TISR và đọc INT_ST qua `rdata` thuộc `register` và không được kiểm ở đây.
