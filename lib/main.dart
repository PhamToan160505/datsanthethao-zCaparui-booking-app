import 'package:flutter/material.dart';
// Thay đổi import từ welcome_screen sang login_screen
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Khởi tạo Firebase App Check
  try {
    if (!kIsWeb) {
      if (kDebugMode) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
        );
      }
    }
  } catch (e) {
    // Không dừng app nếu App Check không khởi tạo được trong môi trường dev/emulator
    // Lỗi sẽ xuất hiện trong logs nếu có — cho phép chạy tiếp để debug.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Thay đổi màn hình khởi đầu (home) thành LoginScreen
      home: const LoginScreen(),
    );
  }
}
