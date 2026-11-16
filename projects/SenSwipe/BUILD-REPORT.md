# Báo cáo build · SenSwipe 0.1.0 beta 1

## Đã kiểm chứng trên máy build Linux

- Biên dịch thành công lõi tweak và bundle Cài đặt, bật `-Wall -Wextra -Werror`.
- Mach-O arm64: tweak là MH_DYLIB, preferences là MH_BUNDLE.
- SDK iPhoneOS15.6; deployment target iOS 15.0. Phạm vi kích hoạt thực tế bị giới hạn thêm bởi mã và phụ thuộc gói: iOS 15.8.8, iPhone9,2 / iPhone9,4.
- Đã pseudo-sign ad-hoc hai binary bằng ldid, kiểm tra lại mọi hash trang mã trong CodeDirectory.
- Phụ thuộc lõi Substrate qua `@rpath`, có đường dẫn framework rootless.
- Payload chỉ có 7 file thuộc `/var/jb/`; không có file MobileGestalt hoặc script cài đặt tự sửa hệ thống.
- Filter lõi chỉ chứa `com.apple.springboard`.
- Tất cả plist đọc được bằng parser, cấu hình principal class trùng tên lớp đã biên dịch.
- Kiểm tra âm: thay 1 byte trong section `__text` làm bộ xác minh từ chối vì code hash sai.
- Kiểm tra âm: thêm file ngoài danh sách cho phép làm bộ xác minh từ chối payload.
- Kiểm tra các symbol import của lõi: Foundation/CoreFoundation, Objective-C runtime, libc và `MSHookMessageEx`.

Chi tiết SHA-256, thư viện liên kết và chữ ký: `packages/Verification.json`.

## Chưa kiểm chứng

- Khả năng nạp, tồn tại và chữ ký runtime của private API trên đúng firmware máy Sếp.
- Cử chỉ về Home, đa nhiệm, Control Center và chuyển cảnh.
- Bàn phím, safe area, Home bar, xoay ngang, màn hình khóa và Touch ID.
- Trang Cài đặt trên iOS thật, cách respring của môi trường hiện tại.
- Xung đột với chỉnh sửa MobileGestalt cũ hoặc tweak đang cài.

Không có kiểm thử mô phỏng nào thay thế được các mục này. Gói được bàn giao với nhãn beta để thử trên thiết bị.

## Công cụ

- Theos commit: `8167f59de02fd32cf45b16bfcb1330dfa5c9974c`.
- theos/sdks commit: `0222fd5413cf4b9af096f37b4621afa2688572f7`, thư mục `iPhoneOS15.6.sdk`.
- Clang 11.1.0 từ toolchain L1ghtmann/llvm-project, release `test-210562a`.
- Script tạo bản giao: `scripts/build-linux.sh`.
- Công cụ đóng gói: `dpkg-deb --root-owner-group -Zxz -z9`.

Không kèm Apple SDK hoặc toolchain vào ZIP mã nguồn.
