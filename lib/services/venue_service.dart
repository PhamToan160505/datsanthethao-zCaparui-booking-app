// lib/services/venue_service.dart (Đã được cập nhật)

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/venue_model.dart';

class VenueService {
  final CollectionReference _venueCollection = FirebaseFirestore.instance
      .collection('venues');

  Stream<List<VenueModel>> streamAllVenues() {
    return _venueCollection.snapshots().map((snapshot) {
      // 💡 Thêm <VenueModel> vào .map để đảm bảo kiểu dữ liệu trả về 💡
      return snapshot.docs.map<VenueModel>((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Gán ID của document làm ID của VenueModel
        data['id'] = doc.id;

        // Lỗi 1 được khắc phục nếu Bước 1 đã hoàn tất
        return VenueModel.fromJson(data);
      }).toList();
    });
  }
}
