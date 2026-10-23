# Kora CRM: Flutter Android app

Native Android client for the existing CodeIgniter 3 application's mobile
API (`m/*` routes). It covers three experiences, chosen from the signed-in
account:

* **CRM** for staff, branch admins and super admins, built from the
  `Kora CRM Prototype` HTML: Today, Leads, Tickets (with customer-OTP
  closing), Customers, Renewals, Insights, Field visits, Approvals, Team,
  Payments, Notifications, Settings, and a read-only Platform area for
  super admins.
* **Customer portal**: AMC status, tickets (reopen), payments and
  renewals, QR code, referrals, notifications, profile.
* **Job-seeker portal**: job search and detail, apply, save, applications
  and interviews, profile, registration.

The backend is unchanged. Reference material: `urls.json` (captured API
calls) and the HTML prototype, both in this repository.

| Document | Contents |
|---|---|
| [docs/AUDIT.md](docs/AUDIT.md) | Roles and their evidence, auth flow, screen ↔ endpoint ↔ role map, uncertainties, backend observations |
| [docs/API_VERIFICATION.md](docs/API_VERIFICATION.md) | Verification status of every endpoint the app uses, inferred fields, endpoints not used and why |
| [docs/API_INVENTORY.md](docs/API_INVENTORY.md) | All 1,044 captured calls, grouped by role (generated from `urls.json`) |

## Requirements

| | Version |
|---|---|
| Flutter | 3.47.7 (stable), Dart 3.13.5 |
| Android minimum | **API 24 (Android 7.0)**, Flutter 3.47's own minimum; every plugin also supports 24 |
| Android target/compile | Flutter defaults (`flutter.targetSdkVersion`, `flutter.compileSdkVersion`) |
| JDK | 17+ |
| Android SDK | via Android Studio or `sdkmanager` |

## Setup

```bash
flutter pub get
```

## Configuration

Everything is set at build time through `--dart-define` or a JSON file passed
with `--dart-define-from-file`. Business code never contains a host name.

| Key | Default | Purpose |
|---|---|---|
| `APP_ENV` | `production` | `development`, `staging` or `production` |
| `API_BASE_URL` | prod: `https://crm-marg.com/`; dev: `http://10.0.2.2/`; staging: *(must be set)* | CI3 base URL; endpoint paths such as `m/auth/login` are appended |
| `APP_NAME` | `Kora CRM` | Visible app name in Flutter **and** the Android launcher |
| `API_BODY_ENCODING` | `form` | `form` (CI3 `$this->input->post()`) or `json` |
| `APP_VERSION` | `1.0.0` | Shown on the splash and settings screens |

Ready-made files live in `config/`:

```bash
flutter run --dart-define-from-file=config/development.json   # emulator → http://10.0.2.2/
flutter run --dart-define-from-file=config/staging.json       # edit API_BASE_URL first
flutter run --dart-define-from-file=config/production.json
```

* `10.0.2.2` is your computer as seen from the Android **emulator**. On a
  physical phone, use your computer's LAN IP, e.g.
  `--dart-define=API_BASE_URL=http://192.168.1.20/`. `localhost` on a
  phone means the phone itself.
* Production must be `https://`; the app refuses to start otherwise.
  Plain HTTP is only allowed in debug and profile builds
  (`android/app/src/debug|profile/AndroidManifest.xml`).

## Changing the app name

There is one source of truth: the `APP_NAME` value.

* **Permanently:** edit the default in `lib/app/app_config.dart`, on the line
  marked `// APP_NAME_DEFAULT`:

  ```dart
  defaultValue: 'Kora CRM', // APP_NAME_DEFAULT
  ```

* **Per build:** `flutter build apk --dart-define=APP_NAME="Marg Care"`
  (or add `"APP_NAME"` to a `config/*.json` file).

Both routes update the Flutter UI (splash, sign-in, settings, task switcher)
and the Android launcher label: `android/app/build.gradle.kts` reads
`APP_NAME` from the dart-defines, falls back to the `APP_NAME_DEFAULT` line,
and generates the `@string/app_name` resource used by `AndroidManifest.xml`.
The application ID (`com.crmmarg.kora_crm`) is separate and does not change
when you rename the app. To change the ID, edit `applicationId` in the
same Gradle file before the first Play Store release.

## Running and building

```bash
flutter run --dart-define-from-file=config/development.json

# Debug APK → build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --debug --dart-define-from-file=config/development.json

# Release APK → build/app/outputs/flutter-apk/app-release.apk
flutter build apk --release --dart-define-from-file=config/production.json

# Smaller per-ABI APKs for low-end phones
flutter build apk --release --split-per-abi --dart-define-from-file=config/production.json
```

### Release signing

Create `android/key.properties` (git-ignored) pointing at your keystore:

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Without it, release builds are signed with the debug key so they can be
installed for testing. Do not publish those.

## Tests

```bash
flutter test          # 84 tests: unit, API client, auth, widget
dart format --output=none --set-exit-if-changed lib test
dart analyze
```

Tests never touch a real server. `test/support/fake_backend.dart` serves the
captured response shapes (with fake personal data) from
`test/support/fixtures.dart`.

