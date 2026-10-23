import 'json.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _monthsLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// `15 Oct 2026`
String formatDate(Object? value, {bool withYear = true}) {
  final d = value is DateTime ? value : parseDate(value);
  if (d == null) return value?.toString() ?? '';
  final base = '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]}';
  return withYear ? '$base ${d.year}' : base;
}

/// `Wednesday, 15 October`
String formatLongDay(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_monthsLong[d.month - 1]}';

/// `2026-10` → `October 2026`
String formatMonthKey(String key) {
  final parts = key.split('-');
  if (parts.length < 2) return key;
  final m = int.tryParse(parts[1]);
  if (m == null || m < 1 || m > 12) return key;
  return '${_monthsLong[m - 1]} ${parts[0]}';
}

/// `2026-10` → `Oct`
String shortMonthKey(String key) {
  final parts = key.split('-');
  final m = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (m == null || m < 1 || m > 12) return key;
  return _months[m - 1];
}

String monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// Relative age such as `40m`, `5h`, `2d`, or a date when older than a week.
String formatAge(Object? value, {DateTime? now}) {
  final d = value is DateTime ? value : parseDate(value);
  if (d == null) return '';
  final diff = (now ?? DateTime.now()).difference(d);
  if (diff.isNegative) return formatDate(d, withYear: false);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return formatDate(d, withYear: d.year != (now ?? DateTime.now()).year);
}

/// Indian grouping: 1234567.5 → `₹12,34,567.50`; whole numbers drop decimals.
String formatRupees(Object? value) {
  final n = value is num ? value.toDouble() : parseDouble(value);
  if (n == null) return value?.toString() ?? '';
  final negative = n < 0;
  final abs = n.abs();
  final whole = abs.truncate();
  final paise = ((abs - whole) * 100).round();
  final digits = whole.toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  final cents = paise > 0 ? '.${paise.toString().padLeft(2, '0')}' : '';
  return '${negative ? '-' : ''}₹$grouped$cents';
}

/// Indian digit grouping for counts: 43997 → `43,997`.
String formatCount(Object? value) {
  final n = value is num ? value.round() : parseInt(value);
  if (n == null) return value?.toString() ?? '0';
  return formatRupees(n).replaceFirst('₹', '');
}

/// Masks all but the last 4 digits of a phone number.
String maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return phone;
  return '•••• ••${digits.substring(digits.length - 4)}';
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}
