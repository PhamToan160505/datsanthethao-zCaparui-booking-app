import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../services/booking_display_service.dart';

class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({super.key});

  // Hàm hiển thị dialog phản hồi (Giữ nguyên của bạn)
  void _showReplyDialog(BuildContext context, BookingModel booking) {
    final replyController = TextEditingController(
      text: booking.adminReply ?? "",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Phản hồi đánh giá"),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(
            labelText: "Nội dung phản hồi...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(booking.id)
                  .update({
                    'adminReply': replyController.text,
                    'adminReplyTime': FieldValue.serverTimestamp(),
                  });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã gửi phản hồi!")),
                );
              }
            },
            child: const Text("Gửi"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BookingDisplayService displayService = BookingDisplayService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đánh giá từ khách hàng"),
        backgroundColor: const Color.fromARGB(255, 128, 203, 244),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lấy tất cả các booking CÓ đánh giá (rating > 0)
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('rating', isGreaterThan: 0)
            .orderBy(
              'rating',
            ) // Firestore bắt buộc order theo field where trước
            .orderBy(
              'reviewTime',
              descending: true,
            ) // Sau đó mới order thời gian
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Chưa có đánh giá nào."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              // Parse booking model
              final booking = BookingModel.fromJson(
                data..['id'] = docs[index].id,
              );

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER: Tên khách + Số sao ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FutureBuilder<Map<String, String>>(
                            future: displayService.getUserDetails(
                              booking.userId,
                            ),
                            builder: (c, s) => Text(
                              s.data?['name'] ?? "Khách hàng",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < (booking.rating ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ✅ [PHẦN MỚI THÊM] HIỂN THỊ TÊN SÂN CỤ THỂ
                      FutureBuilder<DocumentSnapshot>(
                        // Tìm trong collection venues theo venueId của booking
                        future: FirebaseFirestore.instance
                            .collection('venues')
                            .doc(booking.venueId)
                            .get(),
                        builder: (context, venueSnap) {
                          if (venueSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              "Đang tải tên sân...",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            );
                          }

                          String venueName = "Sân không xác định";
                          if (venueSnap.hasData && venueSnap.data!.exists) {
                            final venueData =
                                venueSnap.data!.data() as Map<String, dynamic>;
                            venueName =
                                venueData['name'] ?? "Sân không xác định";
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stadium_outlined,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    venueName,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // ✅ [KẾT THÚC PHẦN MỚI]
                      const SizedBox(height: 8),

                      // Nội dung review
                      Text(
                        booking.reviewComment ?? "Không có lời bình.",
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Ngày chơi: ${booking.date.day}/${booking.date.month}/${booking.date.year}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),

                      const Divider(),

                      // Phần phản hồi của Admin
                      if (booking.adminReply != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Bạn đã trả lời:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(booking.adminReply!),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),
                      // Nút trả lời
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _showReplyDialog(context, booking),
                          icon: const Icon(Icons.reply),
                          label: Text(
                            booking.adminReply == null
                                ? "Trả lời"
                                : "Sửa câu trả lời",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
