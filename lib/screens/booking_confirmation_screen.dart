// lib/screens/booking_confirmation_screen.dart

import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/service_item_model.dart';
import '../services/booking_display_service.dart';
import 'payment_screen.dart';

// --- THEME COLORS ---
const Color _primaryColor = Color(0xFF1E88E5);
const Color _accentColor = Color(0xFFE3F2FD);
const Color _backgroundColor = Color(0xFFF5F7FA);

class BookingConfirmationScreen extends StatefulWidget {
  final BookingModel booking;
  final List<ServiceItem> selectedServices;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    this.selectedServices = const [],
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final BookingDisplayService _displayService = BookingDisplayService();
  String _venueName = 'Đang tải...';
  String _courtName = 'Đang tải...';

  // Tính tổng tiền dịch vụ (Vợt, nước...)
  double get serviceTotal {
    double total = 0;
    for (var item in widget.selectedServices) {
      total += item.total;
    }
    return total;
  }

  // Tính tổng tiền cuối cùng (Sân + Dịch vụ)
  double get finalTotalPrice => widget.booking.totalPrice + serviceTotal;

  @override
  void initState() {
    super.initState();
    _fetchDisplayNames();
  }

  Future<void> _fetchDisplayNames() async {
    final vName = await _displayService.getVenueName(widget.booking.venueId);
    final cName = await _displayService.getCourtName(
      widget.booking.venueId,
      widget.booking.courtId,
    );
    if (mounted) {
      setState(() {
        _venueName = vName;
        _courtName = cName;
      });
    }
  }

  // Format tiền tệ
  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  // ✅ LOGIC QUAN TRỌNG: TÁCH TIỀN VÀ CẬP NHẬT MODEL
  void _handleConfirmBooking() {
    // 1. Xác định rõ các loại tiền
    double priceOfCourt =
        widget.booking.totalPrice; // Giá sân gốc (từ màn hình trước)
    double priceOfServices = serviceTotal; // Giá dịch vụ (tính ở màn hình này)
    double priceTotalFinal = priceOfCourt + priceOfServices; // Tổng cộng

    // 2. Tạo BookingModel mới chứa đầy đủ thông tin giá tách biệt
    // (Sử dụng hàm copyWith mới tạo ở bước trước)
    BookingModel updatedBooking = widget.booking.copyWith(
      courtPrice: priceOfCourt, // Lưu tiền sân riêng
      rentalPrice: priceOfServices, // Lưu tiền dịch vụ riêng
      totalPrice: priceTotalFinal, // Lưu tổng tiền
    );

    // 3. Chuyển sang màn hình thanh toán
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          venueName: _venueName,
          date:
              '${widget.booking.date.day}/${widget.booking.date.month}/${widget.booking.date.year}',
          time: '${widget.booking.startTime} - ${widget.booking.endTime}',
          totalPrice: priceTotalFinal,

          // ✅ Truyền Model đã được cập nhật giá
          bookingModel: updatedBooking,
          // selectedServices: widget.selectedServices, // Có thể truyền nếu PaymentScreen cần hiển thị list
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
          "Xác nhận đặt sân",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- CARD HÓA ĐƠN ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. Header Hóa đơn
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "CHI TIẾT ĐƠN HÀNG",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatCurrency(finalTotalPrice),
                          style: const TextStyle(
                            color: _primaryColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Thông tin Sân
                        _buildSectionTitle("Thông tin sân"),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.stadium, "Sân:", _venueName),
                        _buildInfoRow(Icons.numbers, "Vị trí:", _courtName),
                        _buildInfoRow(
                          Icons.calendar_today,
                          "Ngày:",
                          '${widget.booking.date.day}/${widget.booking.date.month}/${widget.booking.date.year}',
                        ),
                        _buildInfoRow(
                          Icons.access_time,
                          "Giờ:",
                          '${widget.booking.startTime} - ${widget.booking.endTime}',
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Divider(thickness: 1, color: Colors.grey),
                        ),

                        // 3. Chi tiết thanh toán (Tách rõ ràng)
                        _buildSectionTitle("Chi tiết thanh toán"),
                        const SizedBox(height: 10),

                        // Giá sân
                        _buildPriceRow(
                          "Giá thuê sân",
                          widget.booking.totalPrice,
                        ),

                        // Dịch vụ thêm (nếu có)
                        if (widget.selectedServices.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            "Dịch vụ thêm:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          ...widget.selectedServices.map(
                            (s) => _buildPriceRow(
                              "  - ${s.name} (x${s.quantity})",
                              s.total,
                              isSubItem: true,
                            ),
                          ),
                        ],

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Divider(thickness: 1),
                        ),

                        // 4. Tổng cộng
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Thành tiền",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatCurrency(finalTotalPrice),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- NÚT XÁC NHẬN ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _venueName == 'Đang tải...'
                    ? null
                    : _handleConfirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: _primaryColor.withOpacity(0.4),
                ),
                child: const Text(
                  "XÁC NHẬN & THANH TOÁN",
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

  // Widget tiêu đề section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  // Widget dòng thông tin có Icon
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primaryColor),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Widget dòng giá tiền
  Widget _buildPriceRow(String label, double price, {bool isSubItem = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSubItem ? 13 : 15,
              color: isSubItem ? Colors.grey[700] : Colors.black87,
            ),
          ),
          Text(
            _formatCurrency(price),
            style: TextStyle(
              fontSize: isSubItem ? 13 : 15,
              fontWeight: isSubItem ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
