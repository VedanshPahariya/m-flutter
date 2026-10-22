import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/session.dart';

/// Persists tokens in Android Keystore-backed storage.
///
/// Only tokens, the last identifier typed on the sign-in screen and the theme
/// preference are stored. Passwords, profile data and API responses are never
/// written to disk.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureKeyValueStore implements KeyValueStore {
  SecureKeyValueStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // A corrupted keystore entry must not block startup; treat as missing.
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}

/// In-memory store for tests.
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class SessionStore {
  SessionStore(this._kv);

  final KeyValueStore _kv;

  static const _keys = ['access_token', 'refresh_token', 'expires_at'];
  static const _kindKey = 'account_kind';
  static const _lastIdentifierKey = 'last_identifier';
  static const _themeKey = 'theme_mode';

  Future<(AuthTokens, AccountKind)?> readSession() async {
    final values = <String, String>{};
    for (final key in _keys) {
      final v = await _kv.read(key);
      if (v != null) values[key] = v;
    }
    final tokens = AuthTokens.fromStorage(values);
    final kindName = await _kv.read(_kindKey);
    final kind = AccountKind.values
        .where((k) => k.name == kindName)
        .firstOrNull;
    if (tokens == null || kind == null) return null;
    return (tokens, kind);
  }

  Future<void> saveTokens(AuthTokens tokens, AccountKind kind) async {
    for (final entry in tokens.toStorage().entries) {
      await _kv.write(entry.key, entry.value);
    }
    await _kv.write(_kindKey, kind.name);
  }

  Future<void> clearSession() async {
    for (final key in [..._keys, _kindKey]) {
      await _kv.delete(key);
    }
  }

  Future<String?> lastIdentifier() => _kv.read(_lastIdentifierKey);
  Future<void> saveLastIdentifier(String value) =>
      _kv.write(_lastIdentifierKey, value);

  Future<String?> themeMode() => _kv.read(_themeKey);
  Future<void> saveThemeMode(String value) => _kv.write(_themeKey, value);
}
