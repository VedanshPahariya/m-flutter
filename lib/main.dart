import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'app/app_scope.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth_controller.dart';
import 'core/storage/secure_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SessionStore(SecureKeyValueStore());
  final api = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    defaultEncoding: AppConfig.bodyEncoding == 'json'
        ? BodyEncoding.json
        : BodyEncoding.form,
    userAgent: 'KoraCRM-Android/${AppConfig.appVersion}',
  );
  final auth = AuthController(api: api, store: store);
  final theme = ThemeController(store);
  runApp(KoraApp(api: api, auth: auth, theme: theme));
}
