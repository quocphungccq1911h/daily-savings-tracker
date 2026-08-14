import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/savings_provider.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.entries.length,
      itemBuilder: (context, index) {
        final item = state.entries[index];
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Row(
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
                  Text(
                    item.note,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.emeraldLight,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  onPressed: () {
                    ref.read(savingsProvider.notifier).deleteEntry(item.id);
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
