---
name: rtl-s5-tb
description: Stage 5 của RTL flow (tùy chọn, nhẹ) – viết testbench self-checking Verilog-2005 (tb/tb_<m>.v) và mỗi item vplan một file test case (tc/TC_<M>_<NNN>.v) cho MỘT module (leaf hoặc cả cây con ở mức tích hợp) theo cấu trúc 9 phần cố định (golden model, checker, bộ đếm PASS/FAIL, log chuẩn), clock mặc định 20 ns, lái stimulus tại posedge + #1; đăng ký RTL/test vào sim/rtl.f, sim/pat.list rồi tự mô phỏng bằng môi trường QuestaSim trong sim/ (make TESTNAME=... all) và đối chiếu log với vplan. Theo rule testbench của người dùng trong tb_coding_rules/ nếu có. Dùng khi người dùng gọi /rtl-s5-tb <module> hoặc yêu cầu viết testbench theo vplan.
argument-hint: "<tên_module> [tên_module ...]"
disable-model-invocation: true
---

# Stage 5 – Testbench theo vplan

Module: `$ARGUMENTS`

Stage này **tùy chọn**, chỉ chạy khi người dùng cần mô phỏng.

Testbench tự kiểm: stimulus → DUT → golden reference model → checker → bộ đếm PASS/FAIL → log chuẩn → `[SUMMARY]` → `Test_result`. Không chỉ `$display` để xem waveform bằng mắt. Không UVM, class, interface, package, random, coverage, SVA/assertion, framework scoreboard.

## Môi trường mô phỏng `sim/` (của người dùng – chỉ dùng, không sửa)

QuestaSim (`vlog`/`vsim`), chạy từ thư mục `sim/`; bản mẫu ở `references/sim_env/`.

| File | Vai trò |
| --- | --- |
| `sim/Makefile` | `make TESTNAME=TC_<M>_<NNN> all`: chép `tc/<TESTNAME>.v` thành `sim/run_test.v`, `vlog -f compile.f`, `vsim -c tb_<m>` (module suy từ TESTNAME: `TC_APB_SLAVE_001` → `apb_slave`), log `sim/log/<TESTNAME>.log`. `all_wave` mở waveform. |
| `sim/compile.f` | `-timescale 1ns/1ps`, `+incdir+.` (để TB `include "run_test.v"`), `-f rtl.f`, `-f tb.f` |
| `sim/rtl.f` | danh sách RTL, đường dẫn từ `sim/` (`../rtl/<m>.v`), con trước cha sau – **S5 thêm dòng** |
| `sim/tb.f` | `../tb/${TB_NAME}.v` – testbench đặt ở `tb/tb_<m>.v` |
| `sim/pat.list` | danh sách test regression (một ID mỗi dòng, `//` là comment) – **S5 thêm dòng** |
| `sim/run.csh`, `sim/report.csh` | chạy cả `pat.list`, bảng kết quả (đọc `End time` và `Test_result` trong `log/<ID>.log`) – cần `csh` |

Không sửa `Makefile`, `compile.f`, `tb.f`, `run.csh`, `report.csh`, `schematic.tcl`. Môi trường sai/thiếu với một thiết kế hợp lệ → báo, đề xuất sửa (không tự sửa).

## Phạm vi

- Chỉ đúng module(s) được nêu tên; không nhận "all".
- Hiện thực **đúng và đủ** các test trong `doc/vplan/<m>_vplan.*`; test cần thêm → đề xuất trong báo cáo để cập nhật vplan.
- Không sửa RTL, spec, diagram, vplan. Đầu ra: `tb/tb_<m>.v`, `tc/TC_<M>_<NNN>.v` của module, và thêm dòng của module vào `sim/rtl.f`, `sim/pat.list`.

## Bước 0 – Gate

```bash
python3 .claude/skills/rtl-s5-tb/scripts/check_preconditions.py --stage 5 --module <m>
```

