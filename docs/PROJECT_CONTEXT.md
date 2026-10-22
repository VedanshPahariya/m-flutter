# Project context: Kora CRM Flutter app

**Read this first.** It records everything decided and built while creating
this app, so work can continue with only this repository and no chat history.
Last updated: 22 Oct 2026, at commit `645ff2c` plus this document.

Related documents (all in this repo):

| File | What it holds |
|---|---|
| `README.md` | Setup, configuration, build and test commands, architecture summary |
| `docs/AUDIT.md` | Roles with evidence, auth contract, response envelopes, screen ↔ endpoint ↔ role map, uncertainties, backend issues |
| `docs/API_VERIFICATION.md` | Status of every endpoint the app uses; inferred fields; endpoints deliberately not used |
| `docs/API_INVENTORY.md` | All 1,044 captured API calls by role, generated from `urls.json` |
| `docs/PROJECT_CONTEXT.md` | This file: the full story, decisions, file map and next steps |

---

## 1. What this project is

* An existing **CodeIgniter 3 (CI3) web application** runs in production at
  `https://crm-marg.com/` (Apache 2.4, PHP 8.3). It is a CRM for a software
  reseller ("Soft Tech Solution", Marg ERP licences): enquiries (leads),
  complaints (tickets), customers ("parties"), AMC renewals, payments,
  WhatsApp/email automation, QR-sticker field visits, a job portal and an LMS.
  It is multi-tenant (`tenant_code`, e.g. `tenant_001`).
* The owner added **mobile JSON routes under `m/`** (for example
  `https://crm-marg.com/m/auth/login`).
* This repository is a **native Flutter Android client** for those routes. The
  backend must not be changed; compatibility with its legacy behaviour is
  mandatory.

### The original request (summary)

The owner asked for a production-ready, lightweight Flutter Android app:
audit both reference files first, then build every screen the references
support. Requirements included:

* role-aware navigation from evidence, without inventing roles;
* secure session handling, a configurable base URL per environment, and
  `localhost` never used as the production host;
* one place to change the visible app name, including the Android launcher label;
* skeletons, empty, error, offline and permission states everywhere;
* mutations never auto-retried, and slow-API friendly behaviour;
* the oldest Android version Flutter supports;
* unit, API and widget tests;
* documentation and an honest report of what was and wasn't verified.

Strict rules from the request:

* do not invent endpoints, fields or business rules;
* a localhost or network failure is "unverified", never "404";
* skip a feature only when its endpoint genuinely returns a 404;
* no mock data in production flows;
* do not claim success that wasn't verified.

---

## 2. The two reference files (kept in the repo root)

### `urls.json` (2.2 MB)

A captured run of the backend with test accounts. Top-level keys are roles:
`user` (customer, 48 calls), `superadmin` (57), `staff` (351),
`seeker` (45), `public` (94), `admin` (449). Each entry has this shape:

```json
{ "url": "m/auth/login", "method": "POST", "step": -1,
  "request": { "url": "...", "headers": {...}, "body": {...}, "query": {...} },
  "response": { "status": 200, "headers": {...}, "body": "<JSON string>", "is_json": true },
  "skipped": true, "reason": "..." }   // skipped/reason only on entries not called
```

Facts learned from it:

* Test accounts: staff `apitest-staff@example.invalid` (user 47),
  admin `apitest-admin@example.invalid` (48), superadmin (49),
  customer mobile `9000000011` (`DEMO001`), seeker
  `apitest-seeker@example.invalid` (4). Passwords are masked.
* Authenticated calls send `Authorization: Bearer <access_token>`. No
  request recorded a Content-Type.
* Status values: `null` means the run deliberately did not call the endpoint
  (destructive), with a `reason`.
* **Every 404 in the file is a JSON "record not found"** from a working
  controller (for example `"Job not found."` for test id `999999`). There is
  **no route-level 404**, so no feature was skipped for returning 404.
