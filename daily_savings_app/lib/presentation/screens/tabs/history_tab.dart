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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final textColor = isDark ? Colors.white : Colors.black87;
    final innerBgColor = isDark ? AppTheme.bgApp : const Color(0xFFF1F5F9);

    if (state.entries.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                'Nhật Ký Đang Trống',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hãy bấm "➕ Thêm Khoản Mới" ở trên để lưu khoản tiết kiệm đầu tiên hôm nay!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: textMutedColor),
              ),
            ],
          ),
        ),
      );
    }

    // Sort entries descending by date
    final sortedEntries = List<SavingsEntry>.from(state.entries)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Get all available YYYY-MM month keys
    final Set<String> monthKeySet = {};
    for (var e in sortedEntries) {
      if (e.date.length >= 7) {
        monthKeySet.add(e.date.substring(0, 7));
      }
    }
    final sortedMonthKeys = monthKeySet.toList()..sort((a, b) => b.compareTo(a));

    // Filter by selected month
    final filteredEntries = (_selectedMonth == 'ALL')
        ? sortedEntries
        : sortedEntries.where((e) => e.date.startsWith(_selectedMonth)).toList();

    // Group filtered entries by Month, then by Date
    final Map<String, List<SavingsEntry>> monthGroupMap = {};
    for (var e in filteredEntries) {
      final mKey = e.date.length >= 7 ? e.date.substring(0, 7) : 'Khác';
      monthGroupMap.putIfAbsent(mKey, () => []).add(e);
    }

    final List<_MonthGroupData> monthGroups = [];
    for (var mKey in monthGroupMap.keys) {
      final mEntries = monthGroupMap[mKey]!;

      final Map<String, List<SavingsEntry>> dateGroupMap = {};
      for (var e in mEntries) {
        dateGroupMap.putIfAbsent(e.date, () => []).add(e);
      }

      final List<_DateGroupData> dateGroups = [];
      for (var dKey in dateGroupMap.keys) {
        final dEntries = dateGroupMap[dKey]!;
        final dTotal = dEntries.fold(0.0, (sum, item) => sum + item.amount);
        dateGroups.add(_DateGroupData(date: dKey, items: dEntries, totalAmount: dTotal));
      }

      final mTotal = mEntries.fold(0.0, (sum, item) => sum + item.amount);
      monthGroups.add(_MonthGroupData(monthKey: mKey, dateGroups: dateGroups, totalAmount: mTotal));
    }

    return Column(
      children: [
        // Month Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 16, color: AppTheme.skyBlueAccent),
              const SizedBox(width: 6),
              Text(
                'Lọc theo tháng:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textMutedColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: (sortedMonthKeys.contains(_selectedMonth) || _selectedMonth == 'ALL')
                        ? _selectedMonth
                        : 'ALL',
                    dropdownColor: cardBg,
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
                ? 'THÁNG ${int.parse(mParts[1])}/${mParts[0]}'
                : monthGroup.monthKey;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Section Header
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.skyBlueAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.skyBlueAccent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.skyBlueAccent),
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

                // List of Date Cards in this Month
                ...monthGroup.dateGroups.map((dateGroup) {
                  if (dateGroup.items.length == 1) {
                    return _buildItemDetailCard(context, dateGroup.items.first, state.dailyGoal);
                  }

                  final firstItem = dateGroup.items.first;
                  final extraCount = dateGroup.items.length - 1;

                  return Card(
                    color: cardBg,
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isDark ? 0 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Row(
                          children: [
                            Text(
                              Formatters.formatDateVN(dateGroup.date),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppTheme.skyBlueAccent.withValues(alpha: 0.2),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.skyBlueAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.skyBlueAccent.withValues(alpha: 0.3)),
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
                                style: TextStyle(fontSize: 11, color: textMutedColor),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: innerBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.skyBlueAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    subItem.category,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.skyBlueAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    subItem.note.isNotEmpty ? subItem.note : 'Khoản tích lũy',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textMutedColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Formatters.formatShortNumber(subItem.amount),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.emeraldLight,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final textColor = isDark ? Colors.white : Colors.black87;
    final emeraldTextColor = isDark ? AppTheme.emeraldLight : const Color(0xFF047857);

    final double diff = item.amount - dailyGoal;
    final double pct = (diff / dailyGoal) * 100;

    String statusText;
    Color statusColor;
    if (diff > 0) {
      statusText = 'Thừa';
      statusColor = emeraldTextColor;
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
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                Text(
                  Formatters.formatShortNumber(item.amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: emeraldTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: Analytics vs Target & Status Badge
            Row(
              children: [
                Text(
                  diffStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: diff >= 0 ? emeraldTextColor : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '% Kỳ vọng: ',
                  style: TextStyle(fontSize: 11, color: textMutedColor),
                ),
                Text(
                  pctStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: diff >= 0 ? emeraldTextColor : Colors.redAccent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 8),

            // Row 3: Category Badge, Note & Action Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.skyBlueAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.skyBlueAccent.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.skyBlueAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.note.isNotEmpty ? item.note : 'Không có ghi chú',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: item.note.isNotEmpty ? subtextColor(context) : textMutedColor,
                      fontStyle: item.note.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Xóa khoản tiết kiệm',
                  onPressed: () => _handleDelete(context, item.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color subtextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : const Color(0xFF475569);
  }

  void _handleDelete(BuildContext context, String id) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.bgCard : AppTheme.bgCardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('🗑️ Xóa Khoản Tiết Kiệm', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa nhật ký tiết kiệm này không?', style: TextStyle(color: isDark ? AppTheme.textMuted : const Color(0xFF334155), fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: isDark ? AppTheme.textMuted : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(savingsProvider.notifier).deleteEntry(id);
    }
  }
}

class _MonthGroupData {
  final String monthKey;
  final List<_DateGroupData> dateGroups;
  final double totalAmount;

  _MonthGroupData({
    required this.monthKey,
    required this.dateGroups,
    required this.totalAmount,
  });
}

class _DateGroupData {
  final String date;
  final List<SavingsEntry> items;
  final double totalAmount;

  _DateGroupData({
    required this.date,
    required this.items,
    required this.totalAmount,
  });
}