Cần spec PASS, bảng port, RTL của module **và mọi module con** (để mô phỏng được), vplan. Mã thoát ≠ 0 → bỏ qua module đó, báo `[THIẾU]`. Test trong vplan còn `TBD` ở stimulus/mong đợi → bỏ qua test đó, liệt kê trong báo cáo.

## Bước 1 – Rule

Đọc `tb_coding_rules/` (trừ README.md) nếu có; chỗ không nói tới hoặc thư mục trống → `references/default_tb_rules.md`.

## Bước 2 – Viết testbench và test case

Đọc vplan, RTL (port, parameter), spec (handshake, reset, chu kỳ clock, latency). Lấy danh sách item, tên file test case và header log mong đợi:

```bash
python3 .claude/skills/rtl-s5-tb/scripts/check_sim_log.py --items doc/vplan/<m>_vplan.<ext>
```

Chi tiết và khung mẫu: `references/default_tb_rules.md`. Luật bắt buộc:

- **Ngôn ngữ:** Verilog-2005 (IEEE 1364-2005). Không construct SystemVerilog nào (`logic`, `bit`, `string`, `always_ff`, `typedef`, `enum`, `struct`, `interface`, `package`, `class`, `foreach`, queue, `$fatal`, SVA…). Comment, tên task và log chỉ dùng tiếng Anh.
- **Hai loại file:**
  - `tb/tb_<m>.v`, module `tb_<m>`: hạ tầng chung cho mọi test của module (DUT, clock, reset, golden model, checker, task driver). Phần 8 có `` `include "run_test.v" ``; phần 9 gọi `run_test`.
  - `tc/TC_<M>_<NNN>.v`: **mỗi item vplan một file**, chỉ chứa `task run_test;` hiện thực đúng item đó (in header item, lái stimulus, gọi checker). `<M>` = tên module viết hoa; `<NNN>` = ID vplan 3 chữ số (ID số `n` → `00n`; vplan đã dùng `TC_<M>_<NNN>` thì dùng nguyên). Comment đầu file chép ID, tên và mục tiêu từ vplan.
- **Cấu trúc 9 phần của `tb_<m>.v`, đúng thứ tự**, mỗi phần có header comment, giữ đủ header kể cả khi TB nhỏ (phần không cần thì để trống): `1. Declaration` → `2. DUT Instance` → `3. Clock Generation` → `4. Init Reset` → `5. Golden Reference Model` → `6. Checker` → `7. Helper Functions` → `8. Tasks` → `9. Main Program Body`.
- **Clock:** `parameter CLK_PERIOD = 20;` (20 ns mặc định; spec quy định chu kỳ khác thì theo spec), `clk = 1'b0` trong `initial` + `always #(CLK_PERIOD / 2) clk = ~clk;`. Timescale do `compile.f` đặt (`-timescale 1ns/1ps`); TB vẫn ghi `` `timescale 1ns/1ps `` đầu file.
- **Stimulus:** mọi lần lái input DUT là `@(posedge clk); #1;` rồi gán. Không lái ở negedge, không lái đúng tại posedge. `#1` chỉ có trong TB, không bao giờ trong RTL.
- **Reset:** theo spec – reset async tích cực ngay, nhả tại `posedge + #1`; reset đồng bộ lái như stimulus. `reset_dut` (phần 4) khởi tạo mọi input DUT và golden model; phần 9 gọi trước `run_test`, test case gọi lại khi cần trạng thái reset giữa chừng.
- **Self-check:** golden model tính expected độc lập từ spec/vplan (không bao giờ lấy từ output DUT); checker so sánh, tăng `pass_count`/`fail_count` (`integer`), PASS + FAIL = số lần checker so sánh.
- **Log chuẩn** (`check_sim_log.py` và `report.csh` đọc; vsim tự thêm `# ` đầu dòng): đầu test case `-- <item name> test --` với `<item name>` là tên tiếng Anh ngắn của item lấy từ vplan (đúng như `--items` in ra); mỗi case `[<time>] <case> PASS | expected: <exp> | actual: <act>` hoặc `... FAIL | ...`; cuối mỗi lần chạy `[SUMMARY] PASS=<n> FAIL=<n>` rồi `Test_result: PASS` (FAIL = 0 và PASS > 0) hoặc `Test_result: FAIL`. Chi tiết ở mục 6 của `default_tb_rules.md`.
- Timeout toàn cục (in `[TIMEOUT]`, `[SUMMARY]`, `Test_result: FAIL`, `$finish`); driver tuân thủ giao thức handshake.
- DUT có module con (phạm vi tích hợp): instance module cha, stimulus qua port của nó, kiểm output/status cuối; `rtl.f` có RTL cả cây.

