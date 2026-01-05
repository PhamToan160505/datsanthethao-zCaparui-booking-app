import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm này sẽ được gọi khi người dùng bấm nút "Gửi đánh giá"
  Future<void> submitReview({
    required String venueId, // ID của sân (để biết cập nhật sân nào)
    required String bookingId, // ID đơn hàng (để đánh dấu là đã review xong)
    required String userId, // ID người dùng đang đánh giá
    required double userRating, // Số sao khách chấm (Ví dụ: 4.0, 5.0)
    required String comment, // Lời nhắn
  }) async {
    // Tạo các tham chiếu đến đúng vị trí trên Firebase
    final venueRef = _firestore.collection('venues').doc(venueId);
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final reviewRef = _firestore
        .collection('reviews')
        .doc(); // Tự tạo ID mới cho bài review

    // Dùng Transaction (Giao dịch) để đảm bảo an toàn tuyệt đối khi tính toán
    // Nghĩa là: Trong lúc đang tính, không ai được chen ngang sửa dữ liệu
    await _firestore.runTransaction((transaction) async {
      // BƯỚC A: Lấy dữ liệu hiện tại của sân về
      final venueSnapshot = await transaction.get(venueRef);
      if (!venueSnapshot.exists) {
        throw Exception("Lỗi: Không tìm thấy sân này trên hệ thống!");
      }

      final data = venueSnapshot.data() as Map<String, dynamic>;

      // Lấy điểm cũ và số lượng người cũ (nếu null thì coi là 0)
      double currentRating = (data['rating'] ?? 0).toDouble();
      int currentCount = (data['ratingCount'] ?? 0).toInt();

      // BƯỚC B: TÍNH TOÁN ĐIỂM SỐ MỚI (Logic quan trọng nhất)
      double newRating;

      if (currentCount == 0) {
        // TRƯỜNG HỢP 1: Đây là người đầu tiên đánh giá
        // Thì điểm trung bình chính là điểm người này chấm luôn
        newRating = userRating;
      } else {
        // TRƯỜNG HỢP 2: Đã có người đánh giá trước đó
        // Công thức: ((Điểm cũ * Số người cũ) + Điểm mới) / (Số người cũ + 1)
        // Ví dụ: Đang có 10 người đánh 4.5 sao. Người thứ 11 đánh 2 sao.
        // ((4.5 * 10) + 2) / 11 = 4.27...
        newRating =
            ((currentRating * currentCount) + userRating) / (currentCount + 1);
      }

      // Làm tròn 1 chữ số thập phân cho đẹp (Ví dụ: 4.2727... -> 4.3)
      newRating = double.parse(newRating.toStringAsFixed(1));

      // BƯỚC C: CẬP NHẬT LÊN FIREBASE

      // 1. Cập nhật Sân (Điểm mới + Tăng số lượng người lên 1)
      transaction.update(venueRef, {
        'rating': newRating,
        'ratingCount': currentCount + 1,
      });

      // 2. Lưu bài review chi tiết vào lịch sử (để Admin đọc)
      transaction.set(reviewRef, {
        'venueId': venueId,
        'userId': userId,
        'bookingId': bookingId,
        'rating': userRating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(), // Lấy giờ server
      });

      // 3. Đánh dấu đơn hàng này là "Đã đánh giá" (để không cho đánh lại)
      transaction.update(bookingRef, {'isReviewed': true});
    });
  }
}
