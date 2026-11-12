# TEST_CASES.md
# KẾ HOẠCH KIỂM THỬ ỨNG DỤNG QUẢN LÝ SẢN PHẨM ADMIN (FLUTTER + FIREBASE)

> **Mục đích:** Đối chiếu ứng dụng với đề bài: quản lý sản phẩm bằng Flutter, dùng Firebase hoặc MongoDB, chạy trên Web; có đăng nhập, thêm/sửa/xóa, tải và hiển thị ảnh; kiểm tra được trên nền tảng di động.
>
> **Lưu ý:** Đây là tài liệu/kịch bản kiểm thử. Các mục chỉ được đánh dấu **ĐẠT** sau khi đã thực sự chạy thử trên ứng dụng. Việc có mã nguồn hoặc có test case không tự chứng minh chức năng đã hoạt động.

---

## 1. Thông tin đợt kiểm thử

| Nội dung | Giá trị |
|---|---|
| Tên dự án | Product Admin Management |
| Framework | Flutter |
| Cơ sở dữ liệu | Firebase Cloud Firestore (hoặc MongoDB nếu dự án thực tế dùng MongoDB) |
| Dịch vụ xác thực | Firebase Authentication (nếu sử dụng Firebase) |
| Lưu trữ ảnh | Firebase Storage (nếu sử dụng Firebase) |
| Nền tảng Web | Chrome / trình duyệt tương thích |
| Nền tảng di động | Android Emulator hoặc điện thoại Android thật |
| Người kiểm thử | ........................................ |
| Ngày kiểm thử | ....../....../.......... |
| Phiên bản ứng dụng / commit | ........................................ |

### Quy ước kết quả

- [ ] **ĐẠT** – Thực hiện đúng kết quả mong đợi.
- [ ] **KHÔNG ĐẠT** – Có lỗi hoặc kết quả khác mong đợi.
- [ ] **CHƯA KIỂM THỬ** – Chưa thực hiện.
- **Minh chứng** – Ghi tên ảnh chụp màn hình, video hoặc log tương ứng.

---

## 2. Kiểm tra điều kiện bắt buộc của đề bài

| ID | Nội dung cần kiểm tra | Kết quả mong đợi | Trạng thái | Minh chứng / ghi chú |
|---|---|---|---|---|
| REQ-01 | Ứng dụng được xây dựng bằng Flutter | Dự án có cấu trúc Flutter hợp lệ, chạy được bằng Flutter CLI | [ ] | |
| REQ-02 | Có sử dụng cơ sở dữ liệu được yêu cầu | Dữ liệu sản phẩm được lưu và đọc từ Firebase hoặc MongoDB đã chọn | [ ] | |
| REQ-03 | Chạy trên nền tảng Web | Ứng dụng mở và thao tác được trên Chrome | [ ] | |
| REQ-04 | Có đủ trường `name`, `price`, `soluong`, `image` | Mỗi bản ghi sản phẩm có đúng bốn trường nghiệp vụ này | [ ] | |
| REQ-05 | Có chức năng thêm sản phẩm | Thêm sản phẩm mới và dữ liệu được lưu vào database | [ ] | |
| REQ-06 | Có chức năng hiển thị sản phẩm | Danh sách hiển thị dữ liệu thực tế từ database | [ ] | |
| REQ-07 | Có chức năng sửa sản phẩm | Sửa thông tin và dữ liệu sau sửa được cập nhật trong database | [ ] | |
| REQ-08 | Có chức năng xóa sản phẩm | Xóa sản phẩm và bản ghi không còn trong danh sách/database | [ ] | |
| REQ-09 | Có chức năng đăng nhập | Admin đăng nhập bằng thông tin hợp lệ | [ ] | |
| REQ-10 | Có chức năng đăng xuất | Admin đăng xuất và được đưa về màn hình đăng nhập | [ ] | |
| REQ-11 | Có chức năng tải ảnh sản phẩm | Chọn ảnh từ thiết bị và tải ảnh lên dịch vụ lưu trữ | [ ] | |
| REQ-12 | Hiển thị ảnh sản phẩm | Ảnh đã tải được hiển thị đúng ở danh sách/chi tiết | [ ] | |
| REQ-13 | Chạy trên nền tảng di động | Ứng dụng chạy trên Android Emulator hoặc thiết bị thật | [ ] | |
| REQ-14 | Chọn ảnh trên di động | Có thể chọn ảnh từ thư viện/nguồn ảnh của thiết bị Android | [ ] | |
| REQ-15 | Có file dữ liệu để nộp | Có file JSON/SQL phù hợp với loại database thực tế và dữ liệu đúng cấu trúc | [ ] | |
| REQ-16 | Có báo cáo và minh chứng | Có báo cáo các bước, ảnh chụp database, ảnh giao diện và hướng dẫn chạy | [ ] | |
| REQ-17 | Có link GitHub | Repository có source code cần thiết và README hướng dẫn | [ ] | |
| REQ-18 | Có video demo | Video thể hiện các chức năng chính trên Web và thao tác di động | [ ] | |