## Bước 3 – Đăng ký và chạy

1. `sim/rtl.f`: thêm RTL của module (và module con chưa có dòng), dạng `../rtl/<m>.v`, con trước cha sau; không thêm dòng đã có.
2. `sim/pat.list`: thêm ID test case của module (`TC_<M>_<NNN>`), theo thứ tự vplan; không thêm dòng đã có.
3. Chạy từng test của module, từ `sim/` (không cần `csh`):

   ```bash
   cd sim
   for t in $(sed '/\/\//d' pat.list | grep "^TC_<M>_"); do make TESTNAME=$t all; done
   ```

   `make` trả mã 0 kể cả khi test FAIL hay compile lỗi – luôn đọc log. Lỗi compile xem `sim/compile.log`. Có `csh` thì `./run.csh` (cả `pat.list`) + `./report.csh` cho bảng kết quả.
4. Đối chiếu với vplan:

   ```bash
   python3 .claude/skills/rtl-s5-tb/scripts/check_sim_log.py sim/log/TC_<M>_*.log doc/vplan/<m>_vplan.<ext>
   ```

   Script map header về ID vplan theo tên item, rồi kiểm: item vplan chưa chạy/không có case, case FAIL, dòng case sai định dạng, case trước mọi header, header không có trong vplan, mỗi log: `[SUMMARY]` thiếu/trùng/lệch, `Test_result` thiếu/lệch, log `TC_…` chứa item khác ID của nó, `[TIMEOUT]`/fatal/`** Error`. Vplan dùng ID khác `TC_…` mà không phải bảng có cột `ID` → thêm `--id-re '<regex>'`.

Test FAIL → phân loại:
- Lỗi testbench/test case (stimulus/chu kỳ kiểm sai so với vplan, golden model sai so với spec) → sửa TB/tc, chạy lại.
- Lỗi RTL hoặc vplan → **không sửa**; báo test ID, triệu chứng, nghi ngờ ở file/dòng nào, cần sửa ở S3 hay S4.

Không có QuestaSim (`vlog`/`vsim` không có trong PATH) → không phải lỗi thiết kế; ghi "chưa chạy mô phỏng" và lệnh chạy.

## Đầu ra

```
tb/tb_<m>.v                  # Verilog-2005, hạ tầng chung, include run_test.v
tc/TC_<M>_<NNN>.v            # mỗi item vplan một file: task run_test
sim/rtl.f, sim/pat.list      # thêm dòng của module
sim/log/TC_<M>_<NNN>.log     # nếu đã chạy – bị .gitignore, không phải tài liệu cần giữ
```

File output khác của lần chạy (`sim/work/`, `*.wlf`, `run_test.v`, `modelsim.ini`…) đều bị `.gitignore`. Còn testbench cũ theo cấu trúc trước (`tb/<m>/tb_<m>.v`, `tb/<m>/tb_<m>.sv`, `sim/<m>/`) → **không tự xóa**, không đưa vào `tb.f`/`rtl.f`; nêu trong báo cáo là file legacy để người dùng quyết định.

## Báo cáo cuối (chỉ trong chat)

File · ngôn ngữ TB (Verilog-2005) · file legacy còn lại (nếu có) · số item hiện thực / tổng vplan · kết quả theo ID (số case PASS/FAIL, `Test_result`) · test bỏ qua vì TBD · lỗi nghi ở RTL/vplan kèm đề xuất · lệnh chạy lại (`cd sim && make TESTNAME=<ID> all`, `all_wave` để xem sóng).