* Many controllers answer under two names: `m/complaint` = `m/complaintmaster`,
  `m/tasks` = `m/task`, `m/notifications` = `m/notify`,
  `m/platform` = `m/admin`, `m/jobportal/admin` = `m/jobadmin`,
  `m/jobportal/seeker` = `m/seeker`, `m/whatsapp_automation` = `m/waauto`,
  `m/customerauth` ≈ `m/auth` for customers. The app uses the shorter name.
* The admin call set is a superset of staff's plus about 100 admin-only calls
  (approvals, branch add/update, payments add/edit/delete, settings, and so on).

Useful one-liners for inspecting it:

```bash
python3 -c "import json;d=json.load(open('urls.json'));print({k:len(v) for k,v in d.items()})"
python3 - <<'EOF'
import json; d=json.load(open('urls.json'))
for e in d['staff']:
    if e['url']=='m/complaint/list': print(e['response']['body'][:2000])
EOF
```

### `Kora CRM Prototype (standalone) (2).html` (3.8 MB)

This is a *bundled* page, not plain HTML. A loader script unpacks
`<script type="__bundler/manifest">` (base64, often gzip) and
`<script type="__bundler/template">` (a JSON string). To read it:

```python
import re, json, base64, gzip
h = open('Kora CRM Prototype (standalone) (2).html', encoding='utf-8').read()
tag = lambda t: re.search(r'<script type="__bundler/'+t+r'">(.*?)</script>', h, re.S).group(1)
template = json.loads(tag('template'))   # ~240 KB: markup + the app's <script data-dc-script>
open('template.html','w').write(template)
```

The template is a React-like "dc" component. Its script holds sample data
(fake leads, tickets and customers in Pune) plus two important objects:

* `NAV`: the 24 screens: boot, signin, otp, forcepw, workspace, account,
  expired, settings, signout, today, notifications, leads, filter, leadDetail,
  logResponse, leadNew, leadsBulk, bulkReview, bulkRun, tickets,
  ticketDetail, ticketClose, customers, customerDetail, renewals, insights,
  drill, more, field, approvals, team.
* `NOTES`: for each screen, a purpose, the **endpoints** it uses, states,
  role access (Staff / Branch admin / Owner) and the Flutter widgets to use.
  This was the main screen ↔ endpoint mapping source (for example, `leads`
  → `GET m/enquiry/list`, `logResponse` → `POST m/enquiry/response (res,
  resdate, asgn, cmnt)`, `customers` → `POST m/customerdir/list (search, page)`).

The prototype header says it covers "the Staff, Branch admin and Owner apps.
The customer portal and job portal come next." There is no customer or seeker
UI reference.

Design tokens (CSS `--k-*`) were copied into `KoraColors` in
`lib/app/app_theme.dart`: light base `#FAF9F7`, accent `#155E63`, danger
`#B3362B`, warn `#C27A12`, ok `#2F7D4F`, violet `#6A4FB3`, plus a dark
palette. The prototype uses IBM Plex fonts and Material Symbols; the app
uses the system font and the built-in Material icons to stay light.

---

## 3. Key backend facts the app depends on

### Authentication

| Step | Call | Notes |
|---|---|---|
| Staff/customer login | `POST m/auth/login` `identifier, password, login_type=staff\|customer` | returns `data.{user_type, user_id, name, email, tenant_code, force_change, access_token, refresh_token, expires_in=3600}` |
| Seeker login | `POST m/auth/seeker_login` `email, password` | same token shape |
| Customer OTP | `POST m/auth/sendOTP` `identifier` → `POST m/auth/verifyOTP` `pending_token, otp` | only 401 responses were captured; success shape assumed |
| Who am I | `GET m/auth/me` | `user_type` is `staff` for staff, admin **and** superadmin |
| Role | `POST m/dashboard/index` | `data.staff.role` (1 = branch admin, 2 = staff), `data.staff.is_super_admin` |
| Refresh | `POST m/auth/refresh` `refresh_token` | rotates both tokens; 401 "Invalid refresh token." |
| Logout | `POST m/auth/logout` `refresh_token` | |

