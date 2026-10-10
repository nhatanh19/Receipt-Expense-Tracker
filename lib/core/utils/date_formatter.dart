import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static String formatDayOfWeek(DateTime date) {
    return switch (date.weekday) {
      DateTime.monday => 'Thứ 2',
      DateTime.tuesday => 'Thứ 3',
      DateTime.wednesday => 'Thứ 4',
      DateTime.thursday => 'Thứ 5',
      DateTime.friday => 'Thứ 6',
      DateTime.saturday => 'Thứ 7',
      DateTime.sunday => 'Chủ nhật',
      _ => '',
    };
  }

  static DateTime? tryParseDate(String input) {
    final cleanInput = input.trim();
    // Try formats like dd/MM/yyyy, dd-MM-yyyy, yyyy-MM-dd
    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd.MM.yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'd/M/yyyy',
      'd-M-yyyy',
      'dd/MM/yy',
      'dd-MM-yy',
    ];

    for (final fmt in formats) {
      try {
        final parsed = DateFormat(fmt).parseStrict(cleanInput);
        return parsed;
      } catch (_) {}
    }
    return null;
  }
}
