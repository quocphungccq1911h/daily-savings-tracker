import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/savings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/biometric_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../screens/login_screen.dart';
import 'ai_chat_bottom_sheet.dart';
import 'change_target_dialog.dart';
import 'compound_interest_dialog.dart';
import 'expense_tracker_dialog.dart';
import 'perpetual_calendar_dialog.dart';
import 'weekly_report_dialog.dart';

class AppMenuDrawer extends ConsumerWidget {
  const AppMenuDrawer({super.key});

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.bgCard : AppTheme.bgCardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '🚪 Đăng Xuất Tài Khoản',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
          style: TextStyle(color: isDark ? AppTheme.textMuted : const Color(0xFF334155), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: isDark ? AppTheme.textMuted : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
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
      await ref.read(savingsProvider.notifier).clearOnLogout();
      await SupabaseService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(onLoginSuccess: () {
              ref.read(savingsProvider.notifier).rebindRealtimeOnLogin();
            }),
          ),
          (route) => false,
        );
      }
    }
  }

  /// Dynamically finds the exact next Mùng 1 Tết Nguyên Đán
  DateTime _getNextTetSolarDate(DateTime now) {
    for (int i = 0; i <= 400; i++) {
      final candidate = now.add(Duration(days: i));
      final lunar = LunarUtils.convertSolarToLunar(candidate.day, candidate.month, candidate.year);
      if (lunar[0] == 1 && lunar[1] == 1) {
        return candidate;
      }
    }
    return DateTime(now.year + 1, 2, 6);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.currentUser;
    final email = user?.email ?? 'quocphungccq1911h@gmail.com';
    final savingsState = ref.watch(savingsProvider);

    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final cardBgColor = isDark ? AppTheme.bgCard : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;

    // Calculate Today's Lunar Info
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final todayLunarList = LunarUtils.convertSolarToLunar(now.day, now.month, now.year);
    final todayLunarDay = todayLunarList[0];
    final todayLunarMonth = todayLunarList[1];
    final todayLunarYear = todayLunarList[2];

    final todayCanChiDay = LunarUtils.getCanChiDay(now);
    final todayCanChiYear = LunarUtils.getCanChiYear(todayLunarYear);

    // Calculate Tet Countdown
    final tetDate = _getNextTetSolarDate(todayMidnight);
    final daysLeftToTet = tetDate.difference(todayMidnight).inDays;

    final tetLunarList = LunarUtils.convertSolarToLunar(tetDate.day, tetDate.month, tetDate.year);
    final tetYearCanChi = LunarUtils.getCanChiYear(tetLunarList[2]);

    final dailyGoal = savingsState.dailyGoal;
    final lifetimeTotal = savingsState.lifetimeTotal;
    final estimatedTetFund = lifetimeTotal + (daysLeftToTet * dailyGoal);

    return Drawer(
      backgroundColor: isDark ? AppTheme.bgApp : AppTheme.bgAppLight,
      child: SafeArea(
        child: Column(
          children: [
            // Header Section: Profile & Cloud Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBgColor,
                border: Border(bottom: BorderSide(color: borderColor)),
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
                              style: TextStyle(
                                color: textColor,
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
                                  Icon(Icons.cloud_done, color: Colors.green, size: 10),
                                  SizedBox(width: 4),
                                  Text(
                                    'Supabase Cloud Online',
                                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
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
                      onPressed: () => _handleLogout(context, ref),
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'MỤC TIÊU TÍCH LŨY',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subtextColor, letterSpacing: 0.8),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.track_changes, color: AppTheme.skyBlueAccent),
                    title: Text('Đổi Mục Tiêu Ngày', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Thay đổi số tiền mục tiêu ${Formatters.formatShortNumber(dailyGoal)}/ngày', style: TextStyle(color: subtextColor, fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const ChangeTargetDialog());
                    },
                  ),
                  const Divider(color: AppTheme.borderColor, height: 16, indent: 16, endIndent: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'BỘ CÔNG CỤ TIỆN ÍCH',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subtextColor, letterSpacing: 0.8),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_rounded, color: Colors.redAccent),
                    title: Text('Sổ Ghi Chi Tiêu Hằng Ngày', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Ghi lại các khoản tiền đã chi trong ngày', style: TextStyle(color: subtextColor, fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const ExpenseTrackerDialog());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart_rounded, color: AppTheme.skyBlueAccent),
                    title: Text('Báo Cáo Tổng Kết Tuần', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Đánh giá tiến độ 7 ngày & kết quả tích lũy', style: TextStyle(color: subtextColor, fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const WeeklyReportDialog());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined, color: AppTheme.emeraldLight),
                    title: Text('Lịch Vạn Niên & Âm Lịch', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Tra cứu ngày âm, Mùng 1 & Ngày Rằm', style: TextStyle(color: subtextColor, fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const PerpetualCalendarDialog());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calculate_outlined, color: AppTheme.amberGoldLight),
                    title: Text('Máy Tính Lãi Kép & Dự Báo', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Dự tính số tiền tích lũy sau 1, 3, 5 năm', style: TextStyle(color: subtextColor, fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const CompoundInterestDialog());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome_rounded, color: AppTheme.skyBlueAccent),
                    title: Text('Trợ Lý AI Tiết Kiệm (Gemini)', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Hỏi đáp target, đếm ngược Tết & tư vấn AI', style: TextStyle(color: subtextColor, fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      AiChatBottomSheet.show(context);
                    },
                  ),

                  const SizedBox(height: 10),

                  // 🧧 TET COUNTDOWN & SAVINGS MOTIVATION WIDGET
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7F1D1D), Color(0xFFB45309)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.amberGoldLight.withValues(alpha: 0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Text('🧧', style: TextStyle(fontSize: 15)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'ĐẾM NGƯỢC TẾT $tetYearCanChi',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.amberGoldLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Mùng 1: ${tetDate.day}/${tetDate.month}',
                                style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Thời gian đếm ngược:', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$daysLeftToTet',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('ngày', style: TextStyle(color: AppTheme.amberGoldLight, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 32,
                              width: 1,
                              color: Colors.white24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dự kiến quỹ ăn Tết:', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                                  const SizedBox(height: 2),
                                  Text(
                                    Formatters.formatShortNumber(estimatedTetFund),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.amberGoldLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 8),
                        Text(
                          '💰 Đã có ${Formatters.formatShortNumber(lifetimeTotal)} + tích lũy ${Formatters.formatShortNumber(dailyGoal)}/ngày trong $daysLeftToTet ngày tới để đón Tết $tetYearCanChi rực rỡ!',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.3),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 🌙 TODAY'S LUNAR & HOÀNG ĐẠO INFO WIDGET
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.emeraldLight.withValues(alpha: 0.4)),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Text('🌙', style: TextStyle(fontSize: 15)),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'ÂM LỊCH HÔM NAY',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppTheme.emeraldLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                showDialog(context: context, builder: (_) => const PerpetualCalendarDialog());
                              },
                              child: const Text(
                                'Xem Lịch ➔',
                                style: TextStyle(color: AppTheme.skyBlueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldLight.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.emeraldLight.withValues(alpha: 0.5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.emeraldLight.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$todayLunarDay',
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.emeraldLight,
                                      height: 0.95,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tháng $todayLunarMonth Âm',
                                    style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ngày $todayCanChiDay',
                                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tháng $todayLunarMonth • Năm $todayCanChiYear',
                                    style: const TextStyle(color: AppTheme.amberGoldLight, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '✨ Tiết Lập Thu • Hướng Hỷ Thần: Tây Nam',
                                    style: TextStyle(color: subtextColor, fontSize: 9.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: borderColor, height: 1),
                        const SizedBox(height: 8),
                        Text(
                          '🌟 Giờ Hoàng Đạo: Tý (23-1), Sửu (1-3), Mão (5-7), Ngọ (11-13), Thân (15-17), Dậu (17-19)',
                          style: TextStyle(color: subtextColor, fontSize: 9.5, height: 1.3),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Divider(color: AppTheme.borderColor, height: 16, indent: 16, endIndent: 16),

                  // ☀️ / 🌙 THEME & NOTIFICATION SECTION (DƯỚI CÙNG HOÀN TOÀN)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'GIAO DIỆN & BẢO MẬT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subtextColor, letterSpacing: 0.8),
                    ),
                  ),
                  StatefulBuilder(
                    builder: (context, setDrawerState) {
                      final isBioEnabled = LocalStorageService.getBiometricsEnabled();
                      return SwitchListTile(
                        value: isBioEnabled,
                        onChanged: (val) async {
                          await LocalStorageService.saveBiometricsEnabled(val);
                          setDrawerState(() {});
                          if (val) {
                            final ok = await BiometricService.authenticate();
                            if (!ok) {
                              await LocalStorageService.saveBiometricsEnabled(false);
                              setDrawerState(() {});
                            }
                          }
                        },
                        secondary: const Icon(Icons.fingerprint_rounded, color: AppTheme.skyBlueAccent),
                        title: Text(
                          'Khóa Vân Tay / FaceID',
                          style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isBioEnabled ? 'Đã bật bảo mật vân tay khi mở app' : 'Yêu cầu vân tay/FaceID khi mở app',
                          style: TextStyle(color: subtextColor, fontSize: 11),
                        ),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppTheme.emeraldPrimary,
                      );
                    },
                  ),
                  SwitchListTile(
                    value: isDark,
                    onChanged: (_) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: isDark ? AppTheme.amberGoldLight : Colors.orangeAccent,
                    ),
                    title: Text(
                      isDark ? 'Chế Độ Tối (Dark Mode)' : 'Chế Độ Sáng (Light Mode)',
                      style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isDark ? 'Giao diện tối dịu mắt ban đêm' : 'Giao diện sáng rõ ràng ban ngày',
                      style: TextStyle(color: subtextColor, fontSize: 11),
                    ),
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppTheme.emeraldPrimary,
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_rounded, color: AppTheme.amberGoldLight),
                    title: Text('Nhắc Nhở Tối (20:00)', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Tự động phát lúc 20:00 mỗi tối (Bấm để thử ngay 🔔)', style: TextStyle(color: subtextColor, fontSize: 11)),
                    onTap: () async {
                      final notif = NotificationService();
                      final granted = await notif.requestPermissions();
                      if (context.mounted) {
                        if (granted) {
                          await notif.showTestNotification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔔 Đã phát thông báo thử nghiệm! Đã bật nhắc nhở 20:00 hàng ngày.'),
                              backgroundColor: AppTheme.emeraldPrimary,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Vui lòng cấp quyền thông báo cho ứng dụng trong Cài Đặt máy!'),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Footer Version Tag
            Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              child: Text(
                'Sổ Tiết Kiệm Daily v1.2.0 • Build 2026',
                style: TextStyle(color: subtextColor, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
