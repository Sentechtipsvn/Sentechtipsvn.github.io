# ShareWifi 0.2.0 beta 1 — Kết quả kiểm tra

## Trạng thái thiết bị

Sếp đã xác nhận 0.1.1 hoạt động trên iPhone 7 Plus iOS 15.8.8, có một máy iPhone 11 kết nối. 0.2.0 chưa cài/chạy trên iPhone thật trong quá trình build này. Không có thiết bị iOS hay giả lập SpringBoard trong môi trường build.

## Thay đổi

- Giữ nguyên resolver `isDiscoverable`, ABI BOOL/void của `_toggleState`, readback và các API radio đã chạy được ở 0.1.1.
- Thêm ba chế độ dừng. Chế độ chỉ hotspot có danh sách thao tác đúng một công tắc, không gọi setter của ba radio khác.
- Bản ghi trước phiên độc lập với bản ghi trước thao tác, không ghi đè khi bật lặp trong phiên, giữ lại sau lỗi một phần, kết thúc sau dừng thành công. Hoàn tác khôi phục cả trạng thái công tắc và bản ghi phiên tương ứng.
- Không có bản ghi hợp lệ thì từ chối Khôi phục phiên; không tự chuyển thành Tắt cả bộ.
- Module Control Center chuẩn CCUIToggleModule/CCSupport. Darwin notification riêng tránh ghi đè lệnh file của app. Controller quyết định chiều bật/tắt từ trạng thái thực, bỏ lệnh chồng khi bận. Module không báo thành công lạc quan.
- Giữ ID gói/app và đường dẫn tùy chọn; thêm phụ thuộc CCSupport rootless. Không ép respring trong maintainer script.

## Đã kiểm chứng

- App, controller và module biên dịch arm64 với `-Wall -Wextra -Werror`.
- Test profile: 16 tổ hợp trạng thái, 256 tổ hợp khôi phục; kiểm tra thứ tự, mask chỉ hotspot, từ chối thiếu bản ghi/trạng thái lỗi, quy tắc ghi phiên.
- Test ABI: BOOL getter/action, void action, từ chối chữ ký không phù hợp.
- Test parser ARP: framing, padding, nhiều bản ghi, truncation, MAC, sockaddr lỗi và ABI không khớp.
- Cả ba bộ chạy GCC AddressSanitizer và UBSan. LeakSanitizer tắt do host ptrace.
- Giải nén .deb, kiểm tra chính xác 11 file payload, plist/filter/ID/quick actions, dependency CCSupport, giới hạn firmware.
- Kiểm tra Mach-O arm64: controller dylib, app executable, module bundle; iOS deployment target; chữ ký ad-hoc code-page của cả ba; không liên kết đường dẫn máy build.
- Gói rootless `/var/jb`, executable/maintainer scripts đúng quyền, dpkg archive owner root.

SHA-256 và kết quả binary nằm ở `packages/Verification.json`.

## Chưa kiểm chứng

- Nạp module và bố cục Control Center thực tế trên iOS 15.8.8.
- Quyền API, phản hồi radio/hotspot và hành vi tai nghe của bản mới trên iPhone.
- Luồng khôi phục phiên/hoàn tác ở iOS khi radio bị thay đổi đồng thời từ ngoài ShareWifi.
- Tình huống không có SIM/sóng, chế độ máy bay, khóa màn hình và máy khách ngủ/rời hotspot.

Chuỗi build: iPhoneOS15.6 SDK, Clang 11.1.0 (L1ghtmann test-210562a), Theos headers/libs rootless, ldid, dpkg-deb. CCSupport package ID/kiến trúc rootless được đối chiếu trong Packages của nguồn opa334. Không đóng gói CCSupport vào ShareWifi.
