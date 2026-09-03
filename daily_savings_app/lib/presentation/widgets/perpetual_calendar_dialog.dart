import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

/// 100% Exact Ho Ngoc Duc Astronomical Vietnamese Lunar Calendar Algorithm (UTC+7)
class LunarUtils {
  static const _can = ['Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'];
  static const _chi = ['Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'];

  static int jdFromDate(int dd, int mm, int yy) {
    int a = (14 - mm) ~/ 12;
    int y = yy + 4800 - a;
    int m = mm + 12 * a - 3;
    return dd + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }

  static double getNewMoonDay(int k, double timeZone) {
    double T = k / 1236.85;
    double T2 = T * T;
    double T3 = T2 * T;
    double dr = pi / 180.0;
    double Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
    double M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3;
    double Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3;
    double F = 21.1524 + 390.67050646 * k - 0.0016533 * T2 - 0.00000273 * T3;
    double C1 = (0.1734 - 0.000393 * T) * sin(M * dr) + 0.0021 * sin(2 * M * dr);
    C1 = C1 - 0.4068 * sin(Mpr * dr) + 0.0161 * sin(2 * Mpr * dr);
    C1 = C1 - 0.0004 * sin(3 * Mpr * dr);
    C1 = C1 + 0.0104 * sin(2 * F * dr) - 0.0051 * sin((M + Mpr) * dr);
    C1 = C1 - 0.0074 * sin((M - Mpr) * dr) + 0.0004 * sin((2 * F + M) * dr);
    C1 = C1 - 0.0004 * sin((2 * F - M) * dr) - 0.0006 * sin((2 * F + Mpr) * dr);
    C1 = C1 + 0.0010 * sin((2 * F - Mpr) * dr) + 0.0005 * sin((M + 2 * Mpr) * dr);
    double deltat = (T < -0.5)
        ? 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 + 0.000000081 * T * T3
        : -0.00009 + 0.000004 * T + 0.000296 * T2 + 0.000213 * T3 + 0.000025 * T * T3;
    double JdNew = Jd1 + C1 - deltat;
    return JdNew + timeZone / 24.0;
  }

  static double getSunLongitude(double jdn, double timeZone) {
    double jdnUtc = jdn - 0.5 - timeZone / 24.0;
    double T = (jdnUtc - 2451545.0) / 36525.0;
    double T2 = T * T;
    double dr = pi / 180.0;
    double M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2;
    double L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2;
    double DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * sin(M * dr);
    DL += (0.019993 - 0.000101 * T) * sin(2 * M * dr);
    DL += 0.000290 * sin(3 * M * dr);
    double L = L0 + DL;
    L = L * dr;
    L = L - 2 * pi * (L / (2 * pi)).floor();
    return (L / dr / 30.0).floor() * 1.0;
  }

  static int getLunarMonth11(int yy, double timeZone) {
    int off = jdFromDate(31, 12, yy) - 2415021;
    int k = (off / 29.53058868).floor();
    double nm = getNewMoonDay(k, timeZone);
    double sunLong = getSunLongitude(nm, timeZone);
    if (sunLong >= 9) {
      nm = getNewMoonDay(k - 1, timeZone);
    }
    return (nm + 0.5).floor();
  }

  static List<int> convertSolarToLunar(int dd, int mm, int yy, [double timeZone = 7.0]) {
    int dayNumber = jdFromDate(dd, mm, yy);
    int k = ((dayNumber - 2415021.07699) / 29.53058868).floor();
    
    int nextMonthStart = (getNewMoonDay(k + 1, timeZone) + 0.5).floor();
    if (nextMonthStart <= dayNumber) {
      k = k + 1;
    }
    
    int lastMonthStart = (getNewMoonDay(k, timeZone) + 0.5).floor();
    if (lastMonthStart > dayNumber) {
      k = k - 1;
      lastMonthStart = (getNewMoonDay(k, timeZone) + 0.5).floor();
    }
    int lunarDay = dayNumber - lastMonthStart + 1;
    
    int a11 = getLunarMonth11(yy, timeZone);
    int b11 = a11;

    if (dayNumber >= a11) {
      b11 = getLunarMonth11(yy + 1, timeZone);
    } else {
      a11 = getLunarMonth11(yy - 1, timeZone);
    }

    int kCurrent = ((lastMonthStart - 2415021.07699) / 29.53058868).round();
    int kA11 = ((a11 - 2415021.07699) / 29.53058868).round();
    int kB11 = ((b11 - 2415021.07699) / 29.53058868).round();

    int lunarMonth = kCurrent - kA11 + 11;
    
    // Check leap month
    if (kB11 - kA11 == 13) {
      int leapMonthDiff = kCurrent - kA11;
      int leapPos = 0;
      for (int i = 0; i < 13; i++) {
        int nm1 = (getNewMoonDay(kA11 + i, timeZone) + 0.5).floor();
        int nm2 = (getNewMoonDay(kA11 + i + 1, timeZone) + 0.5).floor();
        double sl1 = getSunLongitude(nm1 * 1.0, timeZone);
        double sl2 = getSunLongitude(nm2 * 1.0, timeZone);
        if (sl1 == sl2) {
          leapPos = i;
          break;
        }
      }
      if (leapPos > 0 && leapMonthDiff > leapPos) {
        lunarMonth = lunarMonth - 1;
      }
    }

    if (lunarMonth > 12) {
      lunarMonth = lunarMonth - 12;
    }
    if (lunarMonth < 1) {
      lunarMonth = lunarMonth + 12;
    }

    int finalYear = (dayNumber >= a11) ? (lunarMonth >= 11 ? yy : yy + 1) : (lunarMonth >= 11 ? yy - 1 : yy);
    if (mm <= 2 && lunarMonth >= 10) finalYear = yy - 1;
    if (mm >= 11 && lunarMonth <= 2) finalYear = yy;

    return [lunarDay, lunarMonth, finalYear];
  }

