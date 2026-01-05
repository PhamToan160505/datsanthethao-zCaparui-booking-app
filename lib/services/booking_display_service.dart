// lib/services/booking_display_service.dart (Thêm logic lấy thông tin người dùng)

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDisplayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm tra cứu tên Venue từ ID
  Future<String> getVenueName(String venueId) async {
    // ... (logic giữ nguyên)
    try {
      final doc = await _firestore.collection('venues').doc(venueId).get();
      return doc.get('name') ?? 'Không xác định';
    } catch (_) {
      return 'Lỗi tải tên Venue';
    }
  }

  // Hàm tra cứu tên Court từ ID
  Future<String> getCourtName(String venueId, String courtId) async {
    // ... (logic giữ nguyên)
    try {
      final doc = await _firestore
          .collection('venues')
          .doc(venueId)
          .collection('courts')
          .doc(courtId)
          .get();
      return doc.get('name') ?? 'Không xác định';
    } catch (_) {
      return 'Lỗi tải tên Sân';
    }
  }

  // 💡 HÀM MỚI: Tra cứu Tên và SĐT người dùng từ UID 💡
  Future<Map<String, String>> getUserDetails(String userId) async {
    try {
      // Truy vấn Document trong Collection 'users'
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return {'name': 'Người dùng bị xóa', 'phone': 'N/A'};
      }

      final data = doc.data();
      return {
        'name': data?['name'] ?? 'Chưa cập nhật Tên',
        'phone': data?['phone'] ?? 'Chưa cập nhật SĐT',
      };
    } catch (_) {
      return {'name': 'Lỗi tải', 'phone': 'Lỗi tải'};
    }
  }
}
