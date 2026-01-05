// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../../utils/validator.dart';
import 'home_screen.dart';

// --- CẤU HÌNH MÀU SẮC (BLUE & WHITE THEME) ---
// Màu xanh dương tươi sáng (Giống màu sân cầu lông tiêu chuẩn)
const Color _primaryColor = Color(0xFF1E88E5);
// Màu nền phụ (Xanh rất nhạt)
const Color _accentColor = Color(0xFFBBDEFB);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _handleSignUp(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      try {
        final user = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        if (!mounted) return;
        if (mounted) setState(() => _isLoading = false);

        if (user != null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công!'),
              backgroundColor: _primaryColor, // Màu xanh
              behavior: SnackBarBehavior.floating,
            ),
          );
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(isAdmin: false),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        if (mounted) setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Widget ô nhập liệu (Input Field)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
        ), // Màu chữ nhãn nhẹ nhàng
        prefixIcon: Icon(icon, color: _primaryColor), // Icon màu xanh
        filled: true,
        fillColor: Colors.white, // Nền ô nhập liệu màu trắng
        // Viền khi chưa chọn (Màu xanh nhạt)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _accentColor, width: 1),
        ),
        // Viền khi đang nhập (Màu xanh đậm)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        // Viền khi lỗi (Màu đỏ)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ------------------------------------------------
          // LỚP 1: NỀN GRADIENT (TRẮNG -> XANH NHẠT)
          // ------------------------------------------------
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white, // Trên cùng màu trắng
                  Color(0xFFE3F2FD), // Dưới cùng xanh rất nhạt
                ],
              ),
            ),
          ),

          // ------------------------------------------------
          // LỚP 2: HỌA TIẾT TRANG TRÍ
          // ------------------------------------------------
          // Vòng tròn xanh mờ góc trên trái
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Icon vợt góc phải
          Positioned(
            top: size.height * 0.08,
            right: -20,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Icon(
                Icons.sports_tennis,
                size: 140,
                color: _primaryColor.withOpacity(0.1),
              ),
            ),
          ),

          // ------------------------------------------------
          // LỚP 3: NỘI DUNG CHÍNH
          // ------------------------------------------------
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO
                  Image.asset(
                    'assets/logodd.png',
                    width: size.width * 0.4,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 20),

                  // CARD CHỨA FORM (Nền trắng tinh, đổ bóng nhẹ xanh)
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(
                            0.15,
                          ), // Bóng màu xanh nhẹ
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Đăng ký thành viên",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor, // Tiêu đề màu xanh
                            ),
                          ),
                          const SizedBox(height: 25),

                          // CÁC TRƯỜNG NHẬP LIỆU
                          _buildTextField(
                            controller: _nameController,
                            label: 'Họ và Tên',
                            icon: Icons.person,
                            validator: (v) =>
                                AppValidator.validateRequired(v, 'Họ và Tên'),
                          ),
                          const SizedBox(height: 15),

                          _buildTextField(
                            controller: _phoneController,
                            label: 'Số điện thoại',
                            icon: Icons.phone_android,
                            keyboardType: TextInputType.phone,
                            validator: (v) => AppValidator.validateRequired(
                              v,
                              'Số điện thoại',
                            ),
                          ),
                          const SizedBox(height: 15),

                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidator.validateEmail,
                          ),
                          const SizedBox(height: 15),

                          // PASSWORD FIELD RIÊNG (Vì có nút ẩn hiện)
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: _primaryColor,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: _accentColor,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: _primaryColor,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: AppValidator.validatePassword,
                          ),

                          const SizedBox(height: 30),

                          // NÚT ĐĂNG KÝ (Xanh đậm)
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _handleSignUp(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white, // Màu chữ trắng
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: _primaryColor.withOpacity(0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'ĐĂNG KÝ NGAY',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 20),

                          // QUAY LẠI ĐĂNG NHẬP
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Đã có tài khoản? ",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text(
                                  "Đăng nhập",
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
