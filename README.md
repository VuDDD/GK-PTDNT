# Product Admin Management (Flutter + Firebase)

Ứng dụng quản trị sản phẩm (**Product Admin Management**) hỗ trợ chạy đa nền tảng trên **Flutter Web (Chrome)** và **Flutter Android**, sử dụng **Firebase Authentication**, **Cloud Firestore** và **Firebase Storage** với giao diện **Material Design 3**.

---

## 1. Cấu trúc thư mục dự án

```text
GK/
├── .firebaserc                   # Liên kết Firebase project (gk-ptdnt)
├── firebase.json                 # Cấu hình Rules, Hosting và Emulator Suite
├── firestore.rules               # Luật bảo mật Firestore (chỉ Admin + đúng 4 trường)
├── storage.rules                 # Luật bảo mật Firebase Storage (chỉ Admin ghi/xóa ảnh)
├── cors.json                     # Cấu hình CORS cho Flutter Web tải ảnh Storage
├── sample_products.json          # Dữ liệu mẫu đúng 4 trường (name, price, soluong, image)
├── local_products.json           # Database JSON cục bộ đồng bộ tự động trên máy
├── product_images/               # Thư mục lưu & tự động đồng bộ ảnh sản phẩm từ máy tính
├── sync_to_firebase.mjs          # Script đồng bộ dữ liệu & ảnh giữa máy tính, Emulator, Cloud
├── key_vault.mjs                 # Script mã hóa / giải mã serviceAccountKey.json (AES-256-GCM)
├── serviceAccountKey.json.enc    # Bản mã hóa an toàn của serviceAccountKey.json (không lộ private key)
├── FIREBASE_SETUP.md             # Hướng dẫn chi tiết cấu hình Firebase & Emulator
├── README.md                     # Tài liệu hướng dẫn cài đặt, chạy và xuất bản
└── product_admin/                # Mã nguồn Flutter
    ├── pubspec.yaml
    ├── test/
    │   └── widget_test.dart
    └── lib/
        ├── main.dart                         # Khởi tạo Firebase, cấu hình Emulator & AuthGate
        ├── firebase_options.dart             # Cấu hình Firebase Web & Android
        ├── models/
        │   └── product.dart                  # Model Product (đúng 4 trường + định dạng VNĐ)
        ├── services/
        │   ├── auth_service.dart             # Đăng nhập, đăng xuất Admin Firebase Auth
        │   ├── product_service.dart          # CRUD Firestore thời gian thực, tìm kiếm, sắp xếp
        │   └── storage_service.dart          # Upload (putData Uint8List) & xóa ảnh Storage
        ├── screens/
        │   ├── login_screen.dart             # Màn hình đăng nhập Admin
        │   ├── dashboard_screen.dart         # Dashboard (Sidebar, Header, Thống kê, Quản lý SP)
        │   ├── product_list_screen.dart      # Bảng trên Web / Card ListView trên Android
        │   ├── add_product_screen.dart       # Thêm sản phẩm + upload ảnh Storage
        │   ├── edit_product_screen.dart      # Sửa sản phẩm (giữ ảnh cũ nếu không đổi)
        │   └── product_detail_screen.dart    # Xem chi tiết sản phẩm
        ├── widgets/
        │   ├── custom_text_field.dart        # Ô nhập liệu dùng chung
        │   ├── product_card.dart             # Card sản phẩm + hiển thị ảnh có loading/fallback
        │   └── product_form.dart             # Form nhập liệu + chọn/xem trước ảnh dùng chung
        └── utils/
            └── validators.dart               # Kiểm tra tên, giá > 0, số lượng >= 0, email
```

---

## 2. Yêu cầu chuẩn bị môi trường

1. **Flutter SDK** (>= 3.13 / hiện tại đang dùng `3.47.4` stable):
   ```powershell
   flutter doctor
   ```
