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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      return Card(
                        color: AppTheme.bgCard,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                        child: ListTile(
                          title: Text(
                            Formatters.formatDateVN(item.date),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
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
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Formatters.formatShortNumber(item.amount),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.emeraldLight,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.redAccent),
                                onPressed: () {
                                  ref
                                      .read(savingsProvider.notifier)
                                      .deleteEntry(item.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded,
                                              color: Colors.redAccent),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '🗑️ Đã xóa khoản tiết kiệm thành công!',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppTheme.bgCard,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                            color: Colors.redAccent),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                      );
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
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: Colors.redAccent),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      ref
                                          .read(savingsProvider.notifier)
                                          .deleteEntry(subItem.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded,
                                                  color: Colors.redAccent),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '🗑️ Đã xóa khoản tiết kiệm thành công!',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: AppTheme.bgCard,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: const BorderSide(
                                                color: Colors.redAccent),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
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
        ),
      ],
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