The access token lives 1 hour and the refresh token about 30 days. Login
also sets a `ci_session` cookie, which the mobile API doesn't need.

### Response envelopes (all must be handled)

* Standard: `{"status":"success","message":"OK","data":{...},"code":200}`
* Legacy: `{"type":"done","text":"OK","data":{...}}` and
  `{"type":"error","text":"..."}`. **The legacy error can arrive with
  HTTP 200** (for example `m/qradmin/batch_save`).
* Bare objects: `{"exists":false}`, `{"count":0,"notifications":[]}`,
  `{"success":true,"count":0}`, `{"source":""}`, `{"status":"found",...}`.
* Data next to the status: `{"status":"success","customer":{...}}`.
* Errors: 401, 403 ("Admin access required.", "Not authorized for this
  complaint."), 404 (record), 409 (`data.needs_company`), 422 (validation
  message names the missing fields), 502 (SMTP/WhatsApp down), 503
  ("Employee module is unavailable (empmaster table missing).").
* Data types are loose: numbers come as strings, booleans as "0"/"1", and
  columns use mixed case (`Party_Name`, `cName`, `sname`).
* Many endpoints self-document. A GET or empty POST returns `data.fields`
  listing the accepted fields (for example `m/enquiry/addNewFrm`), and 422
  messages name the required field.

---

## 4. Decisions made (and why)

| Decision | Reason |
|---|---|
| Roles are customer, seeker, staff, branchAdmin, superAdmin | From `user_type` plus `m/dashboard/index`; the prototype's "Owner" maps to super admin |
| The role is re-fetched from the server on every login and restore and never stored | The rules forbid trusting local role values |
| An unknown role value falls back to staff | Least privilege |
| POST bodies are form-encoded | CI3 reads `$this->input->post()`; the Content-Type was never captured. `--dart-define=API_BODY_ENCODING=json` switches it |
| Refresh 60 s before expiry and once after any 401; concurrent 401s share one refresh; a rejected refresh token is not retried | Slow backend; avoids refresh storms |
| GET retried once on network failure; POST never retried; a timeout says "may have been saved" | Mutations are not idempotent |
| Server messages shown for 4xx; 5xx details hidden | 4xx messages are user-facing; 5xx ones leak internals |
| No offline cache | CRM data is sensitive; the role must be re-checked |
| `force_change` → blocking screen that sends the user to the web portal | Password-change endpoint fields were never captured |
| Team uses `m/branch/listall` | `m/employee/*` returns 503; in this backend "branches" are user accounts (`BranchCode` = user id, `btype` 1 admin / 2 staff) |
| Insights uses `m/reports`, `m/renewal/get_chart_data`, `m/emsdashboard`, `m/cmsdashboard` | `m/bi/chart_data` only ever returned "Invalid type." |
| Bulk lead actions, account switcher and workspace picker not built | No documented endpoints for them |
| Charts and skeletons are plain widgets; no chart or state-management packages | APK size and low-end phones |
| The customer QR is drawn on-device with `qr_flutter` | The backend's `qr_image` uses the retired Google Charts API |
| Application ID `com.crmmarg.kora_crm`; display name "Kora CRM" | The name is configurable; the ID is separate |
| minSdk 24 (Android 7.0) | Flutter 3.47's minimum; all plugins support 24 |
| No Android cross-fade on auth changes | A protected screen must not rebuild after the session is cleared (a crash risk found in review) |
| Shells use `maybePop` for system back | So page `PopScope` handlers run (for example the ticket detail returns "changed") |

---

## 5. What was built

### Toolchain

* Flutter **3.47.7** stable, Dart **3.13.5**. In the build session it was
  installed at `/opt/flutter-sdk/flutter` (not part of the repo).
* Dependencies: `http ^1.6.0`, `flutter_secure_storage ^11.2.0`,
  `url_launcher ^6.3.3`, `qr_flutter ^4.1.0`; dev: `flutter_lints ^6.0.0`.
