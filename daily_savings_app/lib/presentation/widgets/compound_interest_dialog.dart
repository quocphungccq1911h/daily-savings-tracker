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
  late double _dailyAmount;
  double _interestRate = 6.0; // 6%/năm
  int _selectedYears = 1;

  @override
  void initState() {
    super.initState();
    _dailyAmount = ref.read(savingsProvider).dailyGoal;
  }

  /// Calculates total accumulated amount with compound interest
  /// Formula: P = dailyAmount * 365
  /// Future value = sum of annuity with annual deposit & monthly interest compounding
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
    final double interestGained = max(0, futureVal - rawSavings);

    return AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.calculate_outlined, color: AppTheme.amberGoldLight),
          SizedBox(width: 8),
          Text(
            '🧮 Dự Báo Lãi Kép & Tích Lũy',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tính toán sức mạnh của tích lũy hằng ngày khi được gửi tiết kiệm sinh lời:',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 14),

            // Daily Deposit & Interest Rate sliders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mức gửi ngày:', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                const Text('Lãi suất ngân hàng:', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
              inactiveColor: AppTheme.bgApp,
              onChanged: (val) => setState(() => _interestRate = val),
            ),
            const SizedBox(height: 10),

            // Time horizon selector (1, 3, 5, 10 năm)
            const Text('Thời gian tích lũy:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 3, 5, 10].map((y) {
                final isSelected = _selectedYears == y;
                return ChoiceChip(
                  label: Text('$y Năm'),
                  selected: isSelected,
                  selectedColor: AppTheme.skyBlueAccent,
                  backgroundColor: AppTheme.bgApp,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedYears = y),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Result summary card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgApp,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiền gốc tự tiết kiệm:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      Text(Formatters.formatShortNumber(rawSavings), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiền lãi phát sinh (+):', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      Text('+${Formatters.formatShortNumber(interestGained)}', style: const TextStyle(color: AppTheme.amberGoldLight, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const Divider(color: AppTheme.borderColor, height: 16),
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
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.skyBlueAccent),
          child: const Text('Đóng', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