| Area | File |
|---|---|
| Envelopes, legacy `type:error` on HTTP 200, 401/403/404/409/422/5xx, timeouts, offline, retries, form encoding, token refresh | `test/core/api_client_test.dart` |
| Login per account type, role resolution, restore, refresh rotation, single-flight refresh, logout | `test/core/auth_controller_test.dart` |
| Role → permission map, token parsing, JSON and format helpers, config defaults | `test/core/roles_and_utils_test.dart` |
| Repository parsing against captured shapes | `test/features/repositories_test.dart` |
| Splash/restore, sign-in validation and errors, role-specific navigation, forced password change, session expiry | `test/widgets/app_flow_test.dart` |
| Skeleton timing, empty vs error, retry, stale-data banner, paging, permission-denied | `test/widgets/state_widgets_test.dart` |

## Architecture

```
lib/
├── main.dart                  wiring: storage → API client → auth → app
├── app/                       config (name, env, URL), theme tokens, AppScope, AuthGate
├── core/
│   ├── api/                   ApiClient, typed exceptions, envelope helpers, Endpoints catalogue
│   ├── auth/                  AuthController (TokenProvider), Session, roles & permissions
│   ├── storage/               Keystore-backed secure storage
│   ├── utils/                 JSON readers for loose PHP types, formatting, url launching
│   └── widgets/               AsyncView, PagedListView, skeletons, state views, shared UI
├── features/
│   ├── splash/  auth/
│   ├── crm/                   today, leads, tickets, customers, renewals, insights,
│   │                          notifications, more (team, approvals, field, payments, platform)
│   ├── customer/              customer portal
│   └── seeker/                job-seeker portal
└── shared/                    sign-out and theme widgets used by every portal
```

* **State:** Flutter's own `ChangeNotifier`, `ListenableBuilder` and an
  `InheritedWidget` (`AppScope`). No state-management package.
* **Data flow:** screen → small per-feature repository → `ApiClient`.
  Repositories turn the backend's envelopes into typed models; widgets
  never see raw JSON.
* **Auth:** bearer access token (1 h) refreshed 60 s before expiry and once
  after any 401 (concurrent 401s share one refresh). A rejected refresh
  ends the session and returns to sign-in with a notice. The role is
  re-read from the server on every start and never stored.
* **Errors:** offline, timeout, 401, 403, 404, 409, 422, 5xx, application
  error on HTTP 200 and unreadable response each map to their own
  exception and UI state. Server text is shown for 4xx (it is written for
  users); 5xx details are hidden.
* **Slow backend:** 15 s connect / 45 s overall timeout (longer for bulk
  actions); GET retried once on network failure; POST never retried
  automatically, and a timeout tells the user the change *may* have been
  saved.
* **Loading:** skeletons appear only if a load takes over 180 ms; refresh
  keeps current data; lists page 10–50 rows at a time; buttons lock while
  their request runs.

## Dependencies

| Package | Why |
|---|---|
| `http` | Small, maintained HTTP client; form, JSON and multipart bodies; `MockClient` for tests |
| `flutter_secure_storage` | Tokens in Android Keystore-encrypted storage |
| `url_launcher` | Dialer, WhatsApp (`wa.me`) and web-portal links |
| `qr_flutter` | Draws the customer QR on-device (the backend's image URL uses a retired Google API) |
| `flutter_lints` (dev) | Static analysis rules |

No charting, animation, routing or state-management packages: charts and
skeletons are plain widgets to keep the APK and memory use small.

## Security

* Tokens only in secure storage; passwords are never stored or logged. Debug
  logs show method, path, status and timing only.
* `android:allowBackup="false"`; cleartext HTTP blocked in release builds.
* Role-based UI is convenience only; every 403 from the server is handled.
* Logout revokes the refresh token server-side and wipes local session data.
* Destructive back-office actions (tenant delete, log clearing, bulk lead
  delete) are deliberately not exposed in the app.
* No certificate pinning: it would need a pin-rotation process for the
  server certificate and nothing in the requirements calls for it.

## Endpoints not verified / not available

* **No endpoint was called live.** The build environment's network policy
  blocks `crm-marg.com`. Everything is built from the captured
  request/response examples. No captured 404 is a missing route (all are
  "record not found"), so no feature was dropped for a 404.
* Request fields that had to be inferred, and screens whose list rows were
  never captured with data, are listed in
  [docs/API_VERIFICATION.md](docs/API_VERIFICATION.md#inferred-values-check-these-first-if-a-call-fails).
  Test those first against a server with real data.

## Known limitations

* **APK not built in this environment.** The Android SDK and Google's Maven
  repository are served from `dl.google.com`, which the sandbox blocks.
  `dart analyze`, formatting and all 84 tests pass; run the build commands
  above on a machine with the Android SDK.
* Not implemented for lack of a documented contract: password change
  (users are sent to the web portal when `force_change` is set),
  customer-created complaints, ticket reassignment, recording payments,
  profile and résumé editing, bulk lead actions, online payment (Razorpay),
  employer job posting (`m/customer_jobs`), multi-workspace account
  switching.
* `m/employee/*` is unavailable on the server (503), so Team uses
  `m/branch/listall`.
* No offline cache: CRM data is sensitive and the role must be re-checked,
  so the app shows clear offline states and keeps already-loaded data on
  screen instead of persisting responses.
