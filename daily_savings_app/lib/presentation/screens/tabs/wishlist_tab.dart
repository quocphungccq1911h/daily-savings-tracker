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

    if (goals.isEmpty) {
      return const Center(
        child: Text('Chưa có mục tiêu ước mơ nào.',
            style: TextStyle(color: AppTheme.textMuted)),
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
                ? AppTheme.emeraldPrimary.withOpacity(0.15)
                : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.emeraldLight
                  : AppTheme.amberGold.withOpacity(0.4),
            ),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Mục tiêu: ${Formatters.formatShortNumber(item.targetAmount)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
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
                  const Text('Tiến độ tích lũy:',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  Text(
                    '${Formatters.formatShortNumber(currentSaved)} (${(pct * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? AppTheme.emeraldLight
                          : AppTheme.amberGoldLight,
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
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? AppTheme.emeraldLight
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
                  color: AppTheme.skyBlueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.skyBlueAccent.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isCompleted
                      ? '🎉 CHÚC MỪNG! ĐÃ HOÀN THÀNH MỤC TIÊU!'
                      : '🚀 Còn thiếu ${Formatters.formatShortNumber(remaining)} — Dự kiến đạt sau ~$daysNeeded ngày',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.skyBlueAccent,
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
