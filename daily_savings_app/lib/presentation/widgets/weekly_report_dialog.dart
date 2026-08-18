import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/savings_provider.dart';

class WeeklyReportDialog extends ConsumerWidget {
  const WeeklyReportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsState = ref.watch(savingsProvider);
    final dailyGoal = savingsState.dailyGoal;
    final weeklyGoal = dailyGoal * 7;

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    double weeklyTotal = 0;
    int savedDaysCount = 0;
    final List<Map<String, dynamic>> daysData = [];
    final Map<String, double> categoryTotals = {};

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dateKey = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
      
      final entriesForDay = savingsState.entries.where((e) => e.date == dateKey).toList();
      double dayAmount = 0;
      for (var entry in entriesForDay) {
        dayAmount += entry.amount;
        if (entry.category.isNotEmpty) {
          categoryTotals[entry.category] = (categoryTotals[entry.category] ?? 0) + entry.amount;
        }
      }

      weeklyTotal += dayAmount;
      if (dayAmount > 0) savedDaysCount++;

      // Chuẩn hóa tên thứ theo tiếng Việt: T2, T3, T4, T5, T6, T7, CN
      String dayLabel;
      switch (dayDate.weekday) {
        case DateTime.monday: dayLabel = 'T2'; break;
        case DateTime.tuesday: dayLabel = 'T3'; break;
        case DateTime.wednesday: dayLabel = 'T4'; break;
        case DateTime.thursday: dayLabel = 'T5'; break;
        case DateTime.friday: dayLabel = 'T6'; break;
        case DateTime.saturday: dayLabel = 'T7'; break;
        case DateTime.sunday: default: dayLabel = 'CN'; break;
      }

      daysData.add({
        'label': dayLabel,
        'amount': dayAmount,
        'isSaved': dayAmount >= dailyGoal,
        'hasPartial': dayAmount > 0 && dayAmount < dailyGoal,
        'dateStr': '${dayDate.day}/${dayDate.month}',
      });
    }

    final double completionPercent = weeklyGoal > 0 ? (weeklyTotal / weeklyGoal * 100).clamp(0, 999) : 0;

    // Tìm danh mục tích lũy cao nhất
    String topCategory = 'Tích lũy chung';
    double maxCatAmount = 0;
    categoryTotals.forEach((cat, amt) {
      if (amt > maxCatAmount) {
        maxCatAmount = amt;
        topCategory = cat;
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = Theme.of(context).cardColor;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);
    final cardBorder = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final innerCardBg = isDark ? AppTheme.bgApp : const Color(0xFFF8FAFC);

    String badgeEmoji = '🏆';
    String badgeTitle = 'XUẤT SẮC TÍCH LŨY!';
    String motivationQuote = 'Bạn đang duy trì thói quen quản lý tài chính cực kỳ kỷ luật!';
    Color accentColor = AppTheme.emeraldPrimary;

    if (completionPercent >= 100) {
      badgeEmoji = '👑';
      badgeTitle = 'BẬC THẦY TIẾT KIỆM TUẦN!';
      motivationQuote = 'Chúc mừng bạn đã hoàn thành 100% mục tiêu tiết kiệm tuần này!';
      accentColor = AppTheme.amberGoldLight;
    } else if (completionPercent >= 70) {
      badgeEmoji = '🔥';
      badgeTitle = 'GIỮ VỮNG PHONG ĐỘ!';
      motivationQuote = 'Bạn đã đạt hơn 70% target tuần. Hãy tiếp tục phát huy nhé!';
      accentColor = AppTheme.skyBlueAccent;
    } else {
      badgeEmoji = '💪';
      badgeTitle = 'CỐ LÊN BẠN ƠI!';
      motivationQuote = 'Mỗi đồng tiết kiệm hôm nay là sự chuẩn bị vững chắc cho tương lai!';
      accentColor = const Color(0xFFF59E0B);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Banner Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor.withValues(alpha: 0.85), accentColor.withValues(alpha: 0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(badgeEmoji, style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BÁO CÁO TỔNG KẾT TUẦN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Đánh giá tiến độ 7 ngày 📊',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Badge Status Title
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          badgeTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Weekly Total Saved Amount Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: innerCardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Tổng Tích Lũy Tuần Này',
                              style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Formatters.formatShortNumber(weeklyTotal),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.emeraldPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (completionPercent / 100).clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Target Tuần: ${Formatters.formatShortNumber(weeklyGoal)}',
                                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                                ),
                                Text(
                                  '${completionPercent.toStringAsFixed(0)}% Đạt Target',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: accentColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 7-Day Checklist Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: innerCardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Chuỗi 7 Ngày Trong Tuần',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emeraldPrimary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$savedDaysCount/7 Ngày',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: daysData.map((d) {
                                final bool isSaved = d['isSaved'] as bool;
                                final bool hasPartial = d['hasPartial'] as bool;
                                final String label = d['label'] as String;
                                final String dateStr = d['dateStr'] as String;

                                Color statusColor = isDark ? Colors.white24 : const Color(0xFFCBD5E1);
                                IconData iconData = Icons.radio_button_unchecked_rounded;
                                if (isSaved) {
                                  statusColor = AppTheme.emeraldPrimary;
                                  iconData = Icons.check_circle_rounded;
                                } else if (hasPartial) {
                                  statusColor = AppTheme.skyBlueAccent;
                                  iconData = Icons.star_half_rounded;
                                }

                                return Column(
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: label == 'CN' ? Colors.redAccent : secondaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Icon(iconData, size: 22, color: statusColor),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr,
                                      style: TextStyle(fontSize: 9, color: secondaryTextColor, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Top Savings Source & Quote Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          children: [
                            if (maxCatAmount > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🏷️', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Nguồn chính: $topCategory (${Formatters.formatShortNumber(maxCatAmount)})',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              '💡 "$motivationQuote"',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: secondaryTextColor, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Primary Close Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Đã Giữ Phong Độ!',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
