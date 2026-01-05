// lib/widgets/court_booking_slot.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/court_model.dart';
import '../models/pricing_rule_model.dart';
import '../models/busy_slot_model.dart';
import '../services/court_service.dart';
import '../services/booking_service.dart';
import '../services/busy_slot_service.dart';
import '../services/auth_service.dart';
import '../services/booking_display_service.dart';
import '../screens/service_selection_screen.dart';

class CourtBookingSlot extends StatefulWidget {
  final String venueId;
  final CourtModel court;
  final DateTime selectedDate;

  // ✅ CÁC THAM SỐ CHO ADMIN
  final bool isAdmin;
  final Function(Map<String, dynamic>)? onAdminTap;

  const CourtBookingSlot({
    super.key,
    required this.venueId,
    required this.court,
    required this.selectedDate,
    this.isAdmin = false,
    this.onAdminTap,
  });

  @override
  State<CourtBookingSlot> createState() => _CourtBookingSlotState();
}

class _CourtBookingSlotState extends State<CourtBookingSlot> {
  final Map<String, double> _selectedSlots = {};
  final Set<String> _locallyBookedSlots = {};

  final CourtService courtService = CourtService();
  final BookingService bookingService = BookingService();
  final BusySlotService busySlotService = BusySlotService();
  final AuthService authService = AuthService();
  final BookingDisplayService displayService = BookingDisplayService();

