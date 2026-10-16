import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
import 'ai_wealth_predictor_dialog.dart';
import 'change_target_dialog.dart';
import 'compound_interest_dialog.dart';
import 'darts_game_dialog.dart';
import 'expense_tracker_dialog.dart';
import 'flappy_piggy_dialog.dart';
import 'perpetual_calendar_dialog.dart';
import 'tetris_game_dialog.dart';
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
    final totalCurrentSavings = savingsState.lifetimeTotal;
    final grabTotal = savingsState.grabLifetimeTotal;
    final otherTotal = max(0.0, totalCurrentSavings - grabTotal);
    final double realAvgRate = savingsState.grabEntries.isEmpty
        ? dailyGoal
        : grabTotal / max(1, savingsState.grabEntries.length);
    final estimatedTetFund = totalCurrentSavings + (daysLeftToTet * realAvgRate);

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
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: const Icon(Icons.build_circle_outlined, color: AppTheme.skyBlueAccent),
                      title: Text('Bộ Công Cụ Tiện Ích 🧰', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('Lịch âm, Máy tính lãi kép & AI Gemini', style: TextStyle(color: subtextColor, fontSize: 11)),
                      childrenPadding: const EdgeInsets.only(left: 12),
                      children: [
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
                        ListTile(
                          leading: const Icon(Icons.psychology_rounded, color: Colors.purpleAccent),
                          title: Text('AI Dự Báo Ngày Chạm Mốc 🔮', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('Dự báo mốc 10M, 50M, 100M & Quỹ Tết', style: TextStyle(color: subtextColor, fontSize: 11)),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(context: context, builder: (_) => const AiWealthPredictorDialog());
                          },
                        ),
                      ],
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: const Icon(Icons.sports_esports_rounded, color: AppTheme.amberGoldLight),
                      title: Text('Góc Game Giải Trí 🎮', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('Các tựa game nhỏ xả stress 60 FPS', style: TextStyle(color: subtextColor, fontSize: 11)),
                      childrenPadding: const EdgeInsets.only(left: 12),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.grid_view_rounded, color: AppTheme.amberGoldLight),
                          title: Text('Game Xếp Gạch Tetris Cổ Điển', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('Xếp gạch giải trí cổ điển 🎮', style: TextStyle(color: subtextColor, fontSize: 11)),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(context: context, builder: (_) => const TetrisGameDialog());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.flutter_dash_rounded, color: Colors.pinkAccent),
                          title: Text('Game Chú Lợn Bay (Flappy Piggy)', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('Vỗ cánh nhặt xu vàng 🪙', style: TextStyle(color: subtextColor, fontSize: 11)),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(context: context, builder: (_) => const FlappyPiggyDialog());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.ads_click_rounded, color: Colors.redAccent),
                          title: Text('Game Phi Tiêu Giải Tỏa Căng Thẳng', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('Ngắm bắn trúng tâm Bullseye 🎯', style: TextStyle(color: subtextColor, fontSize: 11)),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(context: context, builder: (_) => const DartsGameDialog());
                          },
                        ),
                      ],
                    ),
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
                        // 💰 HIGHLIGHT ĐÃ TÍCH LŨY & TIẾN ĐỘ
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.amberGoldLight.withValues(alpha: 0.35), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '💰 ĐÃ TÍCH LŨY',
                                    style: TextStyle(
                                      color: AppTheme.amberGoldLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.amberGoldLight.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.amberGoldLight.withValues(alpha: 0.4), width: 0.8),
                                    ),
                                    child: Text(
                                      '${(estimatedTetFund > 0 ? (totalCurrentSavings / estimatedTetFund * 100).clamp(0, 100) : 0).round()}% mục tiêu',
                                      style: const TextStyle(
                                        color: AppTheme.amberGoldLight,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.formatShortNumber(totalCurrentSavings),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(color: Color(0x99F59E0B), blurRadius: 8),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: estimatedTetFund > 0 ? (totalCurrentSavings / estimatedTetFund).clamp(0.0, 1.0) : 0.0,
                                  backgroundColor: Colors.white12,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.amberGoldLight),
                                  minHeight: 6,
                                ),
                              ),
                              if (otherTotal > 0) ...[
                                const SizedBox(height: 7),
                                Container(
                                  padding: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('🛵 Chạy xe', style: TextStyle(color: Colors.white70, fontSize: 9.0)),
                                            const SizedBox(height: 1),
                                            Text(
                                              Formatters.formatShortNumber(grabTotal),
                                              style: const TextStyle(color: AppTheme.amberGoldLight, fontSize: 11.0, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(height: 20, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('💼 Nguồn khác', style: TextStyle(color: Colors.white70, fontSize: 9.0)),
                                            const SizedBox(height: 1),
                                            Text(
                                              Formatters.formatShortNumber(otherTotal),
                                              style: const TextStyle(color: AppTheme.amberGoldLight, fontSize: 11.0, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '🚀 Tích lũy ${Formatters.formatShortNumber(realAvgRate)}/ngày trong $daysLeftToTet ngày tới!',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.3),
                          textAlign: TextAlign.center,
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
                    subtitle: Text(
                      'Tự động nhắc lúc 20:00 mỗi tối nếu chưa lưu tiền (Bấm để kiểm tra chuông 🔔)',
                      style: TextStyle(color: subtextColor, fontSize: 11),
                    ),
                    onTap: () async {
                      final notif = NotificationService();
                      final granted = await notif.requestPermissions();
                      if (!context.mounted) return;

                      if (!granted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: isDark ? AppTheme.bgCard : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('⚠️ Chưa Cấp Quyền Thông Báo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                            content: Text(
                              'Ứng dụng chưa được cấp quyền hiển thị thông báo trên điện thoại.\n\nVui lòng vào: Cài đặt máy ➔ Ứng dụng ➔ Sổ Tiết Kiệm Daily ➔ Thông báo ➔ Bật Cho phép thông báo.',
                              style: TextStyle(fontSize: 13, color: textColor),
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Đã Hiểu'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                      final hasSavedToday = ref.read(savingsProvider).entries.any((e) => e.date == todayStr && e.amount > 0);

                      final nextScheduleLabel = await notif.syncDailyReminderWithSavedStatus(hasSavedToday: hasSavedToday);
                      final canExact = await notif.canScheduleExact();
                      final isPending = await notif.isDailyReminderPending();

                      // 1. Phát ngay lập tức 1 thông báo thử nghiệm lên thanh trạng thái
                      await notif.showTestNotification();
                      // 2. Hẹn thêm 1 thông báo nổ ngầm sau 10 giây
                      await notif.scheduleDelayedTestNotification(seconds: 10);

                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: isDark ? AppTheme.bgCard : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Row(
                            children: [
                              const Icon(Icons.notifications_active, color: AppTheme.emeraldLight, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Trạng Thái Chuông 20:00',
                                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✅ Quyền thông báo: Đã bật\n'
                                '📅 Lịch hẹn tiếp theo: $nextScheduleLabel\n'
                                '📌 Trạng thái hàng đợi: ${isPending ? "Đang chờ phát" : "Đã kích hoạt"}\n'
                                '⏰ Quyền Báo thức chính xác: ${canExact ? "Đã cấp chuẩn 100%" : "Chưa bật (Cần cấp quyền)"}',
                                style: TextStyle(fontSize: 12.5, height: 1.5, color: textColor),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldPrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.emeraldLight.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '🔔 Đã bắn 1 thông báo tức thì lên màn hình và hẹn thêm 1 chuông nổ ngầm sau 10 giây nữa!',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? AppTheme.emeraldLight : const Color(0xFF047857)),
                                ),
                              ),
                              if (!canExact) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  '⚠️ Lưu ý quan trọng: Điện thoại của bạn chưa bật quyền "Báo thức & lời nhắc" cho ứng dụng nên đúng 20:00 hệ điều hành có thể chặn chuông. Hãy bấm nút bên dưới để bật!',
                                  style: TextStyle(fontSize: 11.5, color: Colors.orangeAccent, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                          actions: [
                            if (!canExact)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await notif.openExactAlarmSettings();
                                },
                                icon: const Icon(Icons.alarm_on, size: 16),
                                label: const Text('Bật Quyền Báo Thức 20:00'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emeraldPrimary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
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
