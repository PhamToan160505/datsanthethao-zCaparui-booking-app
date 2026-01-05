// lib/widgets/venue_card.dart

import 'package:flutter/material.dart';
import '../models/venue_model.dart';

class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onTap;

  const VenueCard({super.key, required this.venue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // ✅ LOGIC 1: XỬ LÝ ĐIỂM ĐÁNH GIÁ
    // Nếu chưa có ai đánh giá (count == 0) -> Hiện 5.0
    // Nếu có rồi -> Hiện điểm thật
    double displayRating = (venue.ratingCount == 0) ? 5.0 : venue.rating;

    // ✅ LOGIC 2: XỬ LÝ ẢNH BÌA
    // Lấy ảnh đầu tiên trong danh sách, nếu không có thì dùng chuỗi rỗng
    String coverImage = venue.imageUrls.isNotEmpty ? venue.imageUrls.first : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ PHẦN HÌNH ẢNH SÂN
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: coverImage.isNotEmpty
                    ? Image.network(
                        coverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Nếu lỗi load ảnh mạng -> Dùng ảnh asset dự phòng
                          return Image.asset(
                            'assets/shuttlecock.png',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/shuttlecock.png', // Ảnh mặc định nếu không có URL
                        fit: BoxFit.cover,
                      ),
              ),
            ),

            // ℹ️ PHẦN THÔNG TIN CHI TIẾT
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tên Sân
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 2. Địa chỉ
                  Text(
                    venue.address,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // 3. Rating và Mô tả ngắn (Đã cập nhật Logic)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),

                      // Hiện điểm số (5.0 hoặc điểm thật)
                      Text(
                        '$displayRating',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Hiện chữ (Mới) hoặc Số lượng đánh giá
                      Text(
                        venue.ratingCount == 0
                            ? "(Mới)"
                            : "(${venue.ratingCount})",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),

                      const Spacer(),

                      // Mô tả ngắn (Giữ nguyên code của bạn)
                      Expanded(
                        child: Text(
                          venue.description,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
