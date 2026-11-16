# ShareWifi

**Điều khiển kết nối và chia sẻ mạng trên iPhone đã jailbreak.**

ShareWifi kết hợp nút chia sẻ mạng một chạm, công tắc riêng cho từng kết nối và menu Haptic Touch ngay trên màn hình chính. Giao diện UIKit hỗ trợ Light/Dark Mode và Dynamic Type.

**Phiên bản:** 0.2.1 beta 1 · **Tác giả:** © Sentechtipsvn

## Tương thích

| Thành phần | Yêu cầu |
| --- | --- |
| Thiết bị | iPhone 7 Plus — iPhone9,2 / iPhone9,4 |
| Hệ điều hành | iOS 15.8.8 |
| Jailbreak | Dopamine rootless |
| Kiến trúc gói | iphoneos-arm64 |
| Control Center | CCSupport 1.3.10 trở lên, bản rootless |

## Cài đặt và cập nhật

1. Thêm nguồn **https://sentechtipsvn.github.io/** vào Sileo.
2. Cài đặt hoặc cập nhật **ShareWifi**, sau đó **respring**.
3. Nhấn giữ biểu tượng ShareWifi → **Bảng điều khiển** để mở ứng dụng.
4. Để dùng nút Control Center, vào **Cài đặt → Trung tâm điều khiển → ShareWifi**.

Cập nhật giữ nguyên ID gói, tùy chỉnh và tên riêng của thiết bị. Không cần gỡ bản trước. Nguồn CCSupport chính thức: https://opa334.github.io/.

## Công tắc từng kết nối

Bốn công tắc kiểu Cài đặt iOS nằm bên phải các hàng **Dữ liệu di động**, **Wi-Fi**, **Bluetooth** và **Điểm truy cập cá nhân**. Mỗi thao tác chỉ gửi lệnh cho kết nối đã chọn. Trạng thái hiển thị dựa trên kết quả đọc lại; công tắc tạm khóa khi đang xử lý, thiếu trạng thái mới hoặc chưa đọc được kết nối đó.

Để bật riêng hotspot qua Wi-Fi, hãy bật dữ liệu di động và Wi-Fi trước. Nếu còn thiếu, ShareWifi thông báo mục cần bật. Nút **Bật chia sẻ mạng** vẫn bật cả bộ theo thứ tự dữ liệu di động → Wi-Fi → Bluetooth → hotspot.

Tắt Wi-Fi hoặc dữ liệu di động có thể khiến iOS tự ngừng chia sẻ mạng. Các công tắc phản ánh lại thay đổi của hệ thống; ShareWifi không gửi thêm lệnh đổi các mục còn lại trong một thao tác riêng lẻ.

## Haptic Touch

Mở **Bảng điều khiển → Tùy chỉnh → Haptic Touch**:

- Bật hoặc tắt menu điều khiển riêng của ShareWifi. Mặc định bật.
- Chọn từng kết nối muốn xuất hiện trong menu. Mặc định hiển thị cả bốn.
- Nhấn giữ biểu tượng ShareWifi trên màn hình chính, chọn **Bật…** hoặc **Tắt…** cho kết nối cần đổi. Không cần mở ứng dụng.

Các nhãn Bật/Tắt được tạo từ trạng thái đọc được khi chuẩn bị menu. Lệnh mang trạng thái đích cụ thể, nên chọn một mục đã cũ không vô tình đảo kết nối hai lần. Nếu chưa đọc được trạng thái, mục tương ứng chỉ yêu cầu làm mới.

Các mục cũ **Bảng điều khiển**, **Thiết bị kết nối**, **Bật chia sẻ mạng**, **Tắt cả bộ kết nối** được giữ. Menu sửa/xóa biểu tượng vẫn do iOS quản lý. Sau khi đổi tùy chọn, đóng rồi mở lại menu để áp dụng. Nếu mục Haptic Touch báo chưa sẵn sàng, respring sau khi cập nhật; công tắc trong ứng dụng vẫn độc lập với menu này.

## Bật/tắt cả bộ và ba chế độ dừng

Chạm biểu tượng Home, nút lớn trong ứng dụng hoặc nút ShareWifi trong Control Center để bật cả bộ hoặc dừng theo chế độ đã chọn ở **Tùy chỉnh**.

| Chế độ | Hành vi |
| --- | --- |
| Tắt cả bộ kết nối | Tắt hotspot trước, rồi dữ liệu di động, Wi-Fi và Bluetooth. Mặc định. |
| Chỉ tắt hotspot | Chỉ gửi lệnh tắt Điểm truy cập cá nhân. |
| Khôi phục trước khi chia sẻ | Trả bốn công tắc về trạng thái trước khi bắt đầu phiên chia sẻ đã lưu. |

**Tắt cả bộ kết nối** trong danh sách điều khiển và quick action cùng tên luôn tắt cả bốn. **Dừng chia sẻ theo chế độ…** cho phép chọn một lần mà không đổi mặc định.

Tắt **Chạm để bật/tắt cả bộ** trong Tùy chỉnh nếu muốn chạm biểu tượng luôn mở ứng dụng.

## Hoàn tác và khôi phục phiên

