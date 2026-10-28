# counter – Direct Test VPLAN

DUT: `counter` · Scope: leaf · Configuration: no parameters · Spec: `doc/spec/architecture/counter_spec.md`, `doc/spec/register_file/register_map.md` (TDR0, TDR1)

The testbench acts as `cnt_ctrl`, `register` and `timer_top`: it drives `cnt_en`, `cnt_clr`, `tdr0_wr_en`, `tdr1_wr_en` and `tim_pwdata`, and checks the 64-bit output `cnt` in every cycle.

_VI:_ Testbench đóng vai `cnt_ctrl`, `register` và `timer_top`: lái `cnt_en`, `cnt_clr`, `tdr0_wr_en`, `tdr1_wr_en` và `tim_pwdata`, và kiểm output 64 bit `cnt` ở mọi chu kỳ.

Cycle notation: `cN` is the clock cycle after the N-th rising edge counted from the start of the sequence. Stimulus changes just after a rising edge; `cnt` is checked before the next rising edge. `cnt` is a flip-flop, so the inputs applied in `cN` decide `cnt` in `cN+1`. Unless stated otherwise, every input holds its previous value, and every test starts right after reset with `cnt_en`=0, `cnt_clr`=0, `tdr0_wr_en`=4'h0, `tdr1_wr_en`=4'h0, `tim_pwdata`=32'h0. `cnt` values are written as 64-bit hex `{TDR1, TDR0}`. In the full IP, `cnt_en` and `cnt_clr` are never 1 together (`cnt_en` needs TIM_EN = 1, `cnt_clr` needs TIM_EN = 0); the module-level tests drive them together only to check the mux priority of the spec.

_VI:_ Ký hiệu chu kỳ: `cN` là chu kỳ clock sau sườn lên thứ N tính từ đầu chuỗi. Stimulus đổi ngay sau sườn lên; `cnt` được kiểm trước sườn lên kế tiếp. `cnt` là flip-flop nên input đặt ở `cN` quyết định `cnt` ở `cN+1`. Nếu không nói khác thì mọi input giữ giá trị trước đó, và mỗi test bắt đầu ngay sau reset với `cnt_en`=0, `cnt_clr`=0, `tdr0_wr_en`=4'h0, `tdr1_wr_en`=4'h0, `tim_pwdata`=32'h0. Giá trị `cnt` ghi dạng hex 64 bit `{TDR1, TDR0}`. Trong IP đầy đủ, `cnt_en` và `cnt_clr` không bao giờ cùng bằng 1 (`cnt_en` cần TIM_EN = 1, `cnt_clr` cần TIM_EN = 0); test mức module lái chúng cùng lúc chỉ để kiểm thứ tự ưu tiên mux của spec.

## Checklist

