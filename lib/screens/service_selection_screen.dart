// lib/screens/service_selection_screen.dart

import 'package:flutter/material.dart';
import '../models/service_item_model.dart';
import '../models/booking_model.dart';
import 'booking_confirmation_screen.dart';

// --- THEME COLORS ---
const Color _primaryColor = Color(0xFF1E88E5);
const Color _accentColor = Color(0xFFE3F2FD);
const Color _backgroundColor = Color(0xFFF5F7FA);

class ServiceSelectionScreen extends StatefulWidget {
  final String venueId;
  final String
  venueName; // Nếu chưa có, bạn có thể truyền thêm vào từ màn hình trước
  final String courtId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double courtPrice;

  // Nếu màn hình trước chưa truyền venueName, bạn có thể tạm để optional hoặc fix cứng để test
  // Ở đây mình thêm venueName vào constructor để đầy đủ logic
  const ServiceSelectionScreen({
    super.key,
    required this.venueId,
    this.venueName = "Sân Cầu Lông", // Giá trị mặc định
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.courtPrice,
  });

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  // Danh sách dịch vụ (Giả lập)
  final List<ServiceItem> _services = [
    ServiceItem(
      id: '1',
      name: 'Vợt Yonex Astrox 77',
      type: 'vot',
      price: 50000,
      imageUrl: 'assets/yonex77.png',
    ),
    ServiceItem(
      id: '2',
      name: 'Vợt Lining Calibar 900',
      type: 'vot',
      price: 45000,
      imageUrl: 'assets/linning.png',
    ),
    ServiceItem(
      id: '3',
      name: 'Vợt Kumpoo K520 Pro',
      type: 'vot',
      price: 30000,
      imageUrl: 'assets/kumpo.png',
    ),
    ServiceItem(
      id: '4',
      name: 'Ống Cầu VinaStar (12 trái)',
      type: 'cau',
      price: 210000,
      imageUrl: 'assets/cau.png',
    ),
    ServiceItem(
      id: '5',
      name: 'Trái Cầu Lẻ',
      type: 'cau',
      price: 20000,
      imageUrl: 'assets/traicau.png',
    ),
  ];

  // Tính tổng tiền dịch vụ
  double get _currentServiceTotal {
    double t = 0;
    for (var s in _services) {
      t += s.total;
    }
    return t;
  }

  void _goToConfirmation() {
    final selectedServices = _services.where((s) => s.quantity > 0).toList();

    // Tạo BookingModel tạm thời để chuyển sang màn hình xác nhận
    final tempBooking = BookingModel(
      id: 'temp_id',
      userId: '',
      venueId: widget.venueId,
      // venueName: widget.venueName, // Nếu Model của bạn có trường này thì bỏ comment
      courtId: widget.courtId,
      date: widget.date,
      startTime: widget.startTime,
      endTime: widget.endTime,
      totalPrice: widget.courtPrice, // Giá sân gốc (chưa cộng dịch vụ)
      status: 'pending',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(
          booking: tempBooking,
          selectedServices: selectedServices,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Chọn Dịch Vụ Thêm",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. DANH SÁCH DỊCH VỤ
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                return _buildServiceCard(_services[index]);
              },
            ),
          ),

          // 2. THANH THANH TOÁN (BOTTOM BAR)
          _buildBottomBar(),
        ],
      ),
    );
  }

  // --- WIDGET CARD DỊCH VỤ ---
  Widget _buildServiceCard(ServiceItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Ảnh sản phẩm
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.sports_tennis,
                    color: _primaryColor,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.price.toStringAsFixed(0)}đ / ${item.type == 'vot' ? 'lượt' : 'cái'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Bộ đếm số lượng
            Container(
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  _buildCounterButton(
                    icon: Icons.remove,
                    onTap: () {
                      if (item.quantity > 0) {
                        setState(() => item.quantity--);
                      }
                    },
                    isActive: item.quantity > 0,
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildCounterButton(
                    icon: Icons.add,
                    onTap: () {
                      setState(() => item.quantity++);
                    },
                    isActive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nút tăng/giảm nhỏ
  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: isActive ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? _primaryColor : Colors.grey,
        ),
      ),
    );
  }

  // --- WIDGET BOTTOM BAR ---
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dòng tổng tiền dịch vụ (chỉ hiện khi có chọn)
            if (_currentServiceTotal > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Tổng tiền dịch vụ:",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    Text(
                      "${_currentServiceTotal.toStringAsFixed(0)}đ",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

            // Nút Tiếp tục
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _goToConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: _primaryColor.withOpacity(0.4),
                ),
                child: const Text(
                  "TIẾP TỤC",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
