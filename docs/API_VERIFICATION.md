# API verification report

How each backend endpoint relates to the app. The full list of 1,044 captured
calls is in [API_INVENTORY.md](API_INVENTORY.md).

## How verification was attempted

* **Live requests: not possible from the build environment.** The supplied
  URLs point at `https://crm-marg.com/` (not localhost), but the sandbox's
  network policy refused the connection (`crm-marg.com:443 — connect_rejected`).
  No endpoint was called live. This is a network restriction, **not** evidence
  that any endpoint is broken.
* **Contract source:** the request/response pairs captured in `urls.json`
  (run on 20–21 Oct 2026 against Apache 2.4 / PHP 8.3 with test accounts for
  staff, branch admin, super admin, customer and job seeker).
* **404 rule:** every 404 in the inventory is a JSON *record* error from a
  working controller ("Job not found.", "Enquiry not found." for test id
  `999999` etc.). There is **no route-level 404**, so no feature was skipped
  for returning 404.
* **Automated tests** replay the captured shapes (with fake values) through
  the real API client and repositories; see `test/`.

## Legend

| Label | Meaning |
|---|---|
| **Sample-verified** | A successful response with data was captured; the parser is tested against that exact shape. |
| **Shape-verified (empty)** | A successful response was captured, but its list was empty, so row keys are read tolerantly from evidence named in the code. |
| **Fields from backend message** | Request field names come from the backend's own 422 message or `fields` list; no success response was captured. |
| **Inferred** | Field names or values are not documented anywhere; derived from a sibling endpoint or record shape. Isolated in `lib/core/api/endpoints.dart` and listed below. |
| **Not used** | Captured but not wired into the app (reason given). |

## Endpoints used by the app

### Authentication (all roles)

| Endpoint | Status | Notes |
|---|---|---|
| `POST m/auth/login` (identifier, password, login_type) | Sample-verified | staff + customer; 401 message shown to the user |
| `POST m/auth/seeker_login` (email, password) | Sample-verified | |
| `POST m/auth/refresh` (refresh_token) | Sample-verified | rotates both tokens; 401 on invalid token ends the session |
| `GET m/auth/me` | Sample-verified | confirms the user on every start |
| `POST m/auth/logout` (refresh_token) | Sample-verified | best effort; local data is wiped regardless |
| `POST m/dashboard/index` | Sample-verified | source of the CRM role (`staff.role`, `staff.is_super_admin`); **only captured for staff and admin, not for the super-admin account** |
| `POST m/auth/sendOTP` (identifier) | Fields verified, success **unverified** | only a 401 was captured; `pending_token` in the success body is inferred from `verifyOTP` |
| `POST m/auth/verifyOTP` (pending_token, otp) | Fields verified, success **unverified** | success assumed to match the login body (tokens) |
| `POST m/auth/staff_forgot` / `seeker_forgot` (email) | Fields verified, success **unverified** | only 404 captured |
| `POST m/auth/seeker_register` | Fields from backend message | full_name, email, phone, password, confirm_password |

### CRM: staff, branch admin, super admin

