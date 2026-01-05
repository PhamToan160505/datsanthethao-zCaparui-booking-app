// lib/screens/drink_shop_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_order_history_screen.dart';

// --- THEME COLORS ---
const Color _primaryColor = Color(0xFF1E88E5);
const Color _accentColor = Color(0xFFE3F2FD);
const Color _backgroundColor = Color(0xFFF5F7FA);

class DrinkShopScreen extends StatefulWidget {
  final String venueId;
  const DrinkShopScreen({super.key, required this.venueId});

  @override
  State<DrinkShopScreen> createState() => _DrinkShopScreenState();
}

class _DrinkShopScreenState extends State<DrinkShopScreen> {
  // Danh sách nước (Giả lập)
  final List<Map<String, dynamic>> products = [
    {'name': 'Nước Suối Aquafina', 'price': 10000, 'image': 'assets/suoi.png'},
    {'name': 'Coca Cola', 'price': 15000, 'image': 'assets/coca.png'},
    {'name': 'Revive', 'price': 15000, 'image': 'assets/revive.png'},
    {'name': 'Pocari Sweat', 'price': 20000, 'image': 'assets/pocari.png'},
    {'name': 'Trà Xanh 0 Độ', 'price': 12000, 'image': 'assets/traxanh.png'},
  ];

  Map<String, int> cart = {};
  final TextEditingController _noteController = TextEditingController();

  double get totalPrice {
    double total = 0;
    cart.forEach((key, qty) {
      final product = products.firstWhere((p) => p['name'] == key);
      total += (product['price'] as int) * qty;
    });
    return total;
  }

  void _updateCart(String productName, int change) {
    setState(() {
      int currentQty = cart[productName] ?? 0;
      int newQty = currentQty + change;
      if (newQty <= 0) {
        cart.remove(productName);
      } else {
        cart[productName] = newQty;
      }
    });
  }

  String _formatCurrency(num amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  // ==========================================
  // 1. DIALOG CHỌN PHƯƠNG THỨC (Bước 1)
  // ==========================================
  void _showCheckoutDialog() {
    if (cart.isEmpty) return;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              "Xác nhận đơn hàng",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Danh sách món
                  ...cart.entries.map((e) {
                    final product = products.firstWhere(
                      (p) => p['name'] == e.key,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${e.key} (x${e.value})",
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            _formatCurrency(product['price'] * e.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TỔNG CỘNG:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatCurrency(totalPrice),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nhập vị trí
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: "Vị trí giao hàng (Bắt buộc)",
                      hintText: "VD: Sân số 2...",
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: _primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      errorText: errorText,
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                    onChanged: (value) {
                      if (errorText != null)
                        setStateDialog(() => errorText = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Chọn phương thức thanh toán:",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),

              // Nút Tiền mặt -> Mở Dialog Xác nhận Tiền mặt
              ElevatedButton.icon(
                onPressed: () {
                  if (_noteController.text.trim().isEmpty) {
                    setStateDialog(
                      () => errorText = "Vui lòng nhập số sân của bạn!",
                    );
                  } else {
                    Navigator.pop(ctx); // Đóng dialog hiện tại
                    _showCashConfirmDialog(); // Mở xác nhận tiền mặt
                  }
                },
                icon: const Icon(Icons.money, size: 18),
                label: const Text("Tiền mặt"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

              // Nút QR Code -> Mở Dialog QR
              ElevatedButton.icon(
                onPressed: () {
                  if (_noteController.text.trim().isEmpty) {
                    setStateDialog(
                      () => errorText = "Vui lòng nhập số sân của bạn!",
                    );
                  } else {
                    Navigator.pop(ctx);
                    _showQRDialog();
                  }
                },
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text("QR Code"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // 2. DIALOG XÁC NHẬN TIỀN MẶT (MỚI THÊM)
  // ==========================================
  void _showCashConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Center(
          child: Text(
            "Thanh toán Tiền mặt",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, size: 60, color: Colors.green),
            const SizedBox(height: 15),
            const Text(
              "Vui lòng chuẩn bị tiền mặt:",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              _formatCurrency(totalPrice),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      "Giao tới: ${_noteController.text}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 🔙 Nút Quay lại
          TextButton.icon(
            onPressed: () {
              Navigator.pop(c);
              _showCheckoutDialog(); // Quay lại chọn phương thức
            },
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text("Đổi phương thức"),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),

          // Nút Chốt đơn
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              _placeOrder('cash', context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              "XÁC NHẬN ĐẶT ĐƠN",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. DIALOG QR CODE (CÓ NÚT QUAY LẠI)
  // ==========================================
  void _showQRDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Center(
          child: Text(
            "Quét mã QR",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Image.asset(
                'assets/qrcode.png',
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.qr_code_2, size: 150, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "VietinBank: 108873448328\nChủ TK: PHAM NGUYEN BAO TOAN",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              "Giao tới: ${_noteController.text}",
              style: const TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          // 🔙 Nút Quay lại
          TextButton.icon(
            onPressed: () {
              Navigator.pop(c);
              _showCheckoutDialog(); // Quay lại chọn phương thức
            },
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text("Đổi phương thức"),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),

          // Nút Chốt đơn
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              _placeOrder('qr', context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text(
              "ĐÃ CHUYỂN KHOẢN XONG",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Gửi đơn hàng lên Firebase
  Future<void> _placeOrder(String method, BuildContext? dialogContext) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<Map<String, dynamic>> orderItems = [];
    cart.forEach((key, qty) {
      final product = products.firstWhere((p) => p['name'] == key);
      orderItems.add({'name': key, 'quantity': qty, 'price': product['price']});
    });

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Khách',
        'venueId': widget.venueId,
        'items': orderItems,
        'totalPrice': totalPrice,
        'note': _noteController.text,
        'paymentMethod': method,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        if (dialogContext != null && Navigator.canPop(dialogContext)) {
          Navigator.pop(dialogContext);
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserOrderHistoryScreen(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đặt nước thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Lỗi đặt nước: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Gọi nước uống",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: "Lịch sử đơn hàng",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserOrderHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final item = products[index];
                final qty = cart[item['name']] ?? 0;
                return _buildProductCard(item, qty);
              },
            ),
          ),
          if (cart.isNotEmpty)
            Container(
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Tổng cộng:",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          _formatCurrency(totalPrice),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _showCheckoutDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "ĐẶT NGAY",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, int qty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: qty > 0
            ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: Colors.grey[100],
              child: Image.asset(
                item['image'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.local_drink, size: 40, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(item['price']),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildQtyBtn(
                  Icons.remove,
                  () => _updateCart(item['name'], -1),
                  qty > 0,
                ),
                if (qty > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "$qty",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                _buildQtyBtn(
                  Icons.add,
                  () => _updateCart(item['name'], 1),
                  true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, bool isActive) {
    return InkWell(
      onTap: isActive ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.orange : Colors.grey,
        ),
      ),
    );
  }
}
