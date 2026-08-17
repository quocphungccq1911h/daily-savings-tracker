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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: AppConstants.milestoneBadges.length,
      itemBuilder: (context, index) {
        final badge = AppConstants.milestoneBadges[index];
        final double amount = (badge['amount'] as num).toDouble();
        final bool isUnlocked = lifetimeSaved >= amount;
        final double progressPct =
            (lifetimeSaved / amount).clamp(0.0, 1.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppTheme.emeraldPrimary.withOpacity(0.12)
                : AppTheme.bgApp.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnlocked
                  ? AppTheme.emeraldLight
                  : AppTheme.borderColor.withOpacity(0.4),
              width: isUnlocked ? 1.5 : 1.0,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: AppTheme.emeraldPrimary.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Opacity(
            opacity: isUnlocked ? 1.0 : 0.45, // Làm mờ mờ huy hiệu chưa active
            child: Row(
              children: [
                // Badge Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppTheme.emeraldPrimary.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge['icon'],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 14),

                // Badge Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            badge['name'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.white : Colors.white70,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? AppTheme.emeraldLight.withOpacity(0.15)
                                  : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isUnlocked
                                    ? AppTheme.emeraldLight.withOpacity(0.4)
                                    : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              isUnlocked ? '✨ Đã đạt' : '🔒 Đang khóa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? AppTheme.emeraldLight
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mục tiêu: ${Formatters.formatShortNumber(amount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked
                              ? AppTheme.textMuted
                              : AppTheme.textMuted.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPct,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isUnlocked
                                ? AppTheme.emeraldLight
                                : Colors.white30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
