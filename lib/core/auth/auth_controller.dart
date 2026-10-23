import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../storage/secure_store.dart';
import '../utils/json.dart';
import 'roles.dart';
import 'session.dart';

enum AuthStatus {
  /// Reading storage and validating the stored session with the server.
  restoring,

  /// A stored session exists but the server could not be reached.
  restoreFailed,
  unauthenticated,
  authenticated,
}

/// Result of `m/auth/sendOTP`.
class OtpChallenge {
  const OtpChallenge({required this.pendingToken, required this.message});

  final String pendingToken;
  final String message;
}

/// Owns the session lifecycle and implements [TokenProvider] for the API
/// client.
///
/// Backend contract (from urls.json):
/// * access tokens live 3600 s (`expires_in`), refresh tokens about 30 days;
/// * `m/auth/refresh` rotates both tokens and answers 401 when the refresh
///   token is invalid;
/// * `m/auth/logout` revokes the refresh token passed in the body.
class AuthController extends ChangeNotifier implements TokenProvider {
  AuthController({required this._api, required this._store}) {
    _api.tokens = this;
  }

  final ApiClient _api;
  final SessionStore _store;

  AuthStatus _status = AuthStatus.restoring;
  AuthStatus get status => _status;

  Session? _session;
  Session? get session => _session;

  /// Shown on the sign-in screen, for example after the session expired.
  String? _notice;
  String? get notice => _notice;

  ApiException? _restoreError;
  ApiException? get restoreError => _restoreError;

  AuthTokens? _tokens;
  AccountKind? _kind;
  Future<bool>? _refreshing;
  bool _loggingOut = false;

  /// Set when the server rejected the refresh token; it will not be retried.
  bool _refreshRejected = false;

  ApiClient get api => _api;

  // ------------------------------------------------------------ startup

  Future<void> restore() async {
    _setStatus(AuthStatus.restoring);
    final stored = await _store.readSession();
    if (stored == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }
    _tokens = stored.$1;
    _kind = stored.$2;
    _refreshRejected = false;
    try {
      await _loadSession();
    } on UnauthorizedException {
      await _clearLocal(
        notice: 'Your session has expired. Please sign in again.',
      );
    } on ApiException catch (e) {
      // Keep the tokens: the user may simply be offline.
      _restoreError = e;
      _setStatus(AuthStatus.restoreFailed);
    }
  }

  // ------------------------------------------------------------ sign-in

  /// `POST m/auth/login` for staff (`login_type=staff`) and customers
  /// (`login_type=customer`).
  Future<void> login({
    required String identifier,
    required String password,
    required AccountKind kind,
  }) async {
    assert(kind != AccountKind.seeker);
    final json = await _api.post(
      Endpoints.login,
      auth: false,
      body: {
        'identifier': identifier.trim(),
        'password': password,
        'login_type': kind == AccountKind.customer ? 'customer' : 'staff',
      },
    );
    await _store.saveLastIdentifier(identifier.trim());
    await _establish(dataMap(json));
  }

  /// `POST m/auth/seeker_login`.
  Future<void> loginSeeker({
    required String email,
    required String password,
  }) async {
    final json = await _api.post(
      Endpoints.seekerLogin,
      auth: false,
      body: {'email': email.trim(), 'password': password},
    );
    await _store.saveLastIdentifier(email.trim());
    await _establish(dataMap(json));
  }

  /// `POST m/auth/sendOTP`. Customer accounts only.
  Future<OtpChallenge> requestOtp(String identifier) async {
    final json = await _api.post(
      Endpoints.sendOtp,
      auth: false,
      body: {'identifier': identifier.trim()},
    );
    final data = dataMap(json);
    final token = str(data, const ['pending_token', 'token']);
    if (token.isEmpty) {
      throw const UnexpectedResponseException(
        'sendOTP returned no pending_token',
      );
    }
    return OtpChallenge(
      pendingToken: token,
      message: messageOf(json).isEmpty ? 'Code sent.' : messageOf(json),
    );
  }

  /// `POST m/auth/verifyOTP`.
  Future<void> verifyOtp({
    required String pendingToken,
    required String otp,
  }) async {
    final json = await _api.post(
      Endpoints.verifyOtp,
      auth: false,
      body: {'pending_token': pendingToken, 'otp': otp.trim()},
    );
    await _establish(dataMap(json));
  }

  Future<String> forgotPassword({
    required String email,
    required AccountKind kind,
  }) async {
    final json = await _api.post(
      kind == AccountKind.seeker
          ? Endpoints.seekerForgot
          : Endpoints.staffForgot,
      auth: false,
      body: {'email': email.trim()},
    );
    final message = messageOf(json);
    return message.isEmpty ? 'Check your email for the reset link.' : message;
  }

  /// `POST m/auth/seeker_register`. Returns the server message.
  Future<String> registerSeeker({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final json = await _api.post(
      Endpoints.seekerRegister,
      auth: false,
      body: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'confirm_password': password,
      },
    );
    final message = messageOf(json);
    return message.isEmpty ? 'Account created. You can sign in now.' : message;
  }

