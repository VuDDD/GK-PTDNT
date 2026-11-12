import 'package:firebase_auth/firebase_auth.dart';

/// Dịch vụ xác thực Admin bằng Firebase Authentication (Email & Password).
class AuthService {
  AuthService({this.auth});

  final FirebaseAuth? auth;
  FirebaseAuth get _instance => auth ?? FirebaseAuth.instance;

  /// Luồng theo dõi trạng thái đăng nhập theo thời gian thực.
  Stream<User?> get authStateChanges => _instance.authStateChanges();

  /// Người dùng Admin hiện tại (hoặc `null` nếu chưa đăng nhập).
  User? get currentUser => _instance.currentUser;

  /// Đăng nhập bằng Email và Password.
  ///
  /// Ném ra [Exception] với thông báo tiếng Việt thân thiện nếu đăng nhập thất bại.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      throw Exception('Không thể đăng nhập: $e');
    }
  }

  /// Đăng xuất tài khoản Admin hiện tại.
  Future<void> signOut() async {
    await _instance.signOut();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản Admin này đã bị khóa.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu Admin không chính xác.';
      case 'too-many-requests':
        return 'Đăng nhập sai quá nhiều lần. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Kiểm tra Internet hoặc Firebase Emulator.';
      default:
        return 'Đăng nhập thất bại (${e.code}): ${e.message ?? 'Vui lòng thử lại.'}';
    }
  }
}
