import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/wishlist_goal.dart';
import '../../../providers/savings_provider.dart';

class WishlistTab extends ConsumerWidget {
  const WishlistTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsProvider);
    final goals = List<WishlistGoal>.from(state.wishlistGoals)
      ..sort((a, b) => a.targetAmount.compareTo(b.targetAmount));
    final totalLifetimeSaved = state.lifetimeTotal;

    // Daily pace
    final dailyPace = state.dailyGoal;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final emeraldTextColor = isDark ? AppTheme.emeraldLight : const Color(0xFF047857);
    final amberTextColor = isDark ? AppTheme.amberGoldLight : const Color(0xFFB45309);
    final skyBlueTextColor = isDark ? AppTheme.skyBlueAccent : const Color(0xFF0284C7);

    if (goals.isEmpty) {
      return Center(
        child: Text('Chưa có mục tiêu ước mơ nào.',
            style: TextStyle(color: textMutedColor)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final item = goals[index];
        final currentSaved = min(item.targetAmount,
            max(item.allocatedAmount, totalLifetimeSaved));
        final double pct = (currentSaved / item.targetAmount).clamp(0.0, 1.0);
        final bool isCompleted = pct >= 1.0;
        final double remaining = max(0.0, item.targetAmount - currentSaved);
        final int daysNeeded = (remaining / dailyPace).ceil();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Mục tiêu: ${Formatters.formatShortNumber(item.targetAmount)}',
                          style: TextStyle(
                              fontSize: 12, color: textMutedColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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
                      color: isCompleted
                          ? emeraldTextColor
                          : amberTextColor,
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
                    isCompleted
                        ? emeraldTextColor
                        : AppTheme.amberGold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Forecast Note
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  isCompleted
                      ? '🎉 CHÚC MỪNG! ĐÃ HOÀN THÀNH MỤC TIÊU!'
                      : '🚀 Còn thiếu ${Formatters.formatShortNumber(remaining)} — Dự kiến đạt sau ~$daysNeeded ngày',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: skyBlueTextColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
