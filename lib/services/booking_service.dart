// lib/services/booking_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference _bookingCollection = FirebaseFirestore.instance
      .collection('bookings');

  // ===== Helpers =====
  String _toDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day'; // yyyy-MM-dd
  }

  // ===== Tạo Booking mới (có createdAt) =====
  Future<void> createBooking(BookingModel booking) async {
    try {
      final data = booking.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();
      await _bookingCollection.add(data);
    } catch (e) {
      debugPrint('Lỗi khi tạo booking: $e');
      throw Exception('Không thể tạo lịch đặt sân. Vui lòng thử lại.');
    }
  }

  /// ✅ Tạo booking + busy_slot cùng lúc (Lưu ý: courtPrice và rentalPrice sẽ được lưu thông qua toJson)
  Future<String> createBookingAndBusySlot({
    required BookingModel booking,
    required String displayName,
  }) async {
    try {
      final bookingRef = _bookingCollection.doc(); // => bookingRef.id
      final busyRef = _firestore.collection('busy_slots').doc(bookingRef.id);

      final batch = _firestore.batch();

      // 1) bookings (+ createdAt)
      // Vì chúng ta đã cập nhật BookingModel.toJson() để bao gồm courtPrice và rentalPrice,
      // nên bookingData ở đây đã có đầy đủ dữ liệu giá.
      final bookingData = booking.toJson();

      // Ghi đè createdAt bằng serverTimestamp để chính xác giờ server
      bookingData['createdAt'] = FieldValue.serverTimestamp();

      batch.set(bookingRef, bookingData);

      // 2) busy_slots (public read) - Dùng để chặn trùng giờ
      batch.set(busyRef, {
        'bookingId': bookingRef.id,
        'venueId': booking.venueId,
        'courtId': booking.courtId,
        'dateKey': _toDateKey(booking.date),
        'startTime': booking.startTime,
        'endTime': booking.endTime,
        'displayName': displayName,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return bookingRef.id;
    } catch (e) {
      debugPrint('Lỗi khi tạo booking + busy_slot: $e');
      throw Exception('Không thể tạo lịch đặt sân. Vui lòng thử lại.');
    }
  }

  /// Lấy các booking đã đặt trong ngày cho 1 sân (court)
  Stream<List<BookingModel>> streamBookedSlots({
    required String courtId,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _bookingCollection
        .where('courtId', isEqualTo: courtId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return BookingModel.fromJson(data);
          }).toList();
        });
  }

  // ✅ Lịch sử booking theo user: mới nhất lên đầu theo createdAt
  Stream<List<BookingModel>> streamUserBookings(String userId) {
    return _bookingCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true) // ✅ mới nhất lên đầu
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return BookingModel.fromJson(data);
          }).toList();
        });
  }

  /// Admin: stream tất cả booking
  Stream<List<BookingModel>> streamAllBookings() {
    return _bookingCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return BookingModel.fromJson(data);
      }).toList();
    });
  }

  /// Admin: stream booking theo ngày (+ optional venueId)
  Stream<List<BookingModel>> streamBookingsByDate({
    required DateTime date,
    String? venueId,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    Query query = _bookingCollection
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .where('status', isEqualTo: 'confirmed');

    if (venueId != null && venueId.isNotEmpty) {
      query = query.where('venueId', isEqualTo: venueId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return BookingModel.fromJson(data);
      }).toList();
    });
  }

  /// Lấy booking theo ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingCollection.doc(bookingId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return BookingModel.fromJson(data);
    } catch (e) {
      debugPrint('Lỗi getBookingById: $e');
      return null;
    }
  }

  /// ✅ ADMIN: Hủy booking + giải phóng slot (xóa busy_slots/{bookingId})
  Future<void> adminCancelBooking(String bookingId) async {
    final bookingRef = _bookingCollection.doc(bookingId);
    final busyRef = _firestore.collection('busy_slots').doc(bookingId);

    final batch = _firestore.batch();
    batch.update(bookingRef, {
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(busyRef);

    await batch.commit();
  }

  /// ✅ ADMIN: Đổi lịch booking + cập nhật busy_slots/{bookingId}
  Future<void> adminRescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required String newStartTime,
    required String newEndTime,
    required String newCourtId,
    required String newVenueId,
  }) async {
    final bookingRef = _bookingCollection.doc(bookingId);
    final busyRef = _firestore.collection('busy_slots').doc(bookingId);

    // Giữ displayName cũ
    String displayName = 'Đã đặt';
    try {
      final busySnap = await busyRef.get();
      if (busySnap.exists) {
        final data = busySnap.data() as Map<String, dynamic>;
        displayName = (data['displayName'] as String?) ?? displayName;
      }
    } catch (_) {}

    final batch = _firestore.batch();

    // Update booking
    batch.update(bookingRef, {
      'venueId': newVenueId,
      'courtId': newCourtId,
      'date': DateTime(newDate.year, newDate.month, newDate.day),
      'startTime': newStartTime,
      'endTime': newEndTime,
      'status': 'confirmed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update busy_slot (docId = bookingId)
    batch.set(busyRef, {
      'bookingId': bookingId,
      'venueId': newVenueId,
      'courtId': newCourtId,
      'dateKey': _toDateKey(newDate),
      'startTime': newStartTime,
      'endTime': newEndTime,
      'displayName': displayName,
      'status': 'confirmed',
      'kind': 'booking',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
