import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String userName; // Tên người mua
  final String userPhone; // Số điện thoại (nếu có)
  final String venueId;
  final String note; // Ví dụ: "Giao tới sân số 2"
  final List<Map<String, dynamic>>
  items; // Danh sách nước: [{name: 'Coca', qty: 2, price: 15000}]
  final double totalPrice;
  final String paymentMethod; // 'cash' hoặc 'qr'
  final String
  status; // 'pending' (chờ), 'confirmed' (đã xác nhận/đang giao), 'completed' (xong)
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone = '',
    required this.venueId,
    required this.note,
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'venueId': venueId,
      'note': note,
      'items': items,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
