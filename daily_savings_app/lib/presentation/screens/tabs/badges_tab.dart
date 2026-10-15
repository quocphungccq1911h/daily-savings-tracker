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
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);
    final emeraldTextColor = isDark ? AppTheme.emeraldLight : const Color(0xFF047857);

    final unlockedCount = AppConstants.milestoneBadges
        .where((b) => lifetimeSaved >= (b['amount'] as num))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏆 Header Summary Row (matching Web)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.borderColor : AppTheme.borderColorLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'DANH SÁCH HUY HIỆU ($unlockedCount/${AppConstants.milestoneBadges.length})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: 'Toàn thời gian: ',
                    style: TextStyle(fontSize: 10.5, color: textMutedColor),
                    children: [
                      TextSpan(
                        text: Formatters.formatShortNumber(lifetimeSaved),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: emeraldTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Milestone Cards List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppConstants.milestoneBadges.length,
            itemBuilder: (context, index) {
              final badge = AppConstants.milestoneBadges[index];
              final double amount = (badge['amount'] as num).toDouble();
              final bool isUnlocked = lifetimeSaved >= amount;
              final double remaining = amount - lifetimeSaved;
              final double progressPct = (lifetimeSaved / amount).clamp(0.0, 1.0);
              final int pct = ((lifetimeSaved / amount) * 100).clamp(0, 100).round();

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
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
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.85,
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
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Badge Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Status Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        '#${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: textMutedColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          badge['name'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: isUnlocked
                                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                                : textColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isUnlocked
                                        ? emeraldTextColor.withValues(alpha: 0.15)
                                        : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isUnlocked
                                          ? emeraldTextColor.withValues(alpha: 0.4)
                                          : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  child: Text(
                                    isUnlocked ? '✨ Đã đạt' : '🔒 Khóa',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isUnlocked ? emeraldTextColor : textMutedColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),

                            // Target Amount
                            Text(
                              'Mục tiêu: ${Formatters.formatShortNumber(amount)}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textMutedColor,
                              ),
                            ),
                            const SizedBox(height: 7),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressPct,
                                minHeight: 6,
                                backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isUnlocked
                                      ? emeraldTextColor
                                      : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // 🎯 FOOTER (matching Web): Lock status + Percentage & Remaining missing amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isUnlocked
                                      ? '🎉 ✓ Đã Hoàn Thành'
                                      : '🔒 Khóa ($pct%)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isUnlocked
                                        ? emeraldTextColor
                                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                  ),
                                ),
                                Text(
                                  isUnlocked
                                      ? Formatters.formatShortNumber(amount)
                                      : 'Thiếu ${Formatters.formatShortNumber(remaining)}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w700,
                                    color: isUnlocked
                                        ? textMutedColor
                                        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
