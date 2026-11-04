# Ghi chú thay đổi thiết kế – cần cập nhật vào `Timer_Design_Specification_Advanced_VI_preview.pdf`

File này liệt kê những chỗ thiết kế đã sửa so với PDF spec gốc, để cập nhật lại PDF. Sau khi PDF đã được sửa xong thì xóa file này. Lý do: S1 đọc mọi file trong `doc/spec/source/` làm input.

## 1. Cách tính `limit` của bộ chia `div_cnt` (module `cnt_ctrl`) – 2026-10-27

**Thay đổi:** `limit = (1 << div_val) - 1` (tính ở 9 bit rồi lấy 8 bit thấp) → `limit = ~(8'hFF << div_val)` (mặt nạ 8 bit tạo trực tiếp).

**Lý do:**
- Với mọi giá trị `div_val` (0..15), hai cách cho cùng kết quả: 0, 1, 3, …, 255 khi `div_val` từ 0 đến 8, và 255 khi `div_val` từ 9 đến 15.
- Bit thứ 9 không được dùng ở đâu và chỉ lên 1 khi `div_val` > 8, là giá trị phần mềm không ghi được. Kết quả là một node không bao giờ toggle trong coverage (`limit_full[8]`).
- Tạo mặt nạ trực tiếp không cần phép trừ và không cần bit phụ.
- Chức năng, interface, latency và register map giữ nguyên.

**Chỗ cần sửa trong PDF:**

| Vị trí trong PDF | Hiện tại | Sửa thành |
| --- | --- | --- |
| Mục 3.3 (cnt_ctrl), Hình 19 "Sơ đồ logic bộ đếm chia div_cnt" – nhãn khối tính limit | `(1 << div_val) - 1` | `~(8'hFF << div_val)` |
| Mục 3.3, "Giải thích sơ đồ logic div_cnt", gạch đầu dòng "Giới hạn chia" | "limit = 2^div_val − 1, tức 0, 1, 3, …, 255 với div_val từ 0 đến 8 (tính ở 9 bit rồi lấy 8 bit thấp)." | "limit = 2^div_val − 1, tức 0, 1, 3, …, 255 với div_val từ 0 đến 8, tạo trực tiếp bằng mặt nạ 8 bit `~(8'hFF << div_val)` (div_val = 8: `8'hFF << 8` = 0, đảo thành 8'hFF = 255)." |

**Đã cập nhật trong project:**
- `doc/spec/architecture/cnt_ctrl_spec.md`: dòng `limit` trong bảng Structure (nhánh `main`, đã merge vào mọi nhánh).
- `doc/diagram/cnt_ctrl/cnt_ctrl.svg`: nhãn `op_limit` và model, bỏ `limit_full` (nhánh `cnt_ctrl`).
- `rtl/cnt_ctrl.v`: bỏ wire `limit_full[8:0]`, `assign limit = ~(8'hFF << div_val);` (nhánh `cnt_ctrl`).
- `tb/tb_cnt_ctrl.v`: hàm `div_limit` của golden model tính theo cùng công thức (nhánh `cnt_ctrl`).
- `doc/vplan/cnt_ctrl_vplan.md`: không đổi, vì kết quả mong đợi giữ nguyên.

## 2. Không ghi đè được TDR0/TDR1 khi đang đếm (module `register`, `counter`) – 2026-11-04

**Thay đổi:** ghi TDR0/TDR1 chỉ có tác dụng khi TIM_EN = 0. Khi TIM_EN = 1, lệnh ghi bị bỏ qua: TDR0/TDR1 vẫn đếm tiếp, giao dịch kết thúc bình thường và không báo lỗi (`tim_pslverr` = 0). Logic: `tdr0_we = wr_en & sel_tdr0 & ~tim_en`, `tdr1_we = wr_en & sel_tdr1 & ~tim_en` (trước đây không có `~tim_en`).

