// lib/screens/booking_history_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:intl/intl.dart'; // Gợi ý: Nên dùng intl để format tiền tệ/ngày tháng đẹp hơn

// Import models & services
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/booking_display_service.dart';
import '../services/review_service.dart';

// --- MÀU SẮC THEME ---
const Color _primaryColor = Color(0xFF1E88E5);
const Color _backgroundColor = Color(0xFFF5F7FA);

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final BookingService _bookingService = BookingService();
  final BookingDisplayService _displayService = BookingDisplayService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Helper: Chuyển đổi giờ string thành DateTime
  DateTime _getFullDateTime(DateTime date, String endTime) {
    try {
      final parts = endTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  // --- DIALOG ĐÁNH GIÁ ---
  void _showRatingDialog(BookingModel booking) {
    double tempRating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "Đánh giá sân",
            style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setLocalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Trải nghiệm của bạn thế nào?",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                // Sao đánh giá
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < tempRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () =>
                          setLocalState(() => tempRating = index + 1.0),
                    );
                  }),
                ),
                const SizedBox(height: 15),
                // Ô nhập bình luận
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: "Nhận xét...",
                    hintText: "Sân sạch, đèn sáng...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: _primaryColor),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _submitReview(booking, tempRating, commentController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Gửi đánh giá",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Logic gửi đánh giá
  Future<void> _submitReview(
    BookingModel booking,
    double rating,
    String comment,
  ) async {
    try {
      // 1. Update Firestore trực tiếp (Logic cũ của bạn)
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({
            'rating': rating,
            'reviewComment': comment,
            'reviewTime': FieldValue.serverTimestamp(),
          });

      // 2. Gọi Service tính điểm trung bình (Nếu có)
      final reviewService = ReviewService();
      await reviewService.submitReview(
        venueId: booking.venueId,
        bookingId: booking.id,
        userId: _currentUserId!,
        userRating: rating,
        comment: comment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đánh giá thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      backgroundColor: _backgroundColor, // Nền xám nhạt
      appBar: AppBar(
        title: const Text(
          "Lịch sử đặt sân",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _bookingService.streamUserBookings(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          // Sắp xếp: Mới nhất lên đầu
          bookings.sort((a, b) {
            final dtA = _getFullDateTime(a.date, a.startTime);
            final dtB = _getFullDateTime(b.date, b.startTime);
            return dtB.compareTo(dtA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(bookings[index]);
            },
          );
        },
      ),
    );
  }

  // --- WIDGET CARD LỊCH SỬ ---
  Widget _buildHistoryCard(BookingModel booking) {
    final endDateTime = _getFullDateTime(booking.date, booking.endTime);
    final isFinished = DateTime.now().isAfter(endDateTime);
    final hasReviewed = booking.rating != null; // Kiểm tra đã đánh giá chưa

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Tên sân + Trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FutureBuilder<String>(
                    future: _displayService.getVenueName(booking.venueId),
                    builder: (ctx, snap) {
                      return Text(
                        snap.data ?? 'Đang tải tên sân...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                _buildStatusChip(isFinished),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),

            // 2. Thông tin chi tiết
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${booking.date.day}/${booking.date.month}/${booking.date.year}',
                  style: const TextStyle(color: Colors.black87),
                ),
                const Spacer(),
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${booking.startTime} - ${booking.endTime}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  size: 18,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  '${booking.totalPrice.toStringAsFixed(0)} đ', // Nên format currency
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            // 3. Phần Đánh giá
            const SizedBox(height: 16),
            if (!isFinished)
              // Chưa đá xong
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    "Đang chờ đến giờ thi đấu...",
                    style: TextStyle(
                      color: _primaryColor,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else if (!hasReviewed)
              // Đá xong, chưa review
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(booking),
                  icon: const Icon(
                    Icons.star_rate_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Viết đánh giá",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Nổi bật
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              )
            else
              // Đã review
              _buildReviewContent(booking),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị nội dung đánh giá
  Widget _buildReviewContent(BookingModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Màu vàng nhạt cho review
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Đánh giá của bạn:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < (booking.rating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (booking.reviewComment != null &&
              booking.reviewComment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              "\"${booking.reviewComment}\"",
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ],

          // Admin phản hồi
          if (booking.adminReply != null && booking.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(left: 10),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: _primaryColor, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Chủ sân phản hồi:",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  Text(
                    booking.adminReply!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Chip trạng thái
  Widget _buildStatusChip(bool isFinished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isFinished ? Colors.grey[200] : Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFinished ? Colors.grey[300]! : Colors.green[200]!,
        ),
      ),
      child: Text(
        isFinished ? "Đã xong" : "Sắp đến giờ",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isFinished ? Colors.grey[600] : Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            "Bạn chưa có lịch đặt sân nào.",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
