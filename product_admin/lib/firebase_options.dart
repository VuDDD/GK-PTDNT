// File cấu hình Firebase mặc định cho dự án `gk-ptdnt`.
//
// LƯU Ý KHI TRIỂN KHAI CLOUD THẬT:
// Chạy lệnh `flutterfire configure --project=gk-ptdnt` trong thư mục `product_admin`
// để tự động ghi đè file này bằng thông số thật từ Firebase Console.
//
// Khi chạy với Firebase Emulator Suite (`--dart-define=USE_EMULATOR=true`),
// các giá trị dự phòng dưới đây đủ để khởi tạo Firebase SDK trên Web & Android.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions chưa hỗ trợ nền tảng này. '
          'Vui lòng chạy trên Web (Chrome) hoặc Android.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'gk-ptdnt',
    authDomain: 'gk-ptdnt.firebaseapp.com',
    storageBucket: 'gk-ptdnt.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'gk-ptdnt',
    storageBucket: 'gk-ptdnt.firebasestorage.app',
  );
}