---

## 3. Kiểm thử đăng nhập và đăng xuất

| ID | Tình huống kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|---|
| AUTH-01 | Mở ứng dụng khi chưa đăng nhập | Mở ứng dụng ở phiên mới hoặc đăng xuất trước đó | Chuyển đến màn hình Login | [ ] | |
| AUTH-02 | Đăng nhập hợp lệ | Nhập email và mật khẩu đúng, nhấn Đăng nhập | Đăng nhập thành công, chuyển đến Dashboard | [ ] | |
| AUTH-03 | Sai mật khẩu | Nhập email đúng nhưng mật khẩu sai | Không đăng nhập; hiển thị thông báo lỗi phù hợp | [ ] | |
| AUTH-04 | Email không tồn tại | Nhập email chưa đăng ký | Không đăng nhập; hiển thị thông báo phù hợp | [ ] | |
| AUTH-05 | Bỏ trống email | Để trống email và nhấn Đăng nhập | Hiển thị yêu cầu nhập email | [ ] | |
| AUTH-06 | Bỏ trống mật khẩu | Để trống mật khẩu và nhấn Đăng nhập | Hiển thị yêu cầu nhập mật khẩu | [ ] | |
| AUTH-07 | Đăng xuất | Nhấn nút Đăng xuất | Phiên đăng nhập kết thúc, trở về Login | [ ] | |
| AUTH-08 | Kiểm tra truy cập sau đăng xuất | Đăng xuất rồi thử mở lại trang quản lý | Không thể truy cập chức năng Admin khi chưa đăng nhập | [ ] | |
| AUTH-09 | Tải lại trang khi đã đăng nhập | Đăng nhập rồi refresh trình duyệt | Trạng thái đăng nhập được xử lý đúng theo thiết kế | [ ] | |

**Ghi chú:** Nếu đề bài yêu cầu tài khoản Admin, cần kiểm tra quyền Admin thực tế. Chỉ ẩn nút trên giao diện là chưa đủ; quyền ghi/xóa phải được bảo vệ ở database hoặc backend bằng Security Rules/quyền truy cập phù hợp.

---

## 4. Kiểm thử hiển thị danh sách sản phẩm

| ID | Tình huống kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|---|
| LIST-01 | Mở danh sách sản phẩm | Đăng nhập và mở trang sản phẩm | Hiển thị dữ liệu đọc từ database | [ ] | |
| LIST-02 | Hiển thị tên | Kiểm tra một sản phẩm có tên | Tên khớp với trường `name` | [ ] | |
| LIST-03 | Hiển thị giá | Kiểm tra giá của một sản phẩm | Giá khớp với `price`, định dạng tiền hợp lý | [ ] | |
| LIST-04 | Hiển thị số lượng | Kiểm tra số lượng của một sản phẩm | Số lượng khớp với `soluong` | [ ] | |
| LIST-05 | Hiển thị ảnh | Kiểm tra ảnh của một sản phẩm | Ảnh đúng, không bị vỡ; có ảnh thay thế nếu URL lỗi | [ ] | |
| LIST-06 | Database chưa có sản phẩm | Xóa dữ liệu thử nghiệm hoặc dùng database rỗng | Hiển thị trạng thái danh sách trống, không bị crash | [ ] | |
| LIST-07 | Nhiều sản phẩm | Tạo nhiều bản ghi thử nghiệm | Danh sách cuộn/phân trang được, giao diện không vỡ | [ ] | |
| LIST-08 | Dữ liệu thay đổi | Thêm/sửa sản phẩm từ phiên khác hoặc database | Danh sách cập nhật theo cơ chế ứng dụng đã triển khai | [ ] | |

