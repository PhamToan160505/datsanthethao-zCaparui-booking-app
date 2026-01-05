// lib/models/court_model.dart

class CourtModel {
  final String id;
  final String venueId;
  final String name;
  final String type;
  // 💡 pricePerHour đã bị loại bỏ vì giá không cố định

  CourtModel({
    required this.id,
    required this.venueId,
    required this.name,
    required this.type,
    // pricePerHour không còn ở đây
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: json['id'] ?? '',
      venueId: json['venueId'] ?? '',
      name: json['name'] ?? 'Sân không tên',
      type: json['type'] ?? '',
      // Không còn đọc pricePerHour
    );
  }
}
