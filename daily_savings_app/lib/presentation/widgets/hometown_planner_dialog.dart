import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hometown_trip.dart';
import '../../providers/savings_provider.dart';

class HometownPlannerDialog extends ConsumerStatefulWidget {
  const HometownPlannerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const HometownPlannerDialog(),
    );
  }

  @override
  ConsumerState<HometownPlannerDialog> createState() => _HometownPlannerDialogState();
}

class _HometownPlannerDialogState extends ConsumerState<HometownPlannerDialog> {
  late int _selectedYear;
  bool _isFormExpanded = false;
  String? _editingTripId;

  final _titleController = TextEditingController();
  final _budgetController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 12));

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _openAddForm() {
    setState(() {
      _editingTripId = null;
      _titleController.clear();
      _budgetController.clear();
      _noteController.clear();
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
      _endDate = _startDate.add(const Duration(days: 5));
      _isFormExpanded = true;
    });
  }

  void _editTrip(HometownTrip trip) {
    setState(() {
      _editingTripId = trip.id;
      _titleController.text = trip.title;
      _budgetController.text = trip.budget > 0 ? Formatters.formatNumberDot(trip.budget) : '';
      _noteController.text = trip.note;
      _startDate = trip.startDateTime;
      _endDate = trip.endDateTime;
      _isFormExpanded = true;
    });
  }

  void _cancelForm() {
    setState(() {
      _isFormExpanded = false;
      _editingTripId = null;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'CHỌN NGÀY VỀ & NGÀY LÊN',
      saveText: 'CHỌN',
      cancelText: 'HỦY',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Color(0xFF162035),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _saveTrip() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập tiêu đề chuyến đi (ví dụ: Tết Nguyên Đán)!'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawBudget = _budgetController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final double budget = double.tryParse(rawBudget) ?? 0.0;

    final trip = HometownTrip(
      id: _editingTripId ?? const Uuid().v4(),
      title: title,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
      budget: budget,
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(savingsProvider.notifier).addOrUpdateHometownTrip(trip);

    if (mounted) {
      setState(() {
        _isFormExpanded = false;
        _editingTripId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🏡 Đã lưu lịch trình "${trip.title}" thành công!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDeleteTrip(HometownTrip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162035),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🗑️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'Xóa Chuyến Đi?',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa kế hoạch "${trip.title}" (${trip.formattedDateRange}) không?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa Bỏ'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(savingsProvider.notifier).deleteHometownTrip(trip.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Đã xóa chuyến đi "${trip.title}"!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF101726) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0);

    // Compute stats for selected year
    final completedCount = state.completedTripsInYear(_selectedYear);
    final totalDaysHome = state.totalDaysHomeInYear(_selectedYear);
    final upcomingCount = state.upcomingTripsInYear(_selectedYear);

    // Trips for selected year
    final tripsInYear = state.sortedHometownTrips.where((t) {
      return t.startDateTime.year == _selectedYear || t.endDateTime.year == _selectedYear;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER BANNER
              _buildHeader(context, isDark),

              // MAIN CONTENT
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // YEAR SELECTOR + 3 STAT CARDS
                      _buildYearAndStatsBar(
                        isDark: isDark,
                        completedCount: completedCount,
                        totalDaysHome: totalDaysHome,
                        upcomingCount: upcomingCount,
                      ),
                      const SizedBox(height: 14),

                      // SECTION BAR WITH "LÊN KẾ HOẠCH MỚI" TOGGLE
                      _buildSectionBar(isDark),
                      const SizedBox(height: 10),

                      // COLLAPSIBLE FORM
                      if (_isFormExpanded) ...[
                        _buildForm(isDark),
                        const SizedBox(height: 14),
                      ],

                      // TRIPS LIST
                      _buildTripsList(isDark, tripsInYear),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162035) : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏡', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SỔ KẾ HOẠCH VỀ QUÊ',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Lên lịch trình, đếm ngược & theo dõi các chuyến thăm quê 🚗',
                        style: TextStyle(
                          color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  Widget _buildYearAndStatsBar({
    required bool isDark,
    required int completedCount,
    required int totalDaysHome,
    required int upcomingCount,
  }) {
    return Column(
      children: [
        // Year Navigator Chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                Text(
                  'Thống kê năm: ',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  onPressed: () {
                    setState(() => _selectedYear--);
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Năm $_selectedYear',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  onPressed: () {
                    setState(() => _selectedYear++);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 3 Stat Cards Side-by-Side
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                isDark: isDark,
                icon: '🚗',
                label: 'ĐÃ VỀ QUÊ',
                value: '$completedCount',
                unit: 'lần',
                accentColor: const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                isDark: isDark,
                icon: '🏡',
                label: 'SUM VẦY',
                value: '$totalDaysHome',
                unit: 'ngày',
                accentColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                isDark: isDark,
                icon: '📅',
                label: 'KẾ HOẠCH',
                value: '$upcomingCount',
                unit: 'chuyến',
                accentColor: const Color(0xFFFBBF24),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required String icon,
    required String label,
    required String value,
    required String unit,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBar(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.flight_takeoff_rounded, size: 16, color: Color(0xFF34D399)),
            const SizedBox(width: 6),
            Text(
              'LỊCH TRÌNH VỀ QUÊ',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            if (_isFormExpanded) {
              _cancelForm();
            } else {
              _openAddForm();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: _isFormExpanded
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
              color: _isFormExpanded
                  ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                  : null,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _isFormExpanded
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isFormExpanded ? Icons.close_rounded : Icons.add_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _isFormExpanded ? 'Đóng Biểu Mẫu' : 'Lên Kế Hoạch Mới',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isDark) {
    final formBg = isDark ? const Color(0xFF141C2E) : const Color(0xFFF8FAFC);
    final borderColor = const Color(0xFF10B981).withValues(alpha: 0.35);

    final durationDays = _endDate.difference(_startDate).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: formBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _editingTripId != null ? '✏️ CHỈNH SỬA KẾ HOẠCH' : '✨ KẾ HOẠCH MỚI',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title field
          TextField(
            controller: _titleController,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Tiêu đề chuyến đi *',
              hintText: 'Ví dụ: Tết Nguyên Đán 2026, Giỗ đầu...',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.bookmark_border_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 10),

          // Date Range picker field
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black26,
                ),
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 18, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thời gian chuyến đi:',
                            style: TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(_startDate)} ➔ ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$durationDays ngày',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Budget field
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ThousandsDotInputFormatter(),
            ],
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Ngân sách dự kiến (đ)',
              hintText: 'Ví dụ: 3.500.000',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.savings_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 10),

          // Note field
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 12.5,
            ),
            decoration: InputDecoration(
              labelText: 'Ghi chú / Việc cần chuẩn bị',
              hintText: 'Ví dụ: Mua vé xe trước 1 tháng, quà biếu gia đình...',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelForm,
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 4,
                ),
                onPressed: _saveTrip,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(
                  _editingTripId != null ? 'Cập Nhật' : 'Lưu Kế Hoạch',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(bool isDark, List<HometownTrip> trips) {
    if (trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141C2E) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            const Text('🚗', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              'Chưa có kế hoạch về quê nào trong năm $_selectedYear',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Bấm "Lên Kế Hoạch Mới" để đặt lịch trình chuyến về quê đầu tiên!',
              style: TextStyle(
                color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: trips.map((trip) => _buildTripCard(isDark, trip)).toList(),
    );
  }

  Widget _buildTripCard(bool isDark, HometownTrip trip) {
    final status = trip.status;
    final cardBg = isDark ? const Color(0xFF141C2E) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    // Status styling
    Color statusColor;
    Color statusBg;
    String statusText;

    switch (status) {
      case HometownTripStatus.ongoing:
        statusColor = const Color(0xFFF472B6);
        statusBg = const Color(0xFFF472B6).withValues(alpha: 0.15);
        statusText = '❤️ Đang ở quê';
        break;
      case HometownTripStatus.today:
        statusColor = const Color(0xFF34D399);
        statusBg = const Color(0xFF10B981).withValues(alpha: 0.18);
        statusText = '🚗 Hôm nay lên đường!';
        break;
      case HometownTripStatus.tomorrow:
        statusColor = const Color(0xFFFBBF24);
        statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.18);
        statusText = '🚗 Ngày mai lên đường!';
        break;
      case HometownTripStatus.upcoming:
        statusColor = const Color(0xFF34D399);
        statusBg = const Color(0xFF10B981).withValues(alpha: 0.15);
        statusText = '⏳ Còn ${trip.daysLeft} ngày';
        break;
      case HometownTripStatus.completed:
        statusColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);
        statusBg = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0);
        statusText = '✅ Đã hoàn thành';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Date Badge: Month + Day + Duration
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trip.dateMonthText,
                    style: TextStyle(
                      color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    trip.dateDayText,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${trip.durationInDays}N',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Center Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge + Date range
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          trip.formattedDateRange,
                          style: TextStyle(
                            color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Title
                  Text(
                    trip.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Budget & Note
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (trip.budget > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🎯 Quỹ: ', style: TextStyle(color: Colors.white60, fontSize: 10)),
                              Text(
                                Formatters.formatCurrency(trip.budget),
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (trip.note.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📝 ', style: TextStyle(fontSize: 10)),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 150),
                                child: Text(
                                  trip.note.trim(),
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Action buttons (Edit & Delete)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  color: const Color(0xFF38BDF8),
                  tooltip: 'Chỉnh sửa',
                  onPressed: () => _editTrip(trip),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  tooltip: 'Xóa',
                  onPressed: () => _confirmDeleteTrip(trip),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThousandsDotInputFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat('#,##0', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final raw = newValue.text.replaceAll('.', '').replaceAll(',', '');
    final num? val = num.tryParse(raw);
    if (val == null) {
      return oldValue;
    }
    final formatted = _fmt.format(val);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
