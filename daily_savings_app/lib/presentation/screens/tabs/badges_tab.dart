import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/savings_provider.dart';

class BadgesTab extends ConsumerWidget {
  const BadgesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsProvider);
    final lifetimeSaved = state.lifetimeTotal;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: AppConstants.milestoneBadges.length,
      itemBuilder: (context, index) {
        final badge = AppConstants.milestoneBadges[index];
        final double amount = (badge['amount'] as num).toDouble();
        final bool isUnlocked = lifetimeSaved >= amount;
        final double progressPct =
            (lifetimeSaved / amount).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppTheme.emeraldPrimary.withOpacity(0.15)
                : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnlocked
                  ? AppTheme.emeraldLight
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Text(
                badge['icon'],
                style: TextStyle(
                  fontSize: 32,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          badge['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isUnlocked ? '✨ Đã đạt' : '🔒 Khóa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? AppTheme.emeraldLight
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mục tiêu: ${Formatters.formatShortNumber(amount)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressPct,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUnlocked
                            ? AppTheme.emeraldLight
                            : AppTheme.skyBlueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
