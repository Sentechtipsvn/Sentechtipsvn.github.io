# ShareWifi · 0.2.0 beta 1

Tiện ích chia sẻ mạng cho **iPhone 7 Plus (iPhone9,2 / iPhone9,4), iOS 15.8.8, Dopamine rootless**. © Sentechtipsvn.

Sếp đã xác nhận bản 0.1.1 hoạt động trên máy thật: bật/tắt, Internet và nhận diện máy khách. **Bản 0.2.0 mới chỉ được biên dịch, kiểm tra gói và chạy test trên máy build; chưa thử trên iPhone thật.**

## Hai phần mới

### 1. Chế độ khi tắt

Mở **nhấn giữ ShareWifi → Bảng điều khiển → Tùy chỉnh** rồi chọn:

| Lựa chọn | Kết quả |
| --- | --- |
| Tắt cả bộ kết nối (mặc định) | Tắt hotspot trước, rồi dữ liệu di động, Wi-Fi và Bluetooth. |
| Chỉ tắt hotspot | Chỉ yêu cầu tắt Điểm truy cập cá nhân; không gửi lệnh thay đổi ba radio còn lại. Hệ thống vẫn có thể tự quản lý radio. |
| Khôi phục trước khi chia sẻ | Trả bốn công tắc về trạng thái ngay trước khi ShareWifi bắt đầu phiên chia sẻ. |

Lựa chọn dùng chung cho **nút lớn trong app, chạm biểu tượng Home và nút Control Center**. Bật vẫn bật cả bộ theo luồng đã có: dữ liệu di động → Wi-Fi → Bluetooth → hotspot.

Trong bảng điều khiển có thêm **Dừng chia sẻ theo chế độ…** để chọn riêng cho một lần, không đổi mặc định. Nút **Tắt cả bộ kết nối** và quick action cùng tên vẫn luôn tắt cả bốn, bất kể chế độ đã chọn.

**Khôi phục phiên khác Hoàn tác:**

- Khôi phục phiên dùng trạng thái trước lần bật ShareWifi đầu tiên của phiên; các thao tác tiếp theo không ghi đè bản ghi này khi phiên còn tồn tại.
- Hoàn tác dùng trạng thái trước thao tác thay đổi gần nhất. Hoàn tác thành công cũng khôi phục bản ghi phiên tương ứng để có thể tiếp tục dùng Khôi phục phiên.
- Phiên được ghi khi hotspot đang tắt và Sếp bật bằng ShareWifi. Nếu hotspot được bật ngoài ShareWifi, tiện ích không đoán trạng thái trước đó.
- Sau khi dừng thành công bằng một trong ba chế độ, phiên kết thúc. Nếu thao tác thất bại một phần, giữ bản ghi phiên để có thể khôi phục.
- Phiên và Hoàn tác lưu trong bộ nhớ SpringBoard: respring/khởi động lại sẽ mất chúng. Chế độ mặc định và tên riêng thiết bị vẫn được giữ.
- Không có bản ghi phiên thì Khôi phục phiên báo rõ và không đổi công tắc. Có thể chọn Chỉ tắt hotspot hoặc Tắt cả bộ để dừng.

Ví dụ: trước khi chia sẻ, Wi-Fi và tai nghe Bluetooth đang bật, dữ liệu di động tắt. Bật ShareWifi rồi chọn Khôi phục phiên sẽ giữ Wi-Fi/Bluetooth bật, tắt hotspot và trả dữ liệu di động về tắt.

### 2. Nút Control Center