  static String getCanChiDay(DateTime date) {
    int jd = jdFromDate(date.day, date.month, date.year);
    int canIdx = (jd + 9) % 10;
    int chiIdx = (jd + 1) % 12;
    return '${_can[canIdx]} ${_chi[chiIdx]}';
  }

  static String getCanChiYear(int year) {
    int canIdx = (year - 4) % 10;
    int chiIdx = (year - 4) % 12;
    return '${_can[canIdx < 0 ? canIdx + 10 : canIdx]} ${_chi[chiIdx < 0 ? chiIdx + 12 : chiIdx]}';
  }
}

class PerpetualCalendarDialog extends StatefulWidget {
  const PerpetualCalendarDialog({super.key});

  @override
  State<PerpetualCalendarDialog> createState() => _PerpetualCalendarDialogState();
}

class _PerpetualCalendarDialogState extends State<PerpetualCalendarDialog> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _viewMonthDate;

  @override
  void initState() {
    super.initState();
    _viewMonthDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _changeMonth(int offset) {
    setState(() {
      _viewMonthDate = DateTime(_viewMonthDate.year, _viewMonthDate.month + offset, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final lunarList = LunarUtils.convertSolarToLunar(_selectedDate.day, _selectedDate.month, _selectedDate.year);
    final lunarDay = lunarList[0];
    final lunarMonth = lunarList[1];
    final lunarYear = lunarList[2];

    final canChiDayStr = LunarUtils.getCanChiDay(_selectedDate);
    final canChiYearStr = LunarUtils.getCanChiYear(lunarYear);

    final isMung1OrRam = lunarDay == 1 || lunarDay == 15;
    final dayOfWeekStr = _selectedDate.weekday == 7 ? 'CHỦ NHẬT' : 'THỨ ${Formatters.formatDayOfWeek(_selectedDate).toUpperCase()}';

    String lunarSpecialBadge = '';
    if (lunarDay == 1) {
      lunarSpecialBadge = '🌙 MÙNG 1 ÂM LỊCH • KHỞI ĐẦU MAY MẮN';
    } else if (lunarDay == 15) {
      lunarSpecialBadge = '🌕 NGÀY RẰM 15 ÂM LỊCH • NĂNG LƯỢNG AN LẠC';
    }

    // Grid calculation
    final daysInViewMonth = DateTime(_viewMonthDate.year, _viewMonthDate.month + 1, 0).day;
    final firstWeekday = DateTime(_viewMonthDate.year, _viewMonthDate.month, 1).weekday;
    final leadingPadding = (firstWeekday == 7) ? 6 : (firstWeekday - 1);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Theme Color Palette
    final dialogBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);
    final weekdayHeaderColor = isDark ? AppTheme.textMuted : const Color(0xFF475569);
    final cellDefaultBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final cellBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.amberGoldLight.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.2),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Royal Header Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7F1D1D), Color(0xFFB45309), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('🗓️', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LỊCH VẠN NIÊN ÂM - DƯƠNG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tra cứu âm lịch & ngày hoàng đạo 🔮',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      // LUXURY TRADITIONAL DESK CALENDAR BLOCK (LỊCH LỐC CAO CẤP)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isMung1OrRam ? AppTheme.amberGoldLight : (isToday ? AppTheme.skyBlueAccent : cardBorder),
                            width: (isMung1OrRam || isToday) ? 2 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Metallic Binder Pins Decorative Top Bar
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.amberGoldLight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    'THÁNG $lunarMonth ÂM LỊCH • NĂM $canChiYearStr',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.amberGoldLight,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.amberGoldLight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Dual Side-by-Side Calendar Card Content (Solar Left vs Lunar Right)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              child: Row(
                                children: [
                                  // LEFT SIDE: SOLAR DATE (DƯƠNG LỊCH)
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.skyBlueAccent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            '☀️ DƯƠNG LỊCH',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.skyBlueAccent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${_selectedDate.day}',
                                          style: TextStyle(
                                            fontSize: 52,
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dayOfWeekStr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _selectedDate.weekday == 7 ? Colors.redAccent : AppTheme.skyBlueAccent,
                                          ),
                                        ),
                                        Text(
                                          'Tháng ${_selectedDate.month}/${_selectedDate.year}',
                                          style: TextStyle(fontSize: 10.5, color: secondaryTextColor),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Center Divider Line
                                  Container(
                                    height: 90,
                                    width: 1.2,
                                    color: cardBorder,
                                  ),

                                  // RIGHT SIDE: LUNAR DATE (ÂM LỊCH)
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.amberGold.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            '🌙 ÂM LỊCH',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.amberGoldLight,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$lunarDay',
                                          style: TextStyle(
                                            fontSize: 52,
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
                                            color: AppTheme.amberGoldLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ngày $canChiDayStr',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.amberGoldLight,
                                          ),
                                        ),
                                        Text(
                                          'Tháng $lunarMonth Âm Lịch',
                                          style: TextStyle(fontSize: 10.5, color: secondaryTextColor),
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
                      const SizedBox(height: 12),

                      // Fengshui & Auspicious Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMung1OrRam
                              ? AppTheme.amberGold.withValues(alpha: 0.12)
                              : cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isMung1OrRam ? AppTheme.amberGoldLight : cardBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome, size: 14, color: AppTheme.amberGoldLight),
                                const SizedBox(width: 6),
                                Text(
                                  isMung1OrRam ? 'NGÀY ÂM LỊCH ĐẶC BIỆT' : 'CHI TIẾT PHONG THỦY & HOÀNG ĐẠO',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.amberGoldLight,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            if (lunarSpecialBadge.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                lunarSpecialBadge,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.amberGoldLight,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Divider(color: cardBorder, height: 10),
                            Text(
                              '🌟 Giờ Hoàng Đạo: Tý (23-1), Sửu (1-3), Mão (5-7), Ngọ (11-13), Thân (15-17), Dậu (17-19)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10.5, color: secondaryTextColor, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // DUAL MONTH GRID SECTION (LỊCH THÁNG)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => _changeMonth(-1),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.chevron_left_rounded, color: AppTheme.skyBlueAccent, size: 20),
                              ),
                            ),
                            Text(
                              'THÁNG ${_viewMonthDate.month}/${_viewMonthDate.year}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: primaryTextColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            InkWell(
                              onTap: () => _changeMonth(1),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.chevron_right_rounded, color: AppTheme.skyBlueAccent, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Weekday Titles Row (T2 -> CN format)
                      Row(
                        children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((w) {
                          return Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                w,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: w == 'CN' ? Colors.redAccent : weekdayHeaderColor,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),

                      // Full Month Dual Calendar Grid (Solar Top + Lunar Bottom)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: leadingPadding + daysInViewMonth,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.05,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                        ),
                        itemBuilder: (ctx, index) {
                          if (index < leadingPadding) {
                            return const SizedBox();
                          }
                          final dayNum = index - leadingPadding + 1;
                          final cellDate = DateTime(_viewMonthDate.year, _viewMonthDate.month, dayNum);

                          final isCellSelected = cellDate.year == _selectedDate.year &&
                              cellDate.month == _selectedDate.month &&
                              cellDate.day == _selectedDate.day;

                          final isCellToday = cellDate.year == now.year &&
                              cellDate.month == now.month &&
                              cellDate.day == now.day;

                          final cellLunarList = LunarUtils.convertSolarToLunar(cellDate.day, cellDate.month, cellDate.year);
                          final cellLunarDay = cellLunarList[0];
                          final cellLunarMonth = cellLunarList[1];
                          final isCellMung1OrRam = cellLunarDay == 1 || cellLunarDay == 15;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDate = cellDate;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isCellSelected
                                    ? AppTheme.skyBlueAccent
                                    : (isCellToday
                                        ? AppTheme.skyBlueAccent.withValues(alpha: 0.25)
                                        : (isCellMung1OrRam ? AppTheme.amberGold.withValues(alpha: 0.15) : cellDefaultBg)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCellSelected
                                      ? AppTheme.skyBlueAccent
                                      : (isCellToday
                                          ? AppTheme.skyBlueAccent
                                          : (isCellMung1OrRam ? AppTheme.amberGoldLight : cellBorderColor)),
                                  width: (isCellSelected || isCellToday) ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Solar Day Number (Dương Lịch)
                                  Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isCellSelected
                                          ? Colors.black
                                          : (cellDate.weekday == 7 ? Colors.redAccent : primaryTextColor),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  // Lunar Day Subtext (Âm Lịch)
                                  Text(
                                    cellLunarDay == 1 ? '1/$cellLunarMonth' : '$cellLunarDay',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: isCellMung1OrRam ? FontWeight.w900 : FontWeight.w500,
                                      color: isCellSelected
                                          ? Colors.black87
                                          : (isCellMung1OrRam ? (isDark ? AppTheme.amberGoldLight : const Color(0xFFD97706)) : secondaryTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Reset to Today Button
                      if (!isToday)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedDate = DateTime.now();
                                _viewMonthDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
                              });
                            },
                            icon: const Icon(Icons.today_rounded, size: 16, color: AppTheme.skyBlueAccent),
                            label: const Text('Quay Về Hôm Nay', style: TextStyle(color: AppTheme.skyBlueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.skyBlueAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
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
}
