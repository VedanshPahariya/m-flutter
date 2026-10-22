import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/auth/auth_controller.dart';
import '../core/auth/session.dart';
import '../core/storage/secure_store.dart';

/// Theme preference, persisted (it is not sensitive).
class ThemeController extends ChangeNotifier {
  ThemeController(this._store);

  final SessionStore _store;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final saved = await _store.themeMode();
    _mode =
        ThemeMode.values.where((m) => m.name == saved).firstOrNull ??
        ThemeMode.system;
    notifyListeners();
  }

  Future<void> set(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _store.saveThemeMode(mode.name);
  }
}

/// Makes app-wide services available to the widget tree without a
/// dependency-injection package.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.api,
    required this.auth,
    required this.theme,
    required super.child,
  });

  final ApiClient api;
  final AuthController auth;
  final ThemeController theme;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      api != oldWidget.api ||
      auth != oldWidget.auth ||
      theme != oldWidget.theme;
}

extension AppScopeX on BuildContext {
  AppScope get scope => AppScope.of(this);
  ApiClient get api => AppScope.of(this).api;

  /// The current session. Only valid below the authenticated shell.
  Session get session => AppScope.of(this).auth.session!;
}
