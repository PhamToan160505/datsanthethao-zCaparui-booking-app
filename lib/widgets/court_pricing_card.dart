import 'package:flutter/material.dart';
import '../models/court_model.dart';
import '../models/pricing_rule_model.dart';
import '../services/court_service.dart';

class CourtPricingCard extends StatelessWidget {
  final String venueId;
  final CourtModel court;

  const CourtPricingCard({
    super.key,
    required this.venueId,
    required this.court,
  });

  @override
  Widget build(BuildContext context) {
    final CourtService courtService = CourtService();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên và Loại Sân
            Text(
              '${court.name} (${court.type})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'Giá thuê theo khung giờ:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),

            // 💡 STREAMBUILDER LẤY CÁC QUY TẮC GIÁ CỦA SÂN CON NÀY 💡
            StreamBuilder<List<PricingRuleModel>>(
              stream: courtService.streamPricingRules(venueId, court.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Lỗi giá: ${snapshot.error}');
                }

                final rules = snapshot.data;
                if (rules == null || rules.isEmpty) {
                  return const Text('Chưa có quy tắc giá.');
                }

                // Sắp xếp Rules theo startTime để hiển thị thứ tự (05:00 trước 17:00)
                rules.sort((a, b) => a.startTime.compareTo(b.startTime));

                return Column(
                  children: rules.map((rule) {
                    // Định dạng giá thành 80.000đ
                    final priceFormatted =
                        '${(rule.price / 1000).toStringAsFixed(0)}.000đ';

                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text('${rule.startTime} - ${rule.endTime}:'),
                          const Spacer(),
                          Text(
                            priceFormatted,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
