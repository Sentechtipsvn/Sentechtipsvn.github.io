# QuickControl · 0.1.0 beta 1

Khay tiện ích nổi cho **iPhone 7 Plus (iPhone9,2 / iPhone9,4), iOS 15.8.8, Dopamine rootless**. © Sentechtipsvn.

**Bản đầu đã biên dịch và kiểm tra gói trên máy build, chưa chạy trên iPhone thật.** Cần Sếp kiểm chứng hiển thị qua ứng dụng, thao tác tay nắm, khóa máy và mở tiện ích trên thiết bị.

## Có gì trong bản này?

- Khay UIKit kính mờ theo Light/Dark Mode, tông xanh lá, hai cột và cuộn khi nhiều nút.
- Tay nắm nhỏ bên phải mặc định. Chạm hoặc kéo vào trong để mở; kéo dọc để đổi vị trí; có thể chuyển sang cạnh trái.
- Khi khay đóng, cửa sổ chỉ nhận chạm trong vùng tay nắm 22 × 72 điểm. Không gắn bộ nhận cử chỉ vào toàn bộ ứng dụng, không hook cử chỉ Home của SenSwipe.
- Chạm vùng bên ngoài hoặc nút đóng để đóng khay. Không lấy quyền key window/không gọi bàn phím trong lớp nổi.
- Kiểm tra trạng thái khóa trước khi nhận chạm hoặc gửi tác vụ; không đọc được API khóa thì ẩn. Có thông báo lockstate và kiểm tra dự phòng mỗi 3 giây. Không có thao tác mở khóa hay vượt mật mã.
- Có app QuickControl ngoài Home để tùy chỉnh và nút Control Center để mở/đóng khay.
- Tối đa 12 nút; sửa tên, xóa, sắp xếp và thêm ứng dụng, URL hoặc phím tắt theo tên.

## Sáu tiện ích mặc định

| Nút | Hành vi |
| --- | --- |
| ShareWifi | Gửi yêu cầu bật/tắt đến controller ShareWifi 0.2.x hiện có. Khi tắt, dùng đúng chế độ Sếp chọn trong ShareWifi. Nếu không nhận trạng thái hợp lệ thì thử mở app ShareWifi. |
| Máy tính | Mở ứng dụng Máy tính của Apple. |
| Ghi chú | Mở ứng dụng Ghi chú của Apple. |
| QR nhanh | Mở công cụ tạo QR trong app QuickControl. |
| Máy ảnh | Mở ứng dụng Máy ảnh của Apple. |
| Cài đặt | Mở Cài đặt iOS. |

Máy tính/Ghi chú/Máy ảnh được mở thành ứng dụng đầy đủ, không nhúng vào khay. Nếu app đã gỡ hoặc API không nhận thì báo chưa mở được. Thành công của lệnh mở không có nghĩa tác vụ bên trong ứng dụng đã hoàn tất.

ShareWifi không là phụ thuộc bắt buộc của gói. Không có ShareWifi thì nút đó không điều khiển được mạng; có thể xóa khỏi khay. QuickControl không tự đổi radio, không sửa chế độ tắt và không ghi đè lệnh file của ShareWifi. Trạng thái ShareWifi cũ quá 90 giây, thời gian trong tương lai, phiên bản khác 0.2.x hoặc dữ liệu thiếu sẽ không được dùng để quyết định điều khiển.

## Cài đặt

