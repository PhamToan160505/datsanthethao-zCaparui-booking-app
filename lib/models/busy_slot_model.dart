class BusySlotModel {
  final String id;
  final String venueId;
  final String courtId;
  final String dateKey; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String displayName;
  final String status; // confirmed

  /// bookingId:
  /// - Nếu kind == 'booking' => bookingId là id của document booking (admin dùng để mở detail)
  /// - Nếu kind == 'block'   => bookingId có thể là chính id của busy_slot (hoặc để rỗng)
  final String bookingId;

  /// ✅ NEW: phân loại busy slot
  /// 'booking' | 'block'
  final String kind;

  /// ✅ NEW: lý do khóa giờ (chỉ dùng khi kind == 'block')
  final String? note;

  BusySlotModel({
    required this.id,
    required this.venueId,
    required this.courtId,
    required this.dateKey,
    required this.startTime,
    required this.endTime,
    required this.displayName,
    required this.status,
    required this.bookingId,
    this.kind = 'booking',
    this.note,
  });

  factory BusySlotModel.fromJson(Map<String, dynamic> json) {
    return BusySlotModel(
      id: json['id'] ?? '',
      venueId: json['venueId'] ?? '',
      courtId: json['courtId'] ?? '',
      dateKey: json['dateKey'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      displayName: json['displayName'] ?? '',
      status: json['status'] ?? '',
      bookingId: json['bookingId'] ?? '',
      kind: (json['kind'] as String?) ?? 'booking',
      note: json['note'] as String?,
    );
  }
}
