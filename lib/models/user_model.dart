class UserModel {
  // ID người dùng, thường dùng UID của Firebase Authentication
  final String uid;
  final String email;
  final String name;
  final String phone;
  // Vai trò: 'user' (người đặt sân) hoặc 'admin' (chủ sân/quản lý)
  final String role;
  final String? avatarUrl; // Ảnh đại diện, có thể có hoặc không

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    this.role = 'user', // Mặc định là 'user'
    this.avatarUrl,
  });

  // *Quan trọng:* Chuyển từ JSON/Map (từ Firestore) sang đối tượng Dart
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      avatarUrl: json['avatarUrl'],
    );
  }

  // *Quan trọng:* Chuyển từ đối tượng Dart sang JSON/Map (để lưu vào Firestore)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'avatarUrl': avatarUrl,
    };
  }
}
