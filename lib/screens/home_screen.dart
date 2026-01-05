// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../services/venue_service.dart';
import '../services/auth_service.dart';
import '../models/venue_model.dart';
import 'venue_detail_screen.dart';
import 'login_screen.dart';
import 'booking_history_screen.dart';

// Import các màn hình Admin (Nếu chưa có thì comment tạm lại)
import 'admin_chat_list_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_dashboard_screen.dart';

// --- MÀU SẮC THEME (Xanh - Trắng) ---
const Color _primaryColor = Color(0xFF1E88E5);
const Color _accentColor = Color(0xFFE3F2FD);
const Color _backgroundColor = Color(0xFFF5F7FA);

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({super.key, required this.isAdmin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VenueService _venueService = VenueService();
  final AuthService _authService = AuthService();

  String _searchQuery = "";

  void _handleSignOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          // 1. HEADER
          _buildCustomHeader(),

          // 2. DANH SÁCH SÂN
          Expanded(
            child: StreamBuilder<List<VenueModel>>(
              stream: _venueService.streamAllVenues(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allVenues = snapshot.data ?? [];

                // Lọc theo tìm kiếm
                final venues = allVenues.where((v) {
                  final name = v.name.toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query);
                }).toList();

                if (venues.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: venues.length,
                  itemBuilder: (context, index) {
                    final venue = venues[index];
                    return _buildVenueCard(venue);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER WIDGET ---
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng 1: Avatar + Tên + Logout
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: _primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<String?>(
                  stream: _authService.streamUserName(),
                  builder: (context, snapshot) {
                    final name = snapshot.data ?? 'Khách';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isAdmin ? "Quản trị viên" : "Xin chào,",
                          style: TextStyle(
                            color: Colors.blue[100],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: 'Lịch sử',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookingHistoryScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70),
                onPressed: _handleSignOut,
              ),
            ],
          ),

          // Hàng 2: ADMIN TOOLS (Chỉ hiện nếu là Admin)
          if (widget.isAdmin) ...[
            const SizedBox(height: 15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAdminChip(Icons.analytics_outlined, "Doanh thu", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                  _buildAdminChip(Icons.local_drink, "Đơn nước", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminOrdersScreen(),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                  _buildAdminChip(Icons.rate_review, "Đánh giá", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminReviewsScreen(),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                  _buildAdminChip(Icons.chat_bubble_outline, "Hỗ trợ", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminChatListScreen(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Hàng 3: SEARCH BAR
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: "Tìm kiếm tên sân...",
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, color: _primaryColor),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- VENUE CARD WIDGET (ĐÃ SỬA KHỚP VỚI MODEL) ---
  Widget _buildVenueCard(VenueModel venue) {
    // 1. Dùng getter 'image' có sẵn trong Model của bạn
    final String venueImage = venue.image;

    // 2. Vì Model chưa có openTime/closeTime, ta dùng giờ mặc định
    // Sau này bạn thêm trường openTime vào Model thì sửa dòng này sau.
    const String timeInfo = "05:00 - 22:00";

    // 3. Lấy rating thực tế
    final String ratingText = venue.rating > 0
        ? venue.rating.toStringAsFixed(1)
        : "Mới";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    VenueDetailScreen(venue: venue, isAdmin: widget.isAdmin),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Ảnh sân
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: _accentColor,
                  child: Stack(
                    children: [
                      Center(
                        child: venueImage.isNotEmpty
                            ? Image.network(
                                venueImage,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              )
                            : Image.asset(
                                'assets/shuttlecock.png',
                                width: 80,
                                height: 80,
                              ),
                      ),
                      // Badge Rating (Hiển thị điểm thật)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ratingText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if (venue.ratingCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  "(${venue.ratingCount})",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Thông tin
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venue.address,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          timeInfo,
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Đặt ngay",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  // Helper cho nút Admin
  Widget _buildAdminChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_tennis_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            _searchQuery.isEmpty ? "Chưa có sân nào" : "Không tìm thấy sân",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
