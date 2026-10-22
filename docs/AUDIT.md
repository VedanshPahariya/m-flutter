# Audit: reference files, roles and screen mapping

Done before implementation. Sources:

* `urls.json`: 1,044 captured calls (678 unique method + path pairs) for six
  roles: `public`, `user` (customer), `seeker`, `staff`, `admin`, `superadmin`.
* `Kora CRM Prototype (standalone) (2).html`: a bundled React prototype
  ("Kora mobile CRM"). Unpacked, it contains 24 screens and a per-screen
  spec (`NOTES`) naming each screen's endpoints, states and role access. Its
  own header says it covers "the Staff, Branch admin and Owner apps. The
  customer portal and job portal come next." It uses illustrative sample
  data only (no API calls).

## 1. Roles

| Role in app | Evidence | How the app decides |
|---|---|---|
| Customer | login `user_type: customer` (`login_type=customer`) | `user_type` from login and `m/auth/me` |
| Job seeker | `m/auth/seeker_login` → `user_type: seeker` | `user_type` |
| Staff | `user_type: staff`; `m/dashboard/index` → `staff.role: 2`, profile `btype: "2"`; admin endpoints answer 403 "Admin access required." | `POST m/dashboard/index` |
| Branch admin | same, `staff.role: 1`, `btype: "1"` | `POST m/dashboard/index` |
| Super admin | inventory account can call `m/admin/*` (tenants, error log), `m/autoassign`, `m/qradmin/*`; `m/dashboard/index` exposes `is_super_admin` | `staff.is_super_admin === true` |

`m/auth/me` and the JWT carry only `user_type` (`staff` for all three CRM
roles), so the CRM role comes from `m/dashboard/index`. It is fetched from
the server at every sign-in and restore and never stored on the device.
Unknown values fall back to Staff (least privilege).

The prototype's "Owner" role (all branches, auto-assign) corresponds to the
backend's super admin.

## 2. Authentication contract

```
Sign in ─ POST m/auth/login {identifier, password, login_type}
        └ POST m/auth/seeker_login {email, password}
        └ POST m/auth/sendOTP {identifier} → POST m/auth/verifyOTP {pending_token, otp}
          ↓ data: user_type, user_id, name, tenant_code, force_change,
            access_token (JWT, 3600 s), refresh_token (≈30 days)
Confirm ─ GET m/auth/me             (Authorization: Bearer <access_token>)
Role    ─ POST m/dashboard/index    (staff only)
Renew   ─ POST m/auth/refresh {refresh_token}  → new pair; 401 = session over
Leave   ─ POST m/auth/logout {refresh_token}
```

* Missing token: 401 "Authorization token missing. Send "Authorization: Bearer <token>"."
* The server also sets a `ci_session` cookie on login; the mobile API does
  not need it (all captured calls authenticate with the bearer token), so
  the app does not keep cookies.
* `force_change: true` on login means the password must be changed first.

## 3. Response envelopes found

| Shape | Example endpoints |
|---|---|
| `{"status":"success","message","data":{…},"code":200}` | most `m/*` |
| `{"type":"done","text","data"}` / `{"type":"error","text"}` (legacy) | `m/task/get_task/1`, `m/qradmin/batch_save` (**HTTP 200 with an error**), `m/complaint/*` |
| bare objects | `m/enquiry/check_mobile` → `{"exists":false}`, `m/notifications/get_unread` → `{"count":0,…}`, `m/complaint/source` → `{"source":""}`, `m/complaint/customer_lookup` → `{"status":"found",…}` |
| status without `data` | `m/customerpayments/getCustomerById` → `{"status":"success","customer":{…}}` |
| list directly in `data` | `m/qrfield/batches`, `m/jobs/locations` |
| errors | 401, 403, 404 (record not found), 409 (`data.needs_company`), 422 (validation), 502 (SMTP/WhatsApp failure), 503 (module unavailable) |

## 4. Screen ↔ endpoint ↔ role map

Prototype screens (all implemented natively unless noted):

