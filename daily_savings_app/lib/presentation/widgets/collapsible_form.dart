import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/savings_entry.dart';
import '../../providers/savings_provider.dart';

class CollapsibleFormWidget extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const CollapsibleFormWidget({super.key, required this.onSaved});

  @override
  ConsumerState<CollapsibleFormWidget> createState() => _CollapsibleFormWidgetState();
}

class _CollapsibleFormWidgetState extends ConsumerState<CollapsibleFormWidget> {
  bool _isExpanded = false;
  final _amountController = TextEditingController(text: '150000');
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = AppConstants.defaultCategory;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitForm() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final entry = SavingsEntry(
      id: const Uuid().v4(),
      date: dateStr,
      amount: amount,
      category: _selectedCategory,
      note: _noteController.text.trim(),
    );

    ref.read(savingsProvider.notifier).addOrUpdateEntry(entry);
    widget.onSaved();

    setState(() {
      _isExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
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
                  const Expanded(
                    child: Text(
                      'Nhập Tiết Kiệm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isExpanded
                          ? Colors.red.withOpacity(0.15)
                          : AppTheme.emeraldPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isExpanded
                            ? Colors.red.withOpacity(0.4)
                            : AppTheme.emeraldLight.withOpacity(0.4),
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
                  const Text('Số tiền tiết kiệm (VNĐ)',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.emeraldLight,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.bgApp,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      suffixText: 'đ',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Pills
                  const Text('Nguồn Thu',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.incomeCategories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppTheme.emeraldPrimary.withOpacity(0.3),
                        backgroundColor: AppTheme.bgApp,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textMuted,
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
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
