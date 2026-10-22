import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hometown_trip.dart';
import '../../providers/savings_provider.dart';
import 'hometown_planner_dialog.dart';

class HometownBannerStrip extends ConsumerStatefulWidget {
  const HometownBannerStrip({super.key});

  @override
  ConsumerState<HometownBannerStrip> createState() => _HometownBannerStripState();
}

class _HometownBannerStripState extends ConsumerState<HometownBannerStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openPlannerModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const HometownPlannerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeTrip = state.activeHometownTrip;
    final nearestUpcoming = state.nearestUpcomingHometownTrip;
    final currentYear = DateTime.now().year;
    final completedCount = state.completedTripsInYear(currentYear);
    final totalDaysHome = state.totalDaysHomeInYear(currentYear);

    // Color definitions matching Web styles
    final bgColor = isDark ? const Color(0xEE111827) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: (activeTrip != null
                        ? const Color(0xFFF472B6)
                        : const Color(0xFF10B981))
                    .withValues(alpha: isDark ? _glowAnimation.value * 0.25 : 0.08),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Left gradient indicator bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: activeTrip != null
                        ? [const Color(0xFFF472B6), const Color(0xFFEC4899)]
                        : [const Color(0xFF10B981), const Color(0xFF38BDF8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openPlannerModal,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ROW 1: TAG + TITLE + HERO COUNTDOWN BADGE
                      _buildRow1(
                        context,
                        isDark: isDark,
                        activeTrip: activeTrip,
                        nearestUpcoming: nearestUpcoming,
                        currentYear: currentYear,
                        completedCount: completedCount,
                        totalDaysHome: totalDaysHome,
                      ),

                      // ROW 2: CHIPS + LINK (Only if there are trips or stats)
                      const SizedBox(height: 8),
                      _buildRow2(
                        context,
                        isDark: isDark,
                        activeTrip: activeTrip,
                        nearestUpcoming: nearestUpcoming,
                        currentYear: currentYear,
                        completedCount: completedCount,
                        totalDaysHome: totalDaysHome,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow1(
    BuildContext context, {
    required bool isDark,
    required HometownTrip? activeTrip,
    required HometownTrip? nearestUpcoming,
    required int currentYear,
    required int completedCount,
    required int totalDaysHome,
  }) {
    if (activeTrip != null) {
      // ĐANG Ở QUÊ
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildTag(
                  text: '🏡 ĐANG Ở QUÊ',
                  color: const Color(0xFFF472B6),
                  bgColor: const Color(0xFFF472B6).withValues(alpha: 0.14),
                  borderColor: const Color(0xFFF472B6).withValues(alpha: 0.35),
                ),
                Text(
                  activeTrip.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '(${activeTrip.formattedDateRange})',
                  style: TextStyle(
                    color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildHeroBadge(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF472B6).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Đang ở quê',
                    style: TextStyle(
                      color: Color(0xFF500724),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'sum vầy',
                  style: TextStyle(
                    color: Color(0xFFFDF2F8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            isPink: true,
          ),
        ],
      );
    } else if (nearestUpcoming != null) {
      // VỀ QUÊ SẮP TỚI
      final daysLeft = nearestUpcoming.daysLeft;

      Widget badgeContent;
      if (daysLeft == 0) {
        badgeContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚗', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            _buildDigitalChip('Hôm nay', isSpecial: true),
            const SizedBox(width: 4),
            const Text(
              'lên đường!',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        );
      } else if (daysLeft == 1) {
        badgeContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚗', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            _buildDigitalChip('Ngày mai', isAmber: true),
            const SizedBox(width: 4),
            const Text(
              'lên đường!',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        );
      } else {
        badgeContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏳', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 3),
            const Text(
              'Còn',
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            _buildDigitalChip('$daysLeft'),
            const SizedBox(width: 4),
            const Text(
              'ngày nữa',
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildTag(
                  text: '🏡 VỀ QUÊ SẮP TỚI',
                  color: const Color(0xFFFBBF24),
                  bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                  borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                ),
                Text(
                  nearestUpcoming.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '(${nearestUpcoming.formattedDateRange})',
                  style: TextStyle(
                    color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildHeroBadge(child: badgeContent),
        ],
      );
    } else {
      // CHƯA CÓ LỊCH VỀ QUÊ
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildTag(
                  text: '🏡 KẾ HOẠCH VỀ QUÊ',
                  color: const Color(0xFF38BDF8),
                  bgColor: const Color(0xFF38BDF8).withValues(alpha: 0.14),
                  borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                ),
                Text(
                  'Bạn chưa có lịch về quê sắp tới',
                  style: TextStyle(
                    color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 14, color: Colors.white),
                SizedBox(width: 3),
                Text(
                  'Lên kế hoạch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildRow2(
    BuildContext context, {
    required bool isDark,
    required HometownTrip? activeTrip,
    required HometownTrip? nearestUpcoming,
    required int currentYear,
    required int completedCount,
    required int totalDaysHome,
  }) {
    final trip = activeTrip ?? nearestUpcoming;

    return Container(
      padding: const EdgeInsets.only(top: 7),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                if (trip != null && trip.budget > 0)
                  _buildChip(
                    isDark: isDark,
                    icon: '🎯',
                    label: 'Quỹ: ',
                    value: Formatters.formatCurrency(trip.budget),
                    valueColor: const Color(0xFF34D399),
                  ),
                if (trip != null && trip.note.trim().isNotEmpty)
                  _buildChip(
                    isDark: isDark,
                    icon: '📝',
                    value: trip.note.trim(),
                    maxWidth: 140,
                  ),
                _buildChip(
                  isDark: isDark,
                  icon: '🚗',
                  label: 'Năm $currentYear: ',
                  value: activeTrip != null
                      ? '${completedCount + 1} lần'
                      : '$completedCount lần',
                  valueColor: const Color(0xFF38BDF8),
                  suffix: totalDaysHome > 0 ? ' ($totalDaysHome ngày)' : '',
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sổ Lịch Trình',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color: Color(0xFF38BDF8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required String text,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildHeroBadge({required Widget child, bool isPink = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPink
              ? [
                  const Color(0xFFF472B6).withValues(alpha: 0.22),
                  const Color(0xFF9D174D).withValues(alpha: 0.38),
                ]
              : [
                  const Color(0xFF10B981).withValues(alpha: 0.22),
                  const Color(0xFF065F46).withValues(alpha: 0.38),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isPink
              ? const Color(0xFFF472B6).withValues(alpha: 0.65)
              : const Color(0xFF34D399).withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPink ? const Color(0xFFF472B6) : const Color(0xFF10B981))
                .withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDigitalChip(String text, {bool isAmber = false, bool isSpecial = false}) {
    List<Color> gradientColors;
    Color textColor;

    if (isAmber) {
      gradientColors = const [Color(0xFFFBBF24), Color(0xFFF59E0B)];
      textColor = const Color(0xFF451A03);
    } else if (isSpecial) {
      gradientColors = const [Color(0xFF34D399), Color(0xFF10B981)];
      textColor = const Color(0xFF022C22);
    } else {
      gradientColors = const [Color(0xFF34D399), Color(0xFF10B981)];
      textColor = const Color(0xFF022C22);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          height: 1.1,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildChip({
    required bool isDark,
    required String icon,
    String? label,
    required String value,
    Color? valueColor,
    String suffix = '',
    double? maxWidth,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10.5)),
          const SizedBox(width: 3),
          if (label != null)
            Text(
              label,
              style: TextStyle(
                color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (suffix.isNotEmpty)
            Text(
              suffix,
              style: TextStyle(
                color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );

    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      );
    }
    return content;
  }
}