  Future<String?> lastIdentifier() => _store.lastIdentifier();

  // ------------------------------------------------------------ sign-out

  /// Revokes the refresh token on the server (best effort) and wipes local
  /// session data. Never blocks the user on a slow or offline server.
  Future<void> logout() async {
    _loggingOut = true;
    final refresh = _tokens?.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _api.post(
          Endpoints.logout,
          body: {'refresh_token': refresh},
          timeout: const Duration(seconds: 8),
        );
      } catch (_) {
        // The refresh token is discarded locally either way.
      }
    }
    await _clearLocal();
    _loggingOut = false;
  }

  /// Leaves a failed restore by discarding the stored session.
  Future<void> abandonStoredSession() => _clearLocal();

  void clearNotice() {
    if (_notice == null) return;
    _notice = null;
    notifyListeners();
  }

  // ------------------------------------------------------ TokenProvider

  @override
  Future<String?> validAccessToken() async {
    final tokens = _tokens;
    if (tokens == null) return null;
    if (tokens.expiresWithin(const Duration(seconds: 60))) {
      try {
        await _refreshOnce();
      } on ApiException {
        // Fall through with the old token; the server will decide.
      }
    }
    return _tokens?.accessToken;
  }

  @override
  Future<bool> refreshAfterUnauthorized(String? rejectedToken) async {
    final current = _tokens?.accessToken;
    if (current != null && rejectedToken != null && current != rejectedToken) {
      return true; // Another request already refreshed.
    }
    return _refreshOnce();
  }

  @override
  void onSessionExpired(String message) {
    if (_status == AuthStatus.unauthenticated || _loggingOut) return;
    unawaited(
      _clearLocal(notice: 'Your session has expired. Please sign in again.'),
    );
  }

  // ------------------------------------------------------------ internals

  Future<bool> _refreshOnce() {
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _refresh() async {
    final refresh = _tokens?.refreshToken;
    final kind = _kind;
    if (refresh == null ||
        refresh.isEmpty ||
        kind == null ||
        _refreshRejected) {
      return false;
    }
    try {
      final json = await _api.post(
        Endpoints.refresh,
        auth: false,
        body: {'refresh_token': refresh},
        timeout: const Duration(seconds: 30),
      );
      final tokens = AuthTokens.fromData(dataMap(json));
      _tokens = tokens;
      await _store.saveTokens(tokens, kind);
      return true;
    } on UnauthorizedException {
      _refreshRejected = true;
      return false;
    } on ValidationException {
      _refreshRejected = true;
      return false;
    } on FormatException {
      return false;
    }
  }

  Future<void> _establish(JsonMap loginData) async {
    final AuthTokens tokens;
    try {
      tokens = AuthTokens.fromData(loginData);
    } on FormatException {
      throw const UnexpectedResponseException('Login response has no tokens');
    }
    final kind = accountKindOf(str(loginData, const ['user_type']));
    if (kind == null) {
      throw const UnexpectedResponseException(
        'Unknown user_type in login response',
      );
    }
    _tokens = tokens;
    _kind = kind;
    _refreshRejected = false;
    await _store.saveTokens(tokens, kind);
    try {
      await _loadSession(
        forceChange: boolOf(loginData, const ['force_change']),
      );
    } catch (_) {
      // Do not keep half-established sessions around.
      await _clearLocal();
      rethrow;
    }
  }

  /// Confirms the user with `m/auth/me` and resolves the role from the
  /// server. Never trusts a locally stored role.
  Future<void> _loadSession({bool forceChange = false}) async {
    final me = UserProfile.fromJson(dataMap(await _api.get(Endpoints.me)));
    final kind = accountKindOf(me.userType) ?? _kind;
    final AppRole role;
    switch (kind) {
      case AccountKind.customer:
        role = AppRole.customer;
      case AccountKind.seeker:
        role = AppRole.seeker;
      case AccountKind.staff:
        role = await _resolveStaffRole();
      case null:
        throw const UnexpectedResponseException('Unknown user_type');
    }
    _session = Session(
      user: me.copyWith(forceChange: forceChange),
      role: role,
    );
    _notice = null;
    _restoreError = null;
    _setStatus(AuthStatus.authenticated);
  }

  Future<AppRole> _resolveStaffRole() async {
    try {
      final data = dataMap(await _api.post(Endpoints.staffDashboard));
      final staff = asMap(data['staff']);
      return resolveStaffRole(
        role: staff['role'],
        isSuperAdmin: staff['is_super_admin'],
      );
    } on ForbiddenException {
      return AppRole.staff;
    } on NotFoundException {
      return AppRole.staff;
    }
  }

  Future<void> _clearLocal({String? notice}) async {
    _tokens = null;
    _kind = null;
    _session = null;
    _restoreError = null;
    _notice = notice;
    await _store.clearSession();
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
