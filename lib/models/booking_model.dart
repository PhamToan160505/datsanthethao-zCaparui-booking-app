// lib/models/booking_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String venueId;
  final String courtId;
  final DateTime date;
  final String startTime;
  final String endTime;

  // --- NHÓM GIÁ TIỀN (QUAN TRỌNG) ---
  final double totalPrice; // Tổng cộng
  final double courtPrice; // Giá sân (MỚI)
  final double rentalPrice; // Giá dịch vụ (MỚI)

  final String status;
  final String paymentStatus;
  final DateTime? createdAt;
  final List<dynamic> services;

  // --- NHÓM ĐÁNH GIÁ (REVIEW) ---
  final double? rating;
  final String? reviewComment;
  final DateTime? reviewTime;
  final String? adminReply;
  final DateTime? adminReplyTime;

  BookingModel({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    // ✅ Thêm giá trị mặc định cho 2 trường mới để tránh lỗi
    this.courtPrice = 0.0,
    this.rentalPrice = 0.0,

    this.createdAt,
    this.paymentStatus = 'unpaid',
    this.services = const [],
    this.rating,
    this.reviewComment,
    this.reviewTime,
    this.adminReply,
    this.adminReplyTime,
  });

  // ✅ HÀM COPYWITH: Giúp cập nhật model dễ dàng
  BookingModel copyWith({
    String? id,
    String? userId,
    String? venueId,
    String? courtId,
    DateTime? date,
    String? startTime,
    String? endTime,
    double? totalPrice,
    double? courtPrice, // Mới
    double? rentalPrice, // Mới
    String? status,
    String? paymentStatus,
    DateTime? createdAt,
    List<dynamic>? services,
    double? rating,
    String? reviewComment,
    DateTime? reviewTime,
    String? adminReply,
    DateTime? adminReplyTime,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      venueId: venueId ?? this.venueId,
      courtId: courtId ?? this.courtId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPrice: totalPrice ?? this.totalPrice,
      // Cập nhật 2 trường giá mới
      courtPrice: courtPrice ?? this.courtPrice,
      rentalPrice: rentalPrice ?? this.rentalPrice,

      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      services: services ?? this.services,
      rating: rating ?? this.rating,
      reviewComment: reviewComment ?? this.reviewComment,
      reviewTime: reviewTime ?? this.reviewTime,
      adminReply: adminReply ?? this.adminReply,
      adminReplyTime: adminReplyTime ?? this.adminReplyTime,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // 1. Xử lý ngày tháng (date)
    final rawDate = json['date'];
    DateTime parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    // 2. Xử lý ngày tạo (createdAt)
    final rawCreatedAt = json['createdAt'];
    DateTime? parsedCreatedAt;
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    }

    // 3. Xử lý thời gian đánh giá
    final rawReviewTime = json['reviewTime'];
    DateTime? parsedReviewTime;
    if (rawReviewTime is Timestamp) {
      parsedReviewTime = rawReviewTime.toDate();
    } else if (rawReviewTime is DateTime) {
      parsedReviewTime = rawReviewTime;
    }

    // 4. Xử lý thời gian phản hồi
    final rawReplyTime = json['adminReplyTime'];
    DateTime? parsedReplyTime;
    if (rawReplyTime is Timestamp) {
      parsedReplyTime = rawReplyTime.toDate();
    } else if (rawReplyTime is DateTime) {
      parsedReplyTime = rawReplyTime;
    }

    return BookingModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      venueId: json['venueId'] ?? '',
      courtId: json['courtId'] ?? '',
      date: parsedDate,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',

      // ✅ Xử lý số liệu giá tiền an toàn (tránh lỗi int/double)
      totalPrice: (json['totalPrice'] is num)
          ? (json['totalPrice'] as num).toDouble()
          : 0.0,
      courtPrice: (json['courtPrice'] is num)
          ? (json['courtPrice'] as num).toDouble()
          : 0.0, // Mới
      rentalPrice: (json['rentalPrice'] is num)
          ? (json['rentalPrice'] as num).toDouble()
          : 0.0, // Mới

      status: json['status'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      createdAt: parsedCreatedAt,
      services: json['services'] ?? [],

      // Mapping đánh giá
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : null,
      reviewComment: json['reviewComment'],
      reviewTime: parsedReviewTime,
      adminReply: json['adminReply'],
      adminReplyTime: parsedReplyTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'venueId': venueId,
      'courtId': courtId,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,

      // ✅ Lưu đầy đủ 3 loại giá lên Firebase
      'totalPrice': totalPrice,
      'courtPrice': courtPrice,
      'rentalPrice': rentalPrice,

      'status': status,
      'paymentStatus': paymentStatus,
      'services': services,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,

      // Lưu đánh giá
      'rating': rating,
      'reviewComment': reviewComment,
      'reviewTime': reviewTime != null ? Timestamp.fromDate(reviewTime!) : null,
      'adminReply': adminReply,
      'adminReplyTime': adminReplyTime != null
          ? Timestamp.fromDate(adminReplyTime!)
          : null,
    };
  }
}
