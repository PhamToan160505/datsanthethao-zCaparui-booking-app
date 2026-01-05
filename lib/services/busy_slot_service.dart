import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/busy_slot_model.dart';

class BusySlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _toDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day'; // yyyy-MM-dd
  }

  Stream<List<BusySlotModel>> streamBusySlots({
    required String venueId,
    required String courtId,
    required DateTime date,
  }) {
    final dateKey = _toDateKey(date);

    return _firestore
        .collection('busy_slots')
        .where('venueId', isEqualTo: venueId)
        .where('courtId', isEqualTo: courtId)
        .where('dateKey', isEqualTo: dateKey)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return BusySlotModel.fromJson(data);
          }).toList();
        });
  }

  /// ✅ NEW: Admin khóa giờ (block time)
  /// - tạo 1 doc trong busy_slots (Auto ID)
  /// - kind='block'
  /// - bookingId = doc.id (để đồng nhất field)
  Future<void> createBlockSlot({
    required String venueId,
    required String courtId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    final ref = _firestore.collection('busy_slots').doc();

    await ref.set({
      'bookingId': ref.id,
      'venueId': venueId,
      'courtId': courtId,
      'dateKey': _toDateKey(date),
      'startTime': startTime,
      'endTime': endTime,
      'displayName': 'Đã khóa',
      'status': 'confirmed',
      'kind': 'block',
      'note': (note == null || note.trim().isEmpty) ? 'Bảo trì/giải đấu' : note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ NEW: Admin mở khóa (xóa doc busy_slots)
  Future<void> deleteBusySlot(String busyId) async {
    await _firestore.collection('busy_slots').doc(busyId).delete();
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return h * 60 + m;
  }

  bool _overlap(String aStart, String aEnd, String bStart, String bEnd) {
    final as = _toMinutes(aStart);
    final ae = _toMinutes(aEnd);
    final bs = _toMinutes(bStart);
    final be = _toMinutes(bEnd);
    return as < be && ae > bs;
  }

  /// ✅ ADMIN: check khung giờ có bị trùng không (bỏ qua chính booking đang sửa)
  Future<bool> hasConflict({
    required String venueId,
    required String courtId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? ignoreBookingId,
  }) async {
    final dateKey = _toDateKey(date);

    final snap = await _firestore
        .collection('busy_slots')
        .where('venueId', isEqualTo: venueId)
        .where('courtId', isEqualTo: courtId)
        .where('dateKey', isEqualTo: dateKey)
        .where('status', isEqualTo: 'confirmed')
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final bookingId = (data['bookingId'] as String?) ?? doc.id;

      if (ignoreBookingId != null && bookingId == ignoreBookingId) continue;

      final s = (data['startTime'] as String?) ?? '';
      final e = (data['endTime'] as String?) ?? '';
      if (s.isEmpty || e.isEmpty) continue;

      if (_overlap(startTime, endTime, s, e)) return true;
    }

    return false;
  }
}