1. Máy cần đang jailbreak, bật nạp tweak. Gói dành riêng iOS 15.8.8 và đường dẫn rootless `/var/jb`, cùng kiểu gói ShareWifi đang dùng được trên máy Sếp.
2. Cài `QuickControl-0.1.0-beta1-iphoneos-arm64.deb` qua Sileo/Filza. Phụ thuộc: mobilesubstrate, uikittools, **CCSupport >= 1.3.10**. Sếp đã có CCSupport nếu đang dùng nút ShareWifi; nếu thiếu, lấy bản rootless từ [nguồn opa334](https://opa334.github.io/).
3. **Respring**, chờ khoảng 5 giây để tạo khay trong SpringBoard.
4. Tìm tay nắm xanh ở giữa cạnh phải. Chạm hoặc kéo vào trong để mở.
5. Mở app **QuickControl** để đổi cạnh, bật/tắt, đặt lại vị trí hoặc sửa danh sách.
6. Tùy chọn: **Cài đặt → Trung tâm điều khiển → thêm QuickControl**. Biểu tượng là lưới bốn ô, khác nút mắt xích ShareWifi.

Không cần ký AltStore/chứng chỉ. Không cần sửa MobileGestalt, SenSwipe hay cài lại ShareWifi. App cấu hình và công cụ QR không thay thế phần khay chạy trong SpringBoard; phải respring sau khi cài/nâng cấp gói.

## Thêm tiện ích của Sếp

Vào **QuickControl → Thêm tiện ích**:

- **Ứng dụng:** đặt tên và nhập Bundle ID, ví dụ `com.apple.mobilenotes`. Nếu không biết Bundle ID, có thể dùng URL ứng dụng hỗ trợ.
- **URL:** nhập đầy đủ scheme hoặc HTTPS, ví dụ `https://example.com` hoặc `quickcontrol://qr`. URL có thể mở trình duyệt, app khác hoặc yêu cầu xác nhận tùy app nhận. Không hỗ trợ các scheme thực thi JavaScript, nội dung data hoặc file cục bộ.
- **Phím tắt:** nhập đúng tên phím tắt đã cài trên chiếc iPhone 7 Plus. QuickControl mã hóa tên thành tham số URL, không ghép thẳng tên vào URL.

Ví dụ thêm nút **VietQR**: chọn Phím tắt → tên hiển thị VietQR → tên chính xác của phím tắt VietQR Sếp đang có → Lưu. QuickControl chỉ mở/chạy phím tắt; không tự cài hay ký phím tắt, không xác nhận kết quả chuyển khoản.

Bấm **Sửa** để kéo đổi thứ tự hoặc xóa. Có thể xóa hết nút và thêm lại. **Khôi phục 6 tiện ích mặc định** có bước xác nhận và thay danh sách hiện tại; không xóa ứng dụng hoặc phím tắt trên máy.

Tùy chọn được lưu cục bộ. Thay đổi trong app gửi thông báo để cập nhật khay, không cần respring. Công tắc **Bật QuickControl** tắt cả tay nắm lẫn việc mở khay từ nút Control Center; mở app để bật lại.

## QR nhanh

- Tạo QR văn bản/đường dẫn ngay trên máy bằng Core Image; không gọi dịch vụ tạo ảnh bên ngoài.
- Tối đa 1.200 byte UTF-8, có kiểm tra nội dung rỗng và lỗi tạo ảnh.
- Ảnh đen trên nền trắng, có vùng trắng quanh mã và dựng theo hệ số nguyên để giữ cạnh rõ. Nút Chia sẻ xuất ảnh qua bảng chia sẻ iOS.
- Đây là QR nội dung tổng quát; không tự tạo VietQR ngân hàng, không tạo cấu trúc Wi-Fi từ các ô SSID/mật khẩu trong bản này. Có thể nhập chuỗi/đường dẫn tương ứng nếu Sếp đã có.
- Không tự đọc clipboard, không lưu lịch sử nội dung QR. QR hiện tại nằm trong bộ nhớ app; chia sẻ ảnh là thao tác chủ động của Sếp.

## Thử trên máy thật

1. Sau cài/respring, thử mở khay ở Home và trong vài app. Thử cả cạnh trái/phải và kéo tay nắm dọc. Kiểm tra thao tác vuốt SenSwipe, bàn phím và vùng chạm ngoài tay nắm.
2. Khóa máy khi khay đang mở/đóng; xác nhận khay biến mất và không thao tác tiện ích được ở màn hình khóa. Mở khóa rồi thử lại.
3. Thử nút Control Center, mở/đóng liên tục và xoay màn hình. Khay được yêu cầu đóng khi chuyển kích thước/orientation, cần kiểm chứng hành vi thực tế.
4. Thử từng nút mặc định. Với ShareWifi, kiểm tra trạng thái trong ShareWifi và Internet trên máy khách; đừng chỉ dựa vào màu nút.
5. Thêm URL và một phím tắt có tên tiếng Việt/dấu cách/ký tự `&`, thử gọi và kiểm tra tên được truyền đúng. App/Shortcuts mới quyết định kết quả cuối cùng.
6. Sửa tên, đổi thứ tự, xóa/thêm; kiểm tra thay đổi có hiệu lực ngay và vẫn còn sau respring.
7. Tạo QR chữ Việt/đường dẫn, dùng iPhone 11 quét và đối chiếu nội dung. Thử chia sẻ ảnh QR.

## Chẩn đoán và xử lý

App **QuickControl → Chẩn đoán** hiển thị phiên bản controller, trạng thái khay/khóa/kích hoạt và thời điểm ghi. Nếu chưa có dữ liệu, kiểm tra cài gói, nạp tweak và respring. Nếu phiên bản có nhưng `locked` luôn true khi máy đã mở khóa, cần kiểm tra API khóa trên máy; tiện ích không tự bỏ kiểm tra để ép hiển thị.

Nếu một cạnh vướng thao tác thường dùng, chuyển cạnh hoặc kéo tay nắm sang vị trí khác. Chưa khẳng định tương thích mọi app toàn màn hình, bàn phím, CallKit, switcher hoặc mọi cấu hình SenSwipe trước khi thử.

Gặp lỗi SpringBoard: tắt nạp tweak khi jailbreak lại bằng Dopamine, gỡ QuickControl bằng Sileo/Filza rồi bật lại nạp tweak. Gói chỉ nạp dylib vào SpringBoard, không hook hoặc sửa binary ứng dụng khác. Gỡ QuickControl không thay đổi mạng hoặc ShareWifi; tùy chọn cục bộ có thể còn để cài lại.

## Kiến trúc / build

- `Sources/Overlay.m`: cửa sổ xuyên chạm khi khay đóng, tay nắm, khay, trạng thái khóa và gửi yêu cầu mở.
- `Sources/QCRuntime.h`: NSInvocation kiểm tra ABI trước các private selector. API mở app có khai báo void/BOOL khác nhau giữa nguồn tham khảo, nên kiểm tra kiểu thật lúc chạy; void chỉ có nghĩa gửi yêu cầu.
- `Sources/QCPolicy.h`: quy tắc vị trí, chạm/khóa, trạng thái mới và kiểm tra chuỗi URL/Bundle ID dùng chung với test C.
- `Sources/QCCommon.h`: dữ liệu mặc định, chuẩn hóa cấu hình, atomic plist 0600 trong thư mục 0700, IPC Darwin.
- `App/main.m`: UIKit cấu hình và QR offline. `ControlCenter/Module.m`: module chuẩn CCSupport.
- Không có máy chủ/cổng điều khiển, daemon root, tự thu lịch sử clipboard hay mã shell được tạo từ dữ liệu nhập.

```sh
SDK_PATH=/path/to/iPhoneOS15.6.sdk \
IOS_TOOLCHAIN_BIN=/path/to/ios-toolchain/bin \
THEOS_HEADERS=/path/to/theos/headers bash scripts/build.sh
bash scripts/test.sh
python3 scripts/verify_package.py packages/QuickControl-0.1.0-beta1-iphoneos-arm64.deb
```

Báo cáo kiểm tra và SHA-256 ở `BUILD-REPORT.md`, `packages/Verification.json`. Test host không thay thế kiểm thử UIKit, SpringBoard, API khóa, launch, Control Center hoặc Core Image trên thiết bị thật.

Tham khảo: [Theos SBLockScreenManager](https://github.com/theos/headers/blob/master/SpringBoard/SBLockScreenManager.h), [Theos LSApplicationWorkspace](https://github.com/theos/headers/blob/master/MobileCoreServices/LSApplicationWorkspace.h), [Theos CCUIToggleModule](https://github.com/theos/headers/blob/master/ControlCenterUIKit/CCUIToggleModule.h), [Apple Shortcuts URL scheme](https://support.apple.com/guide/shortcuts/run-a-shortcut-from-a-url-apd624386f42/ios). Các khai báo là căn cứ thiết kế, không xác nhận tương thích iOS 15.8.8 thay cho thử máy.

© Sentechtipsvn · MIT License
