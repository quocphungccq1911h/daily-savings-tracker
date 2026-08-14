import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  /// Formats currency number into VNĐ display string (e.g. 150.000 đ)
  static String formatShortNumber(num amount) {
    if (amount == 0) return '0 đ';
    return '${_currencyFormat.format(amount.round())} đ';
  }

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
}
