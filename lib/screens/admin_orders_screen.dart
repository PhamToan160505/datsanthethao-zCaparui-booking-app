import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart'; // Nếu bạn muốn format ngày giờ đẹp hơn

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  // Hàm cập nhật trạng thái đơn (Xác nhận / Hoàn thành)
  Future<void> _updateStatus(
    String orderId,
    String newStatus,
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': newStatus},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Đã cập nhật: $newStatus")));
      }
    } catch (e) {
      print("Lỗi cập nhật trạng thái: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi cập nhật: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đơn gọi nước"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true) // Đơn mới nhất lên đầu
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Chưa có đơn hàng nào."));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(10), // Thêm padding cho list
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final orderId = docs[index].id;
              final items = List<Map<String, dynamic>>.from(
                data['items'] ?? [],
              );
              final status = data['status'];

              // Màu sắc trạng thái và text hiển thị
              Color statusColor = Colors.orange; // Mặc định là chờ xác nhận
              String statusText = "Chờ xác nhận";

              if (status == 'confirmed') {
                statusColor = Colors.blue;
                statusText = "Đang giao";
              } else if (status == 'completed') {
                statusColor = Colors.green;
                statusText = "Đã giao"; // ✅ Đổi thành "Đã giao"
              }

              return Card(
                elevation: 3, // Thêm bóng đổ nhẹ cho đẹp
                margin: const EdgeInsets.symmetric(vertical: 8), // Margin dọc
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Tên khách + Trạng thái
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            // Để tên không bị tràn nếu quá dài
                            child: Text(
                              data['userName'] ?? 'Khách',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(
                                20,
                              ), // Bo tròn hơn
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "📍 Vị trí: ${data['note']}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),

                      // List đồ uống
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Text(
                                "• ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text("${item['name']} x${item['quantity']}"),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        "💰 Tổng: ${data['totalPrice']} đ  (${data['paymentMethod'] == 'qr' ? 'Chuyển khoản' : 'Tiền mặt'})",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      // --- NÚT HÀNH ĐỘNG (Chỉ hiện khi chưa hoàn thành) ---
                      if (status != 'completed')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Nút XÁC NHẬN (Hiện khi đơn mới - pending)
                            if (status == 'pending')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                onPressed: () => _updateStatus(
                                  orderId,
                                  'confirmed',
                                  context,
                                ),
                                child: const Text(
                                  "Xác nhận & Giao",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),

                            // Nút ĐÃ XONG (Hiện khi đang giao - confirmed)
                            if (status == 'confirmed')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () => _updateStatus(
                                  orderId,
                                  'completed',
                                  context,
                                ),
                                child: const Text(
                                  "Đã xong",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
