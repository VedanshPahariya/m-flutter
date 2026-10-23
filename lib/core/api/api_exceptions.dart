/// Structured failures produced by [ApiClient].
///
/// Screens never show raw exception text; they call [ApiException.userMessage]
/// which only exposes server messages for client-side problems (4xx and
/// application-level errors), never for 5xx or transport failures.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  /// Message suitable for logs. May contain server text.
  final String message;
  final int? statusCode;

  /// Whether retrying the same request can reasonably succeed.
  bool get isRetryable => false;

  String get userMessage;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// The device could not reach the server (DNS, refused, no route, TLS).
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Network unavailable']);

  @override
  bool get isRetryable => true;

  @override
  String get userMessage =>
      'You appear to be offline. Check your connection and try again.';
}

/// The server did not answer in time. For mutations the server may still have
/// completed the work, so callers must not blindly resubmit.
class TimeoutApiException extends ApiException {
  const TimeoutApiException([super.message = 'Request timed out']);

  @override
  bool get isRetryable => true;

  @override
  String get userMessage =>
      'The server is taking too long to respond. Please try again.';
}

/// 401 that survived a token refresh, or a refresh that was rejected.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Unauthorized'])
    : super(statusCode: 401);

  @override
  String get userMessage => message.isNotEmpty
      ? message
      : 'Your session has expired. Please sign in again.';
}

/// 403: the signed-in role may not perform this action.
class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Access denied'])
    : super(statusCode: 403);

  @override
  String get userMessage =>
      message.isNotEmpty ? message : 'You do not have permission to do this.';
}

/// 404: the record (not the route) was not found.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found'])
    : super(statusCode: 404);

  @override
  String get userMessage =>
      message.isNotEmpty ? message : 'This record could not be found.';
}

/// 422 or an application-level error returned with HTTP 200
/// (`{"status":"error"}` or the legacy `{"type":"error","text":...}`).
class ValidationException extends ApiException {
  const ValidationException(super.message, {super.statusCode, this.data});

  final Object? data;

  @override
  String get userMessage =>
      message.isNotEmpty ? message : 'Please check the details and try again.';
}

/// 409: the request conflicts with the current state, for example a
/// customer that must create a company profile first.
class ConflictException extends ApiException {
  const ConflictException(super.message, {this.data}) : super(statusCode: 409);

  final Object? data;

  @override
  String get userMessage =>
      message.isNotEmpty ? message : 'This action is not possible right now.';
}

/// 5xx. The server message is kept for logs only.
class ServerException extends ApiException {
  const ServerException(super.message, {required int super.statusCode});

  @override
  bool get isRetryable => statusCode != 501;

  @override
  String get userMessage => switch (statusCode) {
    502 => 'An external service used by the server failed. Try again later.',
    503 => 'This feature is temporarily unavailable on the server.',
    _ => 'The server ran into a problem ($statusCode). Please try again.',
  };
}

/// The response was not the JSON shape the app expects.
class UnexpectedResponseException extends ApiException {
  const UnexpectedResponseException(super.message, {super.statusCode});

  @override
  String get userMessage =>
      'The server sent a response the app could not read.';
}

/// Wraps anything else so callers can rely on [ApiException].
class UnknownApiException extends ApiException {
  const UnknownApiException(super.message);

  @override
  String get userMessage => 'Something went wrong. Please try again.';
}

/// Returns a user-facing message for any error thrown by data code.
String describeError(Object error) {
  if (error is ApiException) return error.userMessage;
  return 'Something went wrong. Please try again.';
}
