// lib/utils/validator.dart

class AppValidator {
  // Regex cho mật khẩu mạnh:
  // - Ít nhất 8 ký tự
  // - Chứa ít nhất 1 chữ cái in hoa [A-Z]
  // - Chứa ít nhất 1 chữ cái thường [a-z]
  // - Chứa ít nhất 1 số [0-9]
  // - Chứa ít nhất 1 ký tự đặc biệt (!@#\$%^&*)
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()]).{8,}$',
  );

  // Regex cho Email hợp lệ
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Hàm kiểm tra Mật khẩu Mạnh
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống.';
    }
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự.';
    }
    if (!_passwordRegex.hasMatch(value)) {
      return 'Mật khẩu phải chứa: 1 in hoa, 1 thường, 1 số, 1 ký tự đặc biệt.';
    }
    return null; // Hợp lệ
  }

  // Hàm kiểm tra Email Hợp lệ
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống.';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ.';
    }
    return null; // Hợp lệ
  }

  // Hàm kiểm tra Tên/SĐT không trống
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập $fieldName.';
    }
    return null;
  }

  // Bạn có thể thêm validatePhone (kiểm tra 10 số,...) ở đây.
}
