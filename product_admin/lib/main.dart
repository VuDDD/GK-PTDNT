import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

/// Bật Firebase Emulator Suite cục bộ bằng cờ:
/// `flutter run -d chrome --dart-define=USE_EMULATOR=true`
const bool kUseFirebaseEmulator = bool.fromEnvironment(
  'USE_EMULATOR',
  defaultValue: false,
);

/// Cho phép ghi đè IP máy chủ Emulator khi test trên điện thoại Android thật:
/// `--dart-define=EMULATOR_HOST=192.168.1.10`
const String kCustomEmulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kUseFirebaseEmulator) {
    final String host = _resolveEmulatorHost();
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }

  runApp(const ProductAdminApp(useEmulator: kUseFirebaseEmulator));
}

String _resolveEmulatorHost() {
  if (kCustomEmulatorHost.isNotEmpty) {
    return kCustomEmulatorHost;
  }
  if (kIsWeb) {
    return 'localhost';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
}

/// Ứng dụng gốc Product Admin Management dùng Material Design 3.
class ProductAdminApp extends StatelessWidget {
  const ProductAdminApp({
    super.key,
    this.useEmulator = false,
    this.authService,
  });

  final bool useEmulator;
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1D4ED8),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Product Admin Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: AuthGate(
        useEmulator: useEmulator,
        authService: authService,
      ),
    );
  }
}

/// Kiểm tra trạng thái đăng nhập khi mở ứng dụng:
/// - Chưa đăng nhập -> LoginScreen
/// - Đã đăng nhập -> DashboardScreen
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    this.useEmulator = false,
    this.authService,
  });

  final bool useEmulator;
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final AuthService auth = authService ?? AuthService();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return DashboardScreen(
            useEmulator: useEmulator,
            authService: auth,
          );
        }

        return LoginScreen(
          useEmulator: useEmulator,
          authService: auth,
        );
      },
    );
  }
}