  @override
  void didUpdateWidget(covariant CourtBookingSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      setState(() {
        _selectedSlots.clear();
        _locallyBookedSlots.clear();
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSlotExpired(String startTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );

    if (checkDate.isBefore(today)) return true;
    if (checkDate.isAfter(today)) return false;

    try {
      int startHour = int.parse(startTime.split(':')[0]);
      return startHour <= now.hour;
    } catch (e) {
      return false;
    }
  }

  int _timeToMinutes(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return h * 60 + m;
  }

  bool _rangeCoversSlot({
    required String start,
    required String end,
    required String slotStartTime,
  }) {
    final slotStart = _timeToMinutes(slotStartTime);
    final slotEnd = slotStart + 60;
    final s = _timeToMinutes(start);
    final e = _timeToMinutes(end);
    return slotStart < e && slotEnd > s;
  }

  BusySlotModel? _findCoveringBusySlot(
    List<BusySlotModel> busySlots,
    String slotStartTime,
  ) {
    for (final b in busySlots) {
      if (b.courtId != widget.court.id) continue;
      if (_rangeCoversSlot(
        start: b.startTime,
        end: b.endTime,
        slotStartTime: slotStartTime,
      )) {
        return b;
      }
    }
    return null;
  }

  void _toggleSlotSelection(String startTime, double price) {
    setState(() {
      if (_selectedSlots.containsKey(startTime)) {
        _selectedSlots.remove(startTime);
      } else {
        _selectedSlots[startTime] = price;
      }
    });
  }

  double _calculateTotalPrice() {
    return _selectedSlots.values.fold(0.0, (sum, price) => sum + price);
  }

  Future<void> _proceedToConfirmation(BuildContext context) async {
    if (_selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một khung giờ.')),
      );
      return;
    }

    List<int> selectedHours =
        _selectedSlots.keys
            .map((time) => int.parse(time.split(':')[0]))
            .toList()
          ..sort();

    final startBookingTime =
        '${selectedHours.first.toString().padLeft(2, '0')}:00';
    final endBookingTime =
        '${(selectedHours.last + 1).toString().padLeft(2, '0')}:00';

    String venueName = await displayService.getVenueName(widget.venueId);

    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ServiceSelectionScreen(
          venueId: widget.venueId,
          venueName: venueName,
          courtId: widget.court.id,
          date: widget.selectedDate,
          startTime: startBookingTime,
          endTime: endBookingTime,
          courtPrice: _calculateTotalPrice(),
        ),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      setState(() {
        for (int h = selectedHours.first; h <= selectedHours.last; h++) {
          _locallyBookedSlots.add('${h.toString().padLeft(2, '0')}:00');
        }
        _selectedSlots.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt sân thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    final value = (amount / 1000).toStringAsFixed(0);
    return '$value.000đ';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.court.name} (${widget.court.type})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Các Khung Giờ:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            StreamBuilder<List<PricingRuleModel>>(
              stream: courtService.streamPricingRules(
                widget.venueId,
                widget.court.id,
              ),
              builder: (context, priceSnapshot) {
                if (priceSnapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (priceSnapshot.hasError) {
                  return Text(
                    'Lỗi tải bảng giá: ${priceSnapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                final rules = priceSnapshot.data ?? [];
                if (rules.isEmpty) return const Text('Chưa có quy tắc giá.');

                rules.sort((a, b) {
                  final aHour = int.parse(a.startTime.split(':')[0]);
                  final bHour = int.parse(b.startTime.split(':')[0]);
                  return aHour.compareTo(bHour);
                });

                return StreamBuilder<List<BusySlotModel>>(
                  stream: busySlotService.streamBusySlots(
                    venueId: widget.venueId,
                    courtId: widget.court.id,
                    date: widget.selectedDate,
                  ),
                  builder: (context, busySnapshot) {
                    if (busySnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Lỗi tải lịch bận: ${busySnapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final busySlots = busySnapshot.data ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _buildTimeSlotsFromBusy(rules, busySlots),
                        ),
                        if (_selectedSlots.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Divider(height: 20),
                              Text(
                                'Tổng tiền tạm tính: ${_formatCurrency(_calculateTotalPrice())}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () =>
                                    _proceedToConfirmation(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text(
                                  'Tiếp tục Đặt Sân',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeSlotsFromBusy(
    List<PricingRuleModel> rules,
    List<BusySlotModel> busySlots,
  ) {
    final List<Widget> slots = [];

    for (var rule in rules) {
      final startHour = int.parse(rule.startTime.split(':')[0]);
      final endHour = int.parse(rule.endTime.split(':')[0]);

      for (int i = startHour; i < endHour; i++) {
        final slotStartTime = '${i.toString().padLeft(2, '0')}:00';
        final slotEndTime = '${(i + 1).toString().padLeft(2, '0')}:00';

        final coveringBusy = _findCoveringBusySlot(busySlots, slotStartTime);

        final bool isBooked =
            (coveringBusy != null) ||
            _locallyBookedSlots.contains(slotStartTime);
        final bool isSelected = _selectedSlots.containsKey(slotStartTime);
        final bool isExpired = _isSlotExpired(slotStartTime);

        Color backgroundColor;
        Color foregroundColor;
        TextDecoration? textDecoration;

        if (isBooked) {
          backgroundColor = Colors.red.shade400;
          foregroundColor = Colors.white;
        } else if (isExpired) {
          backgroundColor = Colors.grey.shade400;
          foregroundColor = Colors.white;
          textDecoration = TextDecoration.lineThrough;
        } else if (isSelected) {
          backgroundColor = Colors.blue;
          foregroundColor = Colors.white;
        } else {
          backgroundColor = Colors.grey.shade200;
          foregroundColor = Colors.black87;
        }

        final VoidCallback? onPressedAction = (isBooked || isExpired)
            ? null
            : () => _toggleSlotSelection(slotStartTime, rule.price);

        if (isBooked) {
          // ✅ NẾU ĐÃ ĐẶT: Gắn hàm xử lý Admin vào đây
          slots.add(
            GestureDetector(
              onTap: coveringBusy == null
                  ? null
                  : () async {
                      // 🔥 LOGIC QUAN TRỌNG: NẾU LÀ ADMIN THÌ GỌI CALLBACK KÈM STATUS THANH TOÁN
                      if (widget.isAdmin && widget.onAdminTap != null) {
                        // 1. Lấy thông tin chi tiết user đặt sân
                        final booking = await bookingService.getBookingById(
                          coveringBusy.bookingId,
                        );

                        if (booking != null) {
                          final userDetails = await displayService
                              .getUserDetails(booking.userId);

                          // 2. Gói dữ liệu gửi về màn hình cha
                          final slotData = {
                            'bookingId': coveringBusy.bookingId,
                            'displayName':
                                userDetails['name'] ?? coveringBusy.displayName,
                            'phone': userDetails['phone'],
                            'paymentStatus': booking
                                .paymentStatus, // ✅ LẤY TRẠNG THÁI THANH TOÁN
                          };

                          // 3. Gọi callback
                          widget.onAdminTap!(slotData);
                        }
                      } else {
                        // NẾU KHÔNG PHẢI ADMIN: Chỉ hiện thông báo đơn giản
                        final isBlock = coveringBusy.kind == 'block';
                        showDialog(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: Text(
                              isBlock
                                  ? 'Khung giờ đã bị khóa'
                                  : 'Khung giờ đã được đặt',
                            ),
                            content: Text(
                              isBlock
                                  ? 'Lý do: ${coveringBusy.note ?? "Bảo trì"}'
                                  : 'Người đặt: ${coveringBusy.displayName}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dCtx).pop(),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border.all(color: Colors.grey),
                ),
                child: Text(
                  '$slotStartTime - $slotEndTime',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: foregroundColor),
                ),
              ),
            ),
          );
        } else {
          // CHƯA ĐẶT
          slots.add(
            ActionChip(
              label: Text(
                '$slotStartTime - $slotEndTime',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: foregroundColor,
                  decoration: textDecoration,
                ),
              ),
              onPressed: onPressedAction,
              backgroundColor: backgroundColor,
              side: const BorderSide(color: Colors.grey),
              elevation: isExpired ? 0 : 4,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          );
        }
      }
    }
    return slots;
  }
}