---

## 5. Kiểm thử thêm sản phẩm (Create)

| ID | Tình huống kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|---|
| CREATE-01 | Thêm sản phẩm hợp lệ | Nhập đủ tên, giá, số lượng; chọn ảnh; nhấn Lưu | Tạo sản phẩm thành công | [ ] | |
| CREATE-02 | Kiểm tra dữ liệu sau khi thêm | Mở database và kiểm tra document vừa tạo | Có đúng bốn trường `name`, `price`, `soluong`, `image` | [ ] | |
| CREATE-03 | Bỏ trống tên | Để trống tên và lưu | Không lưu; báo lỗi tên bắt buộc | [ ] | |
| CREATE-04 | Tên chỉ chứa khoảng trắng | Nhập vài dấu cách làm tên | Không lưu; yêu cầu tên hợp lệ | [ ] | |
| CREATE-05 | Giá bằng 0 | Nhập giá 0 và lưu | Không lưu nếu quy tắc yêu cầu giá lớn hơn 0 | [ ] | |
| CREATE-06 | Giá âm | Nhập giá âm | Không lưu; báo lỗi giá không hợp lệ | [ ] | |
| CREATE-07 | Giá không phải số | Nhập chữ vào ô giá | Không cho lưu; báo lỗi định dạng | [ ] | |
| CREATE-08 | Số lượng âm | Nhập số lượng -1 | Không lưu; báo lỗi số lượng | [ ] | |
| CREATE-09 | Số lượng không phải số nguyên | Nhập số thập phân/chữ | Không lưu nếu số lượng yêu cầu số nguyên không âm | [ ] | |
| CREATE-10 | Không chọn ảnh | Bỏ qua chọn ảnh rồi lưu | Xử lý theo quy định của ứng dụng; nếu ảnh bắt buộc thì báo lỗi và không lưu | [ ] | |
| CREATE-11 | Chọn ảnh hợp lệ | Chọn JPG/PNG hợp lệ | Hiển thị ảnh xem trước và tải ảnh thành công | [ ] | |
| CREATE-12 | Chọn file không phải ảnh | Thử chọn PDF/TXT nếu bộ chọn cho phép | Từ chối file không hợp lệ, không làm ứng dụng crash | [ ] | |
| CREATE-13 | Hủy chọn ảnh | Mở bộ chọn ảnh rồi nhấn Cancel | Quay lại form an toàn, không làm mất dữ liệu đã nhập | [ ] | |
| CREATE-14 | Nhấn Lưu nhiều lần | Nhấn nút Lưu liên tiếp khi đang xử lý | Không tạo nhiều bản ghi trùng do thao tác lặp | [ ] | |

---

## 6. Kiểm thử sửa sản phẩm (Update)

| ID | Tình huống kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|---|
| UPDATE-01 | Mở form sửa | Chọn một sản phẩm và nhấn Sửa | Form hiển thị đúng dữ liệu hiện tại | [ ] | |
| UPDATE-02 | Sửa tên | Thay tên rồi lưu | Database cập nhật đúng `name` | [ ] | |
| UPDATE-03 | Sửa giá | Thay giá rồi lưu | Database cập nhật đúng `price` | [ ] | |
| UPDATE-04 | Sửa số lượng | Thay số lượng rồi lưu | Database cập nhật đúng `soluong` | [ ] | |
| UPDATE-05 | Thay ảnh | Chọn ảnh mới và lưu | URL `image` được cập nhật; ảnh mới hiển thị | [ ] | |
| UPDATE-06 | Không thay ảnh | Chỉ sửa tên/giá/số lượng | Giữ nguyên URL ảnh cũ | [ ] | |
| UPDATE-07 | Sửa tên thành rỗng | Xóa tên rồi lưu | Không cập nhật; hiển thị lỗi | [ ] | |
| UPDATE-08 | Sửa giá thành số âm/chữ | Nhập giá không hợp lệ | Không cập nhật; hiển thị lỗi | [ ] | |
| UPDATE-09 | Hủy sửa | Thay đổi dữ liệu rồi nhấn Hủy | Không ghi thay đổi vào database | [ ] | |
| UPDATE-10 | Kiểm tra cấu trúc sau sửa | Mở document sau khi cập nhật | Vẫn chỉ có bốn trường nghiệp vụ được yêu cầu | [ ] | |