**Lý do:**
- Golden model của giảng viên không cho ghi đè TDR khi timer đang đếm (pattern `cnt_ctrl_chk` fail với RTL cũ, vốn cho phép ghi thắng bước đếm).
- `Final_Project_only.pdf` không nói về trường hợp này; error handling chỉ có 2 điều kiện của TCR, nên giả định là bỏ qua không báo lỗi (OPEN-002 trong `doc/spec/spec_status.md`, cần xác nhận bằng log của giảng viên).
- Khi đó ghi và đếm không bao giờ trùng chu kỳ; mux ưu tiên của counter giữ nguyên.

**Trạng thái:** đã sửa vào nguồn LaTeX `~/Documents/ICTC/Final_Project/Timer_Design_Specification/` (mục 8 của change note trong đó, phiên bản 2.2), chưa build lại PDF. Sau khi build trên Overleaf và chép PDF mới vào `doc/spec/source/`, xóa mục này.

**Chỗ cần sửa trong PDF:**

| Vị trí trong PDF | Hiện tại | Sửa thành |
| --- | --- | --- |
| Mục 1.2, gạch đầu dòng "Bộ đếm lên 64-bit" | "… và có thể ghi (theo byte) để nạp giá trị ban đầu." | "… và có thể ghi (theo byte) để nạp giá trị ban đầu khi timer đang dừng (TIM_EN = 0); khi TIM_EN = 1 lệnh ghi bị bỏ qua, không báo lỗi." |
| Mục 2.3 Bảng 4 (TDR0), Mục 2.4 Bảng 5 (TDR1) – cột Mô tả | "32-bit thấp (cao) của bộ đếm. [Advanced] Bị xóa khi TIM_EN H→L." | thêm: "Chỉ ghi được khi TIM_EN = 0; ghi khi TIM_EN = 1 bị bỏ qua (tim_pslverr = 0)." |
| Mục 3.2, Hình 11 "Sơ đồ logic tdr0_wr_en/tdr1_wr_en" | cổng AND `tdr0_we` = `wr_en`, `sel_tdr0` (tương tự `tdr1_we`) | thêm ngõ vào `tim_en` có bubble (đảo) cho cả hai cổng AND |
| Mục 3.2, giải thích Hình 11 | "Khi wr_en = 1 và sel_tdr0 = 1, mux đưa nguyên tim_pstrb[3:0] ra tdr0_wr_en[3:0] …" | "Khi wr_en = 1, sel_tdr0 = 1 và tim_en = 0, mux đưa nguyên tim_pstrb[3:0] ra tdr0_wr_en[3:0] …; khi tim_en = 1 ra 4'h0, nên không ghi đè được bộ đếm đang chạy." |
| Mục 3.2, Bảng 11 – hàng `tim_en, div_en, div_val[3:0]`, cột "Dùng ở" | "wr_err, counter control, mux đọc" | "wr_err, tdr_wr_en (Hình 11), counter control, mux đọc" |
| Mục 3.4, giải thích Hình 24, "Mux giữa" | "cnt_wr = 1 thì chọn cnt_wdata. Phần mềm ghi có ưu tiên cao hơn việc đếm." | "cnt_wr = 1 thì chọn cnt_wdata. cnt_wr chỉ bằng 1 khi TIM_EN = 0 (lúc đó cnt_en = 0), nên ghi và đếm không bao giờ trùng chu kỳ." |

**Đã cập nhật trong project (nhánh `main`):**
- `doc/spec/architecture/register_spec.md`: phần Function, bảng logic tổ hợp (`tdr0_we`/`tdr1_we`), mục Behavior.
- `doc/spec/architecture/counter_spec.md`: phần Function và Behavior (không đổi logic của counter).
- `doc/spec/register_file/register_map.md`: mô tả TDR0/TDR1.
- `doc/spec/architecture/timer_top_spec.md`: vai trò `u_register`, `u_counter`.
- `doc/spec/spec_status.md`: OPEN-002, thêm `Final_Project_only.pdf` vào Input.

**Chưa cập nhật (cần chạy lại):** S2 + S3 `register` (nhánh `register`: `register_ctrl.svg`, `register.svg`, `rtl/register.v` dòng `tdr0_we`/`tdr1_we`), S4/S5 `register`; S4/S5 `timer_top` (các nhánh vplan ghi TDR khi đang đếm, golden model của TB).
