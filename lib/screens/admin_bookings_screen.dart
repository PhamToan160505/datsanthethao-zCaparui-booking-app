// lib/screens/admin_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/court_model.dart';
import '../services/booking_service.dart';
import '../services/booking_display_service.dart';
import '../services/court_service.dart';
import '../services/busy_slot_service.dart';

class AdminBookingsScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? venueId; // bắt buộc để khóa giờ (cần biết venue)
  const AdminBookingsScreen({super.key, this.initialDate, this.venueId});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final BookingService _bookingService = BookingService();
  final BookingDisplayService _displayService = BookingDisplayService();
  final CourtService _courtService = CourtService();
  final BusySlotService _busySlotService = BusySlotService();

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(d.year, d.month, d.day);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ====== Dialog khóa giờ ======
  Future<void> _openBlockTimeDialog() async {
    if (widget.venueId == null || widget.venueId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thiếu venueId. Không thể khóa giờ.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // load danh sách courts của venue
    final courts = await _courtService.getCourtsOnce(widget.venueId!);
    if (!mounted) return;

    if (courts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venue này chưa có sân con (courts).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    CourtModel selectedCourt = courts.first;
    String startTime = '05:00';
    String endTime = '06:00';
    final noteController = TextEditingController(text: 'Bảo trì/giải đấu');

    List<String> hours = List.generate(
      19,
      (i) => '${(5 + i).toString().padLeft(2, '0')}:00',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text('Khóa giờ'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // chọn sân
                  DropdownButtonFormField<CourtModel>(
                    value: selectedCourt,
                    items: courts.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.name));
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => selectedCourt = v);
                    },
                    decoration: const InputDecoration(labelText: 'Chọn sân'),
                  ),
                  const SizedBox(height: 12),

                  // chọn giờ bắt đầu
                  DropdownButtonFormField<String>(
                    value: startTime,
                    items: hours.map((h) {
                      return DropdownMenuItem(value: h, child: Text(h));
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => startTime = v);
                      // auto adjust end if end <= start
                      if (hours.indexOf(endTime) <= hours.indexOf(startTime)) {
                        final idx = hours.indexOf(startTime);
                        final next = (idx + 1 < hours.length)
                            ? hours[idx + 1]
                            : endTime;
                        setLocal(() => endTime = next);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Giờ bắt đầu'),
                  ),
                  const SizedBox(height: 12),

                  // chọn giờ kết thúc
                  DropdownButtonFormField<String>(
                    value: endTime,
                    items: hours.map((h) {
                      return DropdownMenuItem(value: h, child: Text(h));
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => endTime = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Giờ kết thúc',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (tuỳ chọn)',
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                // validate
                final s = int.tryParse(startTime.split(':')[0]) ?? 0;
                final e = int.tryParse(endTime.split(':')[0]) ?? 0;
                if (e <= s) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Giờ kết thúc phải lớn hơn giờ bắt đầu.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _busySlotService.createBlockSlot(
                    venueId: widget.venueId!,
                    courtId: selectedCourt.id,
                    date: _selectedDate,
                    startTime: startTime,
                    endTime: endTime,
                    note: noteController.text,
                  );

                  if (!mounted) return;
                  Navigator.of(dCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã khóa giờ thành công!')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khóa giờ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canBlock = widget.venueId != null && widget.venueId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch đặt theo ngày'),
        backgroundColor: const Color.fromARGB(255, 128, 203, 244),
        actions: [
          IconButton(
            tooltip: canBlock ? 'Khóa giờ' : 'Thiếu venueId',
            onPressed: canBlock ? _openBlockTimeDialog : null,
            icon: const Icon(Icons.lock_clock),
          ),
        ],
      ),
      body: Column(
        children: [
          // chọn ngày
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ngày: ${_dateLabel(_selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Chọn ngày'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // list booking theo ngày
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _bookingService.streamBookingsByDate(
                date: _selectedDate,
                venueId: widget.venueId,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Lỗi: ${snap.error}'));
                }
                final bookings = snap.data ?? [];
                if (bookings.isEmpty) {
                  return const Center(child: Text('Không có lịch đặt.'));
                }

                // group theo court
                final Map<String, List<BookingModel>> byCourt = {};
                for (final b in bookings) {
                  byCourt.putIfAbsent(b.courtId, () => []);
                  byCourt[b.courtId]!.add(b);
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: byCourt.entries.map((entry) {
                    final courtId = entry.key;
                    final list = entry.value;

                    return FutureBuilder<String>(
                      future: _displayService.getCourtName(
                        list.first.venueId,
                        courtId,
                      ),
                      builder: (context, courtNameSnap) {
                        final courtName = courtNameSnap.data ?? courtId;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sân: $courtName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Divider(),

                                ...list.map(
                                  (b) => _BookingRow(
                                    booking: b,
                                    displayService: _displayService,
                                    courtService: _courtService,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// ✅ CLASS _BookingRow ĐÃ ĐƯỢC CẬP NHẬT HOÀN CHỈNH
// =========================================================
class _BookingRow extends StatelessWidget {
  final BookingModel booking;
  final BookingDisplayService displayService;
  final CourtService courtService;

  const _BookingRow({
    required this.booking,
    required this.displayService,
    required this.courtService,
  });

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _toDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  bool _overlap(String aStart, String aEnd, String bStart, String bEnd) {
    final as = _toMinutes(aStart);
    final ae = _toMinutes(aEnd);
    final bs = _toMinutes(bStart);
    final be = _toMinutes(bEnd);
    return as < be && ae > bs;
  }

  Future<bool> _hasConflict({
    required String venueId,
    required String courtId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String ignoreBookingId,
  }) async {
    final dateKey = _toDateKey(date);

    final snap = await FirebaseFirestore.instance
        .collection('busy_slots')
        .where('venueId', isEqualTo: venueId)
        .where('courtId', isEqualTo: courtId)
        .where('dateKey', isEqualTo: dateKey)
        .where('status', isEqualTo: 'confirmed')
        .get();

    for (final doc in snap.docs) {
      if (doc.id == ignoreBookingId) continue;

      final data = doc.data();
      final s = (data['startTime'] as String?) ?? '';
      final e = (data['endTime'] as String?) ?? '';
      if (s.isEmpty || e.isEmpty) continue;

      if (_overlap(startTime, endTime, s, e)) return true;
    }
    return false;
  }

  // ✅ Hàm cập nhật trạng thái thanh toán (Paid/Pending/Unpaid)
  Future<void> _updatePaymentStatus(
    BuildContext context,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({'paymentStatus': newStatus});

      if (context.mounted) {
        Navigator.pop(context); // Đóng dialog để refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái: $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: displayService.getUserDetails(booking.userId),
      builder: (context, snap) {
        final userName = snap.data?['name'] ?? 'Đang tải...';
        final phone = snap.data?['phone'] ?? '';

        // ✅ LOGIC VISUAL: Nổi bật nếu đang chờ duyệt (Pending)
        bool isPending = booking.paymentStatus == 'pending';

        return InkWell(
          onTap: () {
            // ✅ LOGIC TRẠNG THÁI CHO DIALOG
            String statusText;
            Color statusColor;
            IconData statusIcon;

            if (booking.paymentStatus == 'paid') {
              statusText = 'Đã thanh toán (QR/Online)';
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
            } else if (booking.paymentStatus == 'pending') {
              statusText = 'Chờ duyệt (Khách đã chuyển)';
              statusColor = Colors.orange;
              statusIcon = Icons.hourglass_top;
            } else {
              statusText = 'Chưa thanh toán (Tiền mặt)';
              statusColor = Colors.red;
              statusIcon = Icons.money_off;
            }

            showDialog(
              context: context,
              builder: (dCtx) => AlertDialog(
                scrollable: true, // ✅ Cho phép cuộn nếu màn hình bé
                title: Text(userName),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SĐT: $phone'),
                    const SizedBox(height: 8),
                    Text('Ngày: ${_dateLabel(booking.date)}'),
                    Text('Giờ: ${booking.startTime} - ${booking.endTime}'),

                    Text(
                      'Tổng tiền: ${booking.totalPrice.toStringAsFixed(0)} đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    // ✅✅✅ PHẦN MỚI: HIỂN THỊ DỊCH VỤ ĐÃ ĐẶT ✅✅✅
                    if (booking.services.isNotEmpty) ...[
                      const Divider(),
                      const Text(
                        'Dịch vụ đi kèm:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      // Duyệt qua list services từ booking để hiển thị
                      ...booking.services.map((s) {
                        final name = s['name'] ?? 'Dịch vụ';
                        final qty = s['quantity'] ?? 1;
                        final total = s['total'] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            bottom: 2.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "- $name (x$qty)",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "${total}đ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(),
                    ],

                    // ✅✅✅ KẾT THÚC PHẦN MỚI ✅✅✅
                    const SizedBox(height: 12),
                    const Text(
                      'Trạng thái thanh toán:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // Box hiển thị trạng thái hiện tại
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ NÚT XÁC NHẬN CHO ADMIN (Nổi bật nhất)
                    if (booking.paymentStatus == 'pending')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _updatePaymentStatus(context, 'paid'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('XÁC NHẬN ĐÃ NHẬN TIỀN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                    // Nút hoàn tác (Nếu lỡ bấm xác nhận nhầm)
                    if (booking.paymentStatus == 'paid')
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () =>
                              _updatePaymentStatus(context, 'pending'),
                          icon: const Icon(
                            Icons.undo,
                            size: 16,
                            color: Colors.grey,
                          ),
                          label: const Text(
                            'Hoàn tác (Về chờ duyệt)',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),
                    const Text(
                      'Mã Booking:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    // ✅ Mã Booking ID to hơn, đóng khung
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        booking.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // ✅ Nút Hủy Sân (Giữ nguyên logic cũ)
                  if (booking.status == 'confirmed')
                    TextButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: dCtx,
                          builder: (c) => AlertDialog(
                            title: const Text('Hủy lịch đặt?'),
                            content: const Text(
                              'Bạn chắc chắn muốn hủy lịch này không?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Không'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Hủy lịch'),
                              ),
                            ],
                          ),
                        );

                        if (ok != true) return;

                        try {
                          final bookingRef = FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(booking.id);
                          final busyRef = FirebaseFirestore.instance
                              .collection('busy_slots')
                              .doc(booking.id);

                          final batch = FirebaseFirestore.instance.batch();
                          batch.update(bookingRef, {
                            'status': 'cancelled',
                            'cancelledAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                          batch.delete(busyRef);

                          await batch.commit();

                          if (dCtx.mounted) Navigator.pop(dCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã hủy và giải phóng slot.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi hủy: $e')),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Hủy Sân'),
                    ),

                  // ✅ Nút Đổi lịch (Giữ nguyên logic đã sửa lỗi Dropdown)
                  if (booking.status == 'confirmed')
                    ElevatedButton(
                      onPressed: () async {
                        final courts = await courtService.getCourtsOnce(
                          booking.venueId,
                        );
                        if (!context.mounted) return;

                        if (courts.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Venue này chưa có courts.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        CourtModel selectedCourt = courts.firstWhere(
                          (c) => c.id == booking.courtId,
                          orElse: () => courts.first,
                        );

                        DateTime selectedDate = booking.date;
                        String startTime = booking.startTime;
                        String endTime = booking.endTime;

                        final hours = List.generate(
                          19,
                          (i) => '${(5 + i).toString().padLeft(2, '0')}:00',
                        );

                        if (!hours.contains(startTime)) {
                          startTime = hours.first;
                        }
                        if (!hours.contains(endTime)) {
                          final idx = hours.indexOf(startTime);
                          endTime = (idx != -1 && idx + 1 < hours.length)
                              ? hours[idx + 1]
                              : hours.last;
                        }

                        final ok = await showDialog<bool>(
                          context: dCtx,
                          barrierDismissible: false,
                          builder: (dlg) {
                            return AlertDialog(
                              title: const Text('Đổi lịch'),
                              content: StatefulBuilder(
                                builder: (ctx, setLocal) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Ngày'),
                                        subtitle: Text(
                                          _dateLabel(selectedDate),
                                        ),
                                        trailing: const Icon(
                                          Icons.calendar_today_outlined,
                                        ),
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: ctx,
                                            initialDate: selectedDate,
                                            firstDate: DateTime.now().subtract(
                                              const Duration(days: 0),
                                            ),
                                            lastDate: DateTime.now().add(
                                              const Duration(days: 90),
                                            ),
                                          );
                                          if (picked != null) {
                                            setLocal(() {
                                              selectedDate = DateTime(
                                                picked.year,
                                                picked.month,
                                                picked.day,
                                              );
                                            });
                                          }
                                        },
                                      ),

                                      DropdownButtonFormField<CourtModel>(
                                        value: selectedCourt,
                                        items: courts.map((c) {
                                          return DropdownMenuItem(
                                            value: c,
                                            child: Text(c.name),
                                          );
                                        }).toList(),
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setLocal(() => selectedCourt = v);
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Chọn sân',
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      DropdownButtonFormField<String>(
                                        value: startTime,
                                        items: hours.map((h) {
                                          return DropdownMenuItem(
                                            value: h,
                                            child: Text(h),
                                          );
                                        }).toList(),
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setLocal(() => startTime = v);
                                          if (hours.indexOf(endTime) <=
                                              hours.indexOf(startTime)) {
                                            final idx = hours.indexOf(
                                              startTime,
                                            );
                                            final next =
                                                (idx + 1 < hours.length)
                                                ? hours[idx + 1]
                                                : endTime;
                                            setLocal(() => endTime = next);
                                          }
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Giờ bắt đầu',
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      DropdownButtonFormField<String>(
                                        value: endTime,
                                        items: hours.map((h) {
                                          return DropdownMenuItem(
                                            value: h,
                                            child: Text(h),
                                          );
                                        }).toList(),
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setLocal(() => endTime = v);
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Giờ kết thúc',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dlg, false),
                                  child: const Text('Hủy'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dlg, true),
                                  child: const Text('Xác nhận'),
                                ),
                              ],
                            );
                          },
                        );

                        if (ok != true) return;

                        if (_toMinutes(endTime) <= _toMinutes(startTime)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Giờ kết thúc phải lớn hơn giờ bắt đầu.',
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        final conflict = await _hasConflict(
                          venueId: booking.venueId,
                          courtId: selectedCourt.id,
                          date: selectedDate,
                          startTime: startTime,
                          endTime: endTime,
                          ignoreBookingId: booking.id,
                        );

                        if (conflict) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Khung giờ đã bận. Chọn giờ khác.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        try {
                          final bookingRef = FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(booking.id);
                          final busyRef = FirebaseFirestore.instance
                              .collection('busy_slots')
                              .doc(booking.id);

                          final batch = FirebaseFirestore.instance.batch();

                          batch.update(bookingRef, {
                            'venueId': booking.venueId,
                            'courtId': selectedCourt.id,
                            'date': DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                            ),
                            'startTime': startTime,
                            'endTime': endTime,
                            'status': 'confirmed',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          batch.set(busyRef, {
                            'bookingId': booking.id,
                            'venueId': booking.venueId,
                            'courtId': selectedCourt.id,
                            'dateKey': _toDateKey(selectedDate),
                            'startTime': startTime,
                            'endTime': endTime,
                            'displayName': userName.isEmpty
                                ? 'Đã đặt'
                                : userName,
                            'status': 'confirmed',
                            'kind': 'booking',
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                          await batch.commit();

                          if (dCtx.mounted) Navigator.pop(dCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã đổi lịch và cập nhật slot.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi đổi lịch: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Đổi lịch'),
                    ),

                  TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ✅ NỀN VÀNG + VIỀN CAM NẾU ĐANG CHỜ DUYỆT (PENDING)
              color: isPending ? Colors.orange.shade50 : Colors.red.shade400,
              borderRadius: BorderRadius.circular(8),
              border: isPending
                  ? Border.all(color: Colors.orange, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Thêm icon đồng hồ cát nếu pending
                if (isPending)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.hourglass_top,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),

                Text(
                  '${booking.startTime} - ${booking.endTime}',
                  style: TextStyle(
                    color: isPending ? Colors.orange.shade900 : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    userName,
                    style: TextStyle(
                      color: isPending ? Colors.orange.shade900 : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isPending ? Colors.orange.shade900 : Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