2. **Node.js & Firebase CLI** (dùng `npx firebase-tools` hoặc cài toàn cục `npm install -g firebase-tools`).
3. **Java JDK 17/21** (cần nếu chạy Firebase Emulator Suite cục bộ).
4. **Google Chrome** (để chạy Flutter Web) và **Android Studio / Android Emulator** hoặc điện thoại Android bật USB Debugging.

---

## 3. Cài đặt thư viện & Kiểm tra lỗi tĩnh

Các bước tạo và cài thư viện đã được cấu hình sẵn trong `product_admin/pubspec.yaml` (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `image_picker`, `intl`):

```powershell
cd d:\BT-IT\PTDNT\GK\product_admin
flutter pub get
flutter analyze
flutter test
```

---

## 4. Hướng dẫn chạy ứng dụng

### Cách A: Chạy với Firebase Emulator Suite (Dữ liệu lưu vĩnh viễn tại `emulator_data/`)

- **Chạy 1 lệnh tự động song song (bật Emulator nếu chưa chạy + đồng bộ database tự động + mở Chrome/Android):**
  ```powershell
  cd d:\BT-IT\PTDNT\GK\product_admin
  # Mở trên Chrome:
  .\run_dev.ps1
  # Hoặc mở trên máy ảo Android:
  .\run_dev.ps1 emulator-5554
  ```
  *(Script [`run_dev.ps1`](product_admin/run_dev.ps1) chạy ngầm trình theo dõi mỗi 10 giây: khi bạn thêm/sửa/xóa sản phẩm trên app — hoặc thêm/thay ảnh mới trong `product_images/` & `local_products.json` từ máy tính — hệ thống tự động tải ảnh lên Storage, cập nhật Firestore, lưu về `emulator_data/` + `product_images/`, và nếu có `serviceAccountKey.json` hợp lệ sẽ đồng bộ lên Cloud Firestore `gk-ptdnt`.)*

Hoặc nếu muốn tự chạy thủ công từng terminal riêng:

1. Mở terminal thứ nhất tại `d:\BT-IT\PTDNT\GK` (hoặc double-click `start_emulator.bat`):
   ```powershell
   .\start_emulator.bat
   ```
   *(Lệnh trên chạy `npx firebase-tools emulators:start --only auth,firestore,storage --import=./emulator_data --export-on-exit=./emulator_data`, tự nạp lại dữ liệu cũ khi mở và tự lưu thay đổi vào thư mục `emulator_data/` khi nhấn `Ctrl + C`. Nếu muốn lưu ngay khi đang chạy mà chưa tắt terminal, chạy `.\save_database.bat`.)*
2. Nếu chưa có user trong `emulator_data/`, mở `http://localhost:4000` → **Authentication → Add user** → tạo tài khoản Admin `admin@productadmin.com` (mật khẩu tự chọn >= 6 ký tự).
3. Mở terminal thứ hai tại `d:\BT-IT\PTDNT\GK\product_admin`:

   - **Chạy trên Flutter Web (Chrome):**
     ```powershell
     flutter run -d chrome --dart-define=USE_EMULATOR=true
     ```

   - **Chạy trên Android Emulator:**
     ```powershell
     # 1. Xem và khởi động máy ảo (nếu chưa có thì tạo mới bằng flutter emulators --create)
     flutter emulators
     flutter emulators --launch product_admin_avd

     # 2. Xem ID thiết bị vừa lên (thường là emulator-5554) và chạy app (không nhập dấu < >)
     flutter devices
     flutter run -d emulator-5554 --dart-define=USE_EMULATOR=true
     ```
     *(App tự động ánh xạ `10.0.2.2` để Android Emulator kết nối tới máy tính chủ. Nếu muốn xem các ảnh có URL `localhost:9199` từ máy ảo, chạy thêm `adb reverse tcp:9199 tcp:9199` — nếu chưa thêm `platform-tools` vào `PATH`, dùng `& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:9199 tcp:9199`).*

   - **Chạy trên điện thoại Android thật (qua USB hoặc cùng Wi-Fi):**
     - Cách 1 (qua cáp USB, giữ nguyên `localhost` nhờ `adb reverse`, thay `DEVICE_ID` bằng ID từ `flutter devices`):
       ```powershell
       adb reverse tcp:9099 tcp:9099
       adb reverse tcp:8080 tcp:8080
       adb reverse tcp:9199 tcp:9199
       flutter run -d DEVICE_ID --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=localhost
       ```
     - Cách 2 (qua cùng mạng Wi-Fi, thay `192.168.1.x` bằng IP LAN máy tính):
       ```powershell
       flutter run -d DEVICE_ID --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=192.168.1.x
       ```

