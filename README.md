<p align="center">
  <img src="CydiaIcon.png" width="80" height="80" alt="Sentechtipsvn">
</p>

<h1 align="center">Sentechtipsvn</h1>

<p align="center">
  <strong>Nguồn Sileo — Nơi khơi nguồn đam mê.</strong>
</p>

<p align="center">
  <a href="https://sentechtipsvn.github.io/">Website & thêm nguồn</a>
  ·
  <a href="projects/">Mã nguồn</a>
  ·
  <a href="https://github.com/Sentechtipsvn/Sentechtipsvn.github.io/issues">Báo lỗi & đề xuất</a>
</p>

---

Nguồn phân phối tweak chính thức của **Sentechtipsvn**, tập trung vào cử chỉ điều hướng, điều khiển nhanh và các tiện ích phục vụ nhu cầu sử dụng iPhone hằng ngày.

Kho lưu trữ bao gồm gói cài đặt, mã nguồn, tài liệu sử dụng và lịch sử phiên bản của các dự án.

## Thêm nguồn

**Địa chỉ nguồn chính thức:**

```text
https://sentechtipsvn.github.io/
```

### Qua website

Truy cập [sentechtipsvn.github.io](https://sentechtipsvn.github.io/) trên iPhone và chọn **Thêm vào Sileo**.

### Thêm thủ công

1. Mở **Sileo → Nguồn → +**.
2. Dán địa chỉ nguồn ở trên và xác nhận.
3. Chờ Sileo tải danh sách gói.
4. Chọn tweak cần cài đặt và thực hiện **Respring** khi được yêu cầu.

Các bản cập nhật tiếp theo được phân phối qua địa chỉ nguồn này.

## Các tweak

| Tweak | Phiên bản | Giới thiệu |
| --- | --- | --- |
| [SenSwipe](projects/SenSwipe/README.md) | `0.1.0~beta1` | Cử chỉ Home và đa nhiệm kiểu iPhone X, tùy chọn Control Center và thanh Home. |
| [ShareWifi](projects/ShareWifi/README.md) | `0.2.1~beta1` | Công tắc riêng, menu Haptic Touch, chia sẻ mạng một chạm và Control Center. |
| [QuickControl](projects/QuickControl/README.md) | `0.1.0~beta1` | Khay tiện ích nổi để mở ứng dụng, URL, phím tắt và tạo QR offline. |

Xem tài liệu của từng dự án để biết tính năng, cách cấu hình, phụ thuộc và những giới hạn hiện tại.

## Tương thích

Các gói hiện được phát triển cho cấu hình sau:

| Thành phần | Yêu cầu |
| --- | --- |
| Thiết bị | iPhone 7 Plus |
| Hệ điều hành | iOS 15.8.8 |
| Jailbreak | Dopamine — rootless |
| Kiến trúc gói | `iphoneos-arm64` |
| Trình quản lý gói | Sileo |

Các phiên bản hiện tại đang ở giai đoạn **beta**. Khả năng tương thích với thiết bị, phiên bản iOS hoặc môi trường jailbreak khác chưa được xác nhận.

QuickControl hiện chưa được kiểm chứng trên thiết bị thực. Thông tin kiểm thử chi tiết được ghi trong tài liệu của từng tweak.

Một số tính năng Control Center cần [CCSupport](https://opa334.github.io/) từ nguồn của opa334. Kiểm tra mục phụ thuộc của gói trước khi cài đặt.

## Tải xuống và mã nguồn

- **Cài đặt, cập nhật:** sử dụng nguồn Sileo chính thức.
- **Gói `.deb`:** xem thư mục [debs](debs/).
- **Mã nguồn dự án:** xem thư mục [projects](projects/).
- **Mã nguồn theo phiên bản phát hành:** xem thư mục [sources](sources/).
- **Các phiên bản được lưu trữ:** xem thư mục [archive](archive/).

Thông tin phiên bản và thay đổi của các gói được quản lý trong [catalog.json](catalog.json).

## Báo lỗi và đóng góp

Gửi báo lỗi hoặc đề xuất tính năng tại [GitHub Issues](https://github.com/Sentechtipsvn/Sentechtipsvn.github.io/issues).

Một báo lỗi nên có:

- Tên và phiên bản tweak.
- Thiết bị, phiên bản iOS và jailbreak.
- Các bước tái hiện lỗi.
- Kết quả mong đợi và hiện tượng thực tế.
- Ảnh chụp, video hoặc crash log nếu có.

Vui lòng loại bỏ thông tin cá nhân khỏi nội dung và tệp đính kèm trước khi đăng công khai.

Các đóng góp về mã nguồn, tài liệu và khả năng tương thích đều được hoan nghênh qua Pull Request.

## Dành cho nhà phát triển

### Cấu trúc kho

| Đường dẫn | Nội dung |
| --- | --- |
| `debs/` | Gói cài đặt đang được phân phối |
| `depictions/` | Trang giới thiệu gói trong Sileo |
| `projects/` | Mã nguồn và tài liệu từng tweak |
| `sources/` | Bản ZIP mã nguồn theo phiên bản |
| `archive/` | Các phiên bản được lưu trữ |
| `scripts/` | Công cụ tạo và kiểm tra nguồn |
| `tests/` | Bộ kiểm thử và thành phần kiểm thử bên thứ ba |
| `catalog.json` | Danh mục gói, phiên bản và lịch sử thay đổi |
| `Packages*`, `Release` | Chỉ mục và metadata APT |

### Tạo và kiểm tra chỉ mục

Môi trường công cụ sử dụng Python 3 và `dpkg-scanpackages`. Các kiểm tra bổ sung cần Clang hỗ trợ Blocks và bộ công cụ APT.

```sh
python3 scripts/build_repo.py
python3 scripts/verify_repo.py
python3 scripts/verify_sileo.py
bash scripts/verify_apt.sh
```

Khi phát hành bản mới, cập nhật gói cài đặt, mã nguồn và thông tin trong `catalog.json`, sau đó tạo lại chỉ mục và chạy bộ kiểm tra.

Mỗi bản phát hành phải có phiên bản riêng. Không thay thế nội dung một gói đã phát hành mà giữ nguyên số phiên bản.

Hướng dẫn build từng tweak nằm trong README của dự án tương ứng.

## Giấy phép

Mã nguồn do Sentechtipsvn phát triển được phân phối theo [MIT License](LICENSE).

Các thành phần bên thứ ba giữ nguyên giấy phép và thông tin bản quyền tương ứng.

Bộ kiểm thử nguồn có sử dụng mã của Sileo Team:

> This product includes software developed by the Sileo Team.

Xem [giấy phép thành phần Sileo](tests/vendor/sileo-2.5.1/LICENSE).

---

<p align="center">
  © 2026 Sentechtipsvn
</p>