* Android: Kotlin DSL Gradle, AGP 9.1.0 (Flutter template),
  `compileSdk`/`targetSdk` from Flutter, `minSdk = flutter.minSdkVersion` (24).

### File map

```
lib/main.dart                         wires SecureKeyValueStore → ApiClient → AuthController → KoraApp
lib/app/
  app_config.dart                     APP_NAME (line marked APP_NAME_DEFAULT), APP_ENV, API_BASE_URL,
                                      API_BODY_ENCODING, APP_VERSION, validate()
  app.dart                            KoraApp (MaterialApp, theme) + AuthGate (splash / sign-in / role shell)
  app_scope.dart                      AppScope InheritedWidget (api, auth, theme), ThemeController,
                                      context.api / context.session
  app_theme.dart                      KoraColors tokens (light/dark) + ThemeData
lib/core/api/
  api_client.dart                     http wrapper: base URL, bearer auth, form/json/multipart,
                                      timeouts, GET retry, 401→refresh→retry, envelope error detection,
                                      PHP-notice-tolerant JSON decode, safe debug logging
  api_exceptions.dart                 Network, Timeout, Unauthorized, Forbidden, NotFound, Validation,
                                      Conflict, Server, UnexpectedResponse; describeError()
  api_response.dart                   dataMap / dataList / messageOf / PageInfo for the envelopes
  endpoints.dart                      every path + request fields tagged
                                      [verified]/[error-msg]/[prototype]/[inferred]
lib/core/auth/
  auth_controller.dart                restore, login, loginSeeker, requestOtp/verifyOtp, forgotPassword,
                                      registerSeeker, logout; implements TokenProvider
  session.dart                        AuthTokens, UserProfile, Session, AccountKind
  roles.dart                          AppRole, resolveStaffRole(), Permissions (UI-only gates)
lib/core/storage/secure_store.dart    KeyValueStore (secure + in-memory), SessionStore (tokens, kind,
                                      last identifier, theme)
lib/core/utils/                       json.dart (loose PHP readers), format.dart (₹ Indian grouping,
                                      dates), launch.dart (tel:, wa.me, browser)
lib/core/widgets/                     AsyncView (delayed skeleton, stale-data banner), PagedListView,
                                      skeletons, Message/Empty/Error views, common UI (runAction, BusyButton…)
lib/shared/account_actions.dart       confirmSignOut(), ThemeSelector
lib/features/splash/                  SplashScreen (slow-network copy after 3 s, offline retry), AppLogo
lib/features/auth/                    SignInScreen (Staff/Customer/Job seeker selector), OtpScreen,
                                      SeekerRegisterScreen, PasswordChangeRequiredScreen
lib/features/crm/                     CrmShell (Today · Leads · Tickets · Insights · More)
  today/ leads/ tickets/ customers/ renewals/ insights/ notifications/ dashboard/ more/
lib/features/customer/                CustomerShell (Home · Tickets · Payments · Account), QR, referrals
lib/features/seeker/                  SeekerShell (Jobs · Applications · Saved · Profile)
android/app/build.gradle.kts          APP_NAME from dart-defines → resValue app_name; release signing
                                      from android/key.properties
android/app/src/main/AndroidManifest.xml   label @string/app_name, INTERNET, allowBackup=false,
                                      no cleartext; queries for tel/https
android/app/src/{debug,profile}/AndroidManifest.xml   cleartext allowed for the dev server only
android/app/src/main/res/             launch screen (colors.xml, launch_background, v31 splash),
                                      adaptive icon + generated PNG icons
config/{development,staging,production}.json   --dart-define-from-file presets
test/                                 see section 7
```

### Screens by role

* **All:** Splash, Sign in, Forgot password (staff/seeker), session-expired
  notice, theme setting, sign out.
