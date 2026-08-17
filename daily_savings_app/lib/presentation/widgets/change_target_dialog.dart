import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/savings_provider.dart';

class ChangeTargetDialog extends ConsumerStatefulWidget {
  const ChangeTargetDialog({super.key});

  @override
  ConsumerState<ChangeTargetDialog> createState() => _ChangeTargetDialogState();
}

class _ChangeTargetDialogState extends ConsumerState<ChangeTargetDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final currentGoal = ref.read(savingsProvider).dailyGoal;
    _controller = TextEditingController(text: currentGoal.toInt().toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveTarget() {
    final rawText = _controller.text.replaceAll('.', '').replaceAll(',', '').trim();
    final double? val = double.tryParse(rawText);
    if (val != null && val > 0) {
      ref.read(savingsProvider.notifier).updateDailyGoal(val);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎯 Đã đổi mục tiêu ngày thành ${Formatters.formatShortNumber(val)}!'),
          backgroundColor: AppTheme.emeraldLight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBg = isDark ? AppTheme.bgApp : const Color(0xFFF1F5F9);
    final hintColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.track_changes, color: AppTheme.skyBlueAccent),
          const SizedBox(width: 8),
          Text(
            '🎯 Cài Đặt Mục Tiêu Ngày',
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhập số tiền mục tiêu bạn muốn tích lũy mỗi ngày:',
            style: TextStyle(color: textMutedColor, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Mục tiêu ngày (VNĐ)',
              labelStyle: TextStyle(color: hintColor),
              suffixText: 'đ',
              suffixStyle: const TextStyle(color: AppTheme.emeraldLight, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.skyBlueAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [100000, 150000, 200000, 500000].map((preset) {
              return ChoiceChip(
                label: Text('${preset ~/ 1000}k'),
                selected: false,
                onSelected: (_) {
                  _controller.text = preset.toString();
                },
                backgroundColor: inputBg,
                labelStyle: TextStyle(color: textMutedColor, fontSize: 11, fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy', style: TextStyle(color: hintColor, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: _saveTarget,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.skyBlueAccent),
          child: const Text('Lưu Thay Đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
