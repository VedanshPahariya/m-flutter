import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'api_exceptions.dart';

enum BodyEncoding { form, json }

/// Supplies and renews bearer tokens. Implemented by the auth controller so
/// the client does not depend on storage or UI.
abstract interface class TokenProvider {
  /// A non-expired access token, refreshing first when it is about to expire.
  Future<String?> validAccessToken();

  /// Called after a 401. Returns true when a new token is available.
  /// [rejectedToken] lets concurrent callers share one refresh.
  Future<bool> refreshAfterUnauthorized(String? rejectedToken);

  /// Called when the server rejected the session and it cannot be renewed.
  void onSessionExpired(String message);
}

/// A file part for multipart uploads.
class UploadFile {
  const UploadFile({required this.field, required this.path, this.filename});

  final String field;
  final String path;
  final String? filename;
}

/// Thin wrapper over `package:http` that knows the legacy CI3 contract:
///
/// * POST bodies are form encoded by default (see [AppConfig.bodyEncoding]).
/// * Authentication is `Authorization: Bearer <access_token>`.
/// * Successful HTTP responses can still carry an application error:
///   `{"status":"error"}`, `{"type":"error","text":...}` or
///   `{"success":false}`; those are raised as [ValidationException].
/// * Envelopes differ per endpoint, so the decoded JSON is returned as is and
///   unwrapped by the calling repository (see `api_response.dart`).
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    this.defaultEncoding = BodyEncoding.form,
    this.readTimeout = const Duration(seconds: 45),
    this.maxGetAttempts = 2,
    this.retryDelay = const Duration(milliseconds: 800),
    this.userAgent = 'KoraCRM-Android',
  }) : _baseUri = Uri.parse(baseUrl),
       _http = httpClient ?? _defaultClient();

  static http.Client _defaultClient() {
    final io = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..idleTimeout = const Duration(seconds: 20);
    return IOClient(io);
  }

  final Uri _baseUri;
  final http.Client _http;
  final BodyEncoding defaultEncoding;

  /// Upper bound for a whole request. The backend is slow, so this is
  /// generous; long operations pass their own value.
  final Duration readTimeout;
  final int maxGetAttempts;
  final Duration retryDelay;
  final String userAgent;

  TokenProvider? tokens;

  Uri get baseUri => _baseUri;

  Uri resolve(String path, [Map<String, Object?>? query]) {
    final uri = _baseUri.resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );
    final params = _stringify(query);
    if (params.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...params});
  }

  Future<dynamic> get(
    String path, {
    Map<String, Object?>? query,
    bool auth = true,
    Duration? timeout,
  }) {
    return _withRetry(
      () => _send(
        () => http.Request('GET', resolve(path, query)),
        auth: auth,
        timeout: timeout,
      ),
    );
  }

  /// POST is never retried automatically: a timeout does not prove the
  /// server did not act on it.
  Future<dynamic> post(
    String path, {
    Map<String, Object?>? body,
    Map<String, Object?>? query,
    bool auth = true,
    Duration? timeout,
    BodyEncoding? encoding,
  }) {
    final enc = encoding ?? defaultEncoding;
    return _send(
      () {
        final request = http.Request('POST', resolve(path, query));
        final fields = _stringify(body);
        if (enc == BodyEncoding.json) {
          request.headers['Content-Type'] = 'application/json; charset=utf-8';
          request.body = jsonEncode(body ?? const {});
        } else {
          request.bodyFields = fields;
        }
        return request;
      },
      auth: auth,
      timeout: timeout,
    );
  }

  Future<dynamic> multipart(
    String path, {
    Map<String, Object?>? fields,
    List<UploadFile> files = const [],
    bool auth = true,
    Duration timeout = const Duration(minutes: 3),
  }) {
    return _send(
      () =>
          http.MultipartRequest('POST', resolve(path))
            ..fields.addAll(_stringify(fields)),
      auth: auth,
      timeout: timeout,
      // Files are attached per attempt because streams are single use.
      prepare: (request) async {
        if (request is http.MultipartRequest) {
          for (final f in files) {
            request.files.add(
              await http.MultipartFile.fromPath(
                f.field,
                f.path,
                filename: f.filename,
              ),
            );
          }
        }
      },
    );
  }

  void close() => _http.close();

  Future<dynamic> _withRetry(Future<dynamic> Function() run) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await run();
      } on ApiException catch (e) {
        final transient = e is NetworkException || e is TimeoutApiException;
        if (!transient || attempt >= maxGetAttempts) rethrow;
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
  }

  Future<dynamic> _send(
    http.BaseRequest Function() build, {
    required bool auth,
    Duration? timeout,
    Future<void> Function(http.BaseRequest)? prepare,
    bool isRetryAfterRefresh = false,
  }) async {
    final request = build();
    request.headers['Accept'] = 'application/json';
    request.headers['User-Agent'] = userAgent;
    String? token;
    if (auth && tokens != null) {
      token = await tokens!.validAccessToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
    }
    if (prepare != null) await prepare(request);

    final started = DateTime.now();
    http.Response response;
    try {
      final streamed = await _http
          .send(request)
          .timeout(timeout ?? readTimeout);
      response = await http.Response.fromStream(streamed)
          .timeout(timeout ?? readTimeout);
    } on TimeoutException {
      _log(request, null, started);
      throw const TimeoutApiException();
    } on SocketException catch (e) {
      _log(request, null, started);
      throw NetworkException(e.message);
    } on HandshakeException catch (e) {
      _log(request, null, started);
      throw NetworkException('TLS handshake failed: ${e.message}');
    } on http.ClientException catch (e) {
      _log(request, null, started);
      throw NetworkException(e.message);
    }
    _log(request, response.statusCode, started);

    if (response.statusCode == 401 &&
        auth &&
        tokens != null &&
        !isRetryAfterRefresh) {
      final refreshed = await tokens!.refreshAfterUnauthorized(token);
      if (refreshed) {
        return _send(
          build,
          auth: auth,
          timeout: timeout,
          prepare: prepare,
          isRetryAfterRefresh: true,
        );
      }
      final message = _messageOf(_tryDecode(response.body));
      tokens!.onSessionExpired(message);
      throw UnauthorizedException(message);
    }
    if (response.statusCode == 401 && auth && tokens != null) {
      final message = _messageOf(_tryDecode(response.body));
      tokens!.onSessionExpired(message);
      throw UnauthorizedException(message);
    }
    return interpret(response.statusCode, response.body);
  }

  /// Converts a raw response into decoded JSON or a typed [ApiException].
  /// Public for unit tests.
  static dynamic interpret(int status, String body) {
    final decoded = _tryDecode(body);
    if (status >= 200 && status < 300) {
      if (decoded == _notJson) {
        throw UnexpectedResponseException(
          'Expected JSON, got ${body.length} bytes',
          statusCode: status,
        );
      }
      final appError = _applicationError(decoded);
      if (appError != null) throw appError;
      return decoded;
    }
    final json = decoded == _notJson ? null : decoded;
    throw errorForStatus(
      status,
      _messageOf(json),
      json is Map ? json['data'] : null,
    );
  }

  static ApiException errorForStatus(
    int status,
    String message, [
    Object? data,
  ]) {
    return switch (status) {
      401 => UnauthorizedException(message),
      403 => ForbiddenException(message),
      404 => NotFoundException(message),
      409 => ConflictException(message, data: data),
      400 ||
      422 => ValidationException(message, statusCode: status, data: data),
      >= 500 => ServerException(message, statusCode: status),
      _ => ValidationException(message, statusCode: status, data: data),
    };
  }

  static ApiException? _applicationError(Object? json) {
    if (json is! Map) return null;
    final status = json['status']?.toString().toLowerCase();
    final type = json['type']?.toString().toLowerCase();
    final success = json['success'];
    final isError =
        status == 'error' ||
        status == 'failed' ||
        type == 'error' ||
        success == false;
    if (!isError) return null;
    final code = int.tryParse('${json['code'] ?? ''}');
    final message = _messageOf(json);
    if (code != null && code >= 400) {
      return errorForStatus(code, message, json['data']);
    }
    return ValidationException(message, statusCode: 200, data: json['data']);
  }

  static String _messageOf(Object? json) {
    if (json is Map) {
      for (final key in const ['message', 'text', 'error', 'msg']) {
        final value = json[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
        }
      }
    }
    return '';
  }

  static const Object _notJson = Object();

  /// Decodes JSON, tolerating PHP notices printed before the payload.
  static Object? _tryDecode(String body) {
    final text = body.trim();
    if (text.isEmpty) return _notJson;
    try {
      return jsonDecode(text);
    } on FormatException {
      final start = text.indexOf(RegExp(r'[\{\[]'));
      if (start > 0) {
        try {
          return jsonDecode(text.substring(start));
        } on FormatException {
          return _notJson;
        }
      }
      return _notJson;
    }
  }

  static Map<String, String> _stringify(Map<String, Object?>? input) {
    if (input == null) return const {};
    final out = <String, String>{};
    input.forEach((key, value) {
      if (value == null) return;
      out[key] = switch (value) {
        bool b => b ? '1' : '0',
        _ => value.toString(),
      };
    });
    return out;
  }

  /// Logs method, path and status only. Headers, bodies and query strings
  /// may contain tokens, passwords or OTPs and are never logged.
  void _log(http.BaseRequest request, int? status, DateTime started) {
    if (!kDebugMode) return;
    final ms = DateTime.now().difference(started).inMilliseconds;
    debugPrint(
      '[api] ${request.method} ${request.url.path} -> ${status ?? 'ERR'} (${ms}ms)',
    );
  }
}
