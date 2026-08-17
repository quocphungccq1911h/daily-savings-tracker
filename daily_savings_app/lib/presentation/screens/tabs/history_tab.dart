import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/savings_entry.dart';
import '../../../providers/savings_provider.dart';

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);

    if (state.entries.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✨', style: TextStyle(fontSize: 40)),
              SizedBox(height: 12),
              Text(
                'Nhật Ký Đang Trống',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Hãy bấm "➕ Thêm Khoản Mới" ở trên để lưu khoản tiết kiệm đầu tiên hôm nay!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Extract unique months for filter dropdown
    final Set<String> monthsSet = {currentMonthKey};
    for (var entry in state.entries) {
      if (entry.date.length >= 7) {
        monthsSet.add(entry.date.substring(0, 7)); // 'YYYY-MM'
      }
    }
    final sortedMonthKeys = monthsSet.toList()..sort((a, b) => b.compareTo(a));

    if (_selectedMonth != 'ALL' && !sortedMonthKeys.contains(_selectedMonth)) {
      _selectedMonth = currentMonthKey;
    }

    // Filter entries by selected month (Mặc định chỉ lấy tháng hiện tại)
    final filteredEntries = _selectedMonth == 'ALL'
        ? state.entries
        : state.entries.where((e) => e.date.startsWith(_selectedMonth)).toList();

    // Group filtered entries by Month, then by Date
    final Map<String, Map<String, List<SavingsEntry>>> monthMap = {};
    for (var entry in filteredEntries) {
      final monthKey = entry.date.length >= 7 ? entry.date.substring(0, 7) : 'Other';
      monthMap.putIfAbsent(monthKey, () => {});
      monthMap[monthKey]!.putIfAbsent(entry.date, () => []).add(entry);
    }

    final monthGroups = monthMap.entries.map((mEntry) {
      final monthKey = mEntry.key;
      final dateMap = mEntry.value;

      double monthTotal = 0.0;
      final dateGroups = dateMap.entries.map((dEntry) {
        final dTotal = dEntry.value.fold(0.0, (sum, item) => sum + item.amount);
        monthTotal += dTotal;
        return _DateGroup(
          date: dEntry.key,
          totalAmount: dTotal,
          items: dEntry.value,
        );
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return _MonthGroup(
        monthKey: monthKey,
        totalAmount: monthTotal,
        dateGroups: dateGroups,
      );
    }).toList()
      ..sort((a, b) => b.monthKey.compareTo(a.monthKey));

    return Column(
      children: [
        // Month Filter Dropdown Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  size: 18, color: AppTheme.skyBlueAccent),
              const SizedBox(width: 6),
              const Text(
                'Lọc theo tháng:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: (sortedMonthKeys.contains(_selectedMonth) ||
                            _selectedMonth == 'ALL')
                        ? _selectedMonth
                        : 'ALL',
                    dropdownColor: AppTheme.bgCard,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.skyBlueAccent,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'ALL',
                        child: Text('📅 Tất cả các tháng'),
                      ),
                      ...sortedMonthKeys.map((mKey) {
                        final parts = mKey.split('-');
                        final label = parts.length == 2
                            ? 'Tháng ${int.parse(parts[1])}/${parts[0]}'
                            : mKey;
                        return DropdownMenuItem(
                          value: mKey,
                          child: Text(label),
                        );
                      }),
                    ],
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
        ),

        // History List Grouped By Month & Date
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: monthGroups.length,
            itemBuilder: (context, mIndex) {
              final monthGroup = monthGroups[mIndex];
              final mParts = monthGroup.monthKey.split('-');
              final monthTitle = mParts.length == 2
                  ? 'THÁNG ${mParts[1]}/${mParts[0]}'
                  : monthGroup.monthKey;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Section Header
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.skyBlueAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.skyBlueAccent.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            size: 16, color: AppTheme.skyBlueAccent),
                        const SizedBox(width: 8),
                        Text(
                          monthTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppTheme.skyBlueAccent,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Tổng: ${Formatters.formatShortNumber(monthGroup.totalAmount)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.emeraldLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date Cards for this Month
                  ...monthGroup.dateGroups.map((dateGroup) {
                    final isSingle = dateGroup.items.length == 1;

                    if (isSingle) {
                      final item = dateGroup.items.first;
                      return _buildItemDetailCard(context, item, state.dailyGoal);
                    }

                    // Multiple entries for the same date -> Expansion Card
                    final firstItem = dateGroup.items.first;
                    final extraCount = dateGroup.items.length - 1;

                    return Card(
                      color: AppTheme.bgCard,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          title: Row(
                            children: [
                              Text(
                                Formatters.formatDateVN(dateGroup.date),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.skyBlueAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${dateGroup.items.length} khoản',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.skyBlueAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.skyBlueAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.skyBlueAccent
                                          .withOpacity(0.3)),
                                ),
                                child: Text(
                                  firstItem.category,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.skyBlueAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '(+$extraCount khoản khác)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            Formatters.formatShortNumber(dateGroup.totalAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.emeraldLight,
                            ),
                          ),
                          children: dateGroup.items.map((subItem) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.bgApp.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        AppTheme.borderColor.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.skyBlueAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      subItem.category,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.skyBlueAccent),
                                    ),
                                  ),
                                  if (subItem.note.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        subItem.note,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted),
                                      ),
                                    ),
                                  ] else ...[
                                    const Spacer(),
                                  ],
                                  Text(
                                    Formatters.formatShortNumber(subItem.amount),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.emeraldLight,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 16, color: AppTheme.amberGoldLight),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showEditDialog(context, subItem),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16, color: Colors.redAccent),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _handleDelete(context, subItem.id),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      );
  }

  Widget _buildItemDetailCard(BuildContext context, SavingsEntry item, double dailyGoal) {
    final double diff = item.amount - dailyGoal;
    final double pct = (diff / dailyGoal) * 100;

    String statusText;
    Color statusColor;
    if (diff > 0) {
      statusText = 'Thừa';
      statusColor = AppTheme.emeraldLight;
    } else if (diff == 0) {
      statusText = 'Đạt';
      statusColor = AppTheme.skyBlueAccent;
    } else {
      statusText = 'Thiếu';
      statusColor = Colors.redAccent;
    }

    final String diffStr = diff >= 0
        ? '+${Formatters.formatShortNumber(diff)}'
        : '-${Formatters.formatShortNumber(diff.abs())}';
    final String pctStr = diff >= 0
        ? '+${pct.toStringAsFixed(1)}%'
        : '${pct.toStringAsFixed(1)}%';

    return Card(
      color: AppTheme.bgCard,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Date & Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatDateVN(item.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  Formatters.formatShortNumber(item.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.emeraldLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: Analytics vs Target & Status Badge
            Row(
              children: [
                Text(
                  'So với ${(dailyGoal / 1000).toStringAsFixed(0)}k: ',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                Text(
                  diffStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: diff >= 0 ? AppTheme.emeraldLight : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '% Kỳ vọng: ',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                Text(
                  pctStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: diff >= 0 ? AppTheme.emeraldLight : Colors.redAccent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: Category, Note & Action Buttons (Sửa & Xóa)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.skyBlueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.skyBlueAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.skyBlueAccent,
                    ),
                  ),
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
                ] else
                  const Spacer(),

                // Edit Button
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context, item),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: AppTheme.amberGold.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 12, color: AppTheme.amberGoldLight),
                  label: const Text('Sửa', style: TextStyle(fontSize: 11, color: AppTheme.amberGoldLight)),
                ),
                const SizedBox(width: 6),

                // Delete Button
                OutlinedButton.icon(
                  onPressed: () => _handleDelete(context, item.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 12, color: Colors.redAccent),
                  label: const Text('Xóa', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, SavingsEntry item) {
    final dateCtrl = TextEditingController(text: item.date);
    final amountCtrl = TextEditingController(text: item.amount.toInt().toString());
    final noteCtrl = TextEditingController(text: item.note);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('✏️ Chỉnh Sửa Khoản Tiết Kiệm', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Ngày (YYYY-MM-DD)', labelStyle: TextStyle(color: AppTheme.textMuted)),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tiền (VNĐ)', labelStyle: TextStyle(color: AppTheme.textMuted)),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Ghi chú', labelStyle: TextStyle(color: AppTheme.textMuted)),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final newAmount = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? item.amount;
              final updated = item.copyWith(
                date: dateCtrl.text.trim(),
                amount: newAmount,
                note: noteCtrl.text.trim(),
              );
              ref.read(savingsProvider.notifier).addOrUpdateEntry(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Đã cập nhật khoản tiết kiệm thành công!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.skyBlueAccent),
            child: const Text('Lưu Thay Đổi', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleDelete(BuildContext context, String id) {
    ref.read(savingsProvider.notifier).deleteEntry(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '🗑️ Đã xóa khoản tiết kiệm thành công!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.redAccent),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _MonthGroup {
  final String monthKey;
  final double totalAmount;
  final List<_DateGroup> dateGroups;
  _MonthGroup({
    required this.monthKey,
    required this.totalAmount,
    required this.dateGroups,
  });
}

class _DateGroup {
  final String date;
  final double totalAmount;
  final List<SavingsEntry> items;
  _DateGroup({
    required this.date,
    required this.totalAmount,
    required this.items,
  });
}
