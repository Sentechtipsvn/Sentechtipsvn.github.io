# QuickControl 0.1.0 beta 1 — Báo cáo kiểm tra

## Đã hoàn thành

- App cấu hình UIKit, dylib SpringBoard và module Control Center arm64; build bằng iPhoneOS15.6 SDK / Clang 11.1.0 (L1ghtmann test-210562a), Theos headers, ldid và dpkg-deb.
- Build với `-Wall -Wextra -Werror`; không liên kết thư viện từ đường dẫn host.
- Chuẩn hóa cấu hình tối đa 12 nút; chặn chuỗi Bundle ID sai định dạng, scheme JavaScript/data/file, URL chứa ký tự điều khiển; tên phím tắt dùng NSURLComponents.
- Test C dùng đúng policy header trong production: toàn bộ 16 tổ hợp chạm/khóa, vị trí NaN/vô cực/ngoài biên, trạng thái cũ/tương lai, kiểm tra URL/Bundle ID, ABI BOOL/void và 10.000 chuỗi bất thường. Qua GCC AddressSanitizer/UBSan; tắt LeakSanitizer do host ptrace.
- Giải nén gói để kiểm tra đủ 11 file payload rootless, plist injection riêng SpringBoard, ID app/module, URL scheme, dependency CCSupport, firmware restriction, quyền thực thi và maintainer scripts.
- Kiểm tra Mach-O arm64 app executable/dylib/bundle; deployment target iOS15.0; chữ ký ad-hoc code-page của cả ba binary.
- Icon nguyên bản được vẽ từ hình học, có bản SVG và PNG @2x/@3x.

## Chưa kiểm chứng trên thiết bị

Không có iPhone/giả lập SpringBoard trong môi trường build. Chưa kiểm chứng:

- Cửa sổ nổi có hiển thị xuyên ứng dụng và nhận cử chỉ đúng trên iOS15.8.8.
- Lockstate/ẩn khay khi khóa, mở khóa, SpringBoard chuyển scene, xoay máy, Control Center và app toàn màn hình.
- Quyền LaunchServices, hành vi mở app/URL/Shortcuts trên máy thật.
- Khả năng Core Image tạo và iPhone11 quét QR chữ Việt đúng nội dung.
- Nút ShareWifi gửi tới controller đang nạp và hoạt động đúng cùng SenSwipe trên máy Sếp.

Không tuyên bố đã cài/chạy thành công hoặc đã xác nhận hiệu năng/pin trên iPhone. Bản beta cần thử theo README trước khi xem là bản ổn định.

## Giới hạn có chủ đích

Chỉ hỗ trợ iPhone9,2 / iPhone9,4, iOS15.8.8 trong guard runtime. Không hook cử chỉ hệ thống, không chụp dữ liệu app khác, không mở khóa, không sửa ShareWifi/SenSwipe. QR là nội dung tổng quát; VietQR dùng phím tắt do Sếp thêm. LSApplicationWorkspace được gọi qua ABI runtime (void hoặc BOOL); chỉ ghi nhận yêu cầu, không xác nhận app đã hiện thành công.

SHA-256 và chi tiết binary: `packages/Verification.json`.
