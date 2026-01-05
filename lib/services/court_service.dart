// lib/services/court_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/court_model.dart';
import '../models/pricing_rule_model.dart';

class CourtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Lấy tất cả sân con (Courts) thuộc về một Venue
  Stream<List<CourtModel>> streamCourtsByVenue(String venueId) {
    return _firestore
        .collection('venues')
        .doc(venueId)
        .collection('courts')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            data['venueId'] = venueId;
            return CourtModel.fromJson(data);
          }).toList();
        });
  }

  // 2. Stream quy định giá của một Sân con
  Stream<List<PricingRuleModel>> streamPricingRules(
    String venueId,
    String courtId,
  ) {
    return _firestore
        .collection('venues')
        .doc(venueId)
        .collection('courts')
        .doc(courtId)
        .collection('pricing_rules')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PricingRuleModel.fromJson(doc.data());
          }).toList();
        });
  }

  // ✅ 3. HÀM MỚI: Lấy danh sách courts 1 lần (Future)
  // Dùng cho AdminBookingsScreen -> dialog Khóa giờ (Dropdown chọn sân)
  Future<List<CourtModel>> getCourtsOnce(String venueId) async {
    final snap = await _firestore
        .collection('venues')
        .doc(venueId)
        .collection('courts')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      data['venueId'] = venueId; // giữ đồng nhất như stream
      return CourtModel.fromJson(data);
    }).toList();
  }
}