| Prototype screen | Flutter screen | Endpoints | Staff | Branch admin | Super admin |
|---|---|---|---|---|---|
| Launch | `SplashScreen` | refresh, me, dashboard/index | ✓ | ✓ | ✓ |
| Sign in | `SignInScreen` | auth/login, staff_forgot, seeker_login | ✓ | ✓ | ✓ |
| OTP verification | `OtpScreen` | sendOTP, verifyOTP (customers only per backend messages) | — | — | — |
| Force password change | `PasswordChangeRequiredScreen` | (fields unknown → web portal) | ✓ | ✓ | ✓ |
| Choose workspace / Account switcher | not built | no multi-tenant login endpoint exists in the inventory | | | |
| Session expired | sign-in with notice | refresh → 401 | ✓ | ✓ | ✓ |
| Profile & settings, Sign out | `SettingsScreen` | profile, logout | ✓ | ✓ | ✓ |
| Today | `TodayScreen` | emsdashboard, cmsdashboard, renewal, tasks/listall, tasks/update_status, notifications/get_unread, approvals/pending (admin) | own | + approvals alert | + approvals alert |
| Notifications | `NotificationsScreen` | notifications/listing, mark_read, mark_all_read | ✓ | ✓ | ✓ |
| Lead list, Filter | `LeadListScreen` | enquiry/list (st, show_all) | own | + all branches | + all branches |
| Lead detail, Log response | `LeadDetailScreen`, `LogResponseSheet` | enquiry/detail, call_start/end, ai_call, response, del | respond/call | + delete | + delete |
| New lead | `LeadNewScreen` | check_mobile, addNewFrm, add | ✓ | + branch picker | + branch picker |
| Bulk select / review / run | not built | no documented selection-based bulk endpoints | | | |
| Tickets | `TicketListScreen` | complaint/list, cmsdashboard, autoassign | assigned | + show all | + auto-assign |
| Ticket detail | `TicketDetailScreen` | complaint/detail, complaint/response | ✓ (reassign locked) | ✓ | ✓ |
| Close with OTP | `TicketCloseScreen` | otp_generate, otp_verify, close | ✓ | ✓ | ✓ |
| Customers / detail | `CustomerListScreen`, `CustomerDetailScreen` | customerdir/list, customer_lookup, check_wallet, getCustomerById | ✓ | ✓ | ✓ |
| Renewals | `RenewalsScreen` | renewal, records_list, send_renewal_messages (dry run → send) | ✓ | ✓ | ✓ |
| Insights / drill-down | `InsightsScreen` | reports, renewal/get_chart_data, emsdashboard, cmsdashboard | server-scoped | server-scoped | server-scoped |
| More | `MoreScreen` | — | records + directory | + Approvals, Team | + Platform |
| Field visits | `FieldVisitsScreen` | qrfield/tasks, customers, customer_done, assignment_done | ✓ | ✓ | ✓ |
| Approvals | `ApprovalsScreen` | approvals/pending, approve, reject | permission message | ✓ | ✓ |
| Team | `TeamScreen` | branch/listall, branch/changeStatus | read-only directory | + activate/deactivate | + activate/deactivate |

Added from the API (no prototype screen): Payments (`m/customerpayments`,
CRM), Tenants / QR batches / Error log (super admin, read-only), the
customer portal (Home, Tickets, Payments, Account, QR, Referrals,
Notifications) and the job-seeker portal (Jobs, Job detail, Applications,
Interviews, Saved, Profile, Register).

## 5. Navigation

* `AuthGate` swaps whole subtrees: Splash → Sign-in flow → role shell. Sign
  out or expiry drops every protected screen at once.
* CRM shell: bottom bar Today · Leads · Tickets · Insights · More, one
  navigator per tab, tabs built on first visit. Android back pops the tab
  stack, then returns to Today, then exits.
* Customer shell: Home · Tickets · Payments · Account. Seeker shell: Jobs ·
  Applications · Saved · Profile. Same back behaviour.

## 6. Uncertainties and gaps

Isolated in `lib/core/api/endpoints.dart`; details in
[API_VERIFICATION.md](API_VERIFICATION.md).

1. No populated enquiry, customer-directory, renewal-record, approval,
   notification, field-visit, job, application or interview rows were
   captured (test accounts had no data). Those models read several
   candidate keys and never crash on missing fields.
2. Inferred request fields: `complaint/response`, `complaint/close`,
   `complaint/otp_verify` (`otp`), `approvals/approve|reject`
   (`customer_id`), `notifications/mark_read` (`id`),
   `tasks/update_status` (`status`), lead status values.
3. `m/dashboard/index` (role source) was not captured for the super-admin
   account; the `is_super_admin` flag is assumed to be true for it.
4. OTP success response not captured.
5. Request Content-Type was not recorded; POST bodies are form-encoded
   (CI3 default). Switch with `--dart-define=API_BODY_ENCODING=json`.
6. The bulk reminder dry run answered "Total: 20, Sent: 20" while each row
   said `would_send`; the app counts rows with `would_send`. Whether a call
   *without* `dry_run` sends for real is assumed, not verified.

## 7. Backend observations worth a look (not changed — backend is out of scope)

These came up while reading the inventory. They are reported, not fixed.

1. **Password hash exposed publicly.** `GET m/jobs/company/{id}` (no token)
   returns the employer's `password_hash`, `reset_token` and `ip_address`.
2. **Unauthenticated destructive endpoints.** In the `public` group,
   `POST m/sys/util_nuke` answers "POST confirm=1 to IRREVERSIBLY delete
   duplicate enquiries"; `m/utility/delete_duplicates`,
   `m/utility/remove_duplicate`, `m/amc/import*`, `m/UPDATEPARTYMASTER`,
   `m/dbtest/*` and `m/sys/db_*` are listed as public DB-writing endpoints
   (the inventory deliberately did not call them).
3. **Public file listing.** `GET m/utility` (no token) lists downloadable
   files, including executables and an archive named "Microsoft Activation
   Scripts … {CracksHash}.zip".
4. `m/employee/*` answers 503 "empmaster table missing".
5. WhatsApp sends fail with 502: "Your instance has been Stopped due to
   non-payment."
6. `m/customer/qrcode` returns a `qr_image` URL on the retired Google Charts
   QR API; the app draws the QR itself.
