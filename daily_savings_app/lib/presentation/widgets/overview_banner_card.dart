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
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final double monthlyTarget = dailyGoal * daysInMonth;
    final double monthProgressPct = (monthTotal / monthlyTarget).clamp(0.0, 1.0);
    final double monthDiff = monthTotal - (dailyGoal * now.day);

    // Year Forecast
    final int daysInYear = (now.year % 4 == 0) ? 366 : 365;
    final double avgDailyRate = state.entries.isEmpty
        ? dailyGoal
        : lifetimeTotal / max(1, state.entries.length);
    final double yearForecast = avgDailyRate * daysInYear;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
                    : 'Thiếu ${Formatters.formatShortNumber(monthDiff.abs())}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: monthDiff >= 0 ? AppTheme.emeraldLight : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2 Mini Overview Cards Row
          Row(
            children: [
              // Card 1: Month Progress
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
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
                          const Text('TIẾN ĐỘ THÁNG',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted)),
                          Text(
                            Formatters.formatShortNumber(monthTotal),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.emeraldLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: monthProgressPct,
                          minHeight: 6,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.emeraldPrimary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(monthProgressPct * 100).toStringAsFixed(0)}% mục tiêu',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Card 2: Year Forecast
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
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
                          const Text('TIẾN ĐỘ CẢ NĂM',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted)),
                          Text(
                            Formatters.formatShortNumber(lifetimeTotal),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.amberGoldLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (lifetimeTotal / (dailyGoal * daysInYear))
                              .clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.amberGold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dự báo: ${Formatters.formatShortNumber(yearForecast)}',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