* **Staff:** Today (attention items, renewal target with pace marker, stats,
  tasks with mark-done and undo), Leads (status chips → `st`), Lead detail
  (call with `call_start`/`call_end`, WhatsApp, AI call, Log response sheet),
  New lead (debounced `check_mobile`), Tickets (status tabs with counts),
  Ticket detail (add response), Close with OTP (3 steps), Customers
  (search), Customer detail, Renewals (month switcher, records, dry-run
  reminder then send), Insights, Notifications, Field visits, Payments
  (read-only), Team directory (read-only), Approvals (permission message),
  Settings.
* **Branch admin:** everything above, plus all-branches toggles (`show_all`),
  delete lead, branch picker on new lead, approve/reject sign-ups, and
  activate/deactivate team members.
* **Super admin:** everything above, plus ticket auto-assign
  (`m/autoassign confirm=1`) and Platform: Tenants, QR batches, Error log
  (read-only).
* **Customer:** Home (AMC card, ticket counts, referral balance, recent
  payments), Tickets (reopen closed; call support), Payments and renewals,
  Account (profile, QR code, referral earnings, notifications).
* **Job seeker:** Jobs (keyword and category), Job detail (apply, save),
  Applications (withdraw) and Interviews, Saved jobs, Profile (read-only),
  Register.

---

## 6. Uncertainties to check against a real server

All inferred values live in `lib/core/api/endpoints.dart` or the named
repository; details are in `docs/API_VERIFICATION.md`.

1. **No populated rows were captured** for enquiries, the customer
   directory, renewal records, approvals, notifications, field
   visits, jobs, applications or interviews. Those models read several
   candidate keys (for example a lead reads `ecode|id`, `sname|name`,
   `sts|response|status`). Fix the key lists once real data is seen.
2. **Inferred request fields:**
   * `complaint/response` (`cid, response, comments`)
   * `complaint/close` (`cid, resolution`)
   * `complaint/otp_verify` (`otp`)
   * `approvals/approve|reject` (`customer_id`)
   * `notifications/mark_read` (`id`)
   * `tasks/update_status` (`status=completed|pending`)
3. **Inferred values:**
   * Lead statuses: New, Call Back, Demo Schedule, Demo Done, Converted,
     Not Required, Invalid, Switch Off.
   * `resdate` format: dd/mm/yyyy.
   * Enquiry types and sources: taken from the prototype.
4. `m/dashboard/index` was never captured for the super-admin account.
5. The success bodies of OTP login and of `enquiry/detail`, `complaint/detail`
   and `jobs/detail` were never captured. The app falls back to the list row
   when a detail call can't be read.
6. A real reminder send is assumed to be `send_renewal_messages` *without*
   `dry_run` (the dry run's message oddly says "Sent: 20" while each row is
   `would_send`).

---

## 7. Verification status

| Check | Result |
|---|---|
| `dart analyze` | No issues |
| `dart format --set-exit-if-changed lib test` | Clean |
| `flutter test` | **84 tests pass** (api client 21, auth 18, roles/utils 15, repositories 10, widget flows 9, state widgets 11) |
| Live API calls | **None.** The build sandbox's network policy refused `crm-marg.com:443` |
| Android APK build | **Not done.** The Android SDK and Google Maven (`dl.google.com`; `maven.google.com` redirects there) were blocked, so even `gradlew help` and `flutter build bundle` failed for lack of the SDK |
| App-name Gradle logic | Regex and dart-define decoding checked in Python against the real files; the Flutter plugin passes defines as the `dart-defines` property (confirmed in the Flutter source) |

The tests use `test/support/fake_backend.dart` (a `MockClient` router that
records requests) and `test/support/fixtures.dart` (captured response shapes
with fake personal data; real names and phones from `urls.json` were not
copied).

**First thing to do on a machine with the Android SDK:**

```bash
flutter pub get
flutter test
flutter build apk --debug --dart-define-from-file=config/development.json
flutter build apk --release --dart-define-from-file=config/production.json
```

Then sign in with each test account and walk the inferred endpoints from
section 6.

---

## 8. Backend issues noticed (reported, not changed)

1. `GET m/jobs/company/{id}` is public and returns the employer's
   `password_hash`, plus `reset_token` and `ip_address` fields.