---

## 7. Kiểm thử xóa sản phẩm (Delete)

| ID | Tình huống kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|---|
| DELETE-01 | Mở xác nhận xóa | Nhấn Xóa tại một sản phẩm | Hiển thị hộp thoại xác nhận | [ ] | |
| DELETE-02 | Hủy xóa | Chọn Hủy | Sản phẩm vẫn tồn tại | [ ] | |
| DELETE-03 | Đồng ý xóa | Chọn Xác nhận | Document bị xóa khỏi database | [ ] | |
| DELETE-04 | Kiểm tra danh sách sau xóa | Quay lại danh sách | Sản phẩm đã xóa không còn hiển thị | [ ] | |
| DELETE-05 | Xóa sản phẩm cuối cùng | Chỉ để lại một sản phẩm rồi xóa | Hiển thị trạng thái danh sách trống | [ ] | |
| DELETE-06 | Lỗi kết nối khi xóa | Ngắt mạng rồi thử xóa | Hiển thị lỗi; không báo xóa thành công giả | [ ] | |
| DELETE-07 | Xóa ảnh liên quan (nếu triển khai) | Xóa sản phẩm và kiểm tra Storage | Chỉ xóa đúng ảnh thuộc sản phẩm; không xóa nhầm ảnh dùng chung | [ ] | |

---

## 8. Kiểm thử tải lên và hiển thị hình ảnh

| ID | Tình huống kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|---|
| IMG-01 | Chọn ảnh trên Web | Mở form trên Chrome và chọn ảnh từ máy tính | Bộ chọn file hoạt động | [ ] | |
| IMG-02 | Upload ảnh lên Storage | Chọn ảnh và lưu sản phẩm | File ảnh được tải lên Storage | [ ] | |
| IMG-03 | Lưu URL ảnh | Kiểm tra document sản phẩm | Trường `image` chứa URL hoặc đường dẫn ảnh theo thiết kế | [ ] | |
| IMG-04 | Hiển thị ảnh trên Web | Mở danh sách sản phẩm | Ảnh tải và hiển thị đúng | [ ] | |
| IMG-05 | Chọn ảnh trên Android | Mở form trên Android và chọn ảnh | Bộ chọn ảnh hoạt động | [ ] | |
| IMG-06 | Hiển thị ảnh trên Android | Mở danh sách sản phẩm trên Android | Ảnh hiển thị đúng, không tràn khung | [ ] | |
| IMG-07 | Ảnh dung lượng lớn | Chọn ảnh lớn trong giới hạn cho phép | Có xử lý tải ảnh; không treo hoặc crash | [ ] | |
| IMG-08 | URL ảnh không hợp lệ | Thử dữ liệu có URL ảnh lỗi | Hiển thị ảnh thay thế/thông báo, ứng dụng không crash | [ ] | |
| IMG-09 | Mất mạng khi upload | Ngắt mạng trong lúc tải ảnh | Báo lỗi rõ ràng; không lưu sản phẩm với trạng thái thành công giả | [ ] | |

---

## 9. Kiểm thử chức năng nâng cao (nếu có triển khai)

| ID | Tình huống kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|---|
| ADV-01 | Tìm kiếm theo tên | Nhập một phần tên sản phẩm | Hiển thị sản phẩm phù hợp | [ ] | |
| ADV-02 | Tìm kiếm không có kết quả | Nhập tên không tồn tại | Hiển thị thông báo không tìm thấy | [ ] | |
| ADV-03 | Xóa từ khóa tìm kiếm | Xóa nội dung tìm kiếm | Danh sách trở về trạng thái phù hợp | [ ] | |
| ADV-04 | Sắp xếp giá tăng dần | Chọn tăng dần | Giá từ thấp đến cao | [ ] | |
| ADV-05 | Sắp xếp giá giảm dần | Chọn giảm dần | Giá từ cao đến thấp | [ ] | |
| ADV-06 | Tổng số sản phẩm | Đếm sản phẩm trong danh sách | Số hiển thị khớp dữ liệu thực tế | [ ] | |

---

## 10. Kiểm thử riêng trên Flutter Web

