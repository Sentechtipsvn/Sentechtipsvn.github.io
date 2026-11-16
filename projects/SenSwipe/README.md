# SenSwipe 0.1.0 beta 1

Cử chỉ Home kiểu iPhone X cho **iPhone 7 Plus / iOS 15.8.8 / Dopamine rootless**.

**Bản thử nghiệm, chưa chạy trên iPhone thật.** Biên dịch và kiểm tra gói không xác nhận được độ mượt, bố cục hoặc tương thích runtime.

## Bản này làm gì?

- Bật cơ chế home gesture của SpringBoard.
- Chuyển Control Center sang góc trên phải theo tùy chọn.
- Ẩn Home bar mặc định, có công tắc hiển thị trong Cài đặt → SenSwipe.
- Chỉ nạp lõi tweak vào SpringBoard; không nạp vào ứng dụng hay tiến trình bàn phím.
- Chỉ kích hoạt trên iPhone9,2/iPhone9,4 và iOS 15.8.8.
- Kiểm tra tên lớp, selector, số đối số và kiểu trả về trước khi cài hook. Thiếu API cần thiết thì bỏ qua kích hoạt và ghi log `[SenSwipe]`.

## Trước khi cài

1. Đã sao lưu `com.apple.MobileGestalt.plist` là tốt, nhưng cần **khôi phục đúng bản gốc của chính máy, cùng phiên bản iOS hiện tại** nếu thông số giả iPhone X vẫn còn. Nếu bản sao có từ trước khi cập nhật iOS, cần kiểm tra trước khi khôi phục. Không dùng file của máy khác. Tweak không tự sửa hoặc tự khôi phục file này.
2. Sau khi khôi phục, khởi động lại máy và jailbreak lại bằng Dopamine. Xác nhận bàn phím, Home và thanh trạng thái đã về bố cục gốc.
3. Tắt/gỡ các tweak khác cùng sửa cử chỉ, Home bar, bàn phím hoặc thanh trạng thái trong lần thử đầu. Có thể bật lại từng tweak sau khi xác nhận bản cơ bản.

## Cài đặt

1. Lưu `SenSwipe-0.1.0-beta1-iphoneos-arm64.deb` vào Tệp.
2. Mở gói bằng Sileo và cài. Nếu Sileo không nhận qua menu Chia sẻ, mở gói bằng Filza và chọn Install. Sileo sẽ giải quyết phụ thuộc `mobilesubstrate`/`preferenceloader` nếu còn thiếu; không bỏ qua lỗi phụ thuộc.
3. Respring sau khi cài. Nếu trình cài không hiện nút respring, dùng chức năng khởi động lại SpringBoard có sẵn trong môi trường jailbreak của máy.
4. Vào **Cài đặt → SenSwipe**. Các thay đổi cần respring.

Mặc định: bật cử chỉ; Control Center ở góc trên phải; ẩn thanh Home.

Nếu cài qua terminal đã có trên máy: `sudo dpkg -i /đường/dẫn/tới/gói.deb` sau khi giải quyết đầy đủ phụ thuộc trong Sileo. Không cần dùng terminal để cài theo cách thông thường.

## Kiểm thử trên máy

Thử theo thứ tự dưới đây. Giữ Home vật lý để thao tác dự phòng.

| Mục | Cách kiểm tra | Kết quả thực tế |
| --- | --- | --- |
| Home | Mở Cài đặt, vuốt lên từ đáy; thử cả vuốt chậm rồi hủy | Chưa thử |
| Đa nhiệm | Vuốt lên rồi giữ; mở lại app từ thẻ đa nhiệm | Chưa thử |
| Control Center | Kéo từ góc trên phải; đóng/mở nhiều lần | Chưa thử |
| Bàn phím | Gõ trong Ghi chú, Tin nhắn, Safari; đổi ngôn ngữ; mở emoji | Chưa thử |
| Khoảng trống đáy | So sánh với ảnh bàn phím trước khi cài, cả dọc và ngang | Chưa thử |
| Bàn phím bên thứ ba | Nếu dùng, thử riêng từng bàn phím | Chưa thử |
| Thanh trạng thái | Kiểm tra giờ, sóng, pin và giao diện Control Center | Chưa thử |
| Home bar | Bật công tắc, respring; kiểm tra che nút dưới đáy; sau đó thử tắt | Chưa thử |
| Nút vật lý | Home, giữ Home gọi Siri, Touch ID, Home + nguồn chụp màn hình | Chưa thử |
| Màn hình khóa | Khóa/mở lại, thử Touch ID và mật mã | Chưa thử |
| Xoay màn hình | Safari, video toàn màn hình; Display Zoom nếu đang sử dụng | Chưa thử |
| Xung đột | Bật lại từng tweak từng dùng, kiểm tra sau mỗi lần | Chưa thử |

