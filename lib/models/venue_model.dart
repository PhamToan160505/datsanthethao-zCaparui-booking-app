// lib/models/venue_model.dart

class VenueModel {
  final String id;
  final String name;
  final String address;
  final String description;
  final double rating;
  final List<String> imageUrls;
  // ✅ THÊM TRƯỜNG NÀY: Để đếm số lượng đánh giá
  final int ratingCount;

  VenueModel({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.rating,
    required this.imageUrls,
    // ✅ THÊM VÀO CONSTRUCTOR (Mặc định là 0)
    this.ratingCount = 0,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    // 1. Xử lý rating (Code của bạn)
    final ratingValue = json['rating'];
    final double parsedRating = ratingValue is num
        ? ratingValue.toDouble()
        : 0.0;

    // 2. Xử lý imageUrls (Code của bạn)
    final List<String> imageUrlsList =
        (json['imageUrls'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        [];

    // ✅ 3. Xử lý ratingCount (MỚI THÊM)
    // Lấy số lượng đánh giá từ Firebase, nếu null thì bằng 0
    final countValue = json['ratingCount'];
    final int parsedCount = countValue is num ? countValue.toInt() : 0;

    return VenueModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Chưa xác định',
      address: json['address'] ?? '',
      description: json['description'] ?? '',
      rating: parsedRating,
      imageUrls: imageUrlsList,
      // ✅ Gán giá trị ratingCount
      ratingCount: parsedCount,
    );
  }

  // Getter phụ trợ: Lấy ảnh đầu tiên làm ảnh đại diện (để tránh lỗi nếu UI cũ dùng .image)
  String get image => imageUrls.isNotEmpty ? imageUrls.first : '';
}
