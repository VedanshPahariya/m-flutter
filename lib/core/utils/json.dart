/// Null-safe readers for loosely typed legacy PHP JSON.
///
/// The backend returns numbers as strings ("48"), booleans as "0"/"1",
/// and uses different key casing per table (`Party_Name`, `cName`, `sname`).
/// These helpers accept several candidate keys and never throw.
library;

typedef JsonMap = Map<String, dynamic>;

JsonMap asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return const {};
}

List<JsonMap> asMapList(Object? value) {
  if (value is List) {
    return value.whereType<Map>().map(asMap).toList(growable: false);
  }
  return const [];
}

List<String> asStringList(Object? value) {
  if (value is List) {
    return value
        .where((e) => e != null)
        .map((e) => e.toString())
        .toList(growable: false);
  }
  return const [];
}

/// First non-empty string among [keys]; numbers are converted.
String str(JsonMap map, List<String> keys, [String fallback = '']) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return fallback;
}

String? strOrNull(JsonMap map, List<String> keys) {
  final value = str(map, keys);
  return value.isEmpty ? null : value;
}

int intOf(JsonMap map, List<String> keys, [int fallback = 0]) {
  for (final key in keys) {
    final parsed = parseInt(map[key]);
    if (parsed != null) return parsed;
  }
  return fallback;
}

double doubleOf(JsonMap map, List<String> keys, [double fallback = 0]) {
  for (final key in keys) {
    final parsed = parseDouble(map[key]);
    if (parsed != null) return parsed;
  }
  return fallback;
}

bool boolOf(JsonMap map, List<String> keys, [bool fallback = false]) {
  for (final key in keys) {
    final parsed = parseBool(map[key]);
    if (parsed != null) return parsed;
  }
  return fallback;
}

int? parseInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) {
    return int.tryParse(value.trim()) ?? double.tryParse(value.trim())?.round();
  }
  return null;
}

double? parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '').trim());
  return null;
}

bool? parseBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case '1' || 'true' || 'yes' || 'y' || 'active':
        return true;
      case '0' || 'false' || 'no' || 'n' || 'inactive' || '':
        return false;
    }
  }
  return null;
}

/// Parses `yyyy-MM-dd`, `yyyy-MM-dd HH:mm:ss` and `dd/MM/yyyy`.
DateTime? parseDate(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.startsWith('0000')) return null;
  final iso = DateTime.tryParse(text.replaceFirst(' ', 'T'));
  if (iso != null) return iso;
  final parts = text.split('/');
  if (parts.length == 3) {
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2].split(' ').first);
    if (d != null && m != null && y != null) return DateTime(y, m, d);
  }
  return null;
}
