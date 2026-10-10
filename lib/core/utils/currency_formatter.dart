import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  /// Format double amount to Vietnamese Dong string: e.g. "65.000 đ"
  static String formatVND(double amount) {
    return _vndFormat.format(amount).trim();
  }

  /// Format compact for charts: e.g. "120k", "1.5M"
  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}M';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    }
    return amount.toInt().toString();
  }
}
