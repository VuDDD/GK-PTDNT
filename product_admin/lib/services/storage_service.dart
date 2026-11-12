import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Dịch vụ tải lên và xóa hình ảnh sản phẩm trên Firebase Storage.
///
/// Sử dụng `Uint8List` (`putData`) thay vì `dart:io File` để chạy ổn định
/// trên cả Flutter Web (Chrome) và Android.
class StorageService {
  StorageService({this.storage});

  final FirebaseStorage? storage;
  FirebaseStorage get _instance => storage ?? FirebaseStorage.instance;

  /// Tải ảnh từ [XFile] (do `image_picker` trả về) lên Firebase Storage
  /// và trả về URL tải ảnh.
  Future<String> uploadProductImage(XFile imageFile) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    return uploadProductImageBytes(
      bytes: bytes,
      fileName: imageFile.name,
    );
  }

  /// Tải dữ liệu bytes của ảnh lên thư mục `products/` trên Firebase Storage.
  Future<String> uploadProductImageBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Tệp hình ảnh rỗng, vui lòng chọn ảnh khác.');
    }

    final String sanitizedName = _sanitizeFileName(fileName);
    final String objectPath =
        'products/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
    final Reference ref = _instance.ref().child(objectPath);

    try {
      final SettableMetadata metadata = SettableMetadata(
        contentType: _detectContentType(sanitizedName),
      );
      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception(_mapStorageError(e));
    } catch (e) {
      throw Exception('Không thể tải ảnh lên Firebase Storage: $e');
    }
  }

  /// Xóa ảnh cũ trên Firebase Storage dựa theo URL nếu xác định được file thuộc Storage.
  ///
  /// Bỏ qua an toàn nếu là URL mẫu bên ngoài hoặc ảnh không còn tồn tại.
  Future<void> deleteImageByUrl(String imageUrl) async {
    final String trimmed = imageUrl.trim();
    if (trimmed.isEmpty || !_isFirebaseStorageUrl(trimmed)) {
      return;
    }

    try {
      final Reference ref = _instance.refFromURL(trimmed);
      await ref.delete();
    } catch (_) {
      // Không làm gián đoạn thao tác xóa/cập nhật sản phẩm nếu ảnh cũ không xóa được.
    }
  }

  static bool _isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') ||
        url.contains('storage.googleapis.com') ||
        url.contains('/v0/b/');
  }

  static String _sanitizeFileName(String fileName) {
    final String base = fileName.trim().isEmpty ? 'product.jpg' : fileName.trim();
    return base.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  static String _detectContentType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String _mapStorageError(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'Tài khoản hiện tại không có quyền tải ảnh lên Firebase Storage (kiểm tra Storage Rules).';
      case 'canceled':
        return 'Quá trình tải ảnh đã bị hủy.';
      case 'bucket-not-found':
      case 'project-not-found':
        return 'Không tìm thấy Firebase Storage bucket. Hãy bật Firebase Emulator hoặc kiểm tra gói Firebase.';
      default:
        return 'Lỗi Firebase Storage (${e.code}): ${e.message ?? 'Không thể tải ảnh.'}';
    }
  }
}
