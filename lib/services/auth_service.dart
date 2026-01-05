// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // 2. Đăng nhập
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // 💡 Thay đổi: Ném lỗi cụ thể khi Đăng nhập thất bại
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      throw Exception("Lỗi đăng nhập không xác định.");
    }
  }

  // 3. Đăng ký (Hàm đã được mở rộng để lưu UserModel và ném lỗi)
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // 1. Tạo tài khoản Firebase Authentication
      UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // 2. Tạo đối tượng UserModel
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          phone: phone,
          role: 'user', // Mặc định là 'user'
          avatarUrl: null,
        );

        // 3. Lưu thông tin UserModel vào Firestore collection 'users'
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toJson());
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // 💡 Thay đổi: Ném lỗi cụ thể khi Đăng ký thất bại
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      throw Exception("Lỗi đăng ký không xác định.");
    }
  }

  // 4. Đăng xuất
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // 5. Quên mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // 💡 Hàm tiện ích: Ánh xạ mã lỗi Firebase sang thông báo tiếng Việt
  String _mapFirebaseError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Người dùng không tồn tại.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng. Vui lòng thử email khác.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      default:
        return 'Lỗi: $errorCode. Vui lòng thử lại.';
    }
  }

  // 6. Stream tên người dùng hiện tại (theo dõi document user trong Firestore)
  Stream<String?> streamUserName() {
    // Khi trạng thái auth thay đổi, chuyển sang luồng snapshot document tương ứng
    return authStateChanges.asyncExpand((user) {
      if (user == null) {
        return Stream.value(null);
      }

      return _firestore.collection('users').doc(user.uid).snapshots().map((
        snap,
      ) {
        final data = snap.data();
        if (data == null) return null;
        final name = data['name'];
        return name is String ? name : null;
      });
    });
  }

  // 7. Stream vai trò người dùng hiện tại ('user' | 'admin')
  Stream<String?> streamUserRole() {
    return authStateChanges.asyncExpand((user) {
      if (user == null) return Stream.value(null);

      return _firestore.collection('users').doc(user.uid).snapshots().map((
        snap,
      ) {
        final data = snap.data();
        if (data == null) return null;
        final role = data['role'];
        return role is String ? role : null;
      });
    });
  }
}