### Cách B: Chạy với Cloud Firebase thật (`gk-ptdnt`) & Tự động đồng bộ database lên Firebase

1. Hoàn tất các bước trong [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md) (`flutterfire configure --project=gk-ptdnt`, bật Auth Email/Password, tạo user `admin@productadmin.com`, deploy `firestore.rules`).
2. Để mỗi lần chạy tự động đẩy dữ liệu sản phẩm từ [`local_products.json`](local_products.json) (hoặc từ Emulator đang chạy) lên Cloud Firestore `gk-ptdnt` mà không phải nhập mật khẩu lặp lại:
   - **Nếu đã có sẵn bản mã hóa [`serviceAccountKey.json.enc`](serviceAccountKey.json.enc) trên GitHub:** giải mã ra file gốc bằng [`key_vault.mjs`](key_vault.mjs) (dùng mật khẩu riêng đã mã hóa, **tuyệt đối không lưu mật khẩu lên GitHub**):
     ```powershell
     cd d:\BT-IT\PTDNT\GK
     node key_vault.mjs decrypt
     ```
   - **Hoặc tự tải key mới từ Firebase Console:** mở **Project `gk-ptdnt` → Project settings → Service accounts → Generate new private key**, lưu thành `d:\BT-IT\PTDNT\GK\serviceAccountKey.json` *(file `.json` gốc đã được khai báo trong `.gitignore` nên không bị đẩy lên GitHub; nếu cần cập nhật bản mã hóa, chạy `node key_vault.mjs encrypt`)*.
3. Chạy 1 lệnh để tự động đồng bộ database lên Cloud rồi mở app:
   ```powershell
   cd d:\BT-IT\PTDNT\GK
   # Chạy trên Chrome:
   .\run_cloud_sync.bat
   # Hoặc chạy trên Android Emulator:
   .\run_cloud_sync.bat emulator-5554
   ```
   *(Nếu chỉ muốn đồng bộ database lên Cloud mà chưa chạy app: `node sync_to_firebase.mjs`.)*

---

## 5. Hướng dẫn xuất bản Flutter Web

1. Đảm bảo đã cấu hình `firebase_options.dart` thật bằng `flutterfire configure --project=gk-ptdnt`.
2. Build bản release cho Web:
   ```powershell
   cd d:\BT-IT\PTDNT\GK\product_admin
   flutter build web --release
   ```
3. Xuất bản lên **Firebase Hosting** từ thư mục `d:\BT-IT\PTDNT\GK`:
   ```powershell
   cd d:\BT-IT\PTDNT\GK
   npx firebase-tools deploy --only hosting --project gk-ptdnt
   ```
   Sau khi deploy xong, CLI sẽ trả về đường dẫn web công khai dạng `https://gk-ptdnt.web.app`.

*(Ngoài ra có thể deploy thư mục `product_admin/build/web/` lên Vercel, Netlify hoặc GitHub Pages).*

---

## 6. Build file cài đặt Android APK

```powershell
cd d:\BT-IT\PTDNT\GK\product_admin
flutter build apk --release
```

File APK thành phẩm nằm tại:
`product_admin/build/app/outputs/flutter-apk/app-release.apk`

---

## 7. Dữ liệu mẫu nộp bài

File [`sample_products.json`](sample_products.json) chứa danh sách sản phẩm mẫu, trong đó **mỗi sản phẩm chỉ có đúng 4 trường** `name`, `price`, `soluong`, `image` đúng theo yêu cầu đề bài.

