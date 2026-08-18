import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/savings_provider.dart';

class CompoundInterestDialog extends ConsumerStatefulWidget {
  const CompoundInterestDialog({super.key});

  @override
  ConsumerState<CompoundInterestDialog> createState() => _CompoundInterestDialogState();
}

class _CompoundInterestDialogState extends ConsumerState<CompoundInterestDialog> {
  double _interestRate = 6.0; // 6.0% default bank savings interest rate
  int _selectedYears = 3; // 3 years default horizon
  late double _dailyAmount;

  @override
  void initState() {
    super.initState();
    _dailyAmount = ref.read(savingsProvider).dailyGoal;
  }

  double _calculateFutureValue(int years) {
    final double yearlyDeposit = _dailyAmount * 365;
    final double r = _interestRate / 100;
    double total = 0;
    for (int i = 0; i < years; i++) {
      total = (total + yearlyDeposit) * (1 + r);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final double rawSavings = _dailyAmount * 365 * _selectedYears;
    final double futureVal = _calculateFutureValue(_selectedYears);
    final double interestGained = max(0.0, futureVal - rawSavings);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final textColor = isDark ? Colors.white : Colors.black87;
    final innerBgColor = isDark ? AppTheme.bgApp : const Color(0xFFF1F5F9);
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: AppTheme.amberGoldLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '🧮 Dự Báo Lãi Kép & Tích Lũy',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tính toán sức mạnh của tích lũy hằng ngày khi được gửi tiết kiệm sinh lời:',
              style: TextStyle(color: textMutedColor, fontSize: 11),
            ),
            const SizedBox(height: 14),

            // Daily Deposit & Interest Rate sliders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mức gửi ngày:', style: TextStyle(color: textColor, fontSize: 12)),
                Text(
                  Formatters.formatShortNumber(_dailyAmount),
                  style: const TextStyle(color: AppTheme.emeraldLight, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lãi suất ngân hàng:', style: TextStyle(color: textColor, fontSize: 12)),
                Text(
                  '${_interestRate.toStringAsFixed(1)}%/năm',
                  style: const TextStyle(color: AppTheme.amberGoldLight, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            Slider(
              value: _interestRate,
              min: 1.0,
              max: 12.0,
              divisions: 22,
              activeColor: AppTheme.amberGoldLight,
              inactiveColor: isDark ? AppTheme.bgApp : const Color(0xFFE2E8F0),
              onChanged: (val) => setState(() => _interestRate = val),
            ),
            const SizedBox(height: 10),

            // Time horizon selector (1, 3, 5, 10 năm)
            Text('Thời gian tích lũy:', style: TextStyle(color: textColor, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [1, 3, 5, 10].map((y) {
                final isSelected = _selectedYears == y;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      labelPadding: EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Center(
                        child: Text(
                          '$y Năm',
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.skyBlueAccent,
                      backgroundColor: innerBgColor,
                      onSelected: (_) => setState(() => _selectedYears = y),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Result summary card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: innerBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tiền gốc tự tiết kiệm:', style: TextStyle(color: textMutedColor, fontSize: 11)),
                      Text(Formatters.formatShortNumber(rawSavings), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tiền lãi phát sinh (+):', style: TextStyle(color: textMutedColor, fontSize: 11)),
                      Text('+${Formatters.formatShortNumber(interestGained)}', style: const TextStyle(color: AppTheme.amberGoldLight, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  Divider(color: borderColor, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG TÀI SẢN DỰ KIẾN:', style: TextStyle(color: AppTheme.emeraldLight, fontWeight: FontWeight.bold, fontSize: 11)),
                      Text(
                        Formatters.formatShortNumber(futureVal),
                        style: const TextStyle(color: AppTheme.emeraldLight, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldLight),
          child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
