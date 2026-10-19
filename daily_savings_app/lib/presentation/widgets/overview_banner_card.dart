import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/savings_entry.dart';
import '../../providers/savings_provider.dart';

class OverviewBannerCard extends ConsumerStatefulWidget {
  const OverviewBannerCard({super.key});

  @override
  ConsumerState<OverviewBannerCard> createState() => _OverviewBannerCardState();
}

class _OverviewBannerCardState extends ConsumerState<OverviewBannerCard> {
  // Filter mode: 'GRAB' (default), 'OTHER', 'ALL'
  String _selectedFilter = 'GRAB';
  // Period mode: 'MONTH' (default), 'WEEK'
  String _periodMode = 'MONTH';
  // Week offset: 0 = current week, -1 = last week, etc.
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';

    final double dailyGoal = state.dailyGoal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter relevant entries based on category selection
    List<SavingsEntry> activeEntries;
    int streak;

    if (_selectedFilter == 'GRAB') {
      activeEntries = state.grabEntries;
      streak = state.grabStreakCount;
    } else if (_selectedFilter == 'OTHER') {
      activeEntries = state.otherEntries;
      streak = 0;
    } else {
      activeEntries = state.entries;
      streak = state.streakCount;
    }

    // Week info helper
    final weekInfo = Formatters.getWeekRange(_weekOffset);

    // Period calculations
    double periodTotal;
    double periodTarget;
    double periodCumulativeTarget;
    bool isCurrentPeriod;
    int daysPassedInPeriod;
    String modeTitle;
    String metaText;

    if (_periodMode == 'WEEK') {
      final activeWeekEntries = activeEntries
          .where((e) => weekInfo.dateList.contains(e.date))
          .toList();
      periodTotal = activeWeekEntries.fold(0.0, (sum, item) => sum + item.amount);
      periodTarget = 7 * dailyGoal;
      isCurrentPeriod = weekInfo.isCurrentWeek;

      if (isCurrentPeriod) {
        daysPassedInPeriod = now.weekday; // 1 = Monday ... 7 = Sunday
      } else if (_weekOffset > 0) {
        daysPassedInPeriod = 0;
      } else {
        daysPassedInPeriod = 7;
      }
      periodCumulativeTarget = daysPassedInPeriod * dailyGoal;

      final weekLabelText = _weekOffset == 0
          ? 'TUẦN NÀY'
          : (_weekOffset == -1 ? 'TUẦN TRƯỚC' : 'TUẦN');

      if (_selectedFilter == 'GRAB') {
        modeTitle = 'TIẾN ĐỘ GRAB $weekLabelText (${weekInfo.startDisplay} - ${weekInfo.endDisplay})';
        if (isCurrentPeriod) {
          metaText =
              'Mục tiêu tuần đến nay ($daysPassedInPeriod/7 ngày): ${Formatters.formatShortNumber(periodCumulativeTarget)} / ${Formatters.formatShortNumber(periodTarget)}';
        } else {
          metaText =
              'Tổng mục tiêu tuần (7 ngày): ${Formatters.formatShortNumber(periodTarget)}';
        }
      } else if (_selectedFilter == 'OTHER') {
        modeTitle = 'NGUỒN KHÁC $weekLabelText (${weekInfo.startDisplay} - ${weekInfo.endDisplay})';
        metaText = 'Tổng thu nhập nguồn khác toàn thời gian: ${Formatters.formatShortNumber(state.otherLifetimeTotal)}';
      } else {
        modeTitle = 'TỔNG TẤT CẢ $weekLabelText (${weekInfo.startDisplay} - ${weekInfo.endDisplay})';
        final grabWeek = state.grabEntries
            .where((e) => weekInfo.dateList.contains(e.date))
            .fold(0.0, (s, e) => s + e.amount);
        final otherWeek = state.otherEntries
            .where((e) => weekInfo.dateList.contains(e.date))
            .fold(0.0, (s, e) => s + e.amount);
        metaText =
            'Trong tuần: 🛵 Grab (${Formatters.formatShortNumber(grabWeek)}) + 💼 Khác (${Formatters.formatShortNumber(otherWeek)})';
      }
    } else {
      // MONTH MODE
      final monthEntries =
          activeEntries.where((e) => e.date.startsWith(monthStr)).toList();
      periodTotal = monthEntries.fold(0.0, (sum, item) => sum + item.amount);
      periodTarget = dailyGoal * daysInMonth;
      isCurrentPeriod = true;
      daysPassedInPeriod = now.day;
      periodCumulativeTarget = dailyGoal * now.day;

      if (_selectedFilter == 'GRAB') {
        modeTitle = 'LŨY KẾ GRAB HÔM NAY ($dateStr)';
        metaText =
            'Mục tiêu lũy kế đến nay: ${Formatters.formatShortNumber(periodCumulativeTarget)}';
      } else if (_selectedFilter == 'OTHER') {
        modeTitle = 'THU NHẬP NGUỒN KHÁC ($dateStr)';
        metaText = 'Tổng tiết kiệm từ Lương, Thưởng và Nguồn khác tháng này';
      } else {
        modeTitle = 'TỔNG LŨY KẾ TẤT CẢ ($dateStr)';
        final grabM = state.grabEntries
            .where((e) => e.date.startsWith(monthStr))
            .fold(0.0, (s, e) => s + e.amount);
        final otherM = state.otherEntries
            .where((e) => e.date.startsWith(monthStr))
            .fold(0.0, (s, e) => s + e.amount);
        metaText =
            'Trong tháng: 🛵 Grab (${Formatters.formatShortNumber(grabM)}) + 💼 Khác (${Formatters.formatShortNumber(otherM)})';
      }
    }

