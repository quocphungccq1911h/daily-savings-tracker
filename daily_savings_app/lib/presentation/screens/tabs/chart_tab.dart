import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/savings_entry.dart';
import '../../../providers/savings_provider.dart';

class ChartTab extends ConsumerStatefulWidget {
  const ChartTab({super.key});

  @override
  ConsumerState<ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends ConsumerState<ChartTab> {
  String _selectedMonth = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);

    // Extract unique months for filter dropdown
    final Set<String> monthsSet = {};
    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    monthsSet.add(currentMonthKey);

    for (var entry in state.entries) {
      if (entry.date.length >= 7) {
        monthsSet.add(entry.date.substring(0, 7));
      }
    }
    final sortedMonthKeys = monthsSet.toList()..sort((a, b) => b.compareTo(a));

    if (!sortedMonthKeys.contains(_selectedMonth)) {
      _selectedMonth = sortedMonthKeys.first;
    }

    // Parse year and month
    final parts = _selectedMonth.split('-');
    final year = int.tryParse(parts[0]) ?? now.year;
    final month = int.tryParse(parts[1]) ?? now.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    // Map amounts per day for selected month
    final Map<int, double> dayAmountMap = {};
    final List<SavingsEntry> monthEntries = [];

    for (var entry in state.entries) {
      if (entry.date.startsWith(_selectedMonth)) {
        monthEntries.add(entry);
        final day = int.tryParse(entry.date.split('-').last) ?? 0;
        if (day >= 1 && day <= daysInMonth) {
          dayAmountMap[day] = (dayAmountMap[day] ?? 0.0) + entry.amount;
        }
      }
    }

    final monthTotal =
        monthEntries.fold(0.0, (sum, item) => sum + item.amount);
    final targetAchievedDaysCount =
        dayAmountMap.values.where((v) => v >= state.dailyGoal).length;
    final avgDailySpeed = state.entries.isEmpty
        ? 0.0
        : state.lifetimeTotal / max(1, state.entries.length);

    // Category Totals for Doughnut Chart
    final Map<String, double> catTotals = {
      'Grab / Chạy xe': 0.0,
      'Lương cố định': 0.0,
      'Thưởng': 0.0,
      'Thu nhập khác': 0.0,
    };

    for (var e in monthEntries) {
      if (catTotals.containsKey(e.category)) {
        catTotals[e.category] = catTotals[e.category]! + e.amount;
      } else {
        catTotals['Thu nhập khác'] = catTotals['Thu nhập khác']! + e.amount;
      }
    }

    final categoryColors = {
      'Grab / Chạy xe': AppTheme.emeraldPrimary,
      'Lương cố định': AppTheme.skyBlueAccent,
      'Thưởng': AppTheme.amberGold,
      'Thu nhập khác': AppTheme.purpleCategory,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Month Filter Bar
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppTheme.skyBlueAccent),
              const SizedBox(width: 8),
              const Text(
                'Tháng xem biểu đồ:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    dropdownColor: AppTheme.bgCard,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.skyBlueAccent,
                    ),
                    items: sortedMonthKeys.map((mKey) {
                      final p = mKey.split('-');
                      final label = p.length == 2
                          ? 'Tháng ${int.parse(p[1])}/${p[0]}'
                          : mKey;
                      return DropdownMenuItem(
                        value: mKey,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedMonth = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CHART 1: XU HƯỚNG TÍCH LŨY THEO NGÀY (BAR CHART)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 XU HƯỚNG TÍCH LŨY THEO NGÀY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppTheme.skyBlueAccent,
                  ),
                ),
                const SizedBox(height: 12),

                // Bar Chart Legend
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldPrimary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Đã tiết kiệm',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 16,
                      height: 2,
                      color: AppTheme.amberGold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mục tiêu (${Formatters.formatShortNumber(state.dailyGoal)})',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bar Chart View
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (dayAmountMap.values.isEmpty
                              ? state.dailyGoal
                              : [
                                  state.dailyGoal,
                                  ...dayAmountMap.values
                                ].reduce((a, b) => a > b ? a : b)) *
                          1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final day = group.x;
                            final val = rod.toY;
                            return BarTooltipItem(
                              'Ngày $day/$month\n${Formatters.formatShortNumber(val)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text('');
                              return Text(
                                '${(value / 1000).toInt()}k',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (value, meta) {
                              final day = value.toInt();
                              if (day % 3 == 1 || day == daysInMonth) {
                                return Text(
                                  '$day',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 9,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: Colors.white.withOpacity(0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: state.dailyGoal,
                            color: AppTheme.amberGold,
                            strokeWidth: 1.5,
                            dashArray: [4, 4],
                          ),
                        ],
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(daysInMonth, (index) {
                        final day = index + 1;
                        final amount = dayAmountMap[day] ?? 0.0;

                        Color barColor = Colors.white10;
                        if (amount >= state.dailyGoal) {
                          barColor = AppTheme.emeraldLight;
                        } else if (amount > 0) {
                          barColor = Colors.redAccent;
                        }

                        return BarChartGroupData(
                          x: day,
                          barRods: [
                            BarChartRodData(
                              toY: amount,
                              color: barColor,
                              width: daysInMonth > 28 ? 6 : 8,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // STATS OVERVIEW CARDS
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TỐC ĐỘ THỰC TẾ',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Formatters.formatShortNumber(avgDailySpeed)}/ngày',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.skyBlueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ĐẠT TARGET THÁNG',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$targetAchievedDaysCount/$daysInMonth ngày',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.emeraldLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CHART 2: TỶ TRỌNG NGUỒN THU THÁNG (DONUT PIE CHART)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 TỶ TRỌNG NGUỒN THU THÁNG',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppTheme.amberGoldLight,
                  ),
                ),
                const SizedBox(height: 16),

                // Doughnut Pie Chart
                SizedBox(
                  height: 200,
                  child: monthTotal == 0
                      ? const Center(
                          child: Text(
                            'Chưa có dữ liệu tiết kiệm tháng này',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 42,
                            sections: catTotals.entries
                                .where((e) => e.value > 0)
                                .map((e) {
                              final pct = (e.value / monthTotal) * 100;
                              return PieChartSectionData(
                                color: categoryColors[e.key] ??
                                    AppTheme.skyBlueAccent,
                                value: e.value,
                                title: '${pct.toStringAsFixed(0)}%',
                                radius: 45,
                                titleStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Category Legends Grid (Matching Web)
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: catTotals.keys.map((cat) {
                    final color =
                        categoryColors[cat] ?? AppTheme.skyBlueAccent;
                    final amt = catTotals[cat] ?? 0.0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$cat (${Formatters.formatShortNumber(amt)})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