| ID | Tình huống kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|---|
| WEB-01 | Chạy ứng dụng | Chạy `flutter run -d chrome` | Ứng dụng mở trên Chrome | [ ] | |
| WEB-02 | Đăng nhập trên Web | Đăng nhập Admin | Đăng nhập thành công | [ ] | |
| WEB-03 | CRUD trên Web | Thêm, xem, sửa, xóa sản phẩm | Các thao tác hoàn tất và đồng bộ database | [ ] | |
| WEB-04 | Upload ảnh trên Web | Chọn ảnh từ máy tính | Upload và hiển thị ảnh thành công | [ ] | |
| WEB-05 | Kích thước màn hình | Thay đổi kích thước cửa sổ trình duyệt | Giao diện không vỡ, nội dung không bị che khuất nghiêm trọng | [ ] | |
| WEB-06 | Refresh trang | Tải lại trang khi đang ở trạng thái đăng nhập | Ứng dụng khôi phục trạng thái hoặc điều hướng đúng | [ ] | |
| WEB-07 | Console trình duyệt | Mở DevTools > Console | Không có lỗi nghiêm trọng làm hỏng chức năng | [ ] | |
| WEB-08 | Build Web | Chạy `flutter build web` | Build hoàn tất không có lỗi | [ ] | |

---

## 11. Kiểm thử riêng trên Android

| ID | Tình huống kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|---|
| AND-01 | Chạy trên Android | Chạy `flutter run` với thiết bị Android | Ứng dụng khởi động thành công | [ ] | |
| AND-02 | Đăng nhập | Đăng nhập Admin trên Android | Đăng nhập thành công | [ ] | |
| AND-03 | Hiển thị danh sách | Mở danh sách sản phẩm | Hiển thị tên, giá, số lượng, ảnh | [ ] | |
| AND-04 | Thêm sản phẩm | Nhập dữ liệu và lưu | Sản phẩm được thêm vào database | [ ] | |
| AND-05 | Chọn ảnh từ điện thoại | Mở bộ chọn ảnh | Chọn được ảnh từ thiết bị | [ ] | |
| AND-06 | Sửa sản phẩm | Sửa thông tin một sản phẩm | Dữ liệu được cập nhật | [ ] | |
| AND-07 | Xóa sản phẩm | Xác nhận xóa một sản phẩm thử nghiệm | Sản phẩm bị xóa | [ ] | |
| AND-08 | Xoay màn hình/đổi kích thước | Thử thay đổi hướng màn hình nếu thiết bị hỗ trợ | Nội dung vẫn sử dụng được | [ ] | |
| AND-09 | Mất mạng | Ngắt kết nối rồi mở danh sách/thao tác | Có thông báo lỗi phù hợp, không crash | [ ] | |
| AND-10 | Build Android | Chạy `flutter build apk` | Tạo APK thành công | [ ] | |

---

## 12. Kiểm tra cấu trúc database – ĐIỀU KIỆN RẤT QUAN TRỌNG

Đề bài chỉ chấp nhận bốn trường sản phẩm:

1. `name`
2. `price`
3. `soluong`
4. `image`

### 12.1. Checklist cấu trúc

| ID | Nội dung | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|
| DB-01 | Kiểm tra trường `name` | Có và lưu kiểu chuỗi | [ ] | |
| DB-02 | Kiểm tra trường `price` | Có và lưu kiểu số | [ ] | |
| DB-03 | Kiểm tra trường `soluong` | Có và lưu kiểu số nguyên không âm | [ ] | |
| DB-04 | Kiểm tra trường `image` | Có và lưu URL/đường dẫn ảnh dạng chuỗi | [ ] | |
| DB-05 | Kiểm tra trường thừa | Không có trường nghiệp vụ thứ năm như `category`, `description`, `createdAt`, `updatedAt`, `status`, `quantity` | [ ] | |
| DB-06 | Kiểm tra sau thao tác thêm | Bản ghi mới có đúng bốn trường | [ ] | |
| DB-07 | Kiểm tra sau thao tác sửa | Bản ghi vẫn có đúng bốn trường | [ ] | |
| DB-08 | Kiểm tra dữ liệu xuất | File JSON/SQL nộp có đúng cấu trúc theo database thực tế | [ ] | |

