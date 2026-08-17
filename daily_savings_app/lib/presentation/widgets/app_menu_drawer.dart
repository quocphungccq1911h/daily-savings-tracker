import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../screens/login_screen.dart';
import 'change_target_dialog.dart';
import 'compound_interest_dialog.dart';
import 'perpetual_calendar_dialog.dart';

class AppMenuDrawer extends ConsumerWidget {
  const AppMenuDrawer({super.key});

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🚪 Đăng Xuất Tài Khoản', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Đăng Xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await SupabaseService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(onLoginSuccess: () {}),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.currentUser;
    final email = user?.email ?? 'quocphungccq1911h@gmail.com';

    return Drawer(
      backgroundColor: AppTheme.bgApp,
      child: SafeArea(
        child: Column(
          children: [
            // Header Section: Profile & Cloud Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.bgCard,
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.skyBlueAccent.withValues(alpha: 0.2),
                          border: Border.all(color: AppTheme.skyBlueAccent),
                        ),
                        child: const Icon(Icons.person, color: AppTheme.skyBlueAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_done, color: Colors.greenAccent, size: 10),
                                  SizedBox(width: 4),
                                  Text(
                                    'Supabase Cloud Online',
                                    style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout, color: Colors.redAccent, size: 16),
                      label: const Text('Đăng xuất tài khoản', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'CẤU HÌNH TÍCH LŨY',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.track_changes, color: AppTheme.skyBlueAccent),
                    title: const Text('🎯 Đổi Mục Tiêu Ngày', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Thay đổi số tiền mục tiêu 150k/ngày', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const ChangeTargetDialog());
                    },
                  ),
                  const Divider(color: AppTheme.borderColor, height: 16, indent: 16, endIndent: 16),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'BỘ CÔNG CỤ TIỆN ÍCH',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined, color: AppTheme.emeraldLight),
                    title: const Text('🗓️ Lịch Vạn Niên & Âm Lịch', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tra cứu ngày âm, Mùng 1 & Ngày Rằm', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const PerpetualCalendarDialog());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calculate_outlined, color: AppTheme.amberGoldLight),
                    title: const Text('🧮 Máy Tính Lãi Kép & Dự Báo', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Dự tính số tiền tích lũy sau 1, 3, 5 năm', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const CompoundInterestDialog());
                    },
                  ),
                ],
              ),
            ),

            // Footer Version Tag
            Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              child: const Text(
                'Sổ Tiết Kiệm Daily v1.2.0 • Build 2026',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