| ID | Item | Sub item 1 | Sub item 2 | Test sequence | Pass condition |
|---|---|---|---|---|---|
| TC_COUNTER_001 | Reset value check | Reset | cnt = 0 during and after reset | 1. Hold `sys_rst_n`=0 for 2 cycles with `cnt_en`=1, `tdr0_wr_en`=4'hF, `tdr1_wr_en`=4'hF, `tim_pwdata`=32'hFFFF_FFFF. 2. Release reset with every input at its default, then 2 idle cycles. | `cnt`=64'h0 in every cycle (reset ignores count and write; no count after release with `cnt_en`=0). |
| TC_COUNTER_002 | Count up | Count | Increment by 1 when cnt_en = 1, hold when 0 | c0: `cnt_en`=1. c1–c9: idle. c10: `cnt_en`=0. c11–c12: idle. c13: `cnt_en`=1. c14–c15: idle. | `cnt` = 0, 1, 2, …, 10 in c0–c10 (`cnt` in cN = N). c11–c13: `cnt`=10 (held). c14: 11. c15: 12. |
| TC_COUNTER_003 | Byte write | Software write | Per-byte write of TDR0 and TDR1 | `cnt_en`=0. c0: `tdr0_wr_en`=4'b0001, `tim_pwdata`=32'hA1B2_C3D4. c1: `tdr0_wr_en`=4'b0010, `tim_pwdata`=32'h1122_3344. c2: `tdr0_wr_en`=4'b0100, `tim_pwdata`=32'h5566_7788. c3: `tdr0_wr_en`=4'b1000, `tim_pwdata`=32'h99AA_BBCC. c4: `tdr0_wr_en`=4'hF, `tim_pwdata`=32'hDEAD_BEEF. c5: `tdr0_wr_en`=4'h0. c6: `tdr1_wr_en`=4'b0101, `tim_pwdata`=32'h1234_5678. c7: `tdr1_wr_en`=4'b1010, `tim_pwdata`=32'hCAFE_F00D. c8: `tdr1_wr_en`=4'hF, `tim_pwdata`=32'hFFFF_FFFF. c9: `tdr1_wr_en`=4'h0. c10: `tdr0_wr_en`=4'b0011, `tdr1_wr_en`=4'b1100, `tim_pwdata`=32'h0123_4567. c11: `tdr0_wr_en`=4'h0, `tdr1_wr_en`=4'h0. c12: idle. | c0: 64'h0. c1: 64'h0000_0000_0000_00D4. c2: 64'h0000_0000_0000_33D4. c3: 64'h0000_0000_0066_33D4. c4: 64'h0000_0000_9966_33D4. c5–c6: 64'h0000_0000_DEAD_BEEF. c7: 64'h0034_0078_DEAD_BEEF. c8: 64'hCA34_F078_DEAD_BEEF. c9–c10: 64'hFFFF_FFFF_DEAD_BEEF. c11–c12: 64'h0123_FFFF_DEAD_4567 (bytes not enabled keep their value; TDR0 writes never change TDR1 and vice versa). |
| TC_COUNTER_004 | Write over count | Priority | Write wins over counting; other bytes keep cnt, not cnt + 1 | c0: `cnt_en`=1 (held to the end). c1–c4: idle. c5: `tdr0_wr_en`=4'b0001, `tim_pwdata`=32'h0000_00F0. c6: `tdr0_wr_en`=4'b0010, `tim_pwdata`=32'h0000_AB00. c7: `tdr0_wr_en`=4'h0. c8: idle. c9: `tdr1_wr_en`=4'hF, `tim_pwdata`=32'h0000_0001. c10: `tdr1_wr_en`=4'h0. c11: idle. | c0–c5: `cnt` = 0, 1, 2, 3, 4, 5. c6: 64'h0000_0000_0000_00F0 (not 6). c7: 64'h0000_0000_0000_ABF0 (byte 0 keeps F0, not F1). c8: 64'h0000_0000_0000_ABF1. c9: 64'h0000_0000_0000_ABF2. c10: 64'h0000_0001_0000_ABF2 (TDR0 keeps ABF2, count step lost). c11: 64'h0000_0001_0000_ABF3. |
| TC_COUNTER_005 | Clear priority | Clear | cnt_clr clears cnt, priority over write and count | c0: `cnt_en`=1. c1–c2: idle. c3: `cnt_clr`=1. c4: `cnt_clr`=0. c5: idle. c6: `cnt_clr`=1, `tdr0_wr_en`=4'hF, `tdr1_wr_en`=4'hF, `tim_pwdata`=32'h5555_5555. c7: `cnt_clr`=0, `tdr0_wr_en`=4'h0, `tdr1_wr_en`=4'h0. c8: `cnt_en`=0, `cnt_clr`=1. c9: `cnt_clr`=0. c10: idle. | c0–c3: `cnt` = 0, 1, 2, 3. c4: 0 (clear wins over count). c5: 1. c6: 2. c7: 0 (clear wins over write and count). c8: 1. c9–c10: 0. |
| TC_COUNTER_006 | Carry and wrap | Count | Carry across 32 bits and wrap from 2^64 - 1 to 0 | c0: `tdr0_wr_en`=4'hF, `tim_pwdata`=32'hFFFF_FFFE. c1: `tdr0_wr_en`=4'h0, `cnt_en`=1. c2–c3: idle. c4: `cnt_en`=0, `tdr1_wr_en`=4'hF, `tim_pwdata`=32'hFFFF_FFFF. c5: `tdr1_wr_en`=4'h0, `tdr0_wr_en`=4'hF, `tim_pwdata`=32'hFFFF_FFFE. c6: `tdr0_wr_en`=4'h0, `cnt_en`=1. c7–c9: idle. | c1: 64'h0000_0000_FFFF_FFFE. c2: 64'h0000_0000_FFFF_FFFF. c3: 64'h0000_0001_0000_0000 (carry into TDR1). c4: 64'h0000_0001_0000_0001. c5: 64'hFFFF_FFFF_0000_0001. c6: 64'hFFFF_FFFF_FFFF_FFFE. c7: 64'hFFFF_FFFF_FFFF_FFFF. c8: 64'h0 (wrap). c9: 64'h0000_0000_0000_0001. |
| TC_COUNTER_007 | Reset during operation | Reset | Asynchronous reset clears cnt mid-cycle | 1. c0: `cnt_en`=1. c1–c5: idle (`cnt`=5 in c5). 2. Mid-cycle in c5 (no clock edge) assert `sys_rst_n`=0 and hold 2 cycles with `cnt_en`=1, `tdr0_wr_en`=4'hF, `tim_pwdata`=32'hFFFF_FFFF. 3. Release reset with `cnt_en`=1, `tdr0_wr_en`=4'h0, then r0–r3 idle. | c0–c5 before reset: `cnt` = 0..5. Immediately after `sys_rst_n` falls and during reset: `cnt`=64'h0. After release: r0–r3 `cnt` = 0, 1, 2, 3. |

## Function coverage

| Function (spec section) | Test |
| --- | --- |
| Reset: `cnt` = 64'h0 (Reset) | TC_COUNTER_001, TC_COUNTER_007 |
| Increment by 1 when `cnt_en` = 1, hold otherwise (Function, Structure) | TC_COUNTER_002, TC_COUNTER_004, TC_COUNTER_006 |
| Wrap from 2^64 - 1 to 0, adder modulo 2^64 (Function, Structure) | TC_COUNTER_006 |
| Per-byte write: `cnt_wdata` byte k = `tdrX_wr_en[k] ? tim_pwdata` byte : `cnt` byte (Structure) | TC_COUNTER_003, TC_COUNTER_006 |
| Writing TDR0 never alters TDR1 and vice versa (Behavior) | TC_COUNTER_003, TC_COUNTER_004 |
| `cnt_wr` = any byte enable; write wins over count, other bytes keep `cnt` not `cnt + 1` (Structure, Behavior) | TC_COUNTER_004 |
| `cnt_clr` clears `cnt`, priority `cnt_clr` > `cnt_wr` > `cnt_en` (Structure) | TC_COUNTER_005 |
| Counter keeps counting after overflow (Behavior) | TC_COUNTER_006 |

All main functions of the spec are covered. "Keeps counting while an interrupt is pending" has no counter-side input (the module has no interrupt port), so it is covered by the plain count tests; it is a system-level property of `timer_top`.

_VI:_ Mọi chức năng chính của spec đều được phủ. "Vẫn đếm khi đang có ngắt chờ" không có input nào ở phía counter (module không có port ngắt), nên được phủ bởi các test đếm thông thường; đây là tính chất mức hệ thống của `timer_top`.