| Endpoint | Status | Notes |
|---|---|---|
| `GET m/emsdashboard` | Sample-verified | lead counts for Today and Insights |
| `GET m/cmsdashboard` | Sample-verified | ticket counts per status |
| `GET m/renewal?month=` | Sample-verified | month summary, month list, 12-month chart |
| `GET m/renewal/get_chart_data` | Sample-verified | |
| `GET m/reports` | Sample-verified | Insights KPIs |
| `GET m/tasks/listall` | Shape-verified (empty) | row keys from `m/task/get_task/1` sample |
| `POST m/tasks/update_status` (id, **status**) | `id` from message; `status` **inferred** | |
| `GET m/notifications/get_unread` | Sample-verified (`{count, notifications}`) | |
| `GET m/notifications/listing?page=` | Shape-verified (empty) | |
| `POST m/notifications/mark_all_read` | Sample-verified | |
| `POST m/notifications/mark_read` (**id**) | **Inferred** | backend says "Invalid notification ID." |
| `GET m/enquiry/list` (limit, offset, show_all, st) | Shape-verified (empty) | lead row keys inferred from `addNewFrm` fields; **`st` filter values inferred** from `emsdashboard` keys |
| `GET m/enquiry/detail/{id}` | **Unverified** | only 404/422 captured; the list row is shown if the detail cannot be read |
| `GET m/enquiry/addNewFrm` | Sample-verified | field list + branches |
| `POST m/enquiry/add` | Fields verified (`fields` list) | sname, phone, sdate (dd/mm/yyyy), etyp, srs, cmnt, eAddrs, bcode |
| `POST m/enquiry/check_mobile` (mobile) | Sample-verified (`{"exists":false}`) | |
| `POST m/enquiry/response` | `ecode` from message; `res, resdate, cmnt` from prototype notes | status values inferred (see below) |
| `POST m/enquiry/call_start` / `call_end` (id) | Sample-verified | |
| `POST m/enquiry/ai_call` (id, phone) | Fields from backend message | |
| `POST m/enquiry/del` (id) | Fields from backend message | branch admin only |
| `POST m/complaint/list` (status, show_all, limit, offset) | Sample-verified | 9 real rows captured |
| `GET m/complaint/detail/{id}` | **Unverified** | only 403/404 captured; 403 "Not authorized for this complaint." is shown as a permission state |
| `POST m/complaint/otp_generate` (cid) | Fields verified | |
| `POST m/complaint/otp_verify` (cid, **otp**) | `otp` **inferred** | "Complaint ID and OTP are required" |
| `POST m/complaint/close` (cid, **resolution**) | **Inferred** | "Complaint ID required" |
| `POST m/complaint/response` (**cid, response, comments**) | **Inferred** | backend only says "Missing required fields" |
| `POST m/autoassign` (confirm=1) | Fields from backend message | super admin only |
| `POST m/complaint/customer_lookup` (customer_id) | Sample-verified | |
| `GET m/bss/check_wallet/{id}` | Sample-verified | |
| `POST m/customerpayments/getCustomerById` (customer_id) | Sample-verified | |
| `POST m/customerdir/list` (search, page) | Shape-verified (empty) | params from prototype notes; row keys from party-master samples |
| `GET m/customerpayments` | Sample-verified | |
| `GET m/renewal/records_list` (month, type, limit, offset) | Shape-verified (empty) | |
| `POST m/bulkmsg/send_renewal_messages` (dry_run=1) | Sample-verified | preview; the **real send (no dry_run) is inferred** |
| `GET m/qrfield/tasks`, `POST m/qrfield/customers` | Shape-verified (empty) / fields from message | assignment and customer row keys inferred |
| `POST m/qrfield/customer_done` (progress_id), `assignment_done` (assignment_id) | Fields from backend message | |
| `GET m/approvals/pending` | Shape-verified (empty) | |
| `POST m/approvals/approve` / `reject` (**customer_id**) | **Inferred** | "Customer ID is required." |
| `GET m/branch/listall` | Sample-verified | users are stored as "branches" |
| `POST m/branch/changeStatus` (id) | Fields from backend message | assumed to toggle; the list is reloaded to show the server's state |
| `GET m/profile` | Sample-verified | |
| `GET m/admin/tenants`, `GET m/admin/errors`, `GET m/qradmin/batches` | Sample-verified | super admin, read-only |

### Customer portal

| Endpoint | Status | Notes |
|---|---|---|
| `GET m/customer` | Sample-verified | |
| `GET m/customer/profile` | Sample-verified | |
| `GET m/customer/complaints` | Shape-verified (empty) | rows parsed as complaint records |
| `POST m/customer/reopenComplaint` (cid) | Fields from backend message | |
| `GET m/customer/payments`, `GET m/customer/renewals`, `GET m/customer/referral_earnings` | Shape-verified (empty) | |
| `GET m/customer/qrcode` | Sample-verified | QR drawn on-device from `qr_url` (the `qr_image` URL uses the retired Google Charts QR API) |
| `POST m/customer/notifications` | Shape-verified (empty) | |

### Job seeker portal

| Endpoint | Status | Notes |
|---|---|---|
| `GET m/jobs` (keyword, limit, offset), `GET m/jobs/category/{slug}` | Shape-verified (empty) | categories verified; job row keys inferred |
| `GET m/jobs/detail/{id}` | **Unverified** | only 404 captured |
| `POST m/seeker/apply/{id}`, `POST m/seeker/save_job/{id}` | **Unverified** | only 422/404 for a fake id; no body fields required by those responses |
| `POST m/seeker/withdraw_application/{id}` | **Unverified** | |
| `GET m/seeker/dashboard`, `GET m/seeker/public_profile` | Sample-verified | |
| `GET m/seeker/applications`, `GET m/seeker/interviews`, `GET m/seeker/saved_jobs` | Shape-verified (empty) | |

