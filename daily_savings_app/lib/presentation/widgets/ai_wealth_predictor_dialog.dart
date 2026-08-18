import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/savings_provider.dart';
import '../../services/gemini_service.dart';

class AiWealthPredictorDialog extends ConsumerStatefulWidget {
  const AiWealthPredictorDialog({super.key});

  @override
  ConsumerState<AiWealthPredictorDialog> createState() => _AiWealthPredictorDialogState();
}

class _AiWealthPredictorDialogState extends ConsumerState<AiWealthPredictorDialog> {
  bool _isLoadingAi = true;
  String _aiAdvice = '';

  @override
  void initState() {
    super.initState();
    _fetchAiAdvice();
  }

  void _fetchAiAdvice() async {
    final savingsState = ref.read(savingsProvider);
    final now = DateTime.now();

    final double currentTotal = savingsState.lifetimeTotal;
    final double dailyRate = savingsState.entries.isEmpty
        ? savingsState.dailyGoal
        : currentTotal / max(1, savingsState.entries.length);

    // Helper tính ngày dự kiến chạm mốc
    DateTime calcEstDate(double targetAmount) {
      if (currentTotal >= targetAmount) return now;
      final remainingNeeded = targetAmount - currentTotal;
      final daysNeeded = (remainingNeeded / dailyRate).ceil();
      return now.add(Duration(days: daysNeeded));
    }

    final date10M = calcEstDate(10000000.0);
    final date50M = calcEstDate(50000000.0);
    final date100M = calcEstDate(100000000.0);

    // Tính quỹ Tết Đinh Mùi (06/02/2027)
    final tetDate = DateTime(2027, 2, 6);
    final daysToTet = max(0, tetDate.difference(now).inDays);
    final estTetFund = currentTotal + (daysToTet * dailyRate);

    String strDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final advice = await GeminiService.predictWealthInsight(
      currentTotal: currentTotal,
      dailyRate: dailyRate,
      est10MDate: strDate(date10M),
      est50MDate: strDate(date50M),
      est100MDate: strDate(date100M),
      estTetFund: estTetFund,
    );

    if (mounted) {
      setState(() {
        _aiAdvice = advice;
        _isLoadingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final savingsState = ref.watch(savingsProvider);
    final now = DateTime.now();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = Theme.of(context).cardColor;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);
    final cardBorder = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final innerCardBg = isDark ? AppTheme.bgApp : const Color(0xFFF8FAFC);

    final double currentTotal = savingsState.lifetimeTotal;
    final double dailyRate = savingsState.entries.isEmpty
        ? savingsState.dailyGoal
        : currentTotal / max(1, savingsState.entries.length);

    DateTime calcEstDate(double targetAmount) {
      if (currentTotal >= targetAmount) return now;
      final remainingNeeded = targetAmount - currentTotal;
      final daysNeeded = (remainingNeeded / dailyRate).ceil();
      return now.add(Duration(days: daysNeeded));
    }

    final date10M = calcEstDate(10000000.0);
    final date50M = calcEstDate(50000000.0);
    final date100M = calcEstDate(100000000.0);

    // Tính dự báo Cuối Năm 2026 (31/12/2026)
    final endOfYear = DateTime(now.year, 12, 31);
    final daysToEndOfYear = max(0, endOfYear.difference(now).inDays);
    final estYearFund = currentTotal + (daysToEndOfYear * dailyRate);

    // Tính quỹ Tết Đinh Mùi (06/02/2027)
    final tetDate = DateTime(2027, 2, 6);
    final daysToTet = max(0, tetDate.difference(now).inDays);
    final estTetFund = currentTotal + (daysToTet * dailyRate);

    String strDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    int daysUntil(DateTime d) => max(0, d.difference(now).inDays);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.15),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('🔮', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI DỰ BÁO NGÀY CHẠM MỐC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Dự báo cột mốc tài chính tương lai ✨',
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
                      // Current Status Summary Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: innerCardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('TỔNG TÍCH LŨY', style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.formatShortNumber(currentTotal),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 30, color: cardBorder),
                            Column(
                              children: [
                                Text('TỐC ĐỘ TRUNG BÌNH', style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  '${Formatters.formatShortNumber(dailyRate)}/ngày',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.amberGoldLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('🎯 Các Cột Mốc Tương Lai Dự Kiến:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor)),
                      const SizedBox(height: 10),

                      // Milestone 10M Card
                      _buildMilestoneCard(
                        context: context,
                        icon: '🥇',
                        title: 'Mốc 10.000.000 VNĐ',
                        estDateStr: strDate(date10M),
                        daysLeft: daysUntil(date10M),
                        isAchieved: currentTotal >= 10000000.0,
                        color: AppTheme.amberGoldLight,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),

                      // Milestone 50M Card
                      _buildMilestoneCard(
                        context: context,
                        icon: '💎',
                        title: 'Mốc 50.000.000 VNĐ',
                        estDateStr: strDate(date50M),
                        daysLeft: daysUntil(date50M),
                        isAchieved: currentTotal >= 50000000.0,
                        color: Colors.cyanAccent,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),

                      // Milestone 100M Card
                      _buildMilestoneCard(
                        context: context,
                        icon: '👑',
                        title: 'Mốc 100.000.000 VNĐ',
                        estDateStr: strDate(date100M),
                        daysLeft: daysUntil(date100M),
                        isAchieved: currentTotal >= 100000000.0,
                        color: Colors.purpleAccent,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),

                      // End of Year 2026 Forecast Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.amberGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.amberGold.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Text('📊', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dự Báo Cuối Năm 2026 (31/12/2026)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.amberGoldLight)),
                                  Text(
                                    'Dự kiến tích lũy: ${Formatters.formatShortNumber(estYearFund)}',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: primaryTextColor),
                                  ),
                                  Text('Còn đúng $daysToEndOfYear ngày nữa hết năm 2026', style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tet 2027 Fund Forecast Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withValues(alpha: 0.15),
                              Colors.amber.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Text('🧧', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tết Đinh Mùi 2027 (06/02/2027)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                  Text(
                                    'Dự kiến quỹ ăn Tết: ${Formatters.formatShortNumber(estTetFund)}',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: primaryTextColor),
                                  ),
                                  Text('Còn đúng $daysToTet ngày nữa đến Tết!', style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // AI Insight Advice Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Lời Nhuyên Từ AI Gemini 3.6:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_isLoadingAi)
                              const Row(
                                children: [
                                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent)),
                                  SizedBox(width: 10),
                                  Text('AI Gemini đang phân tích tiến độ...', style: TextStyle(fontSize: 11, color: Colors.purpleAccent)),
                                ],
                              )
                            else
                              Text(
                                _aiAdvice,
                                style: TextStyle(fontSize: 12, height: 1.4, color: primaryTextColor, fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
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

  Widget _buildMilestoneCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String estDateStr,
    required int daysLeft,
    required bool isAchieved,
    required Color color,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppTheme.bgApp : const Color(0xFFF8FAFC);
    final border = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAchieved ? AppTheme.emeraldPrimary : border),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text(
                  isAchieved ? '🎉 Đã đạt cột mốc này!' : 'Dự kiến: $estDateStr (Còn $daysLeft ngày)',
                  style: TextStyle(fontSize: 10, color: isAchieved ? AppTheme.emeraldPrimary : secondaryTextColor, fontWeight: isAchieved ? FontWeight.bold : FontWeight.normal),
                ),
              ],
            ),
          ),
          if (isAchieved)
            const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldPrimary, size: 20),
        ],
      ),
    );
  }
}
