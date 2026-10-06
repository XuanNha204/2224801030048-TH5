# Ghi chú cá nhân — Bài 5

Ứng dụng Flutter quản lý ghi chú cá nhân, giao diện tiếng Việt, Material 3 và chế độ sáng/tối theo hệ thống.

## Chức năng

- Màn hình chính hiển thị tiêu đề, nội dung rút gọn và thời gian tạo của mỗi ghi chú.
- Thêm ghi chú bằng nút **Thêm ghi chú**, nhập tiêu đề/nội dung rồi **Lưu ghi chú** để quay về danh sách.
- Nhấn một ghi chú để chỉnh sửa. Giữ nguyên ID và thời gian tạo khi cập nhật.
- Vuốt ghi chú sang trái hoặc giữ lâu để xóa. Có hộp thoại xác nhận; chọn **Hủy** để giữ lại ghi chú.
- Menu ba chấm cung cấp thao tác sửa/xóa thay thế cho cử chỉ.
- Tìm kiếm theo tiêu đề hoặc nội dung, không phân biệt chữ hoa/chữ thường.
- Chặn tiêu đề/nội dung trống; tiêu đề tối đa 120 ký tự.
- Hỏi xác nhận trước khi rời màn hình có thay đổi chưa lưu.
- Hiển thị lỗi đọc/ghi và giữ lại nội dung khi lưu thất bại.

## Chạy ứng dụng

Project được tạo tại thư mục `Bai5`, tên package là `personal_notes`.
Môi trường đã dùng: Flutter 3.44.8, Dart 3.12.2.

```powershell
flutter pub get
flutter run -d chrome
```

Chạy trên Windows:

```powershell
flutter run -d windows
```

Chạy trên Android: bật giả lập hoặc kết nối điện thoại có USB debugging, sau đó:

```powershell
flutter devices
flutter run -d <device-id>
```

Nếu `flutter doctor` báo thiếu Android SDK Command-line Tools, cài **Android SDK Command-line Tools (latest)** trong Android Studio → SDK Manager → SDK Tools. Sau đó chạy `flutter doctor --android-licenses` và xác nhận các giấy phép để hoàn thiện môi trường Android.

Build bản web hoặc APK:

```powershell
flutter build web
flutter build apk --release
```

Build iOS cần macOS và Xcode.

### Lỗi Kotlin incremental cache trên Windows

Nếu project nằm trên ổ `D:` còn Pub cache nằm trên ổ `C:`, Kotlin có thể báo `Could not close incremental caches` kèm `this and base files have different roots`. Project đã đặt `kotlin.incremental=false` trong `android/gradle.properties` để tránh lỗi này. Theo [tài liệu Kotlin](https://kotlinlang.org/docs/gradle-compilation-and-caches.html), thiết lập này tắt biên dịch tăng dần Kotlin/JVM; bước biên dịch Kotlin có thể lâu hơn khi mã nguồn thay đổi.

Khi cần dọn cache cũ và build lại từ terminal PowerShell tại thư mục project:

```powershell
Push-Location android
.\gradlew.bat --stop
Pop-Location
flutter clean
flutter pub get
flutter build apk --debug
```

## Lưu dữ liệu

Dùng `SharedPreferencesAsync` trong package [`shared_preferences`](https://pub.dev/packages/shared_preferences), lưu danh sách ghi chú dưới dạng chuỗi JSON với khóa `personal_notes_v1`.
Các trường: `id`, `title`, `content`, `createdAt`, `updatedAt`. Danh sách sắp xếp theo lần cập nhật gần nhất.

Ứng dụng đợi thao tác lưu hoàn thành rồi mới cập nhật danh sách và quay về màn hình chính. Dữ liệu được đọc lại khi khởi động. Trên web, dữ liệu nằm trong local storage của trình duyệt và phụ thuộc vào origin; dùng cùng cổng khi chạy lại để xem dữ liệu cũ, ví dụ `flutter run -d chrome --web-port 8080`.

Dữ liệu lưu cục bộ, không có đồng bộ tài khoản. Gỡ ứng dụng hoặc xóa dữ liệu trình duyệt sẽ xóa ghi chú. SharedPreferences phù hợp với bài thực hành và danh sách nhỏ; nếu mở rộng để lưu dữ liệu quan trọng hoặc nhiều ghi chú, nên chuyển repository sang SQLite/Hive và bổ sung sao lưu.

## Cấu trúc mã nguồn

```text
lib/
  main.dart                         Khởi chạy ứng dụng
  app.dart                          Theme và ngôn ngữ tiếng Việt
  models/note.dart                  Mô hình ghi chú và chuyển đổi JSON
  data/note_repository.dart         Lưu/đọc bằng SharedPreferences
  screens/home_screen.dart          Danh sách, tìm kiếm, xác nhận xóa
  screens/note_editor_screen.dart   Form thêm/sửa, lưu và xác nhận thoát
  widgets/note_card.dart            Thẻ ghi chú và định dạng thời gian
test/
  note_repository_test.dart         Lưu/đọc và dữ liệu JSON lỗi
  widget_test.dart                  Luồng thao tác và bố cục thích ứng
```

## Kiểm tra

```powershell
flutter analyze
flutter test
```

Các kiểm thử dùng bộ nhớ giả lập để không thay đổi dữ liệu ghi chú thật, bao gồm thêm/sửa/đọc lại, hủy/xác nhận xóa, vuốt xóa, nhập trống, bỏ thay đổi, lỗi lưu/đọc, tìm kiếm và màn hình điện thoại/tablet với chữ lớn ở cả hai theme.