- **Hoàn tác** khôi phục trạng thái trước thao tác thay đổi gần nhất, kể cả thao tác bằng công tắc riêng hoặc Haptic Touch. Cần đọc được đủ bốn trạng thái để có bản ghi hoàn tác đầy đủ.
- **Khôi phục phiên** dùng bản ghi trước lần bật chia sẻ mạng bằng ShareWifi. Bật riêng hotspot cũng có thể tạo phiên nếu trước đó hotspot tắt và đủ trạng thái hợp lệ.
- Thao tác riêng lẻ giữ bản ghi phiên hiện có; dừng thành công bằng một trong ba chế độ kết thúc phiên. Nếu thất bại một phần, giữ phiên để có thể khôi phục.
- Hoàn tác cũng khôi phục bản ghi phiên tương ứng. Nếu không có bản ghi, tiện ích báo rõ và không tự chuyển sang tắt cả bộ.
- Phiên và Hoàn tác lưu trong bộ nhớ SpringBoard, mất sau respring/khởi động lại. Tùy chỉnh và tên riêng thiết bị được giữ.

## Thiết bị kết nối và Internet

Hiển thị số kết nối tethering hệ thống, danh sách thiết bị vừa thấy qua ARP/DHCP, IP/MAC và tên riêng do người dùng đặt. ARP có thể giữ thông tin máy đã rời mạng; danh sách ghi rõ mức độ xác nhận và có thể khác số kết nối hệ thống. MAC riêng tư thay đổi có thể cần đặt lại tên.

Kiểm tra HTTPS tới Apple xác nhận Internet từ máy phát; không thay thế kiểm tra trên máy khách và không xác nhận đường ra chắc chắn là dữ liệu di động. Danh sách thiết bị không được gửi kèm phép thử.

Rời ứng dụng hoặc khóa màn hình không gửi lệnh tắt hotspot. iOS vẫn quản lý thời gian hoạt động của điểm truy cập. Tên/mật khẩu hotspot do Cài đặt iOS quản lý. Liên kết mở Cài đặt hotspot hiện có thể chỉ vào trang Cài đặt gốc.

## Kiểm chứng bản beta

Bản 0.2.1 đã biên dịch arm64, chạy kiểm tra logic trên máy build và kiểm tra cấu trúc/chữ ký code-page của gói. **Công tắc riêng và menu Haptic Touch mới chưa được thử trên iPhone thật trong môi trường build.** Bản 0.1.1 đã có phản hồi hoạt động; module Control Center 0.2.0 đã được xác nhận hiển thị.

Sau khi cập nhật, thử từng công tắc và đối chiếu Cài đặt iOS; thử nhấn giữ biểu tượng, tắt/bật Haptic Touch và ẩn từng mục menu; thử Hoàn tác, ba chế độ dừng và nút Control Center. QuickControl 0.1.0 vẫn nhận nhánh phiên bản ShareWifi 0.2.x.

Nếu có lỗi, mở **Chẩn đoán → Sao chép**, kèm thao tác vừa thực hiện. Chẩn đoán có phiên bản, trạng thái API và khả năng nạp menu. Khi cần gỡ lỗi SpringBoard, có thể tắt nạp tweak trong Dopamine rồi gỡ ShareWifi. Chi tiết kiểm tra nằm ở [BUILD-REPORT.md](BUILD-REPORT.md).

## Mã nguồn

| Thành phần | Vai trò |
| --- | --- |
| App/main.m, App/SWSettings.m | Bảng điều khiển, UISwitch, Tùy chỉnh và Haptic Touch |
| Sources/Controller.m | Điều phối radio, đọc lại trạng thái, phiên và Hoàn tác |
| Sources/SWHapticMenu.m | Menu nhấn giữ cho riêng biểu tượng ShareWifi, kiểm tra ABI trước khi hook |
| Sources/SWRadioAction.h | Lệnh có trạng thái đích và kế hoạch một kết nối; dùng chung với kiểm thử C |
| Sources/SWProfilePlan.h | Thứ tự bật/tắt cả bộ và khôi phục |
| ControlCenter/ShareWifiModule.m | Module CCSupport, dùng chung controller |
| Sources/SWClients.m, Sources/SWArp.c | Đọc thông tin thiết bị, interface, DHCP/ARP |

```sh
THEOS=/path/to/theos SDK_PATH=/path/to/iPhoneOS15.6.sdk \
IOS_TOOLCHAIN_BIN=/path/to/ios-toolchain/bin bash scripts/build.sh
bash scripts/test.sh
python3 scripts/verify_package.py packages/ShareWifi-0.2.1-beta1-iphoneos-arm64.deb
```

Không sửa MobileGestalt, APN, VPN, NAT hoặc SenSwipe. Không thêm daemon root hay cổng điều khiển từ xa. Bộ điều khiển chỉ nạp trên thiết bị/hệ điều hành được liệt kê ở trên.

Tham khảo API và kiểu tích hợp: [Apple UISwitch](https://developer.apple.com/documentation/uikit/uiswitch), [Choicy SpringBoard](https://github.com/opa334/Choicy/blob/master/ChoicySB/SpringBoard.x), [Theos CCUIToggleModule](https://github.com/theos/headers/blob/master/ControlCenterUIKit/CCUIToggleModule.h). Không đóng gói binary của các tweak tham khảo.

© Sentechtipsvn · [MIT License](LICENSE)