**Lưu ý về Firestore:** Document ID do Firestore quản lý không được xem là trường dữ liệu sản phẩm. Không thêm các thuộc tính nghiệp vụ khác vào document. Nếu dùng MongoDB, `_id` là metadata định danh do MongoDB quản lý; vẫn phải bảo đảm document chỉ có bốn trường nghiệp vụ được yêu cầu.

### 12.2. JSON mẫu hợp lệ

File `products.json` có thể dùng cấu trúc:

```json
[
  {
    "name": "iPhone 16 Pro Max",
    "price": 30000000,
    "soluong": 10,
    "image": "https://example.com/iphone.jpg"
  },
  {
    "name": "Samsung Galaxy S25",
    "price": 22000000,
    "soluong": 15,
    "image": "https://example.com/samsung.jpg"
  }
]
```

> Thay URL minh họa bằng URL ảnh thực tế. File JSON là dữ liệu để nộp/nhập mẫu; cần kiểm tra riêng dữ liệu thật trong Firebase hoặc MongoDB.

---

## 13. Kiểm thử bảo mật và xử lý lỗi

| ID | Tình huống kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái | Minh chứng |
|---|---|---|---|---|---|
| SEC-01 | Chưa đăng nhập đọc dữ liệu Admin | Mở chức năng Admin khi chưa đăng nhập | Bị chặn theo chính sách bảo mật | [ ] | |
| SEC-02 | Chưa đăng nhập ghi dữ liệu | Thử thêm/sửa/xóa khi chưa đăng nhập | Database từ chối thao tác | [ ] | |
| SEC-03 | Tài khoản không có quyền Admin | Đăng nhập tài khoản thường (nếu có phân quyền) | Không được thực hiện thao tác Admin | [ ] | |
| SEC-04 | Kiểm tra thông tin bí mật | Kiểm tra source code và file cấu hình được commit | Không commit private key, mật khẩu hoặc thông tin bí mật | [ ] | |
| SEC-05 | Rules database | Kiểm tra Firestore/MongoDB security hoặc backend authorization | Quyền đọc/ghi được giới hạn đúng thiết kế | [ ] | |
| SEC-06 | Rules Storage | Thử upload khi không có quyền | Storage từ chối thao tác trái phép | [ ] | |
| SEC-07 | Lỗi kết nối database | Tạm ngắt mạng hoặc cấu hình sai môi trường thử nghiệm | Hiển thị lỗi dễ hiểu, không crash | [ ] | |
| SEC-08 | Dữ liệu nhập không hợp lệ | Nhập chuỗi bất thường, giá/số lượng sai định dạng | Validate dữ liệu, không ghi dữ liệu sai | [ ] | |

---

## 14. Kiểm tra tài liệu và sản phẩm bàn giao

| ID | Hạng mục bàn giao | Yêu cầu | Trạng thái | Minh chứng / đường dẫn |
|---|---|---|---|---|
| DOC-01 | Source code | Có đầy đủ source Flutter, không thiếu file cần thiết | [ ] | |
| DOC-02 | README.md | Có hướng dẫn cài thư viện, cấu hình và chạy dự án | [ ] | |
| DOC-03 | File dữ liệu | Có `products.json` hoặc file xuất database phù hợp | [ ] | |
| DOC-04 | Cấu hình database | Có hướng dẫn kết nối và ảnh chụp database | [ ] | |
| DOC-05 | Ảnh Login | Có ảnh chụp màn hình đăng nhập | [ ] | |
| DOC-06 | Ảnh danh sách | Có ảnh danh sách sản phẩm trên Web | [ ] | |
| DOC-07 | Ảnh thêm sản phẩm | Có ảnh form thêm và kết quả thêm thành công | [ ] | |
| DOC-08 | Ảnh sửa sản phẩm | Có ảnh trước và sau khi sửa | [ ] | |
| DOC-09 | Ảnh xóa sản phẩm | Có ảnh xác nhận hoặc kết quả xóa | [ ] | |
| DOC-10 | Ảnh database | Có ảnh chứng minh bốn trường dữ liệu | [ ] | |
| DOC-11 | Ảnh Android | Có ảnh ứng dụng chạy trên Android và chọn/hiển thị ảnh | [ ] | |
| DOC-12 | Link GitHub | Link truy cập được, có source code và README | [ ] | |
| DOC-13 | Video demo | Link xem được, có trình bày các chức năng chính | [ ] | |
| DOC-14 | Báo cáo | Có mô tả các bước thực hiện, thư viện và ảnh minh họa | [ ] | |

