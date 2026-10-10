# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3 — On-Device Receipt OCR & Expense Tracker  
**Student / Team Name:** Đoàn Nhật Ánh  
**Submission Date:** 10/10/2026  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Student Information:**
  * **Họ và tên:** Đoàn Nhật Ánh
  * **Mã sinh viên:** 22ITxxx
  * **Lớp:** 22IT
  * **Vai trò:** Toàn bộ kiến trúc hệ thống, On-Device OCR, Quản lý trạng thái Riverpod 2, SQLite DB, CustomPainter Charts & UI/UX (100%)
* **💻 GitHub Repository:** [https://github.com/nhatanh19/Receipt-Expense-Tracker.git](https://github.com/nhatanh19/Receipt-Expense-Tracker.git)
* **📦 Release APK Download:** Sẵn sàng tại `build/app/outputs/flutter-apk/app-release.apk` (83.5 MB — Đã kiểm thử hoạt động ổn định trên thiết bị Android thật)
* **🎥 Video Demo (Optional):** [https://youtu.be/xxx] *(Đính kèm sau khi quay video trải nghiệm trên máy thật)*

---

## 2. FEATURE IMPLEMENTATION CHECKLIST

| # | Hạng Mục / Tiêu Chí Đánh Giá (Rubric Slide 42) | Trọng Số | Trạng Thái | Chi Tiết Kỹ Thuật & Mức Độ Đáp Ứng |
|:---:|---|:---:|:---:|---|
| **1** | **On-Device OCR & Heuristics Engine** | **3.5 pts** |  Hoàn thành xuất sắc | • Tích hợp Google ML Kit Text Recognition (`google_mlkit_text_recognition`) chạy Offline 100% trên thiết bị, bảo mật tuyệt đối.<br>• Bộ Heuristic Regex Engine đa tầng xử lý chuẩn xác: Tổng tiền (Total amount), Ngày tháng (Date), và Tên cửa hàng (Merchant).<br>• Giải quyết triệt để lỗi in nhiệt: khử giãn chữ (`T I E N   M A T`), chuẩn hóa phẩy cách (`537, 000`), negative filtering loại bỏ mã giao dịch/số bàn/giờ in, giải mã chuỗi dính ngày (`2308/2022`) và mã hóa đơn POS (`HDddMMyy`). |
| **2** | **Custom Canvas Visualization** | **2.5 pts** |  Hoàn thành 100% | • **Animated Donut Chart** (`donut_chart_painter.dart`): Tự vẽ bằng `CustomPainter` với `canvas.drawArc` và `canvas.drawCircle`, hiệu ứng xoay góc mượt mà theo tỷ lệ chi tiêu.<br>• **Weekly Bar Chart** (`bar_chart_painter.dart`): Tự vẽ bằng `CustomPainter` với `canvas.drawRRect`, có trục tọa độ, rãnh capsule nền, đường gióng lưới và nhãn thứ/ngày.<br>• **Không dùng bất kỳ thư viện biểu đồ bên thứ 3 nào** (đáp ứng 100% yêu cầu cốt lõi của đề tài). |
| **3** | **State Management & Local Persistence** | **2.0 pts** |  Hoàn thành 100% | • Quản lý trạng thái theo kiến trúc **Flutter Riverpod 2** (`StateNotifierProvider`, `AsyncValue`, `ProviderScope`).<br>• Cơ sở dữ liệu SQLite cục bộ bền vững (`sqflite`), đầy đủ CRUD (Create, Read, Update, Delete) với Virtualized list `ListView.builder` + `ValueKey`.<br>• Quản lý lưu trữ tệp ảnh hóa đơn gốc trong thư mục ứng dụng (`path_provider`) và tự động dọn dẹp file khi xóa chi tiêu. |
| **4** | **UI/UX Polish & Bài tập Lab Slide 45** | **1.0 pt** |  Hoàn thành 100% | • Thiết kế chuẩn **Material Design 3** với Seed Color VKU Navy (`0xFF2C4570`).<br>• Chuyển đổi giao diện Sáng / Tối (Dark / Light Theme) tức thì.<br>• Hộp thoại duyệt & chỉnh sửa `ReceiptReviewDialog` tích hợp **xem toàn màn hình và phóng to/thu nhỏ tương tác 0.8x–5.0x** (`InteractiveViewer`).<br>• Triển khai thẻ `ExpenseSummaryCard` đáp ứng 100% 4 tiêu chí bài tập Lab tại Slide 45 (Icon tròn, căn lề trái, format `###.### đ`, thẻ M3 có hiệu ứng `InkWell`). |
| **5** | **Deliverables, Test Suite & Build** | **1.0 pt** |  Hoàn thành 100% | • Bản Signed Release APK (`app-release.apk`, 83.5 MB) chạy mượt mà trên Android 5.0 trở lên.<br>• Vượt qua toàn bộ **10/10 automated tests** (`flutter test`) kiểm thử cả hóa đơn chuẩn và hóa đơn thực tế của sinh viên.<br>• Phân tích mã nguồn tĩnh: `flutter analyze` đạt **0 lỗi / 0 cảnh báo**. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

### 3.1. Sơ đồ Kiến trúc Hệ thống (Data Flow Architecture)
Ứng dụng áp dụng cấu trúc **Feature-First Architecture** kết hợp với mô hình **3 Trees (Widget Tree $\rightarrow$ Element Tree $\rightarrow$ RenderObject Tree)** của Flutter:

```
[ Camera / Thư viện ảnh ]
           │
           ▼
[ MLKitOcrService (Offline Google ML Kit) ]
           │ Raw OCR Text
           ▼
[ HeuristicParser (Smart Vietnamese POS Regex) ]
           │ ParsedReceipt (Merchant, Amount, Date, Category, Confidence)
           ▼
[ ReceiptReviewDialog (Manual Edit & InteractiveViewer 5.0x Zoom) ]
           │ Confirmed ExpenseItem
           ▼
[ Riverpod 2 ExpenseNotifier ] ──► [ Local SQLite (sqflite) & File Storage ]
           │ Reactive State
           ▼
[ Presentation Layer: Material 3 UI ]
  ├── ExpenseListScreen (ListView.builder + ValueKey + Dismissible)
  ├── ExpenseSummaryCard (Slide 45 Lab Widget)
  └── AnalyticsScreen (Animated Donut Chart & Weekly Bar Chart CustomPainter)
```

### 3.2. Cấu trúc Thư mục Dự án (Project Structure)
```text
lib/
├── core/
│   ├── constants/        # app_colors.dart (VKU Navy), app_categories.dart (6 danh mục)
│   ├── database/         # app_database.dart (SQLite CRUD, migrations, table schema)
│   ├── theme/            # app_theme.dart (M3 light/dark), theme_provider.dart
│   └── utils/            # currency_formatter.dart, date_formatter.dart, receipt_storage.dart
├── features/
│   ├── analytics/
│   │   ├── painters/     # donut_chart_painter.dart, bar_chart_painter.dart (100% CustomPainter)
│   │   ├── presentation/ # analytics_screen.dart & widgets (animated_donut_chart, weekly_bar_chart)
│   │   └── providers/    # analytics_provider.dart (tính toán phân bổ, 7 ngày gần nhất & tuần này)
│   ├── expenses/
│   │   ├── domain/       # expense_model.dart (Entity + SQLite Map Serialization)
│   │   ├── presentation/ # expense_list_screen.dart, expense_detail_screen.dart, widgets
│   │   └── providers/    # expense_provider.dart (Riverpod StateNotifier CRUD)
│   └── ocr/
│       ├── domain/       # parsed_receipt.dart (Model dữ liệu trích xuất)
│       ├── presentation/ # receipt_review_dialog.dart (xem & zoom ảnh, sửa số liệu), camera_scanner_sheet
│       └── services/     # heuristic_parser.dart (bộ não bóc tách), mlkit_ocr_service.dart
└── main.dart             # ProviderScope, MaterialApp M3 Entrypoint
```

---

## 4. EMPIRICAL EVIDENCE & TEST BENCH RESULTS

### 4.1. Kết Quả Kiểm Thử Thực Tế Trên 4 Hóa Đơn Của Sinh Viên / Người Dùng
Tất cả các mẫu hóa đơn thực tế đã được kiểm thử trực tiếp bằng chính bộ mã nguồn ứng dụng (`HeuristicParser.parseReceipt` trong file test tự động [`real_bills_test.dart`](file:///e:/Data_IT_MSI/Project_Nam4/LapTrinhDaNenTang/Project%203_Receipt_expense_tracker/test/real_bills_test.dart)):

| STT | Ảnh Hóa Đơn Kiểm Thử | Tên Cửa Hàng Bóc Tách | Tổng Tiền Nhận Diện | Ngày Ghi Nhận | Danh Mục Gợi Ý | Độ Tin Cậy |
|:---:|---|---|:---:|:---:|:---:|:---:|
| **1** | **Khẩu trang Y tế Hội An** | `37 Nguyễn Phúc Chu, TP Hội An` | **150.000 đ** | **27/01/2020** | Khác | **94%** |
| **2** | **Siêu thị EVMART** | `SIÊU THỊ EVMART` | **708.000 đ** | **23/08/2022** | Mua sắm | **94%** |
| **3** | **Bida Phượng Hoàng** | `Bida Phượng Hoàng` | **136.000 đ** | **13/04/2015** | Giải trí | **94%** |
| **4** | **Thiết bị tính tiền Tín Thông** | `Thiết bị tinh tiền Tin Thong` | **640.000 đ** | **12/08/2019** | Ăn uống | **94%** |

### 4.2. Bằng Chứng Kiểm Thử Tự Động (10/10 Tests Passed)
```bash
$ flutter test
00:00 +0: HeuristicParser Tests Correctly extracts Highlands Coffee receipt (65.000 đ)
00:00 +1: HeuristicParser Tests Correctly extracts Co.op Mart supermarket receipt (245.000 đ)
00:00 +2: HeuristicParser Tests Correctly extracts Petrolimex Gas receipt (50.000 đ)
00:00 +3: HeuristicParser Tests Correctly extracts Quan An Thien Tan receipt (537.000 đ)
00:00 +4: HeuristicParser Tests Handles fallback for empty or degraded text gracefully
00:00 +5: Real Bills Test Bill 1 - Hoi An Mask Receipt -> 150,000 đ (27/01/2020)
00:00 +6: Real Bills Test Bill 2 - Sieu Thi EVMART -> 708,000 đ (23/08/2022)
00:00 +7: Real Bills Test Bill 3 - Bida Phuong Hoang -> 136,000 đ (13/04/2015)
00:00 +8: Real Bills Test Bill 4 - Thiet Bi Tinh Tien Tin Thong -> 640,000 đ (12/08/2019)
00:00 +9: App renders MainNavigationScreen smoke test
00:01 +10: All tests passed!

$ flutter analyze
Analyzing Project 3_Receipt_expense_tracker...                  
No issues found! (ran in 2.6s)
```

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### Thách thức 1: Lỗi bóc tách hóa đơn in nhiệt đặc thù Việt Nam (Thermal POS Receipts)
* **Vấn đề gặp phải:** Hóa đơn quán ăn in nhiệt thường bị giãn chữ (`T  I  E  N   M  A  T`), dấu phẩy có khoảng trắng (`537, 000`), và chứa nhiều mã số kỹ thuật in đậm (`CA 1 MC #01 000887`). Bộ regex đơn giản ban đầu bị gãy và bắt nhầm `000887` thành số tiền $887$ VNĐ.
* **Giải pháp khắc phục:** 
  1. Triển khai kỹ thuật **Letter-Spacing Collapsing**: So khớp từ khóa cả ở dạng loại bỏ toàn bộ khoảng trắng (`TIENMAT`).
  2. **Chuẩn hóa khoảng trắng tiền tệ**: Tự động ghép nối `537, 000` $\rightarrow$ `537,000` trước khi parse.
  3. **Bộ lọc Negative Filtering**: Loại trừ các số bắt đầu bằng số `0` (`000887`), số điện thoại, giờ in (`17:50`), và áp dụng sàn mệnh giá VNĐ $\ge 1.000$ đ.

### Thách thức 2: Lỗi góc quét $360^\circ$ ($2\pi$) trên Canvas Skia/Impeller khiến Biểu đồ Donut bị trống
* **Vấn đề gặp phải:** Khi người dùng chỉ có 1 hóa đơn hoặc tất cả hóa đơn cùng 1 danh mục, tỷ lệ phần trăm đạt $100\%$ $\rightarrow$ góc quét `sweepAngle` bằng đúng $2\pi$ radian. Trong engine đồ họa GPU của Flutter, lệnh `canvas.drawArc` với góc quét $\ge 2\pi$ bị lỗi quay về $0$ radian, khiến biểu đồ Donut hoàn toàn biến mất (vẽ ra vòng tròn trong suốt).
* **Giải pháp khắc phục:** Phát hiện trường hợp chỉ có 1 danh mục hoặc `sweepFraction >= 0.999` để chuyển sang dùng `canvas.drawCircle` (vẽ hình tròn hoàn hảo). Đồng thời cài đặt cơ chế so sánh sâu (`deep comparison`) trong `shouldRepaint` và `didUpdateWidget` để đảm bảo biểu đồ luôn cập nhật tức thì khi Riverpod phát sinh dữ liệu mới.

### Thách thức 3: Lệch ngày hóa đơn dẫn đến Biểu đồ cột không vẽ cột nào
* **Vấn đề gặp phải:** Ban đầu biểu đồ cột chỉ lấy 7 ngày trong tuần lịch hiện tại (`DateTime.now()`). Khi người dùng quét các hóa đơn thực tế có ngày in từ trước (ví dụ 2020, 2022), tất cả 7 cột đều bằng $0$ VNĐ và không hiển thị cột nào.
* **Giải pháp khắc phục:** Bổ sung chế độ thông minh **"7 ngày gần nhất" (`BarChartMode.recentDays`)** tự động gom nhóm các ngày thực tế có hóa đơn để mọi hóa đơn đã quét đều mọc cột hiển thị rõ ràng. Cung cấp nút chuyển đổi (`SegmentedButton`) trực tiếp trên giao diện để người dùng linh hoạt xem theo tuần hoặc theo các ngày có giao dịch gần nhất.
