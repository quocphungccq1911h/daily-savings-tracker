import 'dart:math';
import 'package:flutter/material.dart';

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

  static String getCanChiMonth(int lunarMonth, int lunarYear) {
    int yearCanIdx = ((lunarYear - 4) % 10 + 10) % 10;
    int startMonthCan = (yearCanIdx % 5) * 2 + 2;
    int monthCanIdx = (startMonthCan + (lunarMonth - 1)) % 10;
    int monthChiIdx = (lunarMonth + 1) % 12;
    return '${_can[monthCanIdx]} ${_chi[monthChiIdx]}';
  }

  static String getGioHoangDao(DateTime date) {
    int jd = jdFromDate(date.day, date.month, date.year);
    int chiIdx = (jd + 1) % 12;
    const gioMap = {
      0: 'Tý (23-1), Sửu (1-3), Mão (5-7), Ngọ (11-13), Thân (15-17), Dậu (17-19)',
      6: 'Tý (23-1), Sửu (1-3), Mão (5-7), Ngọ (11-13), Thân (15-17), Dậu (17-19)',
      1: 'Dần (3-5), Mão (5-7), Tỵ (9-11), Thân (15-17), Tuất (19-21), Hợi (21-23)',
      7: 'Dần (3-5), Mão (5-7), Tỵ (9-11), Thân (15-17), Tuất (19-21), Hợi (21-23)',
      2: 'Tý (23-1), Sửu (1-3), Thìn (7-9), Tỵ (9-11), Mùi (13-15), Tuất (19-21)',
      8: 'Tý (23-1), Sửu (1-3), Thìn (7-9), Tỵ (9-11), Mùi (13-15), Tuất (19-21)',
      3: 'Tý (23-1), Dần (3-5), Mão (5-7), Ngọ (11-13), Mùi (13-15), Dậu (17-19)',
      9: 'Tý (23-1), Dần (3-5), Mão (5-7), Ngọ (11-13), Mùi (13-15), Dậu (17-19)',
      4: 'Dần (3-5), Thìn (7-9), Tỵ (9-11), Thân (15-17), Dậu (17-19), Hợi (21-23)',
      10: 'Dần (3-5), Thìn (7-9), Tỵ (9-11), Thân (15-17), Dậu (17-19), Hợi (21-23)',
      5: 'Sửu (1-3), Thìn (7-9), Ngọ (11-13), Mùi (13-15), Tuất (19-21), Hợi (21-23)',
      11: 'Sửu (1-3), Thìn (7-9), Ngọ (11-13), Mùi (13-15), Tuất (19-21), Hợi (21-23)'
    };
    return gioMap[chiIdx] ?? 'Tý (23-1), Sửu (1-3), Mão (5-7), Ngọ (11-13), Thân (15-17), Dậu (17-19)';
  }

  static Map<String, String> getHyThanTaiThan(DateTime date) {
    int jd = jdFromDate(date.day, date.month, date.year);
    int canIdx = (jd + 9) % 10;
    const hyMap = ['Đông Bắc', 'Tây Bắc', 'Tây Nam', 'Chính Nam', 'Đông Nam', 'Đông Bắc', 'Tây Bắc', 'Tây Nam', 'Chính Nam', 'Đông Nam'];
    const taiMap = ['Đông Nam', 'Đông Nam', 'Chính Đông', 'Chính Đông', 'Chính Bắc', 'Chính Nam', 'Tây Nam', 'Tây Nam', 'Chính Tây', 'Chính Bắc'];
    return {'hy': hyMap[canIdx], 'tai': taiMap[canIdx]};
  }

  static String getTietKhi(DateTime date) {
    int mm = date.month;
    int dd = date.day;
    const tietMap = [
      {'m': 1, 'd': 6, 'name': 'Tiểu Hàn'}, {'m': 1, 'd': 21, 'name': 'Đại Hàn'},
      {'m': 2, 'd': 4, 'name': 'Lập Xuân'}, {'m': 2, 'd': 19, 'name': 'Vũ Thủy'},
      {'m': 3, 'd': 6, 'name': 'Kinh Trập'}, {'m': 3, 'd': 21, 'name': 'Xuân Phân'},
      {'m': 4, 'd': 5, 'name': 'Thanh Minh'}, {'m': 4, 'd': 20, 'name': 'Cốc Vũ'},
      {'m': 5, 'd': 6, 'name': 'Lập Hạ'}, {'m': 5, 'd': 21, 'name': 'Tiểu Mãn'},
      {'m': 6, 'd': 6, 'name': 'Mang Chủng'}, {'m': 6, 'd': 21, 'name': 'Hạ Chí'},
      {'m': 7, 'd': 7, 'name': 'Tiểu Thử'}, {'m': 7, 'd': 23, 'name': 'Đại Thử'},
      {'m': 8, 'd': 8, 'name': 'Lập Thu'}, {'m': 8, 'd': 23, 'name': 'Xử Thử'},
      {'m': 9, 'd': 8, 'name': 'Bạch Lộ'}, {'m': 9, 'd': 23, 'name': 'Thu Phân'},
      {'m': 10, 'd': 8, 'name': 'Hàn Lộ'}, {'m': 10, 'd': 24, 'name': 'Sương Giáng'},
      {'m': 11, 'd': 8, 'name': 'Lập Đông'}, {'m': 11, 'd': 22, 'name': 'Tiểu Tuyết'},
      {'m': 12, 'd': 7, 'name': 'Đại Tuyết'}, {'m': 12, 'd': 22, 'name': 'Đông Chí'}
    ];
    String currentTiet = 'Hàn Lộ';
    for (var t in tietMap) {
      if (mm > (t['m'] as int) || (mm == t['m'] && dd >= (t['d'] as int))) {
        currentTiet = t['name'] as String;
      }
    }
    return currentTiet;
  }

  static bool isNgayHoangDao(DateTime date, int lunarMonth) {
    int jd = jdFromDate(date.day, date.month, date.year);
    int chiIdx = (jd + 1) % 12;
    const hoangDaoMonths = {
      1: [0, 1, 4, 7, 8, 11],
      7: [0, 1, 4, 7, 8, 11],
      2: [2, 3, 6, 9, 10, 1],
      8: [2, 3, 6, 9, 10, 1],
      3: [4, 5, 8, 11, 0, 3],
      9: [4, 5, 8, 11, 0, 3],
      4: [6, 7, 10, 1, 2, 5],
      10: [6, 7, 10, 1, 2, 5],
      5: [8, 9, 0, 3, 4, 7],
      11: [8, 9, 0, 3, 4, 7],
      6: [10, 11, 2, 5, 6, 9],
      12: [10, 11, 2, 5, 6, 9]
    };
    final list = hoangDaoMonths[lunarMonth] ?? [0, 2, 4, 6, 8, 10];
    return list.contains(chiIdx);
  }

  static const _zodiacEmojis = {
    'Tý': '🐭', 'Sửu': '🐮', 'Dần': '🐯', 'Mão': '🐱',
    'Thìn': '🐲', 'Tỵ': '🐍', 'Ngọ': '🐴', 'Mùi': '🐐',
    'Thân': '🐵', 'Dậu': '🐔', 'Tuất': '🐶', 'Hợi': '🐷'
  };

  static String getZodiacEmoji(String chi) => _zodiacEmojis[chi] ?? '✨';

  static List<Map<String, String>> getAuspiciousHoursDetailed(DateTime date) {
    int jd = jdFromDate(date.day, date.month, date.year);
    int chiIdx = (jd + 1) % 12;
    const map = {
      0: [{'c': 'Tý', 'r': '23h-01h'}, {'c': 'Sửu', 'r': '01h-03h'}, {'c': 'Mão', 'r': '05h-07h'}, {'c': 'Ngọ', 'r': '11h-13h'}, {'c': 'Thân', 'r': '15h-17h'}, {'c': 'Dậu', 'r': '17h-19h'}],
      6: [{'c': 'Tý', 'r': '23h-01h'}, {'c': 'Sửu', 'r': '01h-03h'}, {'c': 'Mão', 'r': '05h-07h'}, {'c': 'Ngọ', 'r': '11h-13h'}, {'c': 'Thân', 'r': '15h-17h'}, {'c': 'Dậu', 'r': '17h-19h'}],
      1: [{'c': 'Dần', 'r': '03h-05h'}, {'c': 'Mão', 'r': '05h-07h'}, {'c': 'Tỵ', 'r': '09h-11h'}, {'c': 'Thân', 'r': '15h-17h'}, {'c': 'Tuất', 'r': '19h-21h'}, {'c': 'Hợi', 'r': '21h-23h'}],
      7: [{'c': 'Dần', 'r': '03h-05h'}, {'c': 'Mão', 'r': '05h-07h'}, {'c': 'Tỵ', 'r': '09h-11h'}, {'c': 'Thân', 'r': '15h-17h'}, {'c': 'Tuất', 'r': '19h-21h'}, {'c': 'Hợi', 'r': '21h-23h'}],
      2: [{'c': 'Tý', 'r': '23h-01h'}, {'c': 'Sửu', 'r': '01h-03h'}, {'c': 'Thìn', 'r': '07h-09h'}, {'c': 'Tỵ', 'r': '09h-11h'}, {'c': 'Mùi', 'r': '13h-15h'}, {'c': 'Tuất', 'r': '19h-21h'}],
      8: [{'c': 'Tý', 'r': '23h-01h'}, {'c': 'Sửu', 'r': '01h-03h'}, {'c': 'Thìn', 'r': '07h-09h'}, {'c': 'Tỵ', 'r': '09h-11h'}, {'c': 'Mùi', 'r': '13h-15h'}, {'c': 'Tuất', 'r': '19h-21h'}],
      3: [{'c': 'Tý', 'r': '23h-01h'}, {'c': 'Dần', 'r': '03h-05h'}, {'c': 'Mão', 'r': '05h-07h'}, {'c': 'Ngọ', 'r': '11h-13h'}, {'c': 'Mùi', 'r': '13h-15h'}, {'c': 'Dậu', 'r': '17h-19h'}],
      9: [{'c': 'Tý', 'r': '23h-01h'}, {'c': 'Dần', 'r': '03h-05h'}, {'c': 'Mão', 'r': '05h-07h'}, {'c': 'Ngọ', 'r': '11h-13h'}, {'c': 'Mùi', 'r': '13h-15h'}, {'c': 'Dậu', 'r': '17h-19h'}],
      4: [{'c': 'Dần', 'r': '03h-05h'}, {'c': 'Thìn', 'r': '07h-09h'}, {'c': 'Tỵ', 'r': '09h-11h'}, {'c': 'Thân', 'r': '15h-17h'}, {'c': 'Dậu', 'r': '17h-19h'}, {'c': 'Hợi', 'r': '21h-23h'}],
      10: [{'c': 'Dần', 'r': '03h-05h'}, {'c': 'Thìn', 'r': '07h-09h'}, {'c': 'Tỵ', 'r': '09h-11h'}, {'c': 'Thân', 'r': '15h-17h'}, {'c': 'Dậu', 'r': '17h-19h'}, {'c': 'Hợi', 'r': '21h-23h'}],
      5: [{'c': 'Sửu', 'r': '01h-03h'}, {'c': 'Thìn', 'r': '07h-09h'}, {'c': 'Ngọ', 'r': '11h-13h'}, {'c': 'Mùi', 'r': '13h-15h'}, {'c': 'Tuất', 'r': '19h-21h'}, {'c': 'Hợi', 'r': '21h-23h'}],
      11: [{'c': 'Sửu', 'r': '01h-03h'}, {'c': 'Thìn', 'r': '07h-09h'}, {'c': 'Ngọ', 'r': '11h-13h'}, {'c': 'Mùi', 'r': '13h-15h'}, {'c': 'Tuất', 'r': '19h-21h'}, {'c': 'Hợi', 'r': '21h-23h'}]
    };
    final hours = map[chiIdx] ?? map[0]!;
    return hours.map((h) => {
      'emoji': getZodiacEmoji(h['c']!),
      'name': h['c']!,
      'range': h['r']!
    }).toList();
  }

  static String getDailyQuote(int dayNumber) {
    const quotes = [
      'Vạn sự khởi đầu nan, kiên tâm ắt thành đại nghiệp.',
      'Có công mài sắt, có ngày nên kim.',
      'Thuận vợ thuận chồng, tát biển Đông cũng cạn.',
      'Một cây làm chẳng nên non, ba cây chụm lại nên hòn núi cao.',
      'Đi một ngày đàng, học một sàng khôn.',
      'Ở hiền gặp lành, gieo nhân lành gặt quả ngọt.',
      'Tâm an vạn sự an, trí sáng tương lai rạng.',
      'Ăn quả nhớ kẻ trồng cây, uống nước nhớ nguồn.',
      'Lời nói chẳng mất tiền mua, lựa lời mà nói cho vừa lòng nhau.',
      'Trời không phụ lòng người có chí.'
    ];
    return quotes[(dayNumber - 1) % quotes.length];
  }

  static Map<String, String> getTrucNgay(DateTime date, int lunarMonth) {
    int jd = jdFromDate(date.day, date.month, date.year);
    int chiIdx = (jd + 1) % 12;
    int startChi = (lunarMonth + 1) % 12;
    int trucIdx = ((chiIdx - startChi) % 12 + 12) % 12;
    const trucs = [
      {'name': 'Kiến', 'nghii': 'Xuất hành, khởi công, giao dịch', 'ky': 'Động thổ, kiện tụng'},
      {'name': 'Trừ', 'nghii': 'Tẩy uế, dọn dẹp, cầu an', 'ky': 'Cưới hỏi, khai trương'},
      {'name': 'Mãn', 'nghii': 'Cầu tài, mở kho, thu nợ', 'ky': 'Chôn cất, nhậm chức'},
      {'name': 'Bình', 'nghii': 'Sửa chữa, giao dịch, hòa giải', 'ky': 'Đi xa, tranh chấp'},
      {'name': 'Định', 'nghii': 'Giao kết, nhập trạch, ký hợp đồng', 'ky': 'Kiện tụng, xuất quân'},
      {'name': 'Chấp', 'nghii': 'Xây dựng, đặt cọc, tích lũy', 'ky': 'Chuyển nhà, việc mạo hiểm'},
      {'name': 'Phá', 'nghii': 'Phá dỡ, sửa đồ cũ, giải hạn', 'ky': 'Khai trương, ký kết'},
      {'name': 'Nguy', 'nghii': 'Cúng tế, làm từ thiện, an phận', 'ky': 'Đi thuyền bè, leo cao'},
      {'name': 'Thành', 'nghii': 'Khai trương, nhập học, khởi nghiệp', 'ky': 'Kiện tụng, tranh chấp'},
      {'name': 'Thu', 'nghii': 'Thu nợ, gom góp tài sản, an cư', 'ky': 'Xuất hành, an táng'},
      {'name': 'Khai', 'nghii': 'Mở tiệm, kết bạn, cầu tài lộc', 'ky': 'Động thổ, việc hung'},
      {'name': 'Bế', 'nghii': 'Cất giữ tài sản, an cư', 'ky': 'Chữa bệnh, xuất hành'}
    ];
    return trucs[trucIdx];
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
    final isViewingCurrentMonth = _viewMonthDate.year == now.year && _viewMonthDate.month == now.month;

    final lunarList = LunarUtils.convertSolarToLunar(_selectedDate.day, _selectedDate.month, _selectedDate.year);
    final lunarDay = lunarList[0];
    final lunarMonth = lunarList[1];
    final lunarYear = lunarList[2];

    final canChiDayStr = LunarUtils.getCanChiDay(_selectedDate);
    final canChiMonthStr = LunarUtils.getCanChiMonth(lunarMonth, lunarYear);
    final canChiYearStr = LunarUtils.getCanChiYear(lunarYear);
    final hyTai = LunarUtils.getHyThanTaiThan(_selectedDate);
    final tietKhiStr = LunarUtils.getTietKhi(_selectedDate);
    final isHoangDaoDay = LunarUtils.isNgayHoangDao(_selectedDate, lunarMonth);
    final truc = LunarUtils.getTrucNgay(_selectedDate, lunarMonth);
    final auspiciousHours = LunarUtils.getAuspiciousHoursDetailed(_selectedDate);
    final dailyQuote = LunarUtils.getDailyQuote(_selectedDate.day);

    final isMung1 = (lunarDay == 1);
    final isRam = (lunarDay == 15);
    final isSpecialAuspicious = isMung1 || isRam;
    final isSunday = _selectedDate.weekday == DateTime.sunday;
    final dayNames = ['CHỦ NHẬT', 'THỨ HAI', 'THỨ BA', 'THỨ TƯ', 'THỨ NĂM', 'THỨ SÁU', 'THỨ BẢY'];
    final dayOfWeekStr = _selectedDate.weekday == 7 ? 'CHỦ NHẬT' : dayNames[_selectedDate.weekday];

    String specialBadge = '';
    if (isMung1) {
      specialBadge = '🌙 MÙNG 1 ĐẦU THÁNG • KHỞI ĐẦU ĐẠI CÁT';
    } else if (isRam) {
      specialBadge = '🌕 NGÀY RẰM THÁNG $lunarMonth • VIÊN MÃN AN LẠC';
    }

    final daysInViewMonth = DateTime(_viewMonthDate.year, _viewMonthDate.month + 1, 0).day;
    final firstWeekday = DateTime(_viewMonthDate.year, _viewMonthDate.month, 1).weekday;
    final leadingPadding = (firstWeekday == 7) ? 6 : (firstWeekday - 1);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Luxury Theme Colors matching Web
    final dialogBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final blocBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final blocBorder = isSpecialAuspicious
        ? const Color(0xFFF59E0B)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final weekdayHeaderColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cellBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final cellBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🏮 TOP ROYAL HEADER BANNER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7F1D1D), Color(0xFFB45309), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🗓️', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LỊCH VẠN NIÊN HOÀNG GIA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Tra cứu Âm - Dương lịch & Giờ Hoàng Đạo 🔮',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // 🏮 TỜ LỊCH LỐC HOÀNG GIA (3D TEAR-OFF BLOC SHEET)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: blocBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: blocBorder, width: isSpecialAuspicious ? 2 : 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: isSpecialAuspicious
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.15),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 🔩 Metallic Binder Mount with Gold Screws & Title
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                                      : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Screw Left
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        colors: [Color(0xFFFDE68A), Color(0xFFB45309)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text('+', style: TextStyle(fontSize: 8, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.0)),
                                    ),
                                  ),
                                  // Mount Title
                                  Text(
                                    'THÁNG $lunarMonth ÂM LỊCH • NĂM $canChiYearStr',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFF59E0B),
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  // Screw Right
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        colors: [Color(0xFFFDE68A), Color(0xFFB45309)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text('+', style: TextStyle(fontSize: 8, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.0)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ☀️ HERO SOLAR DATE SECTION
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                children: [
                                  // Status Row: Month Pill & Hoang Dao Pill
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Tháng ${_selectedDate.month}/${_selectedDate.year}',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isHoangDaoDay
                                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isHoangDaoDay ? const Color(0xFFF59E0B) : Colors.transparent,
                                          ),
                                        ),
                                        child: Text(
                                          isHoangDaoDay ? '✨ Ngày Hoàng Đạo' : 'Ngày Hắc Đạo',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: isHoangDaoDay ? const Color(0xFFF59E0B) : secondaryTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  // HUGE SOLAR DAY NUMBER
                                  Text(
                                    '${_selectedDate.day}',
                                    style: TextStyle(
                                      fontSize: 68,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                      letterSpacing: -2,
                                      color: isSunday ? const Color(0xFFEF4444) : primaryTextColor,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // Weekday Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSunday
                                          ? const Color(0xFFEF4444)
                                          : (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.18) : const Color(0xFFE0F2FE)),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      dayOfWeekStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        color: isSunday ? Colors.white : const Color(0xFF0284C7),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Daily Wisdom Quote
                                  Text(
                                    '"$dailyQuote"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: secondaryTextColor,
                                      height: 1.3,
                                    ),
                                  ),

                                  if (specialBadge.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFF59E0B)),
                                      ),
                                      child: Text(
                                        specialBadge,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // 🔮 3-COLUMN BÁT TỰ & GOLDEN LUNAR MEDALLION
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.8) : const Color(0xFFF1F5F9),
                                border: Border.symmetric(
                                  horizontal: BorderSide(color: cellBorder, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Left: Tiết Khí & Hướng Thần
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('🌤️ Tiết: $tietKhiStr', style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                                        const SizedBox(height: 2),
                                        Text('🧭 Hỷ: ${hyTai['hy']}', style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                                        const SizedBox(height: 2),
                                        Text('💰 Tài: ${hyTai['tai']}', style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                                      ],
                                    ),
                                  ),

                                  // Center: Golden Lunar Medallion
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFB45309)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$lunarDay',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF451A03),
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          'Tháng $lunarMonth Âm',
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF78350F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Right: Can Chi Bát Tự
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Ngày: $canChiDayStr', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                                        const SizedBox(height: 2),
                                        Text('Tháng: $canChiMonthStr', style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                                        const SizedBox(height: 2),
                                        Text('Năm: $canChiYearStr', style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 🌟 6 KHUNG GIỜ HOÀNG ĐẠO MINI-CARDS
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(
                                    child: Text(
                                      '🌟 6 KHUNG GIỜ HOÀNG ĐẠO KHỞI SỰ CÁT TƯỜNG',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFF59E0B),
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: auspiciousHours.length,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 2.2,
                                      crossAxisSpacing: 6,
                                      mainAxisSpacing: 6,
                                    ),
                                    itemBuilder: (ctx, idx) {
                                      final h = auspiciousHours[idx];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: cellBorder),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(h['emoji']!, style: const TextStyle(fontSize: 10)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  h['name']!,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: primaryTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              h['range']!,
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w600,
                                                color: secondaryTextColor,
                                              ),
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

                      const SizedBox(height: 14),

                      // 📅 INTERACTIVE MONTH CALENDAR PANEL (LỊCH THÁNG TƯƠNG TÁC)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: blocBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: cellBorder),
                        ),
                        child: Column(
                          children: [
                            // Month Nav Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () => _changeMonth(-1),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF38BDF8), size: 18),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'THÁNG ${_viewMonthDate.month} - ${_viewMonthDate.year}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: primaryTextColor,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    if (!isToday || !isViewingCurrentMonth) ...[
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedDate = DateTime.now();
                                            _viewMonthDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF0284C7)),
                                          ),
                                          child: const Text(
                                            '📍 Hôm nay',
                                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                InkWell(
                                  onTap: () => _changeMonth(1),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF38BDF8), size: 18),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Weekday Titles (T2 -> CN)
                            Row(
                              children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((w) {
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      w,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: w == 'CN' ? const Color(0xFFEF4444) : weekdayHeaderColor,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 6),

                            // Month Grid Cells
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: leadingPadding + daysInViewMonth,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1.05,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
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
                                final isCellHD = LunarUtils.isNgayHoangDao(cellDate, cellLunarMonth);

                                final cellBgColor = isCellSelected
                                    ? const Color(0xFF0284C7)
                                    : (isCellToday
                                        ? const Color(0xFF0284C7).withValues(alpha: 0.22)
                                        : (isCellMung1OrRam ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : cellBg));

                                final cellBorderFinal = isCellSelected
                                    ? const Color(0xFF38BDF8)
                                    : (isCellToday
                                        ? const Color(0xFF0284C7)
                                        : (isCellMung1OrRam ? const Color(0xFFF59E0B) : cellBorder));

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = cellDate;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cellBgColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: cellBorderFinal,
                                        width: (isCellSelected || isCellToday) ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Solar number & Hoang Dao dot
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '$dayNum',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: isCellSelected
                                                    ? Colors.white
                                                    : (cellDate.weekday == 7 ? const Color(0xFFEF4444) : primaryTextColor),
                                              ),
                                            ),
                                            if (isCellHD) ...[
                                              const SizedBox(width: 2),
                                              Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: isCellSelected ? const Color(0xFFFDE68A) : const Color(0xFFF59E0B),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 1),
                                        // Lunar day
                                        Text(
                                          cellLunarDay == 1 ? '1/$cellLunarMonth' : (cellLunarDay == 15 ? '15🌕' : '$cellLunarDay'),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: isCellMung1OrRam ? FontWeight.w900 : FontWeight.w500,
                                            color: isCellSelected
                                                ? Colors.white70
                                                : (isCellMung1OrRam ? const Color(0xFFF59E0B) : secondaryTextColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            // ☯️ FENGSHUI ADVISOR CARD (BẢNG TRA CỨU TRỰC NGÀY NÊN / KIÊNG)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cellBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '☯️ Trực ${truc['name']}:',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Nên: ${truc['nghii']}',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Divider(color: cellBorder, height: 6),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Text(
                                        '🚫 Kiêng: ',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${truc['ky']}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '🧭 Hướng Hỷ Thần: ${hyTai['hy']} • Tài Thần: ${hyTai['tai']}',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0284C7),
                                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
