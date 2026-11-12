# Hướng Dẫn Cấu Hình Firebase Cho Dự Án `gk-ptdnt`

Tài liệu này hướng dẫn từng bước cấu hình **Firebase Authentication**, **Cloud Firestore**, **Firebase Storage**, **Security Rules**, và **Firebase Emulator Suite** (dành cho gói **Spark miễn phí**) để ứng dụng **Product Admin Management** chạy được trên cả **Flutter Web (Chrome)** và **Android**.

---

## 1. Cấu trúc dữ liệu Firestore (Bắt buộc)

- Collection: `products`
- Mỗi document chỉ được chứa **đúng 4 trường**:

| Tên trường | Kiểu dữ liệu | Ý nghĩa |
|---|---|---|
| `name` | `string` | Tên sản phẩm |
| `price` | `number` | Giá sản phẩm (VNĐ, > 0) |
| `soluong` | `number` (`int`) | Số lượng tồn kho (>= 0) |
| `image` | `string` | URL hình ảnh sản phẩm |

> **Lưu ý:** Document ID do Firestore tự sinh, không lưu vào bên trong dữ liệu sản phẩm. Không thêm các trường như `createdAt`, `updatedAt`, `category`, `description`, `status`.

---

## 2. Kết nối Firebase Project với Flutter (`flutterfire configure`)

Tại thư mục `d:\BT-IT\PTDNT\GK\product_admin`, chạy:

```powershell
# Cài FlutterFire CLI (chỉ cần chạy 1 lần)
dart pub global activate flutterfire_cli

# Đăng nhập Firebase CLI (nếu chưa đăng nhập)
npx firebase-tools login

# Kết nối Flutter với Firebase project gk-ptdnt (chọn nền tảng android và web)
flutterfire configure --project=gk-ptdnt --platforms=android,web
```

Lệnh trên sẽ tự động tạo/cập nhật:
- `product_admin/lib/firebase_options.dart`
- `product_admin/android/app/google-services.json`

### Bổ sung plugin Google Services cho Android (khi dùng Cloud thật)

Khi chạy `flutterfire configure`, công cụ sẽ tự thêm `com.google.gms.google-services` vào `android/app/build.gradle.kts` và `android/settings.gradle.kts`. Nếu cần kiểm tra thủ công:
1. File `product_admin/android/app/google-services.json` phải tồn tại.
2. `product_admin/android/app/build.gradle.kts` có plugin `id("com.google.gms.google-services")`.

---

## 3. Bật Firebase Authentication và tạo tài khoản Admin

1. Mở [Firebase Console](https://console.firebase.google.com/) và chọn project **`gk-ptdnt`**.
2. Vào **Build → Authentication → Get started**.
3. Trong tab **Sign-in method**, bật **Email/Password** (chỉ bật Email/Password, tắt Email link nếu không dùng) → **Save**.
4. Chuyển sang tab **Users → Add user** để tạo tài khoản Admin (không tạo màn hình đăng ký công khai trong app):
   - Email gợi ý: `admin@productadmin.com` (nếu dùng email khác, nhớ cập nhật lại email trong `firestore.rules` và `storage.rules`).
   - Password: tự đặt mật khẩu mạnh (tối thiểu 6 ký tự). Không ghi mật khẩu vào source code.
5. Vào **Authentication → Settings → User actions**, bỏ chọn **Enable create (sign-up)** để chặn người ngoài tự đăng ký tài khoản qua REST API.

---

## 4. Tạo Cloud Firestore Database

1. Trong Firebase Console, vào **Build → Firestore Database → Create database**.
2. Chọn location gần Việt Nam (ví dụ `asia-southeast1` - Singapore).
3. Chọn **Start in production mode** → **Enable**.
4. Deploy file [`firestore.rules`](firestore.rules) từ thư mục `d:\BT-IT\PTDNT\GK`:

```powershell
npx firebase-tools deploy --only firestore:rules --project gk-ptdnt
```

---

## 5. Cấu hình Firebase Storage (Lưu ý gói Spark vs Blaze & Web CORS)

### Trường hợp A: Đang dùng gói Spark miễn phí (Khuyến nghị dùng Emulator để test đầy đủ)
Các project Firebase mới tạo trên gói Spark chưa bật được Cloud Storage bucket. Để test đầy đủ **chọn ảnh → upload lên Firebase Storage → lấy URL → hiển thị ảnh trên Chrome & Android** mà hoàn toàn miễn phí:

1. Đảm bảo máy có **Java JDK** (kiểm tra bằng `java -version`).
2. Tại thư mục `d:\BT-IT\PTDNT\GK`, chạy Emulator Suite:
   ```powershell
   npx firebase-tools emulators:start
   ```
3. Mở Emulator UI tại `http://localhost:4000`:
   - Vào tab **Authentication → Add user** tạo tài khoản `admin@productadmin.com` (để khớp với `firestore.rules` và `storage.rules`).
4. Chạy Flutter với cờ `--dart-define=USE_EMULATOR=true`:
   ```powershell
   cd product_admin
   flutter run -d chrome --dart-define=USE_EMULATOR=true
   ```
   *(Emulator tự đọc `firestore.rules` và `storage.rules` ở thư mục `GK/`, nên bạn kiểm thử được cả phân quyền Admin và schema 4 trường ngay trên máy).*

### Trường hợp B: Đã nâng cấp gói Blaze (Free Tier 5GB) và dùng Cloud Storage thật
1. Trong Firebase Console, vào **Build → Storage → Get started**.
2. Deploy file [`storage.rules`](storage.rules):
   ```powershell
   npx firebase-tools deploy --only storage --project gk-ptdnt
   ```
3. **Cấu hình CORS cho Flutter Web (bắt buộc để Chrome hiển thị ảnh từ Firebase Storage):**
   Sử dụng Google Cloud SDK (`gcloud` / `gsutil`) với file [`cors.json`](cors.json) đã tạo sẵn:
   ```powershell
   gcloud storage buckets update gs://gk-ptdnt.firebasestorage.app --cors-file=cors.json
   ```
   *(Hoặc với tên bucket dạng cũ `gs://gk-ptdnt.appspot.com`, thay đúng tên bucket trong Firebase Console).*

---

## 6. Bảo mật Security Rules

- [`firestore.rules`](firestore.rules):
  - Chỉ cho phép đọc/ghi/xóa `products/{productId}` khi `request.auth.token.email == 'admin@productadmin.com'` (kiểm tra an toàn `'email' in request.auth.token`).
  - Ép kiểu schema chặt chẽ trên cả `create` và `update`: chỉ cho phép đúng 4 key `['name', 'price', 'soluong', 'image']`, `name` trim tối thiểu 2 và tối đa 200 ký tự, `price > 0`, `soluong` là số nguyên `>= 0`, `image` là URL `http://` hoặc `https://` tối đa 2048 ký tự.
  - Chặn toàn bộ collection khác mặc định.
  - Để kiểm tra cú pháp rules trước khi deploy: `npx firebase-tools deploy --only firestore:rules --dry-run --project gk-ptdnt`.
- [`storage.rules`](storage.rules):
  - Cho phép đọc ảnh qua URL trong `products/{fileName}`.
  - Chỉ Admin mới được phép upload/sửa/xóa file ảnh (giới hạn `< 5MB`, định dạng `image/*`).

