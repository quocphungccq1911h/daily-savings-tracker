import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/savings_entry.dart';
import '../../providers/savings_provider.dart';
import 'package:uuid/uuid.dart';

class CollapsibleFormWidget extends ConsumerStatefulWidget {
  const CollapsibleFormWidget({super.key});

  @override
  ConsumerState<CollapsibleFormWidget> createState() => _CollapsibleFormWidgetState();
}

class _CollapsibleFormWidgetState extends ConsumerState<CollapsibleFormWidget> {
  bool _isExpanded = false;
  final _amountController = TextEditingController(text: '150.000');
  final _noteController = TextEditingController();
  String _selectedCategory = AppConstants.incomeCategories.first;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitForm() {
    final rawText = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final double? amount = double.tryParse(rawText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập số tiền tiết kiệm hợp lệ!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final entry = SavingsEntry(
      id: const Uuid().v4(),
      amount: amount,
      date: dateStr,
      category: _selectedCategory,
      note: _noteController.text.trim(),
    );

    ref.read(savingsProvider.notifier).addOrUpdateEntry(entry);

    _amountController.text = '150.000';
    _noteController.clear();
    setState(() {
      _isExpanded = false;
      _selectedDate = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Đã thêm ${Formatters.formatShortNumber(amount)} vào sổ tiết kiệm!'),
        backgroundColor: AppTheme.emeraldLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppTheme.emeraldLight),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final cardBorder = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final titleTextColor = isDark ? Colors.white : Colors.black87;
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final inputBg = isDark ? AppTheme.bgApp : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header Toggle Bar
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Text('✍️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nhập Tiết Kiệm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: titleTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isExpanded
                          ? Colors.red.withValues(alpha: 0.15)
                          : AppTheme.emeraldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isExpanded
                            ? Colors.red.withValues(alpha: 0.4)
                            : AppTheme.emeraldLight.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'Thu Gọn' : '➕ Thêm Khoản Mới',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isExpanded ? Colors.redAccent : AppTheme.emeraldLight,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 14,
                          color: _isExpanded ? Colors.redAccent : AppTheme.emeraldLight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Animated Collapsible Form Body
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Field
                  Text(
                    'Số tiền tiết kiệm (VNĐ)',
                    style: TextStyle(fontSize: 12, color: textMutedColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      ThousandsSeparatorInputFormatter(),
                    ],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.emeraldLight,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      suffixText: 'đ',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Pills
                  Text(
                    'Nguồn Thu',
                    style: TextStyle(fontSize: 12, color: textMutedColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.incomeCategories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppTheme.emeraldPrimary.withValues(alpha: 0.3),
                        backgroundColor: inputBg,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.white : AppTheme.emeraldPrimary)
                              : textMutedColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lưu Tiết Kiệm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final String cleanString = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanString.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final double? value = double.tryParse(cleanString);
    if (value == null) {
      return oldValue;
    }

    final String formatted = Formatters.formatNumberDot(value);
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
