import '../utils/json.dart';

/// Helpers for the several envelopes the backend uses:
///
/// * `{"status":"success","message":...,"data":{...},"code":200}` (most)
/// * `{"type":"done","text":"OK","data":{...}}` (legacy controllers)
/// * bare objects such as `{"exists":false}` or `{"count":0,...}`
/// * `{"status":"success","customer":{...}}` (data next to the status)
///
/// [ApiClient] has already raised errors, so these only reshape success.

/// The `data` object when present, otherwise the top-level object.
JsonMap dataMap(Object? json) {
  final root = asMap(json);
  final data = root['data'];
  if (data is Map) return asMap(data);
  return root;
}

/// A list either at `data.<key>`, at `data` itself, or at the top-level key.
List<JsonMap> dataList(Object? json, [String? key]) {
  final root = asMap(json);
  final data = root['data'];
  if (key != null) {
    if (data is Map && data[key] is List) return asMapList(data[key]);
    if (root[key] is List) return asMapList(root[key]);
  }
  if (data is List) return asMapList(data);
  if (json is List) return asMapList(json);
  return const [];
}

/// The human message of a success response, if any.
String messageOf(Object? json) {
  final root = asMap(json);
  return str(root, const ['message', 'text']);
}

/// Pagination metadata shared by list endpoints (`total`, `limit`, `offset`
/// or `page`, `per_page`, `total_pages`).
class PageInfo {
  const PageInfo({
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory PageInfo.from(
    JsonMap data, {
    int fallbackLimit = 20,
    int loaded = 0,
  }) {
    final limit = intOf(data, const ['limit', 'per_page'], fallbackLimit);
    final page = intOf(data, const ['page'], 0);
    final offset = data.containsKey('offset')
        ? intOf(data, const ['offset'])
        : (page > 0 ? (page - 1) * limit : 0);
    return PageInfo(
      total: intOf(data, const ['total', 'total_count', 'total_jobs'], loaded),
      limit: limit,
      offset: offset,
    );
  }

  final int total;
  final int limit;
  final int offset;
}
