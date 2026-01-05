// lib/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  double bRevenue = 0, dRevenue = 0; // Doanh thu Sân và Nước
  int bCount = 0, dCount = 0; // Số đơn Sân và Nước
  bool isLoading = true;
  int filterIndex = 0; // 0: Hôm nay, 1: Tháng này, 2: Tất cả

  @override
  void initState() {
    super.initState();
    _fetchAndFilterData();
  }

  // Logic lọc thời gian tại máy khách
  bool _isWithinRange(Timestamp? timestamp) {
    if (timestamp == null) return false;
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();

    if (filterIndex == 0) {
      // Hôm nay
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } else if (filterIndex == 1) {
      // Tháng này
      return date.year == now.year && date.month == now.month;
    }
    return true; // Tất cả thời gian
  }

  Future<void> _fetchAndFilterData() async {
    setState(() => isLoading = true);
    try {
      final bSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .get();
      final oSnap = await FirebaseFirestore.instance.collection('orders').get();

      double tempBRev = 0;
      int tempBCnt = 0;
      double tempDRev = 0;
      int tempDCnt = 0;

      for (var doc in bSnap.docs) {
        final data = doc.data();
        if (_isWithinRange(data['createdAt'] as Timestamp?)) {
          // Cộng dồn toàn bộ totalPrice của booking (Sân + Vợt)
          tempBRev += (data['totalPrice'] ?? 0).toDouble();
          tempBCnt++;
        }
      }

      for (var doc in oSnap.docs) {
        final data = doc.data();
        // Chỉ tính tiền khi đơn nước đã 'completed'
        if (data['status'] == 'completed' &&
            _isWithinRange(data['createdAt'] as Timestamp?)) {
          tempDRev += (data['totalPrice'] ?? 0).toDouble();
          tempDCnt++;
        }
      }

      setState(() {
        bRevenue = tempBRev;
        bCount = tempBCnt;
        dRevenue = tempDRev;
        dCount = tempDCnt;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo kinh doanh"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white, // Chữ màu trắng cho dễ nhìn
        elevation: 0,
      ),
      body: Column(
        children: [
          // THANH BỘ LỌC
          Container(
            color: Colors.blueAccent,
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _filterBtn("Hôm nay", 0),
                _filterBtn("Tháng này", 1),
                _filterBtn("Tất cả", 2),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildCards(),
                        const SizedBox(height: 40),
                        const Text(
                          "Biểu đồ doanh thu (VNĐ)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildChart(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterBtn(String label, int index) {
    bool active = filterIndex == index;
    return InkWell(
      onTap: () {
        setState(() => filterIndex = index);
        _fetchAndFilterData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.blueAccent : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCards() {
    return Row(
      children: [
        _itemCard("Tiền Sân", bCount, bRevenue, Colors.blue),
        const SizedBox(width: 15),
        _itemCard("Tiền Nước", dCount, dRevenue, Colors.orange),
      ],
    );
  }

  Widget _itemCard(String title, int count, double money, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "$count đơn",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "${money.toStringAsFixed(0)}đ",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ HÀM VẼ BIỂU ĐỒ 2 CỘT
  Widget _buildChart() {
    // 1. Tính toán Max Y và khoảng chia (Interval)
    double rawMax = (bRevenue > dRevenue ? bRevenue : dRevenue);
    if (rawMax == 0) rawMax = 100000;

    // Tăng max lên 1.2 lần cho thoáng đỉnh
    double maxY = rawMax * 1.2;

    // Chia biểu đồ thành khoảng 5 dòng kẻ ngang
    double interval = maxY / 5;
    if (interval == 0) interval = 10000;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: bRevenue,
                  color: Colors.blue,
                  width: 45,
                  borderRadius: BorderRadius.circular(6),
                  // Thêm cột mờ làm nền
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: dRevenue,
                  color: Colors.orange,
                  width: 45,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            // Cấu hình trục dưới (Sân/Nước)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    val == 0 ? "Sân" : "Nước",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            // ✅ CẤU HÌNH TRỤC TRÁI (Fix lỗi chèn số)
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40, // Dành chỗ cho chữ số
                interval: interval, // Cách đều các số
                getTitlesWidget: (value, meta) {
                  // Ẩn số 0 cho đỡ rối
                  if (value == 0) return const SizedBox();

                  // Ẩn số nếu nó quá sát đỉnh (tránh đè lên dòng kẻ trên cùng)
                  if (value > maxY * 0.95) return const SizedBox();

                  // Rút gọn số: 150000 -> 150K
                  if (value >= 1000) {
                    return Text(
                      "${(value / 1000).toStringAsFixed(0)}K",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  );
                },
              ),
            ),
          ),
          // Hiển thị dòng kẻ ngang mờ
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
