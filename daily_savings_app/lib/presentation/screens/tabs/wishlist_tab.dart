import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/wishlist_goal.dart';
import '../../../providers/savings_provider.dart';

class WishlistTab extends ConsumerStatefulWidget {
  const WishlistTab({super.key});

  @override
  ConsumerState<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends ConsumerState<WishlistTab> {
  String _selectedMode = 'MILESTONE'; // 'MILESTONE' | 'WATERFALL'

  String _formatEstimatedDuration(int daysNeeded) {
    if (daysNeeded <= 0) return 'Đã hoàn thành';
    final targetDate = DateTime.now().add(Duration(days: daysNeeded));
    final monthYearStr = 'T${targetDate.month}/${targetDate.year}';

    if (daysNeeded < 60) {
      return '~$daysNeeded ngày nữa (Dự kiến: $monthYearStr)';
    }
    final years = daysNeeded ~/ 365;
    final months = ((daysNeeded % 365) / 30).round();
    String humanDuration = '';
    if (years > 0 && months > 0) {
      humanDuration = '~$years năm $months tháng';
    } else if (years > 0) {
      humanDuration = '~$years năm';
    } else {
      final m = max(1, (daysNeeded / 30).round());
      humanDuration = '~$m tháng';
    }
    return '$humanDuration / $daysNeeded ngày (Dự kiến: $monthYearStr)';
  }

  void _showGoalDialog(BuildContext context, {WishlistGoal? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final targetCtrl = TextEditingController(
      text: existing != null ? existing.targetAmount.toStringAsFixed(0) : '',
    );
    final allocatedCtrl = TextEditingController(
      text: existing != null ? existing.allocatedAmount.toStringAsFixed(0) : '0',
    );
    String selectedEmoji = existing?.emoji ?? '🛡️';

    const emojis = [
      {'e': '🛡️', 'l': 'Dự phòng'},
      {'e': '🪙', 'l': 'Mua vàng'},
      {'e': '🛵', 'l': 'Xe máy'},
      {'e': '📜', 'l': 'Sổ TK'},
      {'e': '🏞️', 'l': 'Mua đất'},
      {'e': '🏠', 'l': 'Xây nhà'},
      {'e': '📱', 'l': 'Điện thoại'},
      {'e': '💻', 'l': 'Đồ nghề'},
      {'e': '🚗', 'l': 'Ô tô'},
      {'e': '✈️', 'l': 'Du lịch'},
      {'e': '💍', 'l': 'Gia đình'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: Text(
                existing == null ? '➕ Thêm Mục Tiêu Mới' : '✏️ Chỉnh Sửa Mục Tiêu',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên mục tiêu',
                        hintText: 'VD: Mua 3 chỉ Vàng / Mua đất',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền mục tiêu (VNĐ)',
                        hintText: '30000000',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: allocatedCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền gán riêng (tùy chọn)',
                        hintText: '0',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Biểu tượng:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: emojis.map((item) {
                        final e = item['e']!;
                        final l = item['l']!;
                        final isSelected = selectedEmoji == e;
                        return ChoiceChip(
                          label: Text('$e $l', style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (_) {
                            setModalState(() => selectedEmoji = e);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final target = double.tryParse(
                            targetCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                        0;
                    final allocated = double.tryParse(allocatedCtrl.text
                            .replaceAll(RegExp(r'[^0-9]'), '')) ??
                        0;
                    if (title.isEmpty || target < 100000) return;
                    final goal = WishlistGoal(
                      id: existing?.id ??
                          'wishlist-${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      targetAmount: target,
                      allocatedAmount: allocated,
                      emoji: selectedEmoji,
                    );
                    ref.read(savingsProvider.notifier).addOrUpdateGoal(goal);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);
    final goals = List<WishlistGoal>.from(state.wishlistGoals)
      ..sort((a, b) => a.targetAmount.compareTo(b.targetAmount));
    final totalLifetimeSaved = state.lifetimeTotal;

    // Tính tốc độ tích lũy thực tế trong tháng hiện tại (giống bản Web)
    final now = DateTime.now();
    final daysPassed = max(1, now.day);
    final avgDailyPace = (state.currentMonthTotal / daysPassed).roundToDouble();
    final effectivePace = max(avgDailyPace, state.dailyGoal);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final emeraldTextColor = isDark ? AppTheme.emeraldLight : const Color(0xFF047857);
    final amberTextColor = isDark ? AppTheme.amberGoldLight : const Color(0xFFB45309);
    final skyBlueTextColor = isDark ? AppTheme.skyBlueAccent : const Color(0xFF0284C7);

    double remainingWaterfallPool = totalLifetimeSaved;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '🎯 MỤC TIÊU & DỰ BÁO HOÀN THÀNH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: amberTextColor,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(savingsProvider.notifier).resetDefaultWishlistGoals();
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Bộ 6 chuẩn', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () => _showGoalDialog(context),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Thêm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mode Switcher Pills (Milestone vs Waterfall)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMode = 'MILESTONE'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _selectedMode == 'MILESTONE'
                          ? AppTheme.emeraldPrimary.withValues(alpha: 0.2)
                          : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedMode == 'MILESTONE'
                            ? emeraldTextColor
                            : (isDark ? AppTheme.borderColor : AppTheme.borderColorLight),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '📊 Theo tổng tài sản',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _selectedMode == 'MILESTONE' ? emeraldTextColor : textMutedColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMode = 'WATERFALL'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _selectedMode == 'WATERFALL'
                          ? AppTheme.emeraldPrimary.withValues(alpha: 0.2)
                          : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedMode == 'WATERFALL'
                            ? emeraldTextColor
                            : (isDark ? AppTheme.borderColor : AppTheme.borderColorLight),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '🪣 Rót đầy từng hũ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _selectedMode == 'WATERFALL' ? emeraldTextColor : textMutedColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (goals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Chưa có mục tiêu ước mơ nào.',
                  style: TextStyle(color: textMutedColor),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final item = goals[index];
                double currentSaved = 0;

                if (_selectedMode == 'WATERFALL') {
                  final fromPool = min(item.targetAmount, max(0.0, remainingWaterfallPool));
                  currentSaved = min(item.targetAmount, max(item.allocatedAmount, fromPool));
                  remainingWaterfallPool = max(0.0, remainingWaterfallPool - currentSaved);
                } else {
                  currentSaved = min(item.targetAmount, max(item.allocatedAmount, totalLifetimeSaved));
                }

                final double pct = (currentSaved / item.targetAmount).clamp(0.0, 1.0);
                final bool isCompleted = pct >= 1.0;
                final double remaining = max(0.0, item.targetAmount - currentSaved);
                final int daysNeeded = (remaining / effectivePace).ceil();

                String forecastText;
                if (isCompleted) {
                  forecastText = '🎉 CHÚC MỪNG! ĐÃ HOÀN THÀNH MỤC TIÊU NÀY!';
                } else if (currentSaved > 0) {
                  forecastText =
                      '🚀 Còn thiếu ${Formatters.formatShortNumber(remaining)} — ${_formatEstimatedDuration(daysNeeded)} (${Formatters.formatShortNumber(effectivePace)}/ngày)';
                } else {
                  forecastText =
                      '⏳ Chờ rót vốn (Cần ${Formatters.formatShortNumber(remaining)}) — ${_formatEstimatedDuration(daysNeeded)}';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? (isDark ? AppTheme.emeraldPrimary.withValues(alpha: 0.15) : const Color(0xFFECFDF5))
                        : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted
                          ? emeraldTextColor
                          : AppTheme.amberGold.withValues(alpha: isDark ? 0.4 : 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${index + 1} ${item.title}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Mục tiêu: ${Formatters.formatShortNumber(item.targetAmount)}',
                                  style: TextStyle(fontSize: 12, color: textMutedColor),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.orangeAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showGoalDialog(context, existing: item),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              ref.read(savingsProvider.notifier).deleteGoal(item.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tiến độ tích lũy:',
                              style: TextStyle(fontSize: 12, color: textMutedColor)),
                          Text(
                            '${Formatters.formatShortNumber(currentSaved)} (${(pct * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? emeraldTextColor : amberTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? emeraldTextColor : AppTheme.amberGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Forecast Note
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.skyBlueAccent.withValues(alpha: 0.1)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.skyBlueAccent.withValues(alpha: 0.3)
                                : const Color(0xFFBAE6FD),
                          ),
                        ),
                        child: Text(
                          forecastText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: skyBlueTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