    // Pace difference
    final double paceDiff = isCurrentPeriod
        ? (periodTotal - periodCumulativeTarget)
        : (periodTotal - periodTarget);

    // Current month calculations for mini cards (Always based on Grab Month)
    final grabMonthEntries =
        state.grabEntries.where((e) => e.date.startsWith(monthStr)).toList();
    final double grabMonthTotal =
        grabMonthEntries.fold(0.0, (sum, item) => sum + item.amount);
    final double monthTarget = dailyGoal * daysInMonth;
    final double monthProgressPct =
        (grabMonthTotal / monthTarget).clamp(0.0, 1.0);
    final double remainingMonthAmount = max(0.0, monthTarget - grabMonthTotal);

    final int daysLeftInMonth = max(1, daysInMonth - now.day);
    final double neededDailyRate = remainingMonthAmount / daysLeftInMonth;

    // Lifetime total for active filter
    final double activeLifetimeTotal =
        activeEntries.fold(0.0, (sum, item) => sum + item.amount);

    // Yearly calculations for active filter
    DateTime earliestDateInYear = DateTime(now.year, 1, 1);
    if (activeEntries.isNotEmpty) {
      final dates = activeEntries.map((e) {
        final p = e.date.split('-');
        return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      }).where((d) => d.year == now.year).toList();
      if (dates.isNotEmpty) {
        dates.sort((a, b) => a.compareTo(b));
        earliestDateInYear = dates.first;
      }
    }
    final endOfYear = DateTime(now.year, 12, 31);
    final int activeYearDays =
        max(1, endOfYear.difference(earliestDateInYear).inDays + 1);
    final double yearlyTarget = activeYearDays * dailyGoal;

    final double realAvgRate = activeEntries.isEmpty
        ? dailyGoal
        : activeLifetimeTotal / max(1, activeEntries.length);
    final double yearForecast = realAvgRate * activeYearDays;
    final double yearProgressPct =
        (activeLifetimeTotal / yearlyTarget).clamp(0.0, 1.0);

