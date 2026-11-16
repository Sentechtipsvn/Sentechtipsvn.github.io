# Sentechtipsvn

Nguồn Sileo nơi khơi nguồn đam mê

Kho tweak và mã nguồn của **© Sentechtipsvn**. Website và địa chỉ nguồn Sileo chính thức:

```text
https://sentechtipsvn.github.io/
```

Mở địa chỉ trên để xem trang và chọn **Thêm vào Sileo**, hoặc dán trực tiếp vào **Sileo → Nguồn → +**. Cùng một địa chỉ phục vụ cả trang web và chỉ mục APT, không có tên repo lặp phía sau.

## Tweak hiện có

| Tweak | Bản hiện tại | Chức năng | Trạng thái |
| --- | --- | --- | --- |
| [SenSwipe](projects/SenSwipe/README.md) | `0.1.0~beta1` | Cử chỉ Home, tùy chọn Control Center/Home bar | Đã có phản hồi cử chỉ chạy mượt; vẫn là beta |
| [ShareWifi](projects/ShareWifi/README.md) | `0.2.0~beta1` | Bật chia sẻ mạng một chạm, ba chế độ dừng và Control Center | Bản 0.1.1 đã chạy được, module CC 0.2.0 đã hiển thị; các chế độ mới cần thử thêm |
| [QuickControl](projects/QuickControl/README.md) | `0.1.0~beta1` | Khay tiện ích nổi, ứng dụng/URL/phím tắt, QR offline | Chưa xác nhận chạy trên iPhone thật |

Các gói hiện dành riêng **iPhone 7 Plus · iOS 15.8.8 · Dopamine rootless (`iphoneos-arm64`)**. Respring sau khi cài/nâng cấp. Phụ thuộc bên thứ ba lấy từ nguồn tác giả tương ứng, ví dụ [CCSupport của opa334](https://opa334.github.io/).

Các .deb giữ nguyên byte, ID, version và phụ thuộc so với bản đã bàn giao. Việc chuyển nguồn không yêu cầu cài lại các tweak đã có. Chỉ cần thêm nguồn mới và bỏ nguồn cũ khỏi danh sách nếu muốn tránh hiển thị trùng.

## Chuyển từ kho cũ

[Kho Sentechtipsvn-tweak](https://github.com/Sentechtipsvn/Sentechtipsvn-tweak) và nguồn raw cũ vẫn được giữ làm bản lưu trong giai đoạn chuyển. Nguồn mới là `https://sentechtipsvn.github.io/` — hostname viết thường và không có đường dẫn tên repo nên tránh lỗi hoa/thường từng gặp ở Pages của kho cũ.

Repo này nhận các cập nhật tiếp theo của nguồn. Nguồn cũ không tự đồng bộ với repo mới; nếu đang theo dõi nguồn cũ thì thêm nguồn chính thức mới để nhận cập nhật về sau.

## Cấu trúc

- `index.html`, `Release`, `Packages*`, `CydiaIcon.png`: website và chỉ mục APT đặt ngay tại thư mục gốc, cùng nơi GitHub Pages phục vụ.
- `debs/`: ba gói hiện tại. `Packages`, bản nén gzip/bzip2/xz và `Release` được sinh từ chính dữ liệu .deb.
- `depictions/`: giới thiệu native trong Sileo. Trang web giữ giao diện gọn; chi tiết kiểm thử nằm trong Sileo và hướng dẫn từng dự án.
- `projects/`: mã nguồn, hướng dẫn và bộ kiểm tra của từng tweak.
- `sources/`: ZIP mã nguồn của các bản đang phân phối.
- `archive/`: các bản ShareWifi 0.1.0/0.1.1 và ZIP nguồn để lưu lịch sử.
- `catalog.json`: mô tả, version, changelog và trạng thái kiểm thử của ba tweak.
- `scripts/`: bộ tạo nguồn và các kiểm tra APT/Sileo.
- `.github/workflows/publish.yml`: kiểm tra dữ liệu đã commit bằng parser Sileo và APT. GitHub Pages tự triển khai nhánh master; không chạy thêm workflow deploy cạnh tranh với Pages.

## Cập nhật gói

1. Build tweak với version mới; giữ bản cũ trong `archive/` nếu cần. Không thay byte một .deb đã phát hành mà vẫn giữ nguyên version.
2. Cập nhật `projects/`, ZIP trong `sources/`, .deb trong `debs/` và thông tin tương ứng ở `catalog.json`.
3. Chạy:

```sh
python3 scripts/build_repo.py
python3 scripts/verify_repo.py
python3 scripts/verify_sileo.py
bash scripts/verify_apt.sh
```

4. Commit dữ liệu mới cùng chỉ mục đã sinh, rồi push. GitHub Pages triển khai thư mục gốc của nhánh master. Workflow kiểm tra dữ liệu đã commit; kiểm tra URL công khai sau khi Pages triển khai xong.

Công cụ tạo nguồn cần Python 3 và `dpkg-scanpackages` (`dpkg-dev` trên Debian/Ubuntu). Kiểm tra parser C cần clang hỗ trợ Blocks; thử đọc APT cần apt-get/apt-cache. Mỗi tweak có môi trường build riêng trong README của dự án.

## Cấu hình Pages một lần

Repo có tên đặc biệt `Sentechtipsvn.github.io`, thuộc tài khoản `Sentechtipsvn`. Cấu hình hiện dùng trong **Settings → Pages**: **Deploy from a branch → master → / (root)**. Giữ cấu hình này; dữ liệu nguồn đã nằm ngay tại gốc và có `.nojekyll`.

Địa chỉ là `https://sentechtipsvn.github.io/`. Tách kiểm tra dữ liệu khỏi việc triển khai của Pages để tránh hai workflow ghi đè lẫn nhau. Workflow kiểm tra xanh chưa thay cho kiểm tra HTTP của website, Release, Packages và các gói tải xuống.

## Kiểm tra tương thích nguồn

Release có `Origin`, `Architectures: iphoneos-arm64` và **`Components: main`**. Trường Components là bắt buộc trong bộ đọc nguồn Sileo 2.5.1, kể cả nguồn flat; thiếu nó từng khiến Sileo hiện kho không tên và 0 gói dù HTTP trả 200.

Các kiểm tra gồm: checksum .deb/Release, chỉ mục nén, metadata, URL thêm/sao chép nguồn, parser C của Sileo 2.5.1 và APT đọc chỉ mục trong thư mục tạm. Bài kiểm tra parser tái hiện lỗi thiếu Components và xác nhận dữ liệu đầy đủ được chấp nhận. Chúng không thay thế thử iOS trên máy thật.

Nguồn chưa có chữ ký GPG Release. Chữ ký ad-hoc của binary và checksum .deb không phải chứng chỉ Apple hay bảo đảm tương thích mọi thiết bị.

### Mã kiểm thử bên thứ ba

`tests/vendor/sileo-2.5.1/` giữ parser C và giấy phép gốc. Driver/header tương thích Linux chỉ dùng cho kiểm thử, không đưa vào các tweak. This product includes software developed by the Sileo Team. Xem [giấy phép](tests/vendor/sileo-2.5.1/LICENSE). Đây không phải chứng nhận hoặc sự bảo trợ của Sileo.

© Sentechtipsvn · MIT cho mã riêng; giấy phép khác được ghi trong thư mục tương ứng.
