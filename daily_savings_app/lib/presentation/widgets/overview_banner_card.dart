import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/savings_provider.dart';

class OverviewBannerCard extends ConsumerWidget {
  const OverviewBannerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsProvider);

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';

    final double dailyGoal = state.dailyGoal;
    final int streak = state.streakCount;
    final double lifetimeTotal = state.lifetimeTotal;

    // Filter entries for current month
    final monthEntries = state.entries.where((e) => e.date.startsWith(monthStr)).toList();
    final double monthTotal = monthEntries.fold(0.0, (sum, item) => sum + item.amount);
    final double monthTarget = dailyGoal * daysInMonth;
    final double monthProgressPct = (monthTotal / monthTarget).clamp(0.0, 1.0);
    final double remainingMonthAmount = max(0.0, monthTarget - monthTotal);

    final int daysLeftInMonth = max(1, daysInMonth - now.day);
    final double neededDailyRate = remainingMonthAmount / daysLeftInMonth;

    final double monthExpectedTarget = dailyGoal * now.day;
    final double monthDiff = monthTotal - monthExpectedTarget;

    // Yearly calculations
    DateTime earliestDateInYear = DateTime(now.year, 1, 1);
    if (state.entries.isNotEmpty) {
      final dates = state.entries.map((e) {
        final p = e.date.split('-');
        return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      }).where((d) => d.year == now.year).toList();
      if (dates.isNotEmpty) {
        dates.sort((a, b) => a.compareTo(b));
        earliestDateInYear = dates.first;
      }
    }
    final endOfYear = DateTime(now.year, 12, 31);
    final int activeYearDays = max(1, endOfYear.difference(earliestDateInYear).inDays + 1);
    final double yearlyTarget = activeYearDays * dailyGoal;

    final double realAvgRate = state.entries.isEmpty
        ? dailyGoal
        : lifetimeTotal / max(1, state.entries.length);
    final double yearForecast = realAvgRate * activeYearDays;
    final double yearProgressPct = (lifetimeTotal / yearlyTarget).clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final innerCardBg = isDark ? AppTheme.bgApp : const Color(0xFFF1F5F9);
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF334155);
    final emeraldTextColor = isDark ? AppTheme.emeraldLight : const Color(0xFF047857);
    final amberTextColor = isDark ? AppTheme.amberGoldLight : const Color(0xFFB45309);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Text(
                  'LŨY KẾ ĐẾN HÔM NAY ($dateStr)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: textMutedColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'Chuỗi $streak ngày',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Big Savings Amount Display
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                Formatters.formatShortNumber(monthTotal),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: emeraldTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                monthDiff >= 0
                    ? 'Dư +${Formatters.formatShortNumber(monthDiff)} so với lũy kế'
                    : 'Thiếu -${Formatters.formatShortNumber(monthDiff.abs())} so với lũy kế',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: monthDiff >= 0 ? emeraldTextColor : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mục tiêu lũy kế đến nay: ${Formatters.formatShortNumber(monthExpectedTarget)}',
            style: TextStyle(
              fontSize: 11,
              color: textMutedColor,
            ),
          ),
          const SizedBox(height: 10),

          // Total Lifetime Savings Banner (Tổng Tiết Kiệm Tích Lũy Toàn Bộ)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.amberGold.withValues(alpha: 0.12) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.amberGold.withValues(alpha: isDark ? 0.3 : 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppTheme.amberGold),
                const SizedBox(width: 8),
                Text(
                  'Tổng Tích Lũy Toàn Bộ:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textMuted : const Color(0xFF92400E),
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.formatShortNumber(lifetimeTotal),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: amberTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2 Mini Overview Cards in Vertical List Format
          Column(
            children: [
              // Card 1: Month Progress (Full Width)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: innerCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TIẾN ĐỘ THÁNG',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textMutedColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          Formatters.formatShortNumber(monthTotal),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: emeraldTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: monthProgressPct,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.emeraldPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(monthProgressPct * 100).toStringAsFixed(0)}% mục tiêu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          remainingMonthAmount > 0
                              ? 'Thiếu: ${Formatters.formatShortNumber(remainingMonthAmount)}'
                              : 'Đạt 100%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: remainingMonthAmount > 0 ? Colors.redAccent : emeraldTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remainingMonthAmount > 0
                          ? 'Cần ~${Formatters.formatShortNumber(neededDailyRate)}/ngày cho $daysLeftInMonth ngày còn lại.'
                          : '🎉 Đã hoàn thành mục tiêu tháng!',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Card 2: Year Forecast (Full Width)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: innerCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TIẾN ĐỘ CẢ NĂM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textMutedColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          Formatters.formatShortNumber(lifetimeTotal),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: amberTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: yearProgressPct,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.amberGold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(yearProgressPct * 100).toStringAsFixed(1)}% (${Formatters.formatShortNumber(yearlyTarget)})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Dự báo: ${Formatters.formatShortNumber(yearForecast)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: amberTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tốc độ thực tế: ${Formatters.formatShortNumber(realAvgRate)}/ngày',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