## Inferred values (check these first if a call fails)

All are defined once in `lib/core/api/endpoints.dart` or the named repository.

| What | Value used | Where |
|---|---|---|
| Lead status values (`res`, `st`) | New, Call Back, Demo Schedule, Demo Done, Converted, Not Required, Invalid, Switch Off | `leadStatuses` in `lead_repository.dart` |
| Ticket response statuses | Acknowledge, In Progress, Transfer To IT, Reject (verified as status names in `m/cmsdashboard`) | `ticketResponseStatuses` |
| Task "done" status | `completed` (undo sends `pending`, the captured default) | `today_screen.dart` |
| Date format for `resdate` | dd/mm/yyyy (same as the verified `sdate`) | `LeadRepository._ddmmyyyy` |
| Enquiry types / sources offered | from the prototype (New licence, Upgrade, AMC renewal, Add-on / Walk-in, Call, Website, Referral, WhatsApp) | `lead_new_screen.dart` |

## Captured but not used, and why

| Area | Endpoints | Reason |
|---|---|---|
| Password change | `m/customer/forceChangePassword`, `m/customerauth/changePassword`, `…/forceChangePasswordAction`, `m/customer/changePassword` | deliberately not called in the inventory (would change the test password); fields unknown. `force_change` sends the user to the web portal instead. |
| Create complaint (customer) | `m/customer/createComplaint` | skipped in the inventory; fields unknown |
| Staff create complaint | `m/complaint/add` | needs a customer search flow whose fields are only partly known ("Please search and select a valid customer first") |
| Ticket reassign | `m/complaint/assign` | "Missing required fields" only; assignee id vs name unknown |
| Record / edit / delete payment | `m/customerpayments/add`, `edit`, `delete`, `m/payments/*` | fields undocumented; money actions are not guessed |
| Employee module | `m/employee/*` | answers **503** "Employee module is unavailable (empmaster table missing)"; Team uses `m/branch/listall` instead |
| Bulk lead actions | `m/enquiry/status`, `m/bulkmsg/initiate_enquiry_calls`, `m/export/download` | selection-based bulk endpoints are not documented (status field unknown; enquiry calls are filter-based; export returns an .xlsx) |
| BI chart endpoint | `m/bi/chart_data?type=` | only "Invalid type." (422) captured for every type; Insights uses verified endpoints instead |
| Profile edits | `m/profile/update`, `m/customer/updateProfile`, `m/seeker/profile`, `education`, `experience`, `portfolio`, `settings`, `upload_photo`, `upload_resume` | fields unknown (skipped or "No changes provided"). The API client supports multipart uploads when the fields are known. |
| Online payment | `m/customer/online_payment`, `m/razorpay/*` | needs the Razorpay SDK; `razorpay_configured: false` in the inventory |
| Customer job posting | `m/customer_jobs/*` | answers **409** "Create a company profile first." for the test customer; out of scope of the prototype |
| Admin configuration | `m/settings/*`, `m/tenantsettings/*`, `m/whatsapp_automation/*`, `m/emailautomation/*`, `m/mail/*`, `m/msg/*`, `m/bss/*`, `m/events/*`, `m/jobadmin/*`, `m/sitecontent`, `m/excel_export`, `m/download`, `m/utility` | back-office configuration, imports and file downloads with no mobile UI reference; several return 502 because external services (SMTP, WhatsApp) are down |
| Destructive platform actions | `m/admin/tenant_delete`, `m/admin/errors_clear`, `m/sys/*`, `m/lmsfix`, `m/dbtest/*` | intentionally not exposed in a mobile client |
| LMS | `m/lms`, `m/lms/progress`, `m/lms/search` | public training content with no UI reference; module detail shape unknown |
| Public website helpers | `m/site`, `m/amc`, `m/signup/*`, `m/welcome/*`, `m/qr`, `m/qr/usage` | web-site flows; not part of the mobile app |