Vuốt ngang chuyển app nhanh và vuốt mở khóa chưa được xác nhận trong bản này. Không có xử lý riêng cho các thao tác đó; chỉ có hành vi native mà iOS cung cấp sau khi bật home gesture.

## Khi có lỗi

- Nếu không có tác dụng: kiểm tra đã khôi phục MobileGestalt, đã respring và đã bật nạp tweak trong Dopamine. Gửi log có tiền tố `[SenSwipe]` nếu có.
- Nếu cử chỉ hoạt động nhưng giao diện Control Center bị lệch: chụp ảnh/video, tắt riêng công tắc Control Center trong SenSwipe rồi respring để khoanh vùng. Khi tắt, Control Center có thể dùng lại cạnh dưới và tranh chấp với vuốt Home.
- Nếu bàn phím còn hở đáy: so sánh với ảnh trước cài. Không tự sửa thêm MobileGestalt hoặc ép safe area bằng tweak khác trong lúc chẩn đoán.
- Nếu SpringBoard crash: tắt nạp tweak khi jailbreak lại bằng Dopamine, gỡ SenSwipe bằng Sileo/Filza, rồi bật lại nạp tweak. Gửi crash log SpringBoard trong phần Dữ liệu phân tích của iOS nếu có; chỉ ảnh lỗi không đủ xác định nguyên nhân crash.
- Gỡ gói không tự thay đổi MobileGestalt. Cấu hình SenSwipe có thể còn trong Preferences để giữ lựa chọn khi cài lại.

## Giới hạn có chủ ý

- Không giả model, không sửa cache MobileGestalt hoặc `homeButtonType`.
- Không hook `safeAreaInsets`, không ép chiều cao bàn phím hoặc thanh trạng thái.
- Việc không hook bố cục giúp giảm phạm vi can thiệp; bản thân hành vi native sau khi bật gesture vẫn có thể tác động bố cục và phải kiểm tra trên thiết bị.
- Không thay đổi tổ hợp nút vật lý, không giả Face ID, không bỏ xác thực.
- Không tắt animation Control Center để che lỗi; nếu animation lỗi cần xem runtime/log trước khi sửa có mục tiêu.
- Không có thay đổi thời gian thực: công tắc được đọc một lần lúc SpringBoard khởi động, tránh ghi/đọc cấu hình trên mỗi khung hình.

## Build

Theos + iPhoneOS15.6 SDK, target arm64, deployment target 15.0:

```sh
make clean package FINALPACKAGE=1
```

Trên Linux có toolchain iOS trong `$THEOS/toolchain/linux/iphone/bin`, có thể dùng builder đóng gói trực tiếp:

```sh
THEOS=/đường/dẫn/theos SDK_PATH=/đường/dẫn/iPhoneOS15.6.sdk bash scripts/build-linux.sh
```

`scripts/verify_package.py` kiểm tra tập tin payload, phạm vi injection, kiến trúc arm64, deployment target, thư viện liên kết rootless và từng hash trang mã của chữ ký ad-hoc. Đây không phải chứng nhận hay kiểm thử trên iOS.

## Tham khảo kỹ thuật

- [HomeGesture1315](https://github.com/Tweaker177/HomeGesture1315): cách bật `SBHomeGestureSettings` và Control Center.
- [Little16](https://github.com/michaelmelita1/Little16): tham khảo tách home gesture và Home bar.
- [Little12](https://github.com/ryannair05/Little12): đối chiếu rủi ro khi sửa nhiều thành phần bố cục.
- [Theos rootless](https://theos.dev/docs/rootless).

Các dự án trên không xác nhận SenSwipe hoạt động trên 15.8.8. Nguồn SenSwipe được viết riêng với kiểm tra runtime và phạm vi tính năng nêu trên.

© Sentechtipsvn · MIT License