    // Theme Colors
    final cardBg = Theme.of(context).cardColor;
    final innerCardBg = isDark ? AppTheme.bgApp : const Color(0xFFF1F5F9);
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final textMutedColor =
        isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF334155);
    final emeraldTextColor =
        isDark ? AppTheme.emeraldLight : const Color(0xFF047857);
    final amberTextColor =
        isDark ? AppTheme.amberGoldLight : const Color(0xFFB45309);

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
          // Filter Selector Buttons (Chạy Xe Grab / Nguồn Khác / Tất Cả)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: innerCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(child: _buildFilterPill('🛵 Grab', 'GRAB', isDark)),
                const SizedBox(width: 4),
                Expanded(child: _buildFilterPill('💼 Khác', 'OTHER', isDark)),
                const SizedBox(width: 4),
                Expanded(child: _buildFilterPill('🌐 Tất Cả', 'ALL', isDark)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Period Mode Toggle Row (Tháng / Tuần & Tuần Navigation)
          Row(
            children: [
              // Period Toggle Pill
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: innerCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPeriodPill('Tháng', 'MONTH', isDark),
                    _buildPeriodPill('Tuần', 'WEEK', isDark),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Week Navigator (Only shown in WEEK mode)
              if (_periodMode == 'WEEK')
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: innerCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.skyBlueAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => setState(() => _weekOffset--),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: AppTheme.skyBlueAccent,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _weekOffset == 0
                                ? 'Tuần này (${weekInfo.startDisplay} - ${weekInfo.endDisplay})'
                                : (_weekOffset == -1
                                    ? 'Tuần trước (${weekInfo.startDisplay} - ${weekInfo.endDisplay})'
                                    : '${weekInfo.startDisplay} - ${weekInfo.endDisplay}'),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.skyBlueAccent,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _weekOffset++),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppTheme.skyBlueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Header Row
          Row(
            children: [
              Expanded(
                child: Text(
                  modeTitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: textMutedColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_selectedFilter == 'GRAB') ...[
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
            ],
          ),
          const SizedBox(height: 8),

          // Big Savings Amount Display
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                Formatters.formatShortNumber(periodTotal),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: emeraldTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              if (_selectedFilter == 'GRAB')
                Text(
                  isCurrentPeriod
                      ? (paceDiff >= 0
                          ? 'Dư +${Formatters.formatShortNumber(paceDiff)} so với lũy kế'
                          : 'Thiếu -${Formatters.formatShortNumber(paceDiff.abs())} so với lũy kế')
                      : (paceDiff >= 0
                          ? '🎉 Đạt mục tiêu! Dư +${Formatters.formatShortNumber(paceDiff)}'
                          : 'Thiếu -${Formatters.formatShortNumber(paceDiff.abs())} so với mục tiêu'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: paceDiff >= 0 ? emeraldTextColor : Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            metaText,
            style: TextStyle(
              fontSize: 11,
              color: textMutedColor,
            ),
          ),
          const SizedBox(height: 10),

          // Total Breakdown Banner (Chia Rõ Grab / Khác / Tất Cả)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.amberGold.withValues(alpha: 0.12) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.amberGold.withValues(alpha: isDark ? 0.3 : 0.6)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppTheme.amberGold),
                    const SizedBox(width: 6),
                    Text(
                      'TỔNG TÍCH LŨY TOÀN BỘ:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textMuted : const Color(0xFF92400E),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.formatShortNumber(state.lifetimeTotal),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: amberTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Divider(height: 1, color: AppTheme.amberGold.withValues(alpha: 0.3)),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildSubTotalPill(
                      '🛵 Grab',
                      state.currentMonthGrabTotal,
                      state.grabLifetimeTotal,
                      AppTheme.emeraldLight,
                      isDark,
                    ),
                    _buildSubTotalPill(
                      '💼 Khác',
                      state.currentMonthOtherTotal,
                      state.otherLifetimeTotal,
                      AppTheme.skyBlueAccent,
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 2 Mini Overview Cards (Chỉ hiển thị mục tiêu cho tab Grab / Chạy xe)
          if (_selectedFilter == 'GRAB') ...[
            const SizedBox(height: 12),
            Column(
              children: [
                // Card 1: Month Progress
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
                            'TIẾN ĐỘ THÁNG (GRAB)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textMutedColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            Formatters.formatShortNumber(grabMonthTotal),
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

                // Card 2: Year Forecast
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
                            'TIẾN ĐỘ CẢ NĂM (GRAB)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textMutedColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            Formatters.formatShortNumber(activeLifetimeTotal),
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
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, String key, bool isDark) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.emeraldPrimary
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.emeraldPrimary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppTheme.textMuted : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodPill(String title, String key, bool isDark) {
    final isSelected = _periodMode == key;
    return InkWell(
      onTap: () {
        setState(() {
          _periodMode = key;
          if (key == 'WEEK') {
            _weekOffset = 0;
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.skyBlueAccent
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.black87
                : (isDark ? AppTheme.textMuted : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTotalPill(
      String label, double monthAmt, double totalAmt, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            Text(
              'Tháng: ${Formatters.formatShortNumber(monthAmt)} | Tổng: ${Formatters.formatShortNumber(totalAmt)}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
