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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final emeraldTextColor = isDark ? AppTheme.emeraldLight : const Color(0xFF047857);

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
                ? (isDark ? AppTheme.emeraldPrimary.withValues(alpha: 0.12) : const Color(0xFFECFDF5))
                : cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnlocked
                  ? emeraldTextColor
                  : (isDark ? AppTheme.borderColor : AppTheme.borderColorLight),
              width: isUnlocked ? 1.5 : 1.0,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: AppTheme.emeraldPrimary.withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Opacity(
            opacity: isUnlocked ? 1.0 : 0.7,
            child: Row(
              children: [
                // Badge Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppTheme.emeraldPrimary.withValues(alpha: 0.2)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
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
                              color: isUnlocked
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : textColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? emeraldTextColor.withValues(alpha: 0.15)
                                  : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isUnlocked
                                    ? emeraldTextColor.withValues(alpha: 0.4)
                                    : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            child: Text(
                              isUnlocked ? '✨ Đã đạt' : '🔒 Đang khóa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? emeraldTextColor
                                    : textMutedColor,
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
                          color: textMutedColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPct,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isUnlocked
                                ? emeraldTextColor
                                : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
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
