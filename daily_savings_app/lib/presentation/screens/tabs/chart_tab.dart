import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/savings_provider.dart';

class ChartTab extends ConsumerWidget {
  const ChartTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsProvider);

    // Calculate category totals
    final Map<String, double> catTotals = {
      'Grab / Chạy xe': 0.0,
      'Lương cố định': 0.0,
      'Thưởng': 0.0,
      'Khác': 0.0,
    };

    for (var e in state.entries) {
      if (catTotals.containsKey(e.category)) {
        catTotals[e.category] = catTotals[e.category]! + e.amount;
      } else {
        catTotals['Khác'] = catTotals['Khác']! + e.amount;
      }
    }

    final totalAmount = catTotals.values.fold(0.0, (a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title: Pie Chart
          const Text(
            '📊 TỶ TRỌNG NGUỒN THU THÁNG',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.amberGoldLight,
            ),
          ),
          const SizedBox(height: 16),

          // Doughnut Pie Chart
          SizedBox(
            height: 220,
            child: totalAmount == 0
                ? const Center(
                    child: Text('Chưa có dữ liệu biểu đồ',
                        style: TextStyle(color: AppTheme.textMuted)),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.emeraldPrimary,
                          value: catTotals['Grab / Chạy xe'],
                          title: 'Grab',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: AppTheme.skyBlueAccent,
                          value: catTotals['Lương cố định'],
                          title: 'Lương',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: AppTheme.amberGold,
                          value: catTotals['Thưởng'],
                          title: 'Thưởng',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: AppTheme.purpleCategory,
                          value: catTotals['Khác'],
                          title: 'Khác',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
