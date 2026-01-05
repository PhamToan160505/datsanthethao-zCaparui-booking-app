import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Nhớ import đúng đường dẫn file service bạn vừa tạo ở Bước 2
import '../services/review_service.dart';

class WriteReviewScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData; // Dữ liệu đơn hàng được truyền sang

  const WriteReviewScreen({super.key, required this.bookingData});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  double _selectedRating = 5.0; // Mặc định chọn 5 sao cho hoành tráng
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false; // Biến để hiện vòng xoay loading khi đang gửi

  // Hàm xử lý khi bấm nút Gửi
  void _handleSubmit() async {
    setState(() => _isLoading = true);

    try {
      final reviewService = ReviewService();

      // Gọi hàm submitReview ở Bước 2
      await reviewService.submitReview(
        venueId: widget.bookingData['venueId'], // Lấy ID sân từ đơn hàng
        bookingId: widget.bookingData['id'], // Lấy ID đơn hàng
        userId: FirebaseAuth
            .instance
            .currentUser!
            .uid, // Lấy ID user đang đăng nhập
        userRating: _selectedRating,
        comment: _commentController.text,
      );

      if (mounted) {
        // Thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cảm ơn bạn đã đánh giá!"),
            backgroundColor: Colors.green,
          ),
        );
        // Quay về màn hình trước và báo tin hiệu "true" (để biết là đã đánh giá xong)
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Nếu có lỗi (ví dụ mất mạng)
      print("Lỗi đánh giá: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Viết đánh giá"),
        backgroundColor: Colors.orange, // Màu cam cho nổi bật
        elevation: 0,
      ),
      body: SingleChildScrollView(
        // Cho phép cuộn nếu bàn phím hiện lên
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Bạn cảm thấy sân thế nào?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Chạm vào sao để chấm điểm",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // --- HÀNG 5 NGÔI SAO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 40,
                  icon: Icon(
                    // Nếu index nhỏ hơn số sao đang chọn thì hiện sao đặc, ngược lại sao rỗng
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 10),
            // Hiển thị chữ tương ứng số sao (Cho chuyên nghiệp)
            Text(
              _getRatingLabel(_selectedRating),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),

            const SizedBox(height: 30),

            // --- Ô NHẬP BÌNH LUẬN ---
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: "Nhận xét của bạn (Tùy chọn)",
                hintText: "Sân đẹp, thoáng mát, chủ sân vui tính...",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4, // Cho phép nhập nhiều dòng
            ),

            const SizedBox(height: 30),

            // --- NÚT GỬI ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _handleSubmit, // Nếu đang load thì khóa nút
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "GỬI ĐÁNH GIÁ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm phụ để hiện chữ khen/chê tùy theo số sao
  String _getRatingLabel(double rating) {
    if (rating >= 5) return "Tuyệt vời! 😍";
    if (rating >= 4) return "Hài lòng 😊";
    if (rating >= 3) return "Bình thường 😐";
    if (rating >= 2) return "Tệ 😞";
    return "Rất tệ 😡";
  }
}
