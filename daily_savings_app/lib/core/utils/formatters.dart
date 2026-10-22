import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  /// Formats currency number into VNĐ display string (e.g. 150.000 đ)
  static String formatShortNumber(num amount) {
    if (amount == 0) return '0 đ';
    return '${_currencyFormat.format(amount.round())} đ';
  }

  /// Alias for formatShortNumber
  static String formatCurrency(num amount) => formatShortNumber(amount);


  /// Formats raw number into dotted string (e.g. 150000 -> 150.000)
  static String formatNumberDot(num amount) {
    return _currencyFormat.format(amount.round());
  }

  /// Formats date string YYYY-MM-DD into DD/MM/YYYY
  static String formatDateVN(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }

  /// Formats day of week in Vietnamese
  static String formatDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday: return 'Hai';
      case DateTime.tuesday: return 'Ba';
      case DateTime.wednesday: return 'Tư';
      case DateTime.thursday: return 'Năm';
      case DateTime.friday: return 'Sáu';
      case DateTime.saturday: return 'Bảy';
      case DateTime.sunday: return 'Chủ Nhật';
      default: return '';
    }
  }

  /// Calculates week boundaries (Monday to Sunday) based on offset
  static WeekRange getWeekRange(int offset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // In Dart: Monday = 1, Sunday = 7
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    final targetMonday = currentMonday.add(Duration(days: offset * 7));
    final targetSunday = targetMonday.add(const Duration(days: 6));

    final List<String> dateList = [];
    for (int i = 0; i < 7; i++) {
      final d = targetMonday.add(Duration(days: i));
      dateList.add(
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      );
    }

    final startDisplay =
        '${targetMonday.day.toString().padLeft(2, '0')}/${targetMonday.month.toString().padLeft(2, '0')}';
    final endDisplay =
        '${targetSunday.day.toString().padLeft(2, '0')}/${targetSunday.month.toString().padLeft(2, '0')}';

    return WeekRange(
      startDate: targetMonday,
      endDate: targetSunday,
      startDisplay: startDisplay,
      endDisplay: endDisplay,
      dateList: dateList,
      isCurrentWeek: offset == 0,
    );
  }
}

class WeekRange {
  final DateTime startDate;
  final DateTime endDate;
  final String startDisplay;
  final String endDisplay;
  final List<String> dateList;
  final bool isCurrentWeek;

  const WeekRange({
    required this.startDate,
    required this.endDate,
    required this.startDisplay,
    required this.endDisplay,
    required this.dateList,
    required this.isCurrentWeek,
  });
}
