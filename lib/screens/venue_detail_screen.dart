// lib/screens/venue_detail_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Models & Services
import '../models/venue_model.dart';
import '../models/court_model.dart';
import '../services/court_service.dart';
import '../services/booking_service.dart';
import '../widgets/court_booking_slot.dart';

// Screens
import 'chat_screen.dart';
import 'login_screen.dart';
import 'drink_shop_screen.dart';

const Color _primaryColor = Color(0xFF1E88E5);
const Color _accentColor = Color(0xFFE3F2FD);
const Color _backgroundColor = Color(0xFFF5F7FA);

class VenueDetailScreen extends StatefulWidget {
  final VenueModel venue;
  final bool isAdmin;

  const VenueDetailScreen({
    super.key,
    required this.venue,
    this.isAdmin = false,
  });

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  DateTime selectedDate = DateTime.now();
  final CourtService courtService = CourtService();
  final BookingService bookingService = BookingService();
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);

    _midnightTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        final n = DateTime.now();
        selectedDate = DateTime(n.year, n.month, n.day);
      });
      _scheduleMidnightRefresh();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final normalizedPicked = DateTime(picked.year, picked.month, picked.day);
      if (normalizedPicked != selectedDate) {
        setState(() => selectedDate = normalizedPicked);
      }
    }
  }

  String _getCleanImageUrl(String rawUrl) {
    if (rawUrl.isEmpty) return "";
    String cleanUrl = rawUrl
        .replaceAll("['", "")
        .replaceAll("']", "")
        .replaceAll('["', "")
        .replaceAll('"]', "");
    if (cleanUrl.contains(',')) {
      cleanUrl = cleanUrl.split(',')[0].trim();
    }
    return cleanUrl;
  }

  // =======================================================
  // 🔥 MENU ADMIN: HIỂN THỊ TRẠNG THÁI & NÚT DUYỆT
  // =======================================================
  void _showAdminBookingOptions(Map<String, dynamic> slotData) {
    // Lấy trạng thái thanh toán từ dữ liệu truyền sang
    String paymentStatus = slotData['paymentStatus'] ?? 'unpaid';
    bool isPaid = paymentStatus == 'paid';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: const [
              Icon(Icons.admin_panel_settings, color: _primaryColor),
              SizedBox(width: 10),
              Text("Quản lý đặt sân"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoLine(
                Icons.person,
                "Khách:",
                slotData['displayName'] ?? 'Khách vãng lai',
              ),
              if (slotData['phone'] != null)
                _buildInfoLine(Icons.phone, "SĐT:", slotData['phone']),

              // 🔥 HIỂN THỊ TRẠNG THÁI THANH TOÁN
              const SizedBox(height: 8),
              _buildInfoLine(
                Icons.payment,
                "Thanh toán:",
                isPaid ? "Đã thanh toán" : "Chờ duyệt (QR)",
                textColor: isPaid ? Colors.green : Colors.orange,
              ),

              const SizedBox(height: 10),
              const Divider(),
              const Text(
                "Thao tác:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsOverflowButtonSpacing: 8,
          actions: [
            // 1. NÚT DUYỆT THANH TOÁN (Chỉ hiện nếu chưa thanh toán)
            if (!isPaid)
              ElevatedButton.icon(
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "Duyệt TT",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  String? bookingId = slotData['bookingId'];
                  if (bookingId != null) {
                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(bookingId)
                        .update({'paymentStatus': 'paid'});

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Đã duyệt thanh toán thành công!"),
                        ),
                      );
                    }
                  }
                },
              )
            else
              // Nếu đã thanh toán thì hiện nút xám (disable)
              OutlinedButton.icon(
                icon: const Icon(Icons.check, color: Colors.grey),
                label: const Text(
                  "Đã duyệt",
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: null,
              ),

            // 2. ĐỔI LỊCH
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_calendar, color: Colors.blue),
              label: const Text(
                "Đổi lịch",
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showRescheduleDialog(slotData);
              },
            ),

            // 3. HỦY SÂN
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text("Hủy sân", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                bool confirm =
                    await showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text("Xác nhận hủy"),
                        content: const Text("Bạn chắc chắn muốn hủy lịch này?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text("Không"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text("Có, Hủy"),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (confirm) {
                  String? bookingId = slotData['bookingId'];
                  if (bookingId != null) {
                    await bookingService.adminCancelBooking(bookingId);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("🗑️ Đã hủy lịch thành công!"),
                        ),
                      );
                      setState(() {});
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showRescheduleDialog(Map<String, dynamic> slotData) async {
    DateTime tempDate = selectedDate;
    TimeOfDay tempTime = const TimeOfDay(hour: 7, minute: 0);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Đổi lịch đặt sân"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Chọn thời gian mới:",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                    ),
                    title: Text(
                      "Ngày: ${DateFormat('dd/MM/yyyy').format(tempDate)}",
                    ),
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null)
                        setStateDialog(() => tempDate = picked);
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: Colors.orange,
                    ),
                    title: Text("Bắt đầu: ${tempTime.format(context)}"),
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: tempTime,
                      );
                      if (picked != null)
                        setStateDialog(() => tempTime = picked);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String? bookingId = slotData['bookingId'];
                    if (bookingId != null) {
                      try {
                        final newDate = DateTime(
                          tempDate.year,
                          tempDate.month,
                          tempDate.day,
                        );
                        final startH = tempTime.hour.toString().padLeft(2, '0');
                        final startM = tempTime.minute.toString().padLeft(
                          2,
                          '0',
                        );
                        final endH = (tempTime.hour + 1).toString().padLeft(
                          2,
                          '0',
                        );
                        final strStartTime = "$startH:$startM";
                        final strEndTime = "$endH:$startM";

                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(bookingId)
                            .update({
                              'date': Timestamp.fromDate(newDate),
                              'startTime': strStartTime,
                              'endTime': strEndTime,
                            });

                        final dateKey =
                            "${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}";
                        await FirebaseFirestore.instance
                            .collection('busy_slots')
                            .doc(bookingId)
                            .update({
                              'dateKey': dateKey,
                              'startTime': strStartTime,
                              'endTime': strEndTime,
                            });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "✅ Đã đổi sang $strStartTime ngày ${DateFormat('dd/MM').format(newDate)}",
                              ),
                            ),
                          );
                          setState(() {});
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("❌ Lỗi khi đổi lịch.")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  child: const Text(
                    "Lưu thay đổi",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoLine(
    IconData icon,
    String label,
    String value, {
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label ", style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = DateFormat('dd/MM/yyyy').format(selectedDate);
    final venue = widget.venue;

    String rawImage = venue.image;
    if (rawImage.isEmpty && venue.imageUrls.isNotEmpty) {
      rawImage = venue.imageUrls.first;
    }
    final String venueImage = _getCleanImageUrl(rawImage);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                backgroundColor: _primaryColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: _primaryColor,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      venueImage.isNotEmpty
                          ? Image.network(
                              venueImage,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Image.asset(
                                'assets/shb.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset('assets/shb.png', fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -20, 0),
                  decoration: const BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                venue.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    venue.rating > 0
                                        ? venue.rating.toStringAsFixed(1)
                                        : "Mới",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                venue.address,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        const Text(
                          "Chọn ngày đặt:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _primaryColor.withOpacity(0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      color: _primaryColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      dateDisplay,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  "Thay đổi",
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          "Lịch Trống:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<List<CourtModel>>(
                          stream: courtService.streamCourtsByVenue(venue.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Lỗi tải sân: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }
                            final courts = snapshot.data ?? [];
                            if (courts.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Chưa có sân nào hoạt động.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: courts.length,
                              separatorBuilder: (ctx, i) =>
                                  const SizedBox(height: 15),
                              itemBuilder: (context, index) {
                                final court = courts[index];
                                return CourtBookingSlot(
                                  venueId: venue.id,
                                  court: court,
                                  selectedDate: selectedDate,
                                  isAdmin: widget.isAdmin,
                                  onAdminTap: _showAdminBookingOptions,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!widget.isAdmin)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFloatingButton(
                    icon: Icons.local_drink,
                    label: "Gọi nước",
                    color: Colors.green,
                    onTap: () => _checkAuthAndNavigate(
                      context,
                      () => DrinkShopScreen(venueId: widget.venue.id),
                    ),
                  ),
                  _buildFloatingButton(
                    icon: Icons.chat_bubble_outline,
                    label: "Chat ngay",
                    color: Colors.orange,
                    onTap: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: user.uid,
                            chatTitle: 'Chat với Chủ sân',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _checkAuthAndNavigate(
    BuildContext context,
    Widget Function() screenBuilder,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screenBuilder()),
      );
    }
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      elevation: 5,
      shadowColor: color.withOpacity(0.4),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
