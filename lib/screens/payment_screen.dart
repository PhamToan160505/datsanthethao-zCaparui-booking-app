// lib/screens/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/service_item_model.dart';
import '../services/booking_service.dart';

// --- THEME COLORS ---
const Color _primaryColor = Color(0xFF1E88E5);
const Color _accentColor = Color(0xFFE3F2FD);
const Color _backgroundColor = Color(0xFFF5F7FA);

class PaymentScreen extends StatefulWidget {
  final BookingModel bookingModel;
  final String venueName;
  final String date;
  final String time;
  final double totalPrice;
  final List<ServiceItem> selectedServices;

  const PaymentScreen({
    Key? key,
    required this.bookingModel,
    required this.venueName,
    required this.date,
    required this.time,
    required this.totalPrice,
    this.selectedServices = const [],
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 1; // 1: QR, 0: Tiền mặt
  final BookingService _bookingService = BookingService();
  bool _isProcessing = false;

  // Format tiền tệ
  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Thanh Toán",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TÓM TẮT ĐƠN HÀNG (CARD HÓA ĐƠN)
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  _buildInfoRow(Icons.stadium, "Sân:", widget.venueName),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    "Thời gian:",
                    "${widget.date} | ${widget.time}",
                  ),

                  if (widget.selectedServices.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Dịch vụ thêm:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.selectedServices.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "- ${s.name} (x${s.quantity})",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              _formatCurrency(s.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const Divider(height: 30, thickness: 1.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TỔNG CỘNG:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatCurrency(widget.totalPrice),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 2. CHỌN PHƯƠNG THỨC THANH TOÁN
            const Text(
              "Phương thức thanh toán",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _buildPaymentOption(
              index: 1,
              icon: Icons.qr_code_scanner,
              title: "Chuyển khoản QR",
              subtitle: "Quét mã VietQR để thanh toán ngay",
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              index: 0,
              icon: Icons.money,
              title: "Tiền mặt tại sân",
              subtitle: "Thanh toán trực tiếp khi check-in",
            ),

            // 3. HIỂN THỊ MÃ QR (NẾU CHỌN QR)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _selectedMethod == 1
                  ? Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Logo Ngân hàng (Giả lập)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance, color: _primaryColor),
                              const SizedBox(width: 8),
                              const Text(
                                "VietinBank",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          // Ảnh QR
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/qrcode.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.qr_code_2,
                                    size: 150,
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Thông tin TK
                          const Text(
                            "PHAM NGUYEN BAO TOAN",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "STK: 108873448328",
                            style: TextStyle(fontSize: 15, letterSpacing: 1),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Nội dung: Tên + SĐT",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 40), // Khoảng trống cuối cùng
          ],
        ),
      ),

      // BUTTON THANH TOÁN
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handlePaymentAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _selectedMethod == 1
                        ? "ĐÃ CHUYỂN KHOẢN XONG"
                        : "XÁC NHẬN ĐẶT SÂN",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // --- Widget Con ---
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? _primaryColor : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? _primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _primaryColor, size: 28),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePaymentAndSave() async {
    setState(() => _isProcessing = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Vui lòng đăng nhập lại.');

      // Lấy tên User
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final displayName =
          (userDoc.data()?['name'] as String?)?.trim() ?? 'Khách';

      // Trạng thái thanh toán
      String statusPay = _selectedMethod == 1 ? 'pending' : 'unpaid';

      // Chuẩn bị dữ liệu dịch vụ
      List<Map<String, dynamic>> servicesToSave = widget.selectedServices
          .map(
            (s) => {
              'name': s.name,
              'quantity': s.quantity,
              'price': s.price,
              'total': s.total,
            },
          )
          .toList();

      // Model cuối cùng
      final finalBooking = BookingModel(
        id: '',
        userId: currentUser.uid,
        venueId: widget.bookingModel.venueId,
        courtId: widget.bookingModel.courtId,
        date: widget.bookingModel.date,
        startTime: widget.bookingModel.startTime,
        endTime: widget.bookingModel.endTime,
        totalPrice: widget.totalPrice,
        status: 'confirmed',
        paymentStatus: statusPay,
        services: servicesToSave,
      );

      // Lưu Firebase
      await _bookingService.createBookingAndBusySlot(
        booking: finalBooking,
        displayName: displayName,
      );

      if (!mounted) return;

      // Thông báo thành công
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                "Đặt Sân Thành Công!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _selectedMethod == 0
                    ? "Vui lòng thanh toán tại quầy khi đến sân."
                    : "Cảm ơn bạn đã thanh toán. Admin sẽ duyệt đơn sớm.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                child: const Text(
                  "Về Trang Chủ",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
