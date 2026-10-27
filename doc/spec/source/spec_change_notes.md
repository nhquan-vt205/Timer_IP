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