---

## 15. Dữ liệu dùng để kiểm thử

Nên tạo ít nhất ba sản phẩm thử nghiệm. Không dùng dữ liệu quan trọng hoặc sản phẩm thật trong các bài kiểm thử xóa.

| Tên sản phẩm | Giá | Số lượng | Ảnh |
|---|---:|---:|---|
| Sản phẩm Test A | 100000 | 5 | Ảnh JPG |
| Sản phẩm Test B | 250000 | 0 | Ảnh PNG |
| Sản phẩm Test C | 500000 | 12 | Ảnh JPG |

Các trường hợp dữ liệu sai cần thử riêng:

- Tên rỗng.
- Giá bằng 0.
- Giá âm.
- Giá chứa chữ.
- Số lượng âm.
- Số lượng chứa chữ hoặc số thập phân (nếu quy định số nguyên).
- Không chọn ảnh.
- URL ảnh không truy cập được.

---

## 16. Tổng hợp kết quả kiểm thử

Điền số lượng sau khi thực hiện toàn bộ test case:

| Kết quả | Số lượng |
|---|---:|
| Tổng test case | ........ |
| Đạt | ........ |
| Không đạt | ........ |
| Chưa kiểm thử | ........ |

**Tỷ lệ đạt** = Số test case Đạt / Số test case đã thực hiện × 100%.

Không tính các mục Chưa kiểm thử vào mẫu số. Tuy nhiên, các yêu cầu bắt buộc của đề bài không được để ở trạng thái Chưa kiểm thử khi kết luận sẵn sàng nộp bài.

### Điều kiện kết luận sẵn sàng nộp

- [ ] Các yêu cầu bắt buộc trong mục 2 đều đạt.
- [ ] Đăng nhập/đăng xuất hoạt động.
- [ ] Thêm, hiển thị, sửa, xóa hoạt động với database thật.
- [ ] Document sản phẩm chỉ có đúng bốn trường `name`, `price`, `soluong`, `image`.
- [ ] Ảnh được tải lên và hiển thị đúng.
- [ ] Ứng dụng chạy được trên Chrome.
- [ ] Ứng dụng chạy được trên Android.
- [ ] File JSON/SQL dữ liệu được chuẩn bị để nộp.
- [ ] Có báo cáo, ảnh chụp database, link GitHub và video demo.
- [ ] Không còn lỗi nghiêm trọng ảnh hưởng đến chức năng chính.

**Kết luận:**

- [ ] ĐỦ ĐIỀU KIỆN NỘP BÀI.
- [ ] CHƯA ĐỦ ĐIỀU KIỆN NỘP BÀI.

**Các lỗi còn tồn tại / việc cần hoàn thành:**

..............................................................................

..............................................................................

**Người kiểm thử:** ........................................

**Ngày:** ....../....../..........

---

## 17. Lệnh chạy và kiểm tra nhanh

Chạy các lệnh sau tại thư mục gốc dự án Flutter:

```bash
# Kiểm tra môi trường Flutter
flutter doctor

# Cài đặt dependencies
flutter pub get

# Phân tích lỗi và cảnh báo Dart
flutter analyze

# Chạy unit test/widget test nếu dự án đã có
flutter test

# Chạy ứng dụng trên Chrome
flutter run -d chrome

# Build bản Web
flutter build web

# Liệt kê thiết bị
flutter devices

# Chạy trên thiết bị Android đang kết nối
flutter run

# Build APK Android
flutter build apk
```

### Ghi nhận kết quả lệnh

| Lệnh | Kết quả thực tế | Ghi chú |
|---|---|---|
| `flutter doctor` | ................................ | |
| `flutter pub get` | ................................ | |
| `flutter analyze` | ................................ | |
| `flutter test` | ................................ | |
| `flutter build web` | ................................ | |
| `flutter build apk` | ................................ | |

> `flutter analyze` không có lỗi phân tích không đồng nghĩa mọi chức năng đã hoạt động. `flutter test` chỉ kiểm tra những test đã được viết. Vẫn phải chạy ứng dụng và thực hiện các kịch bản thủ công ở trên.
