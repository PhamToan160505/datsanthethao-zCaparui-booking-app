class ServiceItem {
  final String id;
  final String name;
  final String type; // 'vot' hoặc 'cau'
  final double price;
  final String imageUrl;
  int quantity; // Số lượng khách chọn

  ServiceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.imageUrl,
    this.quantity = 0,
  });

  // Tính tổng tiền của riêng món này
  double get total => price * quantity;
}
