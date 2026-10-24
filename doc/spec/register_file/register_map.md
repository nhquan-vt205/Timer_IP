# Timer IP – Register map / Bảng thanh ghi

Bus: APB, 12-bit address, 32-bit data, byte strobes `tim_pstrb[3:0]`. Registers are word aligned and decoded on `tim_paddr[11:2]` (`tim_paddr[1:0]` ignored). Addresses not listed are reserved: RAZ/WI (read 0, write ignored, no error). Access types: RW = read/write (per byte), RO = read-only (writes ignored), RW1C = write 1 to clear. Only writes to TCR can return an error response (see Error response below); reads never fail.

_VI:_ Bus APB, địa chỉ 12-bit, dữ liệu 32-bit, byte strobe `tim_pstrb[3:0]`. Thanh ghi căn theo word, giải mã theo `tim_paddr[11:2]` (bỏ qua `tim_paddr[1:0]`). Địa chỉ không liệt kê là reserved: RAZ/WI (đọc 0, ghi bị bỏ qua, không lỗi). Kiểu truy cập: RW = đọc/ghi (theo byte), RO = chỉ đọc (ghi bị bỏ qua), RW1C = ghi 1 để xóa. Chỉ ghi vào TCR mới có thể trả error response (xem mục Error response); đọc không bao giờ lỗi.

## Summary

| Offset | Word address `tim_paddr[11:2]` | Name | Reset | Description |
| --- | --- | --- | --- | --- |
| 0x00 | 10'h000 | TCR | 0x0000_0100 | Timer Control Register |
| 0x04 | 10'h001 | TDR0 | 0x0000_0000 | Timer Data Register 0 (cnt[31:0]) |
| 0x08 | 10'h002 | TDR1 | 0x0000_0000 | Timer Data Register 1 (cnt[63:32]) |
| 0x0C | 10'h003 | TCMP0 | 0xFFFF_FFFF | Timer Compare Register 0 |
| 0x10 | 10'h004 | TCMP1 | 0xFFFF_FFFF | Timer Compare Register 1 |
| 0x14 | 10'h005 | TIER | 0x0000_0000 | Timer Interrupt Enable Register |
| 0x18 | 10'h006 | TISR | 0x0000_0000 | Timer Interrupt Status Register |
| 0x1C | 10'h007 | THCSR | 0x0000_0000 | Timer Halt Control Status Register |
| others | – | Reserved | 0x0000_0000 | RAZ/WI |

## Fields

| Offset | Name | Bit | Field | Access | Reset | Description |
| --- | --- | --- | --- | --- | --- | --- |
| 0x00 | TCR | 31:12 | Reserved | RO | 0 | Reads 0 |
| 0x00 | TCR | 11:8 | DIV_VAL | RW | 4'h1 | Count speed divider 2^DIV_VAL; 0..8 = divide by 1, 2, 4, …, 256; values > 8 forbidden (error response). Change while TIM_EN = 1 → error response |
| 0x00 | TCR | 7:2 | Reserved | RO | 0 | Reads 0 |
| 0x00 | TCR | 1 | DIV_EN | RW | 0 | 0: count every `sys_clk` cycle; 1: count every 2^DIV_VAL cycles. Change while TIM_EN = 1 → error response |
| 0x00 | TCR | 0 | TIM_EN | RW | 0 | 0: counter stopped; 1: counter counts. H→L: hardware clears TDR0/TDR1 |
| 0x04 | TDR0 | 31:0 | TDR0 | RW | 32'h0 | Counter bits [31:0]; cleared when TIM_EN H→L |
| 0x08 | TDR1 | 31:0 | TDR1 | RW | 32'h0 | Counter bits [63:32]; cleared when TIM_EN H→L |
| 0x0C | TCMP0 | 31:0 | TCMP0 | RW | 32'hFFFF_FFFF | Compare value bits [31:0] |
| 0x10 | TCMP1 | 31:0 | TCMP1 | RW | 32'hFFFF_FFFF | Compare value bits [63:32] |
| 0x14 | TIER | 31:1 | Reserved | RO | 0 | Reads 0 |
| 0x14 | TIER | 0 | INT_EN | RW | 0 | 0: `tim_int` masked (= 0); 1: INT_ST drives `tim_int`. Clearing INT_EN does not change INT_ST |
| 0x18 | TISR | 31:1 | Reserved | RO | 0 | Reads 0 |
| 0x18 | TISR | 0 | INT_ST | RW1C | 0 | Interrupt pending; set when `cnt` == {TCMP1, TCMP0}; write 1 (byte 0 strobed) clears, write 0 no effect; clear has highest priority |
| 0x1C | THCSR | 31:2 | Reserved | RO | 0 | Reads 0 |
| 0x1C | THCSR | 1 | HALT_ACK | RO | 0 | 1: timer halted; HALT_ACK = `dbg_mode` & HALT_REQ |
| 0x1C | THCSR | 0 | HALT_REQ | RW | 0 | 1: halt request (effective only when `dbg_mode` = 1); clear to resume |

## Error response / Phản hồi lỗi

A write to TCR is rejected (`tim_pslverr` = 1, no register bit changes, whole transaction discarded) when any condition holds. An error is raised only when a strobed field actually changes; rewriting the current value (e.g. only to clear TIM_EN) is legal.

_VI:_ Giao dịch ghi TCR bị từ chối (`tim_pslverr` = 1, không bit nào thay đổi, hủy cả giao dịch) khi một trong các điều kiện sau đúng. Chỉ báo lỗi khi field được strobe thực sự thay đổi; ghi lại đúng giá trị cũ (vd. chỉ để xóa TIM_EN) là hợp lệ.

| # | Condition | Expression |
| --- | --- | --- |
| 1 | Forbidden DIV_VAL (> 8) | `tim_pstrb[1] & (tim_pwdata[11:8] > 4'd8)` |
| 2 | DIV_VAL changed while TIM_EN = 1 | `tim_en & tim_pstrb[1] & (tim_pwdata[11:8] != div_val)` |
| 3 | DIV_EN changed while TIM_EN = 1 | `tim_en & tim_pstrb[0] & (tim_pwdata[1] != div_en)` |

`tim_en`, `div_en`, `div_val` are the current (stored) TCR values.

_VI:_ `tim_en`, `div_en`, `div_val` là giá trị TCR hiện đang lưu.
