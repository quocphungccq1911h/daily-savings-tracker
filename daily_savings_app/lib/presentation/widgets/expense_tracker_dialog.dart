import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_entry.dart';
import '../../providers/savings_provider.dart';
import '../../services/local_storage_service.dart';
import '../../services/supabase_service.dart';
import 'collapsible_form.dart';

class ExpenseTrackerDialog extends ConsumerStatefulWidget {
  const ExpenseTrackerDialog({super.key});

  @override
  ConsumerState<ExpenseTrackerDialog> createState() => _ExpenseTrackerDialogState();
}

class _ExpenseTrackerDialogState extends ConsumerState<ExpenseTrackerDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = AppConstants.expenseCategories.first;
  List<ExpenseEntry> _allExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() async {
    setState(() {
      _allExpenses = LocalStorageService.getExpenses();
    });
    // Tự động tải & đồng bộ dữ liệu chi tiêu từ Cloud Supabase
    final cloudExpenses = await SupabaseService.fetchExpensesFromCloud();
    if (cloudExpenses.isNotEmpty) {
      for (var exp in cloudExpenses) {
        await LocalStorageService.saveExpense(exp);
      }
      if (mounted) {
        setState(() {
          _allExpenses = LocalStorageService.getExpenses();
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addExpense() async {
    final rawText = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final double? amount = double.tryParse(rawText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập số tiền chi tiêu hợp lệ!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final entry = ExpenseEntry(
      id: const Uuid().v4(),
      amount: amount,
      date: dateStr,
      category: _selectedCategory,
      note: _noteController.text.trim(),
    );

    await LocalStorageService.saveExpense(entry);
    SupabaseService.syncSaveExpense(entry); // Đồng bộ Cloud Supabase
    _amountController.clear();
    _noteController.clear();
    _loadExpenses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💸 Đã ghi nhận khoản chi ${Formatters.formatShortNumber(amount)}!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteExpense(String id) async {
    await LocalStorageService.deleteExpense(id);
    SupabaseService.syncDeleteExpense(id); // Xóa trên Cloud Supabase
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final savingsState = ref.watch(savingsProvider);
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Tính tổng chi hôm nay
    final todayExpenses = _allExpenses.where((e) => e.date == todayStr).toList();
    double todayExpenseTotal = 0;
    for (var e in todayExpenses) {
      todayExpenseTotal += e.amount;
    }

    // Tính tổng tiết kiệm hôm nay
    final todaySavingsEntries = savingsState.entries.where((e) => e.date == todayStr).toList();
    double todaySavingsTotal = 0;
    for (var e in todaySavingsEntries) {
      todaySavingsTotal += e.amount;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = Theme.of(context).cardColor;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);
    final cardBorder = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final innerCardBg = isDark ? AppTheme.bgApp : const Color(0xFFF8FAFC);
    final inputBg = isDark ? AppTheme.bgApp : const Color(0xFFF1F5F9);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('💸', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SỔ GHI CHI TIÊU HẰNG NGÀY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Theo dõi số tiền tiêu trong ngày 🛒',
                                style: TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Today Overview Cards Side-by-Side (Chi Tiêu vs Tiết Kiệm)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hôm Nay Đã Chi', style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatShortNumber(todayExpenseTotal),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.redAccent),
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
                                color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.emeraldPrimary.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hôm Nay Tiết Kiệm', style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatShortNumber(todaySavingsTotal),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Input Form Area
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: innerCardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✍️ Nhập Khoản Chi Mới',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor),
                            ),
                            const SizedBox(height: 10),

                            // Amount Input
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                ThousandsSeparatorInputFormatter(),
                              ],
                              style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Số tiền chi (VNĐ)',
                                hintText: 'Ví dụ: 40.000',
                                prefixIcon: const Icon(Icons.attach_money_rounded, color: Colors.redAccent),
                                filled: true,
                                fillColor: inputBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Category Choice Chips
                            Text('Danh mục khoản chi:', style: TextStyle(fontSize: 11, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: AppConstants.expenseCategories.map((cat) {
                                final isSelected = _selectedCategory == cat;
                                return ChoiceChip(
                                  label: Text(cat, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : primaryTextColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  selected: isSelected,
                                  selectedColor: Colors.redAccent,
                                  backgroundColor: inputBg,
                                  side: BorderSide(color: isSelected ? Colors.redAccent : cardBorder),
                                  onSelected: (val) {
                                    if (val) setState(() => _selectedCategory = cat);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),

                            // Note Field
                            TextField(
                              controller: _noteController,
                              style: TextStyle(color: primaryTextColor, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Ghi chú (Ví dụ: Cơm trưa bún bò)',
                                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.skyBlueAccent),
                                filled: true,
                                fillColor: inputBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.skyBlueAccent)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Add Expense Button
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: _addExpense,
                                icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                                label: const Text('Ghi Khoản Chi Này', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Today Expenses History List
                      Text(
                        '📋 Lịch Sử Chi Tiêu Hôm Nay (${todayExpenses.length})',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor),
                      ),
                      const SizedBox(height: 8),

                      if (todayExpenses.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: Text('Chưa có khoản chi nào hôm nay! 👍', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: todayExpenses.length,
                          itemBuilder: (context, index) {
                            final exp = todayExpenses[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: innerCardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(exp.category, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor)),
                                        if (exp.note.isNotEmpty)
                                          Text(exp.note, style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '-${Formatters.formatShortNumber(exp.amount)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                    onPressed: () => _deleteExpense(exp.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