1. Cài **CCSupport** của opa334 qua Sileo nếu máy chưa có. Nguồn của tác giả: [https://opa334.github.io/](https://opa334.github.io/). Gói ShareWifi khai báo phụ thuộc `com.opa334.ccsupport (>= 1.3.10)`; dùng bản rootless dành cho `iphoneos-arm64`.
2. Cài đè `ShareWifi-0.2.0-beta1-iphoneos-arm64.deb` bằng Sileo/Filza, sau đó **respring**. Không chỉ đóng/mở app.
3. Vào **Cài đặt → Trung tâm điều khiển → thêm ShareWifi**.
4. Chạm nút hình mắt xích hotspot: đang tắt thì bật cả bộ; đang bật thì dừng theo chế độ đã chọn trong Tùy chỉnh.

Nút có màu xanh khi trạng thái đọc lại cho biết hotspot đang cho phép kết nối. Không coi số máy kết nối bằng 0 là hotspot đã tắt. Lệnh đi qua cùng controller với nút Home; không tạo bộ điều khiển radio thứ hai. Khi đang xử lý, bỏ qua thao tác chồng lệnh. Màu phản ánh trạng thái đọc được, không tự báo đã bật chỉ vì vừa bấm. Thay đổi ngoài ShareWifi có thể trễ theo chu kỳ đọc trạng thái (tối đa khoảng 60 giây khi đang nghỉ).

Nếu chưa thấy nút, kiểm tra CCSupport và ShareWifi đã cài thành công, đã respring và bật nạp tweak trong Dopamine. Không cần reset bố cục Control Center ngay. Phần mới cần được xác nhận trực tiếp trên máy Sếp.

## Chức năng cũ được giữ

- Chạm icon Home bật/tắt nhanh; nhấn giữ → Bảng điều khiển để mở app. Tùy chỉnh vẫn cho chuyển sang luôn mở giao diện. Không chiếm thao tác sắp xếp biểu tượng.
- Các quick action Bảng điều khiển, Thiết bị kết nối, Bật chia sẻ mạng và Tắt cả bộ kết nối.
- Hiển thị bốn công tắc thực tế, Hoàn tác, Kiểm tra Internet, mở Cài đặt hotspot, Chẩn đoán.
- Bộ đếm tethering hệ thống và danh sách ARP/DHCP; đặt tên riêng theo MAC. ARP có thể còn máy đã rời đi, nên vẫn ghi rõ chưa xác nhận còn online.
- Rời app hoặc khóa màn hình không gửi lệnh tắt. iOS vẫn tự quản lý hotspot, có thể ngắt khi không còn máy dùng.
- Phép thử HTTPS Apple chỉ xác nhận Internet từ iPhone 7 Plus; không chứng minh Internet ở iPhone 11 hay đường ra chắc chắn là 4G. Không gửi danh sách khách tới máy chủ.
- URL mở hotspot trên máy Sếp hiện chỉ vào Cài đặt; bản này giữ hành vi đó.

Không sửa MobileGestalt, APN, nhà mạng, VPN, NAT hay tweak SenSwipe. Tắt dữ liệu di động vẫn giữ nghe gọi/SMS. Tên/mật khẩu hotspot do Cài đặt iOS quản lý. Chưa có chặn riêng từng máy hay thống kê dung lượng từng khách.

## Thử bản mới

1. Cài đè, respring, chờ vài giây. Nhấn giữ → Bảng điều khiển → Chẩn đoán: version phải là `0.2.0 beta 1`.
2. Ghi nhớ trạng thái ban đầu của Wi-Fi/Bluetooth/dữ liệu di động. Bật bằng ShareWifi, kết nối iPhone 11 và kiểm tra Internet trên máy khách.
3. Chọn Chỉ tắt hotspot, thử từ app/Home: hotspot dừng; tai nghe và các radio khác vẫn theo trạng thái trước khi bấm tắt.
4. Tắt hotspot, đặt trạng thái ban đầu khác nhau, bật lại bằng ShareWifi rồi thử Khôi phục phiên. Đối chiếu từng công tắc với trạng thái trước khi bật.
5. Thêm nút Control Center, thử bật và dừng theo cả ba chế độ. Thử bấm nhanh khi đang xử lý; đọc thông báo kết quả.
6. Thử Hoàn tác sau khi dừng rồi Khôi phục phiên; kiểm tra tên thiết bị và các chức năng cũ vẫn còn.
7. Sau respring, Khôi phục phiên phải không khả dụng cho đến khi tạo phiên mới; nếu chọn mặc định này rồi tắt một hotspot bật bên ngoài thì phải báo thiếu bản ghi, không tắt cả bộ ngoài ý muốn.

Nếu có lỗi, gửi **Chẩn đoán → Sao chép**, kèm vị trí nút đã bấm và chế độ đang chọn. Chưa đọc được API thì dừng trước khi đổi radio; hết thời gian chờ thì báo có thể đã đổi một phần, có thể Hoàn tác hoặc chỉnh thủ công. Nếu gặp lỗi SpringBoard, tắt nạp tweak khi jailbreak lại rồi gỡ ShareWifi; không cần sửa SenSwipe. Gỡ gói không tự thay đổi radio hay xóa tùy chọn đã lưu.

## Mã nguồn và kiểm chứng

- `Sources/Controller.m`: controller SpringBoard, ABI kiểm tra trước khi gọi, điều phối tuần tự, chờ trạng thái và hoàn tác.
- `Sources/SWProfilePlan.h`: lập kế hoạch trạng thái/thứ tự và giới hạn công tắc được thay đổi; được dùng thật trong controller và test C.
- `ControlCenter/ShareWifiModule.m`: module CCUIToggleModule, đọc trạng thái, gửi Darwin notification riêng, không ghi đè file lệnh của app.
- `App/main.m`: UIKit, chọn chế độ, danh sách khách, chẩn đoán. Light/Dark Mode và Dynamic Type theo giao diện hiện có.
- `Sources/SWClients.m`, `SWArp.c`: chỉ đọc interface/DHCP/ARP. Không mở cổng điều khiển hay daemon root.
- `Sources/SWCommon.h`: file atomic, thư mục 0700, file 0600; giữ nguyên tên thiết bị và tùy chọn cũ.

Build bằng iPhoneOS15.6 SDK, toolchain arm64 clang/ldid và Theos headers/libs rootless:

```sh
THEOS=/path/to/theos SDK_PATH=/path/to/iPhoneOS15.6.sdk \
IOS_TOOLCHAIN_BIN=/path/to/ios-toolchain/bin bash scripts/build.sh
bash scripts/test.sh
python3 scripts/verify_package.py packages/ShareWifi-0.2.0-beta1-iphoneos-arm64.deb
```

Máy build đã qua ba bộ test với AddressSanitizer/UBSan, kiểm tra 11 file payload rootless và chữ ký code-page của cả app, controller, module. Chi tiết ở `BUILD-REPORT.md` và `packages/Verification.json`. Các kiểm tra này không thay thế thử private API/Control Center trên iPhone thật.

Tham khảo khai báo API: [Theos CCUIToggleModule](https://github.com/theos/headers/blob/master/ControlCenterUIKit/CCUIToggleModule.h), [CCSupport template](https://github.com/opa334/CCSupportModuleTemplate), [Flipswitch hotspot](https://github.com/a3tweaks/Flipswitch/blob/master/Switches/Hotspot.x). ShareWifi không đóng gói binary hoặc mã triển khai của các tweak tham khảo.

© Sentechtipsvn · MIT License
