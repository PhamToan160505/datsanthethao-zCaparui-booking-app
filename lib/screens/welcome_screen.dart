import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        128,
        203,
        244,
      ), // Màu xanh bạn đang dùng
      body: Center(
        child: Column(
          // mainAxisAlignment: Giữ phần trên cùng ở giữa, không cần Center
          children: [
            // Spacer 1: Đẩy phần logo xuống dưới một chút (làm cho logo không dính sát viền trên)
            const Spacer(flex: 2),

            // Logo thể thao badminton sử dụng ảnh asset
            Image.asset(
              'assets/shuttlecock.png', // <-- ĐƯỜNG DẪN ĐÃ ĐƯỢC FIX
              width: 122,
              height: 122,
            ),

            const SizedBox(height: 20),

            const Text(
              "Sport Booking",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),

            // Spacer 2: Đẩy mọi thứ phía trên lên và mọi thứ phía dưới xuống cuối màn hình
            const Spacer(flex: 3),

            // Thanh loading ngang
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: const LinearProgressIndicator(
                minHeight: 5,
                color: Colors.orange,
                backgroundColor: Color.fromARGB(255, 255, 224, 178),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Loading...",
              style: TextStyle(color: Color.fromARGB(137, 0, 0, 0)),
            ),

            // SizedBox nhỏ ở cuối để loading không dính sát viền dưới cùng
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
