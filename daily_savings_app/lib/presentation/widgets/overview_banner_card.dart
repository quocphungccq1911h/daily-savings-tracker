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
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';

    final double monthTotal = state.currentMonthTotal;
    final double lifetimeTotal = state.lifetimeTotal;
    final int streak = state.streakCount;
    final double dailyGoal = state.dailyGoal;

    // Monthly Target Progress
    final int currentDay = now.day;
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final double monthlyTarget = dailyGoal * daysInMonth;
    final double monthProgressPct = (monthTotal / monthlyTarget).clamp(0.0, 1.0);
    final double monthExpectedTarget = dailyGoal * currentDay;
    final double monthDiff = monthTotal - monthExpectedTarget;
    final double remainingMonthAmount = max(0.0, monthlyTarget - monthTotal);
    final int daysLeftInMonth = max(1, daysInMonth - currentDay + 1);
    final double neededDailyRate = remainingMonthAmount / daysLeftInMonth;

    // Year Forecast & Active Days Target
    final currentYearStr = '${now.year}';
    final yearEntries = state.entries.where((e) => e.date.startsWith(currentYearStr)).toList();
    DateTime earliestDateInYear = DateTime(now.year, 1, 1);
    if (yearEntries.isNotEmpty) {
      final dates = yearEntries
          .map((e) => DateTime.tryParse(e.date))
          .whereType<DateTime>()
          .toList();
      if (dates.isNotEmpty) {
        final minDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
        if (minDate.year == now.year) {
          earliestDateInYear = minDate;
        }
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.textMuted,
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
                      color: const Color(0xFFF59E0B).withOpacity(0.4),
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
          // Big Savings Amount Display
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                Formatters.formatShortNumber(monthTotal),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.emeraldLight,
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
                  color: monthDiff >= 0 ? AppTheme.emeraldLight : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mục tiêu lũy kế đến nay: ${Formatters.formatShortNumber(monthExpectedTarget)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 10),

          // Total Lifetime Savings Banner (Tổng Tiết Kiệm Tích Lũy Toàn Bộ)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.amberGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.amberGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 16, color: AppTheme.amberGoldLight),
                const SizedBox(width: 8),
                const Text(
                  'Tổng Tích Lũy Toàn Bộ:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.formatShortNumber(lifetimeTotal),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.amberGoldLight,
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
                  color: AppTheme.bgApp,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TIẾN ĐỘ THÁNG',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          Formatters.formatShortNumber(monthTotal),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.emeraldLight,
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
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.emeraldPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(monthProgressPct * 100).toStringAsFixed(0)}% mục tiêu',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          remainingMonthAmount > 0
                              ? 'Thiếu: ${Formatters.formatShortNumber(remainingMonthAmount)}'
                              : 'Đạt 100%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: remainingMonthAmount > 0
                                ? Colors.redAccent
                                : AppTheme.emeraldLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remainingMonthAmount > 0
                          ? 'Cần ~${Formatters.formatShortNumber(neededDailyRate)}/ngày cho $daysLeftInMonth ngày còn lại.'
                          : '🎉 Đã hoàn thành mục tiêu tháng!',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
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
                  color: AppTheme.bgApp,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TIẾN ĐỘ CẢ NĂM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          Formatters.formatShortNumber(lifetimeTotal),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.amberGoldLight,
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
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.amberGold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(yearProgressPct * 100).toStringAsFixed(1)}% (${Formatters.formatShortNumber(yearlyTarget)})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Dự báo: ${Formatters.formatShortNumber(yearForecast)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.amberGoldLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tốc độ thực tế: ${Formatters.formatShortNumber(realAvgRate)}/ngày',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
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
