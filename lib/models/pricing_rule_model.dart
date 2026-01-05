// lib/models/pricing_rule_model.dart

class PricingRuleModel {
  final String startTime;
  final String endTime;
  final double price; // Giá (80000.0, 100000.0)

  PricingRuleModel({
    required this.startTime,
    required this.endTime,
    required this.price,
  });

  factory PricingRuleModel.fromJson(Map<String, dynamic> json) {
    return PricingRuleModel(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      // Quan trọng: Ép kiểu sang double vì chúng ta lưu là number
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