2. Public DB-writing or destructive endpoints: `POST m/sys/util_nuke`
   ("POST confirm=1 to IRREVERSIBLY delete duplicate enquiries"),
   `m/utility/delete_duplicates`, `m/utility/remove_duplicate`,
   `m/amc/import*`, `m/UPDATEPARTYMASTER`, `m/dbtest/*`, `m/sys/db_*`.
3. `GET m/utility` publicly lists downloadable files, including executables
   and a "Microsoft Activation Scripts … {CracksHash}.zip".
4. `m/employee/*` → 503 (the `empmaster` table is missing).
5. WhatsApp sends → 502: the instance was stopped for non-payment.
6. `m/customer/qrcode.qr_image` points at the retired Google Charts QR API.

---

## 9. Not implemented, and what would unlock each

| Feature | Blocker | Unlock |
|---|---|---|
| Password change (incl. forced) | fields of `m/customer/forceChangePassword` etc. unknown | capture one successful call |
| Customer creates complaint | `m/customer/createComplaint` fields unknown | same |
| Staff creates complaint | `m/complaint/add` needs a customer-search flow | document fields |
| Reassign ticket | `m/complaint/assign` "Missing required fields" | document fields (assignee id or name?) |
| Record/edit/delete payment | `m/customerpayments/add` fields unknown | document fields |
| Profile, résumé, photo editing | seeker/customer/staff update fields unknown | document fields (`ApiClient.multipart` is ready) |
| Bulk lead actions (prototype screens leadsBulk, bulkReview, bulkRun) | no selection-based bulk endpoint; `enquiry/status` field unknown | backend support or docs |
| Account switcher / workspace picker | no multi-tenant login endpoint | backend support |
| Online payment | Razorpay SDK + `razorpay_configured: false` | configure Razorpay, add SDK |
| Employer job posting (`m/customer_jobs`) | 409 "Create a company profile first."; no UI reference | scope decision |
| Push notifications | no push endpoint or FCM config | backend + Firebase |

---

## 10. How to continue

* **Branch and PR:** the work is on `claude/intelligent-allen-n0mdgz`
  (GitHub `VedanshPahariya/m-flutter`); pull request #1 targets `main`.
  `main` held only the two reference files at the time. Merge the PR to
  see the code on `main`.
* **Coding conventions:**
  * Repositories in each feature folder turn envelopes into typed models
    with the `json.dart` helpers.
  * Screens use `AsyncView` or `PagedListView` for loading/empty/error states.
  * Mutations go through `runAction()` or local busy state, and are never
    retried.
  * Add every new path to `endpoints.dart` with its evidence tag.
  * Permission checks live in `Permissions`.
  * Keep `dart analyze` clean and `dart format` applied; add tests using
    `FakeBackend`.
* **Changing the app name:** edit `defaultValue` on the `APP_NAME_DEFAULT`
  line in `lib/app/app_config.dart`, or pass `--dart-define=APP_NAME=...`.
* **Changing the server:** use `config/*.json` or
  `--dart-define=API_BASE_URL=...` (it must end in `/`; production must be
  https).
* **Release signing:** create `android/key.properties` (git-ignored) with
  `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.

### Session history (for the record)

1. Audited both files (unpacked the HTML bundle; summarised `urls.json` by
   role and status; read the bodies the screens depend on).
2. Installed Flutter 3.47.7 and created the project
   (`flutter create --org com.crmmarg --project-name kora_crm --platforms android`).
3. Built core (config, API client, auth, storage, theme, shared widgets),
   then the CRM features, then the customer and seeker portals.
4. Configured Android (name wiring, manifests, launch screen, icons,
   signing).
5. Wrote 84 tests; fixed issues found by tests and review (a rebuild loop
   in ticket detail, a double refresh, the auth cross-fade crash risk,
   back-button results).
6. Wrote README, AUDIT, API_VERIFICATION and API_INVENTORY.
7. Committed `645ff2c`. The first push failed with 403 until the owner
   installed the Claude GitHub App; then it was pushed.
