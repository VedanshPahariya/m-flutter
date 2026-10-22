/// Central build-time configuration.
///
/// Every value can be overridden at build time with `--dart-define` or
/// `--dart-define-from-file=config/<env>.json` (see README). Nothing here is
/// read from the network or from local storage, so it cannot be tampered with
/// at runtime.
enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig._();

  /// Visible application name used across the Flutter UI.
  ///
  /// The Android launcher label is generated from the same value: the Gradle
  /// build reads `APP_NAME` from the dart-defines and, when it is not passed,
  /// parses the default on the line marked `APP_NAME_DEFAULT` below. Change
  /// the name here (or pass `--dart-define=APP_NAME=...`) and both update.
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Kora CRM', // APP_NAME_DEFAULT
  );

  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static AppEnvironment get environment => switch (_envName) {
    'development' || 'dev' => AppEnvironment.development,
    'staging' || 'test' || 'testing' => AppEnvironment.staging,
    _ => AppEnvironment.production,
  };

  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Base URL of the CodeIgniter application, ending with `/`.
  ///
  /// Endpoint paths (for example `m/auth/login`) are appended to it. The
  /// mobile routes live under `m/` on the same host as the web app.
  static String get apiBaseUrl {
    final value = _baseUrlOverride.isNotEmpty
        ? _baseUrlOverride
        : switch (environment) {
            // 10.0.2.2 is the host machine as seen from the Android emulator.
            // `localhost` would point at the device itself.
            AppEnvironment.development => 'http://10.0.2.2/',
            // Staging has no known host; it must be supplied explicitly.
            AppEnvironment.staging => '',
            AppEnvironment.production => 'https://crm-marg.com/',
          };
    if (value.isEmpty) return value;
    return value.endsWith('/') ? value : '$value/';
  }

  /// Request body encoding for POST calls: `form` (default) or `json`.
  ///
  /// The captured API inventory does not record the request Content-Type.
  /// CodeIgniter 3 reads `$this->input->post()` from form-encoded bodies, so
  /// form encoding is the safe default. Switch to `json` only if the backend
  /// is confirmed to parse JSON bodies.
  static const String bodyEncoding = String.fromEnvironment(
    'API_BODY_ENCODING',
    defaultValue: 'form',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// Returns a human readable problem with the configuration, or null.
  static String? validate() {
    final base = apiBaseUrl;
    if (base.isEmpty) {
      return 'API_BASE_URL is not set for the $_envName environment.';
    }
    final uri = Uri.tryParse(base);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'API_BASE_URL "$base" is not a valid URL.';
    }
    if (environment == AppEnvironment.production && uri.scheme != 'https') {
      return 'Production builds must use an https API_BASE_URL.';
    }
    return null;
  }
}
