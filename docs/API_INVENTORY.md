# API endpoint inventory

1044 rows across 6 roles.
Generated from `urls.json` (the captured run against the backend). One row per method + path per role.
Every authenticated call used `Authorization: Bearer <access_token>`; no request recorded a Content-Type, so the app form-encodes POST bodies (configurable).

**Status legend:** a number is the HTTP status captured; `—` means the inventory deliberately did not call it (reason given).
All captured 404s are record-level JSON errors (for example "Job not found." for test id 999999) from working controllers; none is a missing route.

Aliases: many controllers answer under two names (`m/complaint` = `m/complaintmaster`, `m/tasks` = `m/task`, `m/notifications` = `m/notify`, `m/whatsapp_automation` = `m/waauto`, `m/jobportal/admin` = `m/jobadmin`, `m/platform` = `m/admin`, `m/qrinfo` ≈ `m/qradmin`/`m/qrfield`, `m/customerauth` = `m/auth` for customers, `m/jobportal/seeker` = `m/seeker`). The app uses the shorter name.

## Public (no token)

| Method | Path | Status | Request fields seen | Response shape | Message / note |
|---|---|---|---|---|---|
| GET | `m/UPDATEPARTYMASTER` | — |  |  | G: alias of public bulk import (writes DB) |
| GET | `m/amc` | 200 |  | data{license_param, upi_id} | OK |
| GET | `m/amc/import` | — |  |  | G: public bulk CSV import into enquiries+renewals |
| POST | `m/amc/import/confirm` | — |  |  | G: DB write stage of public bulk import |
| GET | `m/amc/import/preview` | — |  |  | G: upload+parse stage of public bulk import |
| POST | `m/amc/search` | 404 | license_no | {status, message, data, code} | License "DUMMY-NOT-REAL" nahi mila. Number check karein. |
| POST | `m/auth/checkPasswordStatus` | 404 | customer_id | data{has_password} | Customer not found. |
| POST | `m/auth/customer_lookup` | 404 | identifier | {status, message, data, code} | Customer not found. Please check Mobile Number or Customer ID. |
| POST | `m/auth/login` | 401 | identifier, password | {status, message, data, code} | Account not found. Check Mobile Number / Customer ID. |
| POST | `m/auth/refresh` | 401 | refresh_token | {status, message, data, code} | Invalid refresh token. |
| POST | `m/auth/seeker_forgot` | 404 | email | {status, message, data, code} | Email not found. |
| POST | `m/auth/seeker_login` | 401 | email, password | {status, message, data, code} | Invalid email or password. |
| POST | `m/auth/seeker_register` | 422 | full_name, email, password, phone | {status, message, data, code} | The Confirm Password field is required. |
| POST | `m/auth/seeker_reset` | 401 | token, password, confirm_password | {status, message, data, code} | Reset token is invalid or expired. |
| POST | `m/auth/sendOTP` | 401 | identifier | {status, message, data, code} | Customer not found. Check Mobile Number or Customer ID. |
| POST | `m/auth/staff_forgot` | 404 | email | {status, message, data, code} | No staff account found for this email. |
| POST | `m/auth/verifyOTP` | 401 | pending_token, otp | {status, message, data, code} | Invalid OTP session. Request a new OTP. |
| GET | `m/customer/login` | 401 |  | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/customerauth/checkPasswordStatus` | 404 | customer_id | data{has_password} | Customer not found. |
| GET | `m/customerauth/login` | 401 |  | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/customerauth/passwordLoginStep1` | 401 | identifier | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/customerauth/passwordLoginStep2` | 401 | customer_id, password | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/customerauth/sendOTP` | 401 | identifier | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/customerauth/verifyOTP` | 401 | customer_id, otp | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/dbtest/createcustomer` | — |  |  | SKIP: M_sys::db_create DELETES customers id=1 |
| POST | `m/dbtest/customer` | — |  |  | SKIP: M_sys::db_customer overwrites otp on id=1 |
| POST | `m/eventreg/del` | — |  |  | G: unauthenticated delete |
| POST | `m/jobportal` | 401 | email, password | {status, message, data, code} | Invalid email or password. |
| POST | `m/jobportal/auth/forgot_password` | 422 |  | {status, message, data, code} | Valid email is required. |
| POST | `m/jobportal/auth/forgot_password/data-entry` | 422 |  | {status, message, data, code} | Valid email is required. |
| POST | `m/jobportal/auth/login` | 422 |  | {status, message, data, code} | Email and password are required. |
| POST | `m/jobportal/auth/login/data-entry` | 422 |  | {status, message, data, code} | Email and password are required. |
| POST | `m/jobportal/auth/register` | 422 |  | {status, message, data, code} | The Full Name field is required.   The Email field is required.   The Password field is re |
| POST | `m/jobportal/auth/register/data-entry` | 422 |  | {status, message, data, code} | The Full Name field is required.   The Email field is required.   The Password field is re |
| POST | `m/jobportal/auth/reset_password` | 422 |  | {status, message, data, code} | Reset token is required. |
| POST | `m/jobportal/auth/reset_password/data-entry` | 422 |  | {status, message, data, code} | Reset token is required. |
| GET | `m/jobportal/jobs` | 200 |  | data{jobs, total_jobs, per_page, offset, filters, categories, featured_jobs} | OK |
| GET | `m/jobportal/jobs/category/data-entry` | 200 |  | data{category, jobs, total_jobs, per_page, offset} | OK |
| GET | `m/jobportal/jobs/company/1` | 200 |  | data{company, jobs} | OK |
| GET | `m/jobportal/jobs/detail/1` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/jobportal/jobs/detail/1/data-entry` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/jobportal/jobs/index` | 200 |  | data{jobs, total_jobs, per_page, offset, filters, categories, featured_jobs} | OK |
| GET | `m/jobportal/jobs/index/1` | 200 |  | data{jobs, total_jobs, per_page, offset, filters, categories, featured_jobs} | OK |
| GET | `m/jobportal/jobs/locations` | 200 |  | data[0] | OK |
| GET | `m/jobportal/jobs/search` | 200 |  | data[0] | OK |
| GET | `m/jobs` | 200 |  | data{jobs, total_jobs, per_page, offset, filters, categories, featured_jobs} | OK |
| GET | `m/jobs/category/data-entry` | 200 |  | data{category, jobs, total_jobs, per_page, offset} | OK |
| GET | `m/jobs/company/1` | 200 |  | data{company, jobs} | OK |
| GET | `m/jobs/detail/1` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/jobs/index` | 200 |  | data{jobs, total_jobs, per_page, offset, filters, categories, featured_jobs} | OK |
| GET | `m/jobs/index/1` | 200 |  | data{jobs, total_jobs, per_page, offset, filters, categories, featured_jobs} | OK |
| GET | `m/jobs/locations` | 200 |  | data[0] | OK |
| GET | `m/jobs/search` | 200 |  | data[0] | OK |
| GET | `m/lms` | 200 |  | data{modules, total_modules} | OK |
| GET | `m/lms/index` | 200 |  | data{modules, total_modules} | OK |
| GET | `m/lms/module` | 422 |  | {status, message, data, code} | Module slug is required. |
| GET | `m/lms/module/data-entry` | 404 |  | {status, message, data, code} | Module not found. |
| GET | `m/lms/progress` | 200 |  | data{total_modules, completed, completion_percent} | Progress tracking is not enabled yet. |
| GET | `m/lms/search` | 200 |  | data{query, results, total_results} | OK |
| GET | `m/login` | 401 |  | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/logout/index` | 401 |  | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| GET | `m/passwordrecovery` | 401 |  | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| GET | `m/qr` | 422 |  | {status, message, data, code} | QR token is required. |
| GET | `m/qr/data-entry` | 404 |  | data{customer_id, customer, token} | Invalid or expired QR code. |
| POST | `m/qr/submitRequest` | 422 |  | {status, message, data, code} | Invalid request type. |
| POST | `m/qr/usage` | 200 | customer_id | data{total_referrals, converted, closed, pending, total_services, earning} | OK |
| GET | `m/razorpay/check_status/data-entry` | 404 |  | {status, message, data, code} | Order not found. |
| POST | `m/razorpay/create_order` | 422 |  | {status, message, data, code} | Invalid amount. |
| POST | `m/razorpay/verify` | 422 |  | {status, message, data, code} | Missing payment details. |
| GET | `m/signup` | 401 |  | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/signup/submit` | 422 |  | {status, message, data, code} | Company name, email, phone and password are required. |
| GET | `m/site` | 200 |  | data{app_name, support_phone, base_url, api_base, auth} | OK |
| GET | `m/site/index` | 200 |  | data{app_name, support_phone, base_url, api_base, auth} | OK |
| POST | `m/site/signup_submit` | 422 |  | {status, message, data, code} | Company name, email, phone and password are required. |
| POST | `m/site/submitEnquiry` | 422 |  | {status, message, data, code} | Name is required. |
| POST | `m/sys/db_create` | — |  |  | SKIP: DELETES customers id=1, inserts Test Customer |
| POST | `m/sys/db_customer` | — |  |  | SKIP: overwrites otp/otp_expiry on customers id=1 |
| GET | `m/sys/util_dupes` | 200 |  | data{duplicates, count} | OK |
| POST | `m/sys/util_nuke` | 200 |  | data{would_delete, fields} | POST confirm=1 to IRREVERSIBLY delete duplicate enquiries. |
| GET+POST | `m/tasker/create_event` | — |  |  | G: unauthenticated scaffold with DB writes |
| GET | `m/tasker/my_tasks` | — |  |  | G: unauthenticated scaffold |
| GET+POST | `m/tasker/update_task` | — |  |  | G: unauthenticated scaffold with DB writes |
| GET | `m/updatepartymaster` | — |  |  | G: alias of public bulk import |
| GET | `m/utility` | 200 |  | data{files} | OK |
| POST | `m/utility/download` | 422 |  | {status, message, data, code} | Filename is required. |
| POST | `m/utility/download/data-entry` | 404 |  | {status, message, data, code} | File not found. |
| GET | `m/utility/remove_duplicate` | — |  |  | G: destructive cross-customer DELETE |
| GET | `m/welcome/index` | 200 |  | data{app_name, support_phone, base_url, api_base, auth} | OK |
| POST | `m/welcome/loginchk` | 401 | u, p | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/welcome/loginems` | 401 | u, p | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/welcome/logout` | 401 |  | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/welcome/resetPsw` | 401 | emal | {status, message, data, code} | Authorization token missing. Send "Authorization: Bearer <token>". |
| POST | `m/welcome/submitEnquiry` | 422 |  | {status, message, data, code} | Name is required. |
| POST | `m/utility/delete_duplicates` | — |  |  | G: executes the destructive delete |

## Customer (`user_type: customer`)

| Method | Path | Status | Request fields seen | Response shape | Message / note |
|---|---|---|---|---|---|
| POST | `m/auth/login` | 200 | identifier, password, login_type | data{user_type, user_id, name, mobile, email, tenant_code, force_change, is_default…} | Login successful. |
| POST | `m/auth/refresh` | 200 | refresh_token | data{access_token, refresh_token, expires_in, token_type} | Token refreshed. |
| GET | `m/auth/me` | 200 |  | data{user_type, user_id, tenant_code, name, mobile, email} | OK |
| GET | `m/customer` | 200 |  | data{customer_id, customer_name, customer, amc_info, complaints_count, qr_token, recent_payments, recent_complaints…} | OK |
| POST | `m/customer/changePassword` | — |  |  | SKIP: would change pass123 and lock out the run |
| GET | `m/customer/complaintDetail` | 422 |  | {status, message, data, code} | Complaint id is required (?id=). |
| GET | `m/customer/complaintDetail/1` | 404 |  | {status, message, data, code} | Complaint not found. |
| GET | `m/customer/complaints` | 200 |  | data{complaints, current_status} | OK |
| POST | `m/customer/createComplaint` | — |  |  | SKIP: empty-body create is unsafe; covered by QA fixture test |
| GET | `m/customer/dashboard` | 200 |  | data{customer_id, customer_name, customer, amc_info, complaints_count, qr_token, recent_payments, recent_complaints…} | OK |
| GET | `m/customer/download_receipt` | 422 |  | {status, message, data, code} | Receipt id is required (?id=). |
| GET | `m/customer/download_receipt/1` | 404 |  | {status, message, data, code} | Receipt not found. |
| POST | `m/customer/forceChangePassword` | — |  |  | SKIP: would change pass123 and lock out the run |
| POST | `m/customer/notifications` | 200 |  | data{notifications} | OK |
| GET | `m/customer/online_payment` | 200 |  | data{customer, amc_info, razorpay_configured, razorpay_key} | OK |
| GET | `m/customer/payments` | 200 |  | data{payments, total_paid, pending_amount} | OK |
| GET | `m/customer/printQR` | 200 |  | data{qr_url, qr_image, qr_token, customer_id, customer_name, customer_mobile, company, referral_amount…} | OK |
| GET | `m/customer/profile` | 200 |  | data{customer, pending_changes, pending_requested_at, total_complaints, resolved_complaints, referral_count, referral_balance, party_status} | OK |
| GET | `m/customer/qrcode` | 200 |  | data{qr_url, qr_image, qr_token, customer_id, customer_name, customer_mobile, company, referral_amount…} | OK |
| GET | `m/customer/referral_earnings` | 200 |  | data{earnings, total_earned, pending_earnings, referral_balance} | OK |
| GET | `m/customer/renewals` | 200 |  | data{renewals} | OK |
| POST | `m/customer/reopenComplaint` | 422 |  | {type, text} | cid is required. |
| POST | `m/customer/updateProfile` | 422 |  | {status, message, data, code} | No changes provided. |
| GET | `m/customer_jobs` | 200 |  | data{company, has_company} | OK |
| GET | `m/customer_jobs/applications` | 409 |  | data{needs_company} | Create a company profile first. |
| GET | `m/customer_jobs/applications/1` | 409 |  | data{needs_company} | Create a company profile first. |
| POST | `m/customer_jobs/cancel_interview/1` | 409 |  | data{needs_company} | Create a company profile first. |
| GET | `m/customer_jobs/candidates` | 409 |  | data{needs_company} | Create a company profile first. |
| POST | `m/customer_jobs/complete_interview/1` | 409 |  | data{needs_company} | Create a company profile first. |
| POST | `m/customer_jobs/create_company` | 422 |  | {status, message, data, code} | Company name is required. |
| GET | `m/customer_jobs/dashboard` | 200 |  | data{company, has_company} | OK |
| POST | `m/customer_jobs/edit_company` | 409 |  | data{needs_company} | Create a company profile first. |
| GET | `m/customer_jobs/export_applications` | 409 |  | data{needs_company} | Create a company profile first. |
| GET | `m/customer_jobs/export_applications/1` | 409 |  | data{needs_company} | Create a company profile first. |
| POST | `m/customer_jobs/interviews` | 409 |  | data{needs_company} | Create a company profile first. |
| GET | `m/customer_jobs/my_jobs` | 409 |  | data{needs_company} | Create a company profile first. |
| POST | `m/customer_jobs/post_job` | 409 |  | data{needs_company} | Create a company profile first. |
| POST | `m/customer_jobs/post_job/1` | 409 |  | data{needs_company} | Create a company profile first. |
| POST | `m/customer_jobs/save_seeker/1` | 409 |  | data{needs_company} | Create a company profile first. |
| GET | `m/customer_jobs/saved_seekers` | 409 |  | data{needs_company} | Create a company profile first. |
| POST | `m/customer_jobs/settings` | — |  |  | SKIP: body is current/new/confirm password (would lock out) |
| POST | `m/customer_jobs/update_application_status/1` | 409 |  | data{needs_company} | Create a company profile first. |
| POST | `m/customerauth/changePassword` | — |  |  | SKIP: would change pass123 and lock out the run |
| POST | `m/customerauth/forceChangePassword` | — |  |  | SKIP: would change pass123 and lock out the run |
| POST | `m/customerauth/forceChangePasswordAction` | — |  |  | SKIP: would change pass123 and lock out the run |
| POST | `m/auth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |
| POST | `m/customerauth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |
| POST | `m/jobportal/auth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |

## Job seeker (`user_type: seeker`)

| Method | Path | Status | Request fields seen | Response shape | Message / note |
|---|---|---|---|---|---|
| POST | `m/auth/seeker_login` | 200 | email, password | data{user_type, user_id, name, email, access_token, refresh_token, expires_in, token_type} | Login successful. |
| POST | `m/auth/refresh` | 200 | refresh_token | data{access_token, refresh_token, expires_in, token_type} | Token refreshed. |
| GET | `m/auth/me` | 200 |  | data{user_type, user_id, tenant_code, name, mobile, email} | OK |
| POST | `m/jobportal/jobs/quick_apply/999999` | 422 |  | {status, message, data, code} | This job is not open for applications. |
| POST | `m/jobportal/jobs/save_job/999999` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/jobportal/seeker/applications` | 200 |  | data{applications, stats, current_status} | OK |
| GET | `m/jobportal/seeker/dashboard` | 200 |  | data{seeker, stats, recent_applications, saved_jobs, profile_completion} | OK |
| POST | `m/jobportal/seeker/delete_education/999999` | 404 |  | {status, message, data, code} | Education record not found. |
| POST | `m/jobportal/seeker/delete_experience/999999` | 404 |  | {status, message, data, code} | Experience record not found. |
| POST | `m/jobportal/seeker/delete_portfolio/999999` | 404 |  | {status, message, data, code} | Portfolio item not found. |
| GET | `m/jobportal/seeker/delete_resume` | 200 |  | {status, message, data, code} | Resume deleted. |
| POST | `m/jobportal/seeker/education` | — |  |  | SKIP: write covered by QA fixture test |
| POST | `m/jobportal/seeker/experience` | — |  |  | SKIP: write covered by QA fixture test |
| GET | `m/jobportal/seeker/interviews` | 200 |  | data{interviews, upcoming} | OK |
| POST | `m/jobportal/seeker/portfolio` | — |  |  | SKIP: empty-body insert creates a blank row; covered by QA fixture test |
| POST | `m/jobportal/seeker/profile` | — |  |  | SKIP: empty-body update wipes the profile; covered by QA fixture test |
| GET | `m/jobportal/seeker/profile/1` | 403 |  | {status, message, data, code} | You can only view your own profile here. |
| GET | `m/jobportal/seeker/public_profile/1` | 403 |  | {status, message, data, code} | You can only view your own profile here. |
| GET | `m/jobportal/seeker/saved_jobs` | 200 |  | data{jobs} | OK |
| POST | `m/jobportal/seeker/settings` | — |  |  | SKIP: body is current/new/confirm password |
| POST | `m/jobportal/seeker/upload_photo` | 422 |  | {status, message, data, code} | No file selected. |
| POST | `m/jobportal/seeker/upload_resume` | 422 |  | {status, message, data, code} | No file selected. |
| POST | `m/jobportal/seeker/withdraw_application/999999` | 422 |  | {status, message, data, code} | Application not found. |
| GET | `m/seeker` | 200 |  | data{seeker, stats, recent_applications, saved_jobs, profile_completion} | OK |
| GET | `m/seeker/applications` | 200 |  | data{applications, stats, current_status} | OK |
| POST | `m/seeker/apply/999999` | 422 |  | {status, message, data, code} | This job is not open for applications. |
| GET | `m/seeker/dashboard` | 200 |  | data{seeker, stats, recent_applications, saved_jobs, profile_completion} | OK |
| POST | `m/seeker/delete_education/999999` | 404 |  | {status, message, data, code} | Education record not found. |
| POST | `m/seeker/delete_experience/999999` | 404 |  | {status, message, data, code} | Experience record not found. |
| POST | `m/seeker/delete_portfolio/999999` | 404 |  | {status, message, data, code} | Portfolio item not found. |
| GET | `m/seeker/delete_resume` | 200 |  | {status, message, data, code} | Resume deleted. |
| POST | `m/seeker/education` | — |  |  | SKIP: write covered by QA fixture test |
| POST | `m/seeker/experience` | — |  |  | SKIP: write covered by QA fixture test |
| GET | `m/seeker/interviews` | 200 |  | data{interviews, upcoming} | OK |
| POST | `m/seeker/portfolio` | — |  |  | SKIP: empty-body insert creates a blank row; covered by QA fixture test |
| POST | `m/seeker/profile` | — |  |  | SKIP: empty-body update wipes the profile; covered by QA fixture test |
| GET | `m/seeker/public_profile` | 200 |  | data{seeker, education, experience, portfolio} | OK |
| GET | `m/seeker/public_profile/1` | 403 |  | {status, message, data, code} | You can only view your own profile here. |
| POST | `m/seeker/save_job/999999` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/seeker/saved_jobs` | 200 |  | data{jobs} | OK |
| POST | `m/seeker/settings` | — |  |  | SKIP: body is current/new/confirm password |
| POST | `m/seeker/upload_photo` | 422 |  | {status, message, data, code} | No file selected. |
| POST | `m/seeker/upload_resume` | 422 |  | {status, message, data, code} | No file selected. |
| POST | `m/seeker/withdraw_application/999999` | 422 |  | {status, message, data, code} | Application not found. |
| POST | `m/auth/logout` | 200 |  | {status, message, data, code} | Logged out. |

## Staff (`user_type: staff`, role 2)

| Method | Path | Status | Request fields seen | Response shape | Message / note |
|---|---|---|---|---|---|
| POST | `m/auth/login` | 200 | identifier, password, login_type | data{user_type, user_id, name, email, tenant_code, force_change, access_token, refresh_token…} | Login successful. |
| POST | `m/auth/refresh` | 200 | refresh_token | data{access_token, refresh_token, expires_in, token_type} | Token refreshed. |
| GET | `m/auth/me` | 200 |  | data{user_type, user_id, tenant_code, name, email, branch_name} | OK |
| GET | `m/bi` | 200 |  | data{charts} | Pass ?type= (see charts list) with optional year/months/start/end. |
| GET | `m/bi/chart_data` | 422 |  | data[0] | Invalid type. |
| GET | `m/bi/index` | 200 |  | data{charts} | Pass ?type= (see charts list) with optional year/months/start/end. |
| GET | `m/bidashboard` | 200 |  | data{charts} | Pass ?type= (see charts list) with optional year/months/start/end. |
| GET | `m/bidashboard/chart_data` | 422 |  | data[0] | Invalid type. |
| GET | `m/bidashboard/index` | 200 |  | data{charts} | Pass ?type= (see charts list) with optional year/months/start/end. |
| GET | `m/branch` | 200 |  | data{branches, total, limit, offset} | OK |
| GET | `m/branch/detail` | 422 |  | {status, message, data, code} | Branch id is required (?id=). |
| GET | `m/branch/detail/47` | 200 |  | data{branch} | OK |
| GET | `m/branch/list` | 200 |  | data{branches, total, limit, offset} | OK |
| GET | `m/branch/listall` | 200 |  | data{branches, total, limit, offset} | OK |
| POST | `m/branch/perm_view` | 200 | id | non-JSON (8000 bytes) |  |
| POST | `m/branch/permissions` | 200 | id | non-JSON (8000 bytes) |  |
| GET | `m/branches` | 200 |  | data{branches, total, limit, offset} | OK |
| GET | `m/branches/addNewFrm` | 200 |  | data{fields, roles, defaults} | OK |
| POST | `m/branches/chngBrnch` | — |  |  | SKIP: session-switch is meaningless stateless (doc G) |
| GET | `m/branches/index` | 200 |  | data{branches, total, limit, offset} | OK |
| GET | `m/branches/listall` | 200 |  | data{branches, total, limit, offset} | OK |
| POST | `m/branches/perm_view` | 200 | id | non-JSON (8000 bytes) |  |
| POST | `m/branches/profile` | 403 | id | {status, message, data, code} | Admin access required. |
| GET | `m/bss` | 200 |  | data{total, pending, success, failed, customers} | OK |
| GET | `m/bss/api_status` | 200 |  | data{online, http_code} | BSS service unreachable. |
| POST | `m/bss/bulk_generate` | 200 |  | {type, text, created, skipped} | 0 requests created. |
| GET | `m/bss/bulk_list` | 200 |  | data{pending, batches} | OK |
| POST | `m/bss/bulk_new` | 422 |  | {status, message, data, code} | Please select a file to upload (field excel_file). |
| POST | `m/bss/bulk_new_licence` | 422 |  | {status, message, data, code} | Please select a file to upload (field excel_file). |
| POST | `m/bss/bulk_process` | 200 | dry_run | data{fields} | POST with confirm=1 to process a chunk of the batch. |
| POST | `m/bss/bulk_process/1` | 200 | dry_run | data{fields} | POST with confirm=1 to process a chunk of the batch. |
| GET | `m/bss/check_wallet/1000336` | 200 |  | data{found, customer_id, party_name, mobile, sw_type, city, address, wallet_id} | OK |
| POST | `m/bss/coupon_confirm` | 200 |  | data{fields} | Run coupon_preview first, then POST the file again with column indexes + confirm=1. |
| POST | `m/bss/coupon_direct` | 200 |  | data{fields} | POST the file with confirm=1. Columns auto-detected from headers. |
| POST | `m/bss/coupon_import_confirm` | 200 |  | data{fields} | Run coupon_preview first, then POST the file again with column indexes + confirm=1. |
| POST | `m/bss/coupon_import_direct` | 200 |  | data{fields} | POST the file with confirm=1. Columns auto-detected from headers. |
| POST | `m/bss/coupon_import_preview` | 422 |  | {status, message, data, code} | File upload failed (field import_file). |
| POST | `m/bss/coupon_preview` | 422 |  | {status, message, data, code} | File upload failed (field import_file). |
| GET | `m/bss/coupon_used` | 200 |  | data{coupons, total, limit, offset, batches} | OK |
| GET | `m/bss/download_sample` | 200 |  | non-JSON (8000 bytes) |  |
| POST | `m/bss/generate_licence` | 200 |  | {type, text} | Customer not found. |
| GET | `m/bss/history` | 200 |  | data{requests, total, limit, offset} | OK |
| POST | `m/bss/import` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| GET | `m/bss/index` | 200 |  | data{total, pending, success, failed, customers} | OK |
| POST | `m/bss/info_change` | 422 |  | {status, message, data, code} | customer_id and fields{} are required. |
| GET | `m/bss/logs` | 200 |  | data{logs, total, limit, offset} | OK |
| POST | `m/bss/process_bulk_requests` | 200 | dry_run | data{fields} | POST with confirm=1 to process a chunk of the batch. |
| POST | `m/bss/process_bulk_requests/test` | 200 | dry_run | data{fields} | POST with confirm=1 to process a chunk of the batch. |
| POST | `m/bss/process_queue` | 200 | dry_run | data{fields, pending} | POST with confirm=1 to process a chunk of the licence queue. |
| POST | `m/bss/queue_process` | 200 | dry_run | data{fields, pending} | POST with confirm=1 to process a chunk of the licence queue. |
| GET | `m/bulkmsg/bulk_enquiry_call` | 200 |  | data{fields} | GET get_enquiry_call_customers to preview, POST initiate_enquiry_calls to run. |
| GET | `m/bulkmsg/get_bulk_msg_clients` | 200 |  | data{status, total, total_count, clients, filter, offset, limit} | OK |
| GET | `m/bulkmsg/get_enquiry_call_customers` | 200 |  | data{status, total, total_count, enquiries, filter, offset, limit} | OK |
| GET | `m/bulkmsg/get_renewal_call_customers` | 200 |  | data{status, total, total_count, customers, filter, offset, limit} | OK |
| GET | `m/bulkmsg/get_renewal_msg_customers` | 200 |  | data{status, total, total_count, customers, filter, offset, limit} | OK |
| POST | `m/bulkmsg/initiate_enquiry_calls` | 200 | dry_run | data{calls_made} | No eligible enquiries found. |
| POST | `m/bulkmsg/initiate_renewal_calls` | 200 | dry_run | data{calls_made, calls_failed, already_called, results} | Total: 20, Calls: 20, Failed: 0, Skipped: 0. |
| GET | `m/bulkmsg/renewal_bulk_call` | 200 |  | data{fields} | GET get_renewal_call_customers to preview, POST initiate_renewal_calls to run. |
| POST | `m/bulkmsg/send_bulk_client_messages` | 200 | dry_run | data{sent, failed, results} | Total: 20, Sent: 20, Failed: 0. |
| GET | `m/bulkmsg/send_bulk_msg` | 200 |  | data{fields} | GET get_bulk_msg_clients to preview, POST send_bulk_client_messages to run. |
| POST | `m/bulkmsg/send_renewal_messages` | 200 | dry_run | data{sent, failed, results} | Total: 20, Sent: 20, Failed: 0. |
| GET | `m/bulkmsg/send_renewal_msg` | 200 |  | data{fields} | GET get_renewal_msg_customers to preview, POST send_renewal_messages to run. |
| GET | `m/bulkqr` | 200 |  | data{customers, total, limit, offset} | OK |
| GET | `m/bulkqr/printBulk` | 200 |  | data{customers, total, limit, offset} | OK |
| GET | `m/callreport` | 200 |  | data{filters, endpoints} | Call reports. Staff see own calls; admins may pass usr. |
| GET | `m/callreport/details` | 200 |  | data{details, usr, from, to} | OK |
| GET | `m/callreport/index` | 200 |  | data{filters, endpoints} | Call reports. Staff see own calls; admins may pass usr. |
| GET | `m/callreport/list` | 200 |  | data{calls, total, limit, offset, usr, from, to} | OK |
| GET | `m/callreport/listSummery` | 200 |  | data{summary, usr, from, to} | OK |
| GET | `m/callreport/listall` | 200 |  | data{calls, total, limit, offset, usr, from, to} | OK |
| GET | `m/callreport/loadDetails` | 200 |  | data{details, usr, from, to} | OK |
| GET | `m/callreport/summary` | 200 |  | data{summary, usr, from, to} | OK |
| GET | `m/cmsdashboard` | 200 |  | data{counts, chart} | OK |
| GET | `m/cmsdashboard/index` | 200 |  | data{counts, chart} | OK |
| POST | `m/complaint` | 200 |  | data{complaints, total, limit, offset, current_status, show_all} | OK |
| POST | `m/complaint/add` | 422 |  | {type, text} | Please search and select a valid customer first |
| POST | `m/complaint/close` | 422 |  | {type, text} | Complaint ID required |
| POST | `m/complaint/customer_lookup` | 200 | customer_id | {status, customer_id, name, phone, email, city} |  |
| GET | `m/complaint/detail` | 422 |  | {status, message, data, code} | Complaint id is required (?id=). |
| GET | `m/complaint/detail/12` | 403 |  | {status, message, data, code} | Not authorized for this complaint. |
| POST | `m/complaint/list` | 200 |  | data{complaints, total, limit, offset, current_status, show_all} | OK |
| POST | `m/complaint/otp_generate` | 403 | cid | {status, message, data, code} | Not authorized for this complaint. |
| POST | `m/complaint/otp_verify` | 422 |  | {type, text} | Complaint ID and OTP are required |
| POST | `m/complaint/response` | 422 |  | {type, text} | Missing required fields |
| POST | `m/complaint/source` | 200 | cid | {source} |  |
| POST | `m/complaintmaster` | 200 |  | data{complaints, total, limit, offset, current_status, show_all} | OK |
| POST | `m/complaintmaster/addNew` | 422 |  | {type, text} | Please search and select a valid customer first |
| POST | `m/complaintmaster/closeComplaint` | 422 |  | {type, text} | Complaint ID required |
| POST | `m/complaintmaster/generateClosureOTP` | 403 | cid | {status, message, data, code} | Not authorized for this complaint. |
| POST | `m/complaintmaster/getComplaintSource` | 200 | cid | {source} |  |
| POST | `m/complaintmaster/getCustomerByID` | 200 | customer_id | {status, customer_id, name, phone, email, city} |  |
| GET | `m/complaintmaster/index` | 200 |  | data{complaints, total, limit, offset, current_status, show_all} | OK |
| POST | `m/complaintmaster/updateResponse` | 422 |  | {type, text} | Missing required fields |
| POST | `m/complaintmaster/verifyClosureOTP` | 422 |  | {type, text} | Complaint ID and OTP are required |
| POST | `m/customerdir` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| POST | `m/customerdir/bulk_upload` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| GET | `m/customerdir/index` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| POST | `m/customerdir/list` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| POST | `m/customerdir/listall` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| GET | `m/customerdir/qr_bulk` | 200 |  | data{customers, total, limit, offset} | OK |
| GET | `m/customerdir/whatsapp_list` | 200 |  | data{customers, total, limit, offset} | OK |
| GET | `m/customerpayments` | 200 |  | data{payments, total, limit, offset} | OK |
| POST | `m/customerpayments/getCustomerById` | 200 | customer_id | {status, customer} |  |
| POST | `m/customers` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| GET | `m/customers/addBulkFrm` | 200 |  | data{fields, format, scope, note} | OK |
| POST | `m/customers/addInBulk` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| GET | `m/customers/index` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| POST | `m/customers/listall` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| GET | `m/customers/sendWhatsApp` | 200 |  | data{customers, total, limit, offset} | OK |
| POST | `m/dashboard/index` | 200 |  | data{staff, counts, redirect} | OK |
| GET | `m/download` | 200 |  | non-JSON (6050 bytes) |  |
| GET | `m/emailautomation` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/emailautomation/index` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/emailautomation/logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/emailautomation/preview` | 200 |  | data{days_config, upcoming, total_eligible} | OK |
| POST | `m/emailautomation/save_settings` | 200 |  | data{saved} | Settings saved successfully! |
| POST | `m/emailautomation/send_reminders` | 200 | dry_run | data{sent, failed, skipped, results} | Sent: 27 / Failed: 0 / Skipped (already sent): 0. |
| POST | `m/emailautomation/send_test` | 200 | test_email | {status, message, data, code} | Test email sent. |
| GET | `m/employee` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/add` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/addNewFrm` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/addnew` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/chngUser` | — |  |  | SKIP: session-switch is meaningless stateless (doc G) |
| GET | `m/employee/detail` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/detail/1` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/index` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/list` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/listall` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/profile` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/update` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/emsdashboard` | 200 |  | data{staff, counts, targets, all_targets, charts} | OK |
| GET | `m/emsdashboard/index` | 200 |  | data{staff, counts, targets, all_targets, charts} | OK |
| GET | `m/enquiry` | 200 |  | data{enquiries, total, limit, offset, filters} | OK |
| POST | `m/enquiry/add` | 422 |  | {type, text} | sname and phone are required. |
| GET | `m/enquiry/addNewFrm` | 200 |  | data{fields, branches, defaults} | OK |
| POST | `m/enquiry/ai_call` | 422 | id | data[0] | Missing id or phone. |
| POST | `m/enquiry/bulk_upload` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| POST | `m/enquiry/call_end` | 200 | id | {status, message, data, code} | Call tracking ended. |
| POST | `m/enquiry/call_start` | 200 | id | data{id} | Call tracking started. |
| POST | `m/enquiry/check_mobile` | 200 | mobile | {exists} |  |
| GET | `m/enquiry/detail` | 422 |  | {status, message, data, code} | Enquiry id is required (?id=). |
| GET | `m/enquiry/detail/1` | 404 |  | {status, message, data, code} | Enquiry not found. |
| GET | `m/enquiry/list` | 200 |  | data{enquiries, total, limit, offset, filters} | OK |
| POST | `m/enquiry/notify` | 422 | id | {status, message, data, code} | bc is required. |
| POST | `m/enquiry/profile` | 422 |  | {status, message, data, code} | ecode is required. |
| POST | `m/enquiry/response` | 422 |  | {status, message, data, code} | ecode is required. |
| POST | `m/enquiry/status` | 422 |  | {status, message, data, code} | id is required. |
| POST | `m/enquiry/update` | 422 |  | {status, message, data, code} | ecode is required. |
| GET | `m/enquirymaster` | 200 |  | data{enquiries, total, limit, offset, filters} | OK |
| GET | `m/enquirymaster/addBulkFrm` | 200 |  | data{fields} | POST a spreadsheet with confirm=1 to bulk-import enquiries. |
| POST | `m/enquirymaster/addInBulk` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| POST | `m/enquirymaster/addInBulkMarg` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| POST | `m/enquirymaster/addNew` | 422 |  | {type, text} | sname and phone are required. |
| GET | `m/enquirymaster/addNewFrm` | 200 |  | data{fields, branches, defaults} | OK |
| POST | `m/enquirymaster/ai_call` | 422 | id | data[0] | Missing id or phone. |
| POST | `m/enquirymaster/changeStatus` | 422 |  | {status, message, data, code} | id is required. |
| POST | `m/enquirymaster/checkMobile` | 200 | mobile | {exists} |  |
| POST | `m/enquirymaster/endCallRecord` | 200 | id | {status, message, data, code} | Call tracking ended. |
| GET | `m/enquirymaster/enquiry_update` | 422 |  | {status, message, data, code} | Enquiry id is required (?id=). |
| GET | `m/enquirymaster/enquiry_update/1` | 404 |  | {status, message, data, code} | Enquiry not found. |
| GET | `m/enquirymaster/index` | 200 |  | data{enquiries, total, limit, offset, filters} | OK |
| GET | `m/enquirymaster/listall` | 200 |  | data{enquiries, total, limit, offset, filters} | OK |
| GET | `m/enquirymaster/notifications` | 200 |  | data{notifications, total, limit} | OK |
| GET | `m/enquirymaster/profile` | 422 |  | {status, message, data, code} | Enquiry id is required (?id=). |
| POST | `m/enquirymaster/pushCallRecord` | 200 | id | data{id} | Call tracking started. |
| POST | `m/enquirymaster/pushNotify` | 422 | id | {status, message, data, code} | bc is required. |
| GET | `m/enquirymaster/response` | 422 |  | {status, message, data, code} | Enquiry id is required (?id=). |
| POST | `m/enquirymaster/update` | 422 |  | {status, message, data, code} | ecode is required. |
| POST | `m/enquirymaster/updateResponse` | 422 |  | {status, message, data, code} | ecode is required. |
| GET | `m/enquirymaster/uploadDoc` | 200 |  | data{fields} | POST a spreadsheet with confirm=1 to bulk-import enquiries. |
| GET | `m/eventreg/index` | 200 |  | data{registrations, total, available} | Event registration module is not installed. |
| POST | `m/eventreg/listBrnach` | 200 |  | data{branches} | OK |
| GET | `m/eventreg/listall` | 200 |  | data{registrations, total, available} | Event registration module is not installed. |
| GET | `m/events/addNewFrm` | 200 |  | data{fields, statuses, available} | OK |
| POST | `m/events/addNewFrmGall` | 200 |  | data{fields, types, available} | OK |
| POST | `m/events/addnew` | 422 |  | {type, text} | ttl and loc are required. |
| POST | `m/events/addnewGall` | 422 |  | {type, text} | eid and gttl are required. |
| POST | `m/events/changeStatus` | 422 |  | {type, text} | id is required. |
| POST | `m/events/changeStatusGall` | 422 |  | {type, text} | id is required. |
| POST | `m/events/del` | 422 |  | {type, text} | id is required. |
| POST | `m/events/delGall` | 422 |  | {type, text} | id is required. |
| POST | `m/events/gallery` | 200 |  | data{gallery, total, available} | Gallery module is not installed. |
| GET | `m/events/index` | 200 |  | data{events, total, available} | Events module is not installed. |
| GET | `m/events/listall` | 200 |  | data{events, total, available} | Events module is not installed. |
| POST | `m/events/profile` | 422 |  | {type, text} | ecode is required. |
| POST | `m/events/profileGall` | 422 |  | {type, text} | gid is required. |
| POST | `m/events/update` | 422 |  | {type, text} | ecode is required. |
| POST | `m/events/updateGall` | 422 |  | {type, text} | gid is required. |
| GET | `m/excel_export/index` | 200 |  | non-JSON (6050 bytes) |  |
| GET | `m/export/cms` | 200 |  | data{counts, chart} | OK |
| GET | `m/export/download` | 200 |  | non-JSON (6052 bytes) |  |
| GET | `m/jobadmin/all_jobs` | 200 |  | data{jobs, limit, offset} | OK |
| GET | `m/jobadmin/audit_logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/jobadmin/categories` | 200 |  | data{categories} | OK |
| GET | `m/jobadmin/chart_data` | 200 |  | data[12] | OK |
| GET | `m/jobadmin/chart_data/test` | 422 |  | data[0] | Invalid type. |
| GET | `m/jobadmin/companies` | 200 |  | data{companies, limit, offset} | OK |
| GET | `m/jobadmin/dashboard` | 200 |  | data{stats, monthly, recent_jobs, latest_seekers, top_categories} | OK |
| GET | `m/jobadmin/email_templates` | 200 |  | data{templates} | OK |
| GET | `m/jobadmin/export` | 404 |  | {status, message, data, code} | No data to export. |
| GET | `m/jobadmin/export/test` | 404 |  | {status, message, data, code} | No data to export. |
| GET | `m/jobadmin/pending_jobs` | 200 |  | data{jobs, limit, offset} | OK |
| GET | `m/jobadmin/reports` | 200 |  | data{type, rows} | OK |
| GET | `m/jobadmin/reports/test` | 200 |  | data{type, rows} | OK |
| GET | `m/jobadmin/seekers` | 200 |  | data{seekers, limit, offset} | OK |
| POST | `m/jobadmin/settings` | 403 |  | {status, message, data, code} | Admin access required. |
| GET | `m/jobadmin/skills` | 200 |  | data{skills, categories} | OK |
| GET | `m/jobportal/admin/all_jobs` | 200 |  | data{jobs, limit, offset} | OK |
| GET | `m/jobportal/admin/audit_logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/jobportal/admin/categories` | 200 |  | data{categories} | OK |
| POST | `m/jobportal/admin/category_get/1` | 200 | id | data{category} | OK |
| GET | `m/jobportal/admin/chart_data/test` | 422 |  | data[0] | Invalid type. |
| GET | `m/jobportal/admin/companies` | 200 |  | data{companies, limit, offset} | OK |
| GET | `m/jobportal/admin/dashboard` | 200 |  | data{stats, monthly, recent_jobs, latest_seekers, top_categories} | OK |
| GET | `m/jobportal/admin/email_templates` | 200 |  | data{templates} | OK |
| GET | `m/jobportal/admin/export` | 404 |  | {status, message, data, code} | No data to export. |
| GET | `m/jobportal/admin/export/test` | 404 |  | {status, message, data, code} | No data to export. |
| GET | `m/jobportal/admin/pending_jobs` | 200 |  | data{jobs, limit, offset} | OK |
| GET | `m/jobportal/admin/profile` | 200 |  | data{stats, monthly, recent_jobs, latest_seekers, top_categories} | OK |
| GET | `m/jobportal/admin/reports` | 200 |  | data{type, rows} | OK |
| GET | `m/jobportal/admin/reports/test` | 200 |  | data{type, rows} | OK |
| GET | `m/jobportal/admin/seekers` | 200 |  | data{seekers, limit, offset} | OK |
| POST | `m/jobportal/admin/settings` | 403 |  | {status, message, data, code} | Admin access required. |
| GET | `m/jobportal/admin/skills` | 200 |  | data{skills, categories} | OK |
| GET | `m/mail` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/mail/index` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/mail/logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/mail/preview` | 200 |  | data{days_config, upcoming, total_eligible} | OK |
| POST | `m/mail/save_settings` | 200 |  | data{saved} | Settings saved successfully! |
| POST | `m/mail/send_reminders` | 200 | dry_run | data{sent, failed, skipped, results} | Sent: 27 / Failed: 0 / Skipped (already sent): 0. |
| POST | `m/mail/send_test` | 200 | test_email | {status, message, data, code} | Test email sent. |
| GET | `m/msg/email_logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/msg/email_preview` | 200 |  | data{days, samples} | OK |
| POST | `m/msg/email_test` | 502 | test_email | {status, message, data, code} | SMTP send failed. |
| GET | `m/msg/wa_download_unverified` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/msg/wa_logs` | 200 |  | data{logs, total, limit, offset} | OK |
| POST | `m/msg/wa_mark_sent` | 200 |  | data{status} | OK |
| GET | `m/msg/wa_preview` | 200 |  | data{days, samples} | OK |
| GET | `m/msg/wa_stats` | 200 |  | data{total, whatsapp_yes, whatsapp_no, msg_sent, pending} | OK |
| POST | `m/msg/wa_test` | 502 | test_number | {status, message, data, code} | WhatsApp send failed. |
| GET | `m/notifications` | 200 |  | data{notifications, total, page, per_page} | OK |
| GET | `m/notifications/get_unread` | 200 |  | {count, notifications} |  |
| GET | `m/notifications/listing` | 200 |  | data{notifications, total, page, per_page} | OK |
| POST | `m/notifications/mark_all_read` | 200 |  | {success, count} |  |
| POST | `m/notifications/mark_read` | 422 |  | {status, message, data, code} | Invalid notification ID. |
| GET | `m/notify` | 200 |  | data{notifications, total, page, per_page} | OK |
| GET | `m/notify/get_unread` | 200 |  | {count, notifications} |  |
| GET | `m/notify/listing` | 200 |  | data{notifications, total, page, per_page} | OK |
| POST | `m/notify/mark_all_read` | 200 |  | {success, count} |  |
| POST | `m/notify/mark_read` | 422 |  | {status, message, data, code} | Invalid notification ID. |
| GET | `m/payments` | 200 |  | data{payments, total, limit, offset} | OK |
| POST | `m/payments/customer_lookup` | 200 | customer_id | {status, customer} |  |
| GET | `m/payments/detail` | 422 |  | {status, message, data, code} | Payment id is required (?id=). |
| GET | `m/payments/detail/0` | 422 |  | {status, message, data, code} | Payment id is required (?id=). |
| GET | `m/payments/list` | 200 |  | data{payments, total, limit, offset} | OK |
| GET | `m/payments/listall` | 200 |  | data{payments, total, limit, offset} | OK |
| GET | `m/profile` | 200 |  | data{branch} | OK |
| GET | `m/profile/index` | 200 |  | data{branch} | OK |
| POST | `m/profile/update` | 422 |  | {type, text} | No profile fields provided. |
| POST | `m/qrfield/assignment_done` | 422 |  | {type, text} | assignment_id is required. |
| GET | `m/qrfield/batch_count` | 200 |  | {count} |  |
| GET | `m/qrfield/batches` | 200 |  | data[2] | OK |
| POST | `m/qrfield/customer_done` | 422 |  | {type, text} | progress_id is required. |
| POST | `m/qrfield/customers` | 422 |  | {status, message, data, code} | assignment_id is required. |
| GET | `m/qrfield/employees` | 200 |  | data[39] | OK |
| GET | `m/qrfield/notif_count` | 200 |  | {count} |  |
| POST | `m/qrfield/notif_read` | 422 |  | {type, text} | id is required. |
| GET | `m/qrfield/notifications` | 200 |  | data[0] | OK |
| GET | `m/qrfield/tasks` | 200 |  | data{assignments} | OK |
| GET | `m/qrinfo/employeeBatchCount` | 200 |  | {count} |  |
| GET | `m/qrinfo/employeeTasks` | 200 |  | data{assignments} | OK |
| GET | `m/qrinfo/getBatchesDropdown` | 200 |  | data[2] | OK |
| GET | `m/qrinfo/getEmployees` | 200 |  | data[39] | OK |
| POST | `m/qrinfo/getTaskCustomers` | 422 |  | {status, message, data, code} | assignment_id is required. |
| POST | `m/qrinfo/markAssignmentComplete` | 422 |  | {type, text} | assignment_id is required. |
| POST | `m/qrinfo/markCustomerComplete` | 422 |  | {type, text} | progress_id is required. |
| POST | `m/qrinfo/markNotificationRead` | 422 |  | {type, text} | id is required. |
| GET | `m/qrinfo/myNotifications` | 200 |  | data[0] | OK |
| GET | `m/qrinfo/myTasks` | 200 |  | data{assignments} | OK |
| GET | `m/qrinfo/notificationCount` | 200 |  | {count} |  |
| GET | `m/renewal` | 200 |  | data{month, is_admin, section_b, chart_12m, import_logs, months, branch, month_summary} | OK |
| POST | `m/renewal/auto_ai_calls` | 200 | dry_run | data{calls_made} | No pending renewal customers with phone numbers found. |
| GET | `m/renewal/export_csv` | 200 |  | non-JSON (147 bytes) |  |
| GET | `m/renewal/get_chart_data` | 200 |  | data[6] | OK |
| GET | `m/renewal/get_detail_records` | 200 |  | data{data, count, section} | OK |
| POST | `m/renewal/import` | 422 |  | {status, message, data, code} | File upload failed (field import_file). |
| POST | `m/renewal/import_confirm` | 200 |  | data{fields} | Run import_preview first, then POST the file again with column indexes + confirm=1. |
| POST | `m/renewal/import_preview` | 422 |  | {status, message, data, code} | File upload failed (field import_file). |
| GET | `m/renewal/index` | 200 |  | data{month, is_admin, section_b, chart_12m, import_logs, months, branch, month_summary} | OK |
| GET | `m/renewal/records_list` | 200 |  | data{month, type, records, total, limit, offset} | OK |
| GET | `m/renewal/report_advance` | 200 |  | data{month, advance} | OK |
| GET | `m/renewal/report_branch_wise` | 200 |  | data{month, rows} | OK |
| GET | `m/renewal/report_employee_wise` | 200 |  | data{month, rows} | OK |
| GET | `m/renewal/report_monthly_targets` | 200 |  | data{year, targets} | OK |
| GET | `m/renewal/report_pending` | 200 |  | data{month, pending} | OK |
| GET | `m/renewal/report_pending_completed` | 200 |  | data{month, rows} | OK |
| GET | `m/renewal/report_performance` | 200 |  | data{months, performance} | OK |
| GET | `m/renewal/target_set` | 200 |  | data{month, users, user_targets, months} | OK |
| GET | `m/reports` | 200 |  | data{sales_summary, amc_summary, customer_summary, enquiry_summary, monthly_sales, monthly_amc, customer_status} | OK |
| GET | `m/reports/amc` | 200 |  | data{selected_month, selected_year, amc_summary, monthly_trend, employee_amc} | OK |
| GET | `m/reports/customer_list/test` | 200 |  | data{status_filter, customers, total, limit, offset} | OK |
| GET | `m/reports/customers` | 200 |  | data{customer_summary, status_distribution, city_distribution, software_type, software_trade, monthly_growth, subpartner_summary} | OK |
| GET | `m/reports/edition_customers/test` | 200 |  | data{type, customers, total, limit, offset} | OK |
| GET | `m/reports/export_customers` | 200 |  | non-JSON (342 bytes) |  |
| GET | `m/reports/export_sales` | 200 |  | non-JSON (91 bytes) |  |
| GET | `m/reports/get_chart_data` | 422 |  | data[0] | Invalid chart type. |
| GET | `m/reports/index` | 200 |  | data{sales_summary, amc_summary, customer_summary, enquiry_summary, monthly_sales, monthly_amc, customer_status} | OK |
| GET | `m/reports/pincode_customers/test` | 200 |  | data{pincode, customers, total, limit, offset} | OK |
| GET | `m/reports/sales` | 200 |  | data{selected_month, selected_year, sales_summary, monthly_trend, daily_sales, employee_sales} | OK |
| GET | `m/reports/subpartner_parties/test` | 200 |  | data{subpartner_code, subpartner_name, parties} | OK |
| GET | `m/reports/trade_customers/test` | 200 |  | data{trade, customers, total, limit, offset} | OK |
| GET | `m/sitecontent/index` | 200 |  | data{content, items, available} | OK |
| GET | `m/task` | 200 |  | data{tasks, total, limit, offset, can_edit_all} | OK |
| GET | `m/task/get_task/1` | 200 |  | data{id, tenant_code, title, description, assigned_to, assigned_by, priority, status…} | OK |
| GET | `m/task/listall` | 200 |  | data{tasks, total, limit, offset, can_edit_all} | OK |
| POST | `m/task/update_status` | 422 |  | {type, text} | id is required. |
| GET | `m/tasks` | 200 |  | data{tasks, total, limit, offset, can_edit_all} | OK |
| GET | `m/tasks/get_task/1` | 200 |  | data{id, tenant_code, title, description, assigned_to, assigned_by, priority, status…} | OK |
| GET | `m/tasks/index` | 200 |  | data{tasks, total, limit, offset, can_edit_all} | OK |
| GET | `m/tasks/listall` | 200 |  | data{tasks, total, limit, offset, can_edit_all} | OK |
| POST | `m/tasks/update_status` | 422 |  | {type, text} | id is required. |
| GET | `m/waauto` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/waauto/index` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/waauto/logs` | 200 |  | data{logs, total, page, per_page} | OK |
| GET | `m/waauto/preview` | 200 |  | data{days_config, upcoming, total_eligible} | OK |
| POST | `m/waauto/send_birthday_wishes` | 200 | dry_run | data{sent, failed, skipped, results} | Dry run complete. |
| POST | `m/waauto/send_campaign` | 422 | dry_run | data[0] | template_id or custom_message is required. |
| POST | `m/waauto/send_reminders` | 200 | dry_run | data{sent, failed, skipped, results} | Dry run complete. |
| POST | `m/waauto/send_test` | 502 | test_number | data[0] | Send failed: Your instance has been Stopped due to non-payment. you can activate this inst |
| POST | `m/waauto/trigger_complaint_notification` | 422 |  | {status, message, data, code} | number, name, complaint_id are required. |
| POST | `m/waauto/trigger_enquiry_acknowledgment` | 422 |  | {status, message, data, code} | number, name, enquiry_id are required. |
| POST | `m/waauto/trigger_payment_receipt` | 422 |  | {status, message, data, code} | number, name, amount, purpose, receipt_no are required. |
| GET | `m/whatsapp_automation` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/whatsapp_automation/index` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/whatsapp_automation/logs` | 200 |  | data{logs, total, page, per_page} | OK |
| GET | `m/whatsapp_automation/preview` | 200 |  | data{days_config, upcoming, total_eligible} | OK |
| POST | `m/whatsapp_automation/send_birthday_wishes` | 200 | dry_run | data{sent, failed, skipped, results} | Dry run complete. |
| POST | `m/whatsapp_automation/send_campaign` | 422 | dry_run | data[0] | template_id or custom_message is required. |
| POST | `m/whatsapp_automation/send_reminders` | 200 | dry_run | data{sent, failed, skipped, results} | Dry run complete. |
| POST | `m/whatsapp_automation/send_test` | 502 | test_number | data[0] | Send failed: Your instance has been Stopped due to non-payment. you can activate this inst |
| POST | `m/whatsapp_automation/trigger_complaint_notification` | 422 |  | {status, message, data, code} | number, name, complaint_id are required. |
| POST | `m/whatsapp_automation/trigger_enquiry_acknowledgment` | 422 |  | {status, message, data, code} | number, name, enquiry_id are required. |
| POST | `m/whatsapp_automation/trigger_payment_receipt` | 422 |  | {status, message, data, code} | number, name, amount, purpose, receipt_no are required. |
| GET | `m/whatsapp_campaign/download_unverified` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/whatsapp_campaign/get_stats` | 200 |  | data{total, whatsapp_yes, whatsapp_no, msg_sent, pending} | OK |
| GET | `m/whatsapp_campaign/index` | 200 |  | data{total, whatsapp_yes, whatsapp_no, msg_sent, pending} | OK |
| GET | `m/whatsapp_campaign/load_numbers` | 200 |  | data{numbers, limit, offset} | OK |
| POST | `m/whatsapp_campaign/mark_sent` | 200 |  | data{status} | OK |
| POST | `m/auth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |
| POST | `m/customerauth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |
| POST | `m/jobportal/auth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |

## Branch admin (`user_type: staff`, role 1)

| Method | Path | Status | Request fields seen | Response shape | Message / note |
|---|---|---|---|---|---|
| POST | `m/auth/login` | 200 | identifier, password, login_type | data{user_type, user_id, name, email, tenant_code, force_change, access_token, refresh_token…} | Login successful. |
| POST | `m/auth/refresh` | 200 | refresh_token | data{access_token, refresh_token, expires_in, token_type} | Token refreshed. |
| GET | `m/auth/me` | 200 |  | data{user_type, user_id, tenant_code, name, email, branch_name} | OK |
| GET | `m/approvals` | 200 |  | data{pending_requests, total, limit, offset} | OK |
| POST | `m/approvals/approve` | 422 |  | {status, message, data, code} | Customer ID is required. |
| GET | `m/approvals/pending` | 200 |  | data{pending_requests, total, limit, offset} | OK |
| POST | `m/approvals/reject` | 422 |  | {status, message, data, code} | Customer ID is required. |
| GET | `m/bi` | 200 |  | data{charts} | Pass ?type= (see charts list) with optional year/months/start/end. |
| GET | `m/bi/chart_data` | 422 |  | data[0] | Invalid type. |
| GET | `m/bi/index` | 200 |  | data{charts} | Pass ?type= (see charts list) with optional year/months/start/end. |
| GET | `m/bidashboard` | 200 |  | data{charts} | Pass ?type= (see charts list) with optional year/months/start/end. |
| GET | `m/bidashboard/chart_data` | 422 |  | data[0] | Invalid type. |
| GET | `m/bidashboard/index` | 200 |  | data{charts} | Pass ?type= (see charts list) with optional year/months/start/end. |
| GET | `m/branch` | 200 |  | data{branches, total, limit, offset} | OK |
| POST | `m/branch/add` | 422 |  | {type, text} | unm and psw are required. |
| POST | `m/branch/addnew` | 422 |  | {type, text} | unm and psw are required. |
| POST | `m/branch/changeStatus` | 422 |  | {status, message, data, code} | id is required. |
| POST | `m/branch/del` | 422 |  | {status, message, data, code} | id is required. |
| GET | `m/branch/detail` | 422 |  | {status, message, data, code} | Branch id is required (?id=). |
| GET | `m/branch/detail/48` | 200 |  | data{branch} | OK |
| GET | `m/branch/list` | 200 |  | data{branches, total, limit, offset} | OK |
| GET | `m/branch/listall` | 200 |  | data{branches, total, limit, offset} | OK |
| POST | `m/branch/perm_view` | 200 | id | non-JSON (8000 bytes) |  |
| POST | `m/branch/permissions` | 200 | id | non-JSON (8000 bytes) |  |
| POST | `m/branch/save_permissions` | 422 |  | {status, message, data, code} | bcode is required. |
| POST | `m/branch/status` | 422 |  | {status, message, data, code} | id is required. |
| POST | `m/branch/update` | 422 |  | {status, message, data, code} | bcode is required. |
| GET | `m/branches` | 200 |  | data{branches, total, limit, offset} | OK |
| GET | `m/branches/addNewFrm` | 200 |  | data{fields, roles, defaults} | OK |
| POST | `m/branches/addnew` | 422 |  | {type, text} | unm and psw are required. |
| POST | `m/branches/changeStatus` | 422 |  | {status, message, data, code} | id is required. |
| POST | `m/branches/chngBrnch` | — |  |  | SKIP: session-switch meaningless stateless (doc G) |
| POST | `m/branches/del` | 422 |  | {status, message, data, code} | id is required. |
| GET | `m/branches/index` | 200 |  | data{branches, total, limit, offset} | OK |
| GET | `m/branches/listall` | 200 |  | data{branches, total, limit, offset} | OK |
| POST | `m/branches/perm_view` | 200 | id | non-JSON (8000 bytes) |  |
| POST | `m/branches/profile` | 422 | id | {type, text} | No branch fields provided. |
| POST | `m/branches/save_permissions` | 422 |  | {status, message, data, code} | bcode is required. |
| POST | `m/branches/update` | 422 |  | {status, message, data, code} | bcode is required. |
| GET | `m/bss` | 200 |  | data{total, pending, success, failed, customers} | OK |
| GET | `m/bss/api_status` | 200 |  | data{online, http_code} | BSS service unreachable. |
| POST | `m/bss/bulk_generate` | 200 |  | {type, text, created, skipped} | 0 requests created. |
| GET | `m/bss/bulk_list` | 200 |  | data{pending, batches} | OK |
| POST | `m/bss/bulk_new` | 422 |  | {status, message, data, code} | Please select a file to upload (field excel_file). |
| POST | `m/bss/bulk_new_licence` | 422 |  | {status, message, data, code} | Please select a file to upload (field excel_file). |
| POST | `m/bss/bulk_process` | 200 | dry_run | data{fields} | POST with confirm=1 to process a chunk of the batch. |
| POST | `m/bss/bulk_process/1` | 200 | dry_run | data{fields} | POST with confirm=1 to process a chunk of the batch. |
| GET | `m/bss/check_wallet/1000336` | 200 |  | data{found, customer_id, party_name, mobile, sw_type, city, address, wallet_id} | OK |
| POST | `m/bss/coupon_confirm` | 200 |  | data{fields} | Run coupon_preview first, then POST the file again with column indexes + confirm=1. |
| POST | `m/bss/coupon_direct` | 200 |  | data{fields} | POST the file with confirm=1. Columns auto-detected from headers. |
| POST | `m/bss/coupon_import_confirm` | 200 |  | data{fields} | Run coupon_preview first, then POST the file again with column indexes + confirm=1. |
| POST | `m/bss/coupon_import_direct` | 200 |  | data{fields} | POST the file with confirm=1. Columns auto-detected from headers. |
| POST | `m/bss/coupon_import_preview` | 422 |  | {status, message, data, code} | File upload failed (field import_file). |
| POST | `m/bss/coupon_preview` | 422 |  | {status, message, data, code} | File upload failed (field import_file). |
| GET | `m/bss/coupon_used` | 200 |  | data{coupons, total, limit, offset, batches} | OK |
| GET | `m/bss/credentials` | 200 |  | data{has_credentials, bss_username, bss_url, has_password, updated_at} | OK |
| GET | `m/bss/download_sample` | 200 |  | non-JSON (8000 bytes) |  |
| POST | `m/bss/generate_licence` | 200 |  | {type, text} | Customer not found. |
| GET | `m/bss/history` | 200 |  | data{requests, total, limit, offset} | OK |
| POST | `m/bss/import` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| GET | `m/bss/index` | 200 |  | data{total, pending, success, failed, customers} | OK |
| POST | `m/bss/info_change` | 422 |  | {status, message, data, code} | customer_id and fields{} are required. |
| GET | `m/bss/logs` | 200 |  | data{logs, total, limit, offset} | OK |
| POST | `m/bss/process_bulk_requests` | 200 | dry_run | data{fields} | POST with confirm=1 to process a chunk of the batch. |
| POST | `m/bss/process_bulk_requests/test` | 200 | dry_run | data{fields} | POST with confirm=1 to process a chunk of the batch. |
| POST | `m/bss/process_queue` | 200 | dry_run | data{fields, pending} | POST with confirm=1 to process a chunk of the licence queue. |
| POST | `m/bss/queue_process` | 200 | dry_run | data{fields, pending} | POST with confirm=1 to process a chunk of the licence queue. |
| GET | `m/bulkmsg/bulk_enquiry_call` | 200 |  | data{fields} | GET get_enquiry_call_customers to preview, POST initiate_enquiry_calls to run. |
| GET | `m/bulkmsg/get_bulk_msg_clients` | 200 |  | data{status, total, total_count, clients, filter, offset, limit} | OK |
| GET | `m/bulkmsg/get_enquiry_call_customers` | 200 |  | data{status, total, total_count, enquiries, filter, offset, limit} | OK |
| GET | `m/bulkmsg/get_renewal_call_customers` | 200 |  | data{status, total, total_count, customers, filter, offset, limit} | OK |
| GET | `m/bulkmsg/get_renewal_msg_customers` | 200 |  | data{status, total, total_count, customers, filter, offset, limit} | OK |
| POST | `m/bulkmsg/initiate_enquiry_calls` | 200 | dry_run | data{calls_made} | No eligible enquiries found. |
| POST | `m/bulkmsg/initiate_renewal_calls` | 200 | dry_run | data{calls_made, calls_failed, already_called, results} | Total: 20, Calls: 20, Failed: 0, Skipped: 0. |
| GET | `m/bulkmsg/renewal_bulk_call` | 200 |  | data{fields} | GET get_renewal_call_customers to preview, POST initiate_renewal_calls to run. |
| POST | `m/bulkmsg/send_bulk_client_messages` | 200 | dry_run | data{sent, failed, results} | Total: 20, Sent: 20, Failed: 0. |
| GET | `m/bulkmsg/send_bulk_msg` | 200 |  | data{fields} | GET get_bulk_msg_clients to preview, POST send_bulk_client_messages to run. |
| POST | `m/bulkmsg/send_renewal_messages` | 200 | dry_run | data{sent, failed, results} | Total: 20, Sent: 20, Failed: 0. |
| GET | `m/bulkmsg/send_renewal_msg` | 200 |  | data{fields} | GET get_renewal_msg_customers to preview, POST send_renewal_messages to run. |
| GET | `m/bulkqr` | 200 |  | data{customers, total, limit, offset} | OK |
| GET | `m/bulkqr/printBulk` | 200 |  | data{customers, total, limit, offset} | OK |
| GET | `m/callreport` | 200 |  | data{filters, endpoints} | Call reports. Staff see own calls; admins may pass usr. |
| GET | `m/callreport/details` | 200 |  | data{details, usr, from, to} | OK |
| GET | `m/callreport/index` | 200 |  | data{filters, endpoints} | Call reports. Staff see own calls; admins may pass usr. |
| GET | `m/callreport/list` | 200 |  | data{calls, total, limit, offset, usr, from, to} | OK |
| GET | `m/callreport/listSummery` | 200 |  | data{summary, usr, from, to} | OK |
| GET | `m/callreport/listall` | 200 |  | data{calls, total, limit, offset, usr, from, to} | OK |
| GET | `m/callreport/loadDetails` | 200 |  | data{details, usr, from, to} | OK |
| GET | `m/callreport/summary` | 200 |  | data{summary, usr, from, to} | OK |
| GET | `m/cmsdashboard` | 200 |  | data{counts, chart} | OK |
| GET | `m/cmsdashboard/index` | 200 |  | data{counts, chart} | OK |
| POST | `m/complaint` | 200 |  | data{complaints, total, limit, offset, current_status, show_all} | OK |
| POST | `m/complaint/add` | 422 |  | {type, text} | Please search and select a valid customer first |
| POST | `m/complaint/assign` | 422 |  | {type, text} | Missing required fields |
| POST | `m/complaint/close` | 422 |  | {type, text} | Complaint ID required |
| POST | `m/complaint/customer_lookup` | 200 | customer_id | {status, customer_id, name, phone, email, city} |  |
| GET | `m/complaint/detail` | 422 |  | {status, message, data, code} | Complaint id is required (?id=). |
| GET | `m/complaint/detail/14` | 404 |  | {status, message, data, code} | Complaint not found. |
| POST | `m/complaint/list` | 200 |  | data{complaints, total, limit, offset, current_status, show_all} | OK |
| POST | `m/complaint/otp_generate` | 404 | cid | {type, text} | Complaint not found |
| POST | `m/complaint/otp_verify` | 422 |  | {type, text} | Complaint ID and OTP are required |
| POST | `m/complaint/response` | 422 |  | {type, text} | Missing required fields |
| POST | `m/complaint/source` | 200 | cid | {source} |  |
| POST | `m/complaintmaster` | 200 |  | data{complaints, total, limit, offset, current_status, show_all} | OK |
| POST | `m/complaintmaster/addNew` | 422 |  | {type, text} | Please search and select a valid customer first |
| POST | `m/complaintmaster/assignComplaint` | 422 |  | {type, text} | Missing required fields |
| POST | `m/complaintmaster/closeComplaint` | 422 |  | {type, text} | Complaint ID required |
| POST | `m/complaintmaster/generateClosureOTP` | 404 | cid | {type, text} | Complaint not found |
| POST | `m/complaintmaster/getComplaintSource` | 200 | cid | {source} |  |
| POST | `m/complaintmaster/getCustomerByID` | 200 | customer_id | {status, customer_id, name, phone, email, city} |  |
| GET | `m/complaintmaster/index` | 200 |  | data{complaints, total, limit, offset, current_status, show_all} | OK |
| POST | `m/complaintmaster/updateResponse` | 422 |  | {type, text} | Missing required fields |
| POST | `m/complaintmaster/verifyClosureOTP` | 422 |  | {type, text} | Complaint ID and OTP are required |
| POST | `m/customerdir` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| POST | `m/customerdir/bulk_upload` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| GET | `m/customerdir/index` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| POST | `m/customerdir/list` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| POST | `m/customerdir/listall` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| GET | `m/customerdir/qr_bulk` | 200 |  | data{customers, total, limit, offset} | OK |
| GET | `m/customerdir/whatsapp_list` | 200 |  | data{customers, total, limit, offset} | OK |
| GET | `m/customerpayments` | 200 |  | data{payments, total, limit, offset} | OK |
| POST | `m/customerpayments/add` | 422 |  | {status, message} | All required fields must be filled |
| POST | `m/customerpayments/delete/999999` | 404 |  | {status, message} | Payment not found |
| POST | `m/customerpayments/edit/999999` | 404 |  | {status, message} | Payment not found |
| POST | `m/customerpayments/getCustomerById` | 200 | customer_id | {status, customer} |  |
| POST | `m/customers` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| GET | `m/customers/addBulkFrm` | 200 |  | data{fields, format, scope, note} | OK |
| POST | `m/customers/addInBulk` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| GET | `m/customers/index` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| POST | `m/customers/listall` | 200 |  | data{customers, total, page, per_page, total_pages} | OK |
| GET | `m/customers/sendWhatsApp` | 200 |  | data{customers, total, limit, offset} | OK |
| POST | `m/dashboard/index` | 200 |  | data{staff, counts, redirect} | OK |
| GET | `m/download` | 200 |  | non-JSON (6047 bytes) |  |
| GET | `m/emailautomation` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/emailautomation/index` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/emailautomation/logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/emailautomation/preview` | 200 |  | data{days_config, upcoming, total_eligible} | OK |
| POST | `m/emailautomation/save_settings` | 200 |  | data{saved} | Settings saved successfully! |
| POST | `m/emailautomation/send_reminders` | 200 | dry_run | data{sent, failed, skipped, results} | Sent: 27 / Failed: 0 / Skipped (already sent): 0. |
| POST | `m/emailautomation/send_test` | 200 | test_email | {status, message, data, code} | Test email sent. |
| GET | `m/employee` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/add` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/addNewFrm` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/addnew` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/changeStatus` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/chngUser` | — |  |  | SKIP: session-switch meaningless stateless (doc G) |
| POST | `m/employee/del` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/detail` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/detail/1` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/index` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/list` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/employee/listall` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/profile` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/status` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| POST | `m/employee/update` | 503 |  | {status, message, data, code} | Employee module is unavailable (empmaster table missing). |
| GET | `m/emsdashboard` | 200 |  | data{staff, counts, targets, all_targets, charts} | OK |
| GET | `m/emsdashboard/index` | 200 |  | data{staff, counts, targets, all_targets, charts} | OK |
| GET | `m/enquiry` | 200 |  | data{enquiries, total, limit, offset, filters} | OK |
| POST | `m/enquiry/add` | 422 |  | {type, text} | sname and phone are required. |
| GET | `m/enquiry/addNewFrm` | 200 |  | data{fields, branches, defaults} | OK |
| POST | `m/enquiry/ai_call` | 422 | id | data[0] | Missing id or phone. |
| POST | `m/enquiry/bulk_upload` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| POST | `m/enquiry/call_end` | 404 | id | {status, message, data, code} | No active call record found. |
| POST | `m/enquiry/call_start` | 200 | id | data{id} | Call tracking started. |
| POST | `m/enquiry/check_mobile` | 200 | mobile | {exists} |  |
| POST | `m/enquiry/del` | 422 |  | {status, message, data, code} | id is required. |
| GET | `m/enquiry/detail` | 422 |  | {status, message, data, code} | Enquiry id is required (?id=). |
| GET | `m/enquiry/detail/1` | 404 |  | {status, message, data, code} | Enquiry not found. |
| GET | `m/enquiry/list` | 200 |  | data{enquiries, total, limit, offset, filters} | OK |
| POST | `m/enquiry/notify` | 422 | id | {status, message, data, code} | bc is required. |
| POST | `m/enquiry/profile` | 422 |  | {status, message, data, code} | ecode is required. |
| POST | `m/enquiry/response` | 422 |  | {status, message, data, code} | ecode is required. |
| POST | `m/enquiry/status` | 422 |  | {status, message, data, code} | id is required. |
| POST | `m/enquiry/update` | 422 |  | {status, message, data, code} | ecode is required. |
| GET | `m/enquirymaster` | 200 |  | data{enquiries, total, limit, offset, filters} | OK |
| GET | `m/enquirymaster/addBulkFrm` | 200 |  | data{fields} | POST a spreadsheet with confirm=1 to bulk-import enquiries. |
| POST | `m/enquirymaster/addInBulk` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| POST | `m/enquirymaster/addInBulkMarg` | 422 |  | {status, message, data, code} | Bulk import needs confirm=1. |
| POST | `m/enquirymaster/addNew` | 422 |  | {type, text} | sname and phone are required. |
| GET | `m/enquirymaster/addNewFrm` | 200 |  | data{fields, branches, defaults} | OK |
| POST | `m/enquirymaster/ai_call` | 422 | id | data[0] | Missing id or phone. |
| POST | `m/enquirymaster/changeStatus` | 422 |  | {status, message, data, code} | id is required. |
| POST | `m/enquirymaster/checkMobile` | 200 | mobile | {exists} |  |
| POST | `m/enquirymaster/del` | 422 |  | {status, message, data, code} | id is required. |
| POST | `m/enquirymaster/endCallRecord` | 200 | id | {status, message, data, code} | Call tracking ended. |
| GET | `m/enquirymaster/enquiry_update` | 422 |  | {status, message, data, code} | Enquiry id is required (?id=). |
| GET | `m/enquirymaster/enquiry_update/1` | 404 |  | {status, message, data, code} | Enquiry not found. |
| GET | `m/enquirymaster/index` | 200 |  | data{enquiries, total, limit, offset, filters} | OK |
| GET | `m/enquirymaster/listall` | 200 |  | data{enquiries, total, limit, offset, filters} | OK |
| GET | `m/enquirymaster/notifications` | 200 |  | data{notifications, total, limit} | OK |
| GET | `m/enquirymaster/profile` | 422 |  | {status, message, data, code} | Enquiry id is required (?id=). |
| POST | `m/enquirymaster/pushCallRecord` | 200 | id | data{id} | Call tracking started. |
| POST | `m/enquirymaster/pushNotify` | 422 | id | {status, message, data, code} | bc is required. |
| GET | `m/enquirymaster/response` | 422 |  | {status, message, data, code} | Enquiry id is required (?id=). |
| POST | `m/enquirymaster/update` | 422 |  | {status, message, data, code} | ecode is required. |
| POST | `m/enquirymaster/updateResponse` | 422 |  | {status, message, data, code} | ecode is required. |
| GET | `m/enquirymaster/uploadDoc` | 200 |  | data{fields} | POST a spreadsheet with confirm=1 to bulk-import enquiries. |
| GET | `m/eventreg/index` | 200 |  | data{registrations, total, available} | Event registration module is not installed. |
| POST | `m/eventreg/listBrnach` | 200 |  | data{branches} | OK |
| GET | `m/eventreg/listall` | 200 |  | data{registrations, total, available} | Event registration module is not installed. |
| GET | `m/events/addNewFrm` | 200 |  | data{fields, statuses, available} | OK |
| POST | `m/events/addNewFrmGall` | 200 |  | data{fields, types, available} | OK |
| POST | `m/events/addnew` | 422 |  | {type, text} | ttl and loc are required. |
| POST | `m/events/addnewGall` | 422 |  | {type, text} | eid and gttl are required. |
| POST | `m/events/changeStatus` | 422 |  | {type, text} | id is required. |
| POST | `m/events/changeStatusGall` | 422 |  | {type, text} | id is required. |
| POST | `m/events/del` | 422 |  | {type, text} | id is required. |
| POST | `m/events/delGall` | 422 |  | {type, text} | id is required. |
| POST | `m/events/gallery` | 200 |  | data{gallery, total, available} | Gallery module is not installed. |
| GET | `m/events/index` | 200 |  | data{events, total, available} | Events module is not installed. |
| GET | `m/events/listall` | 200 |  | data{events, total, available} | Events module is not installed. |
| POST | `m/events/profile` | 422 |  | {type, text} | ecode is required. |
| POST | `m/events/profileGall` | 422 |  | {type, text} | gid is required. |
| POST | `m/events/update` | 422 |  | {type, text} | ecode is required. |
| POST | `m/events/updateGall` | 422 |  | {type, text} | gid is required. |
| GET | `m/excel_export/index` | 200 |  | non-JSON (6046 bytes) |  |
| GET | `m/export/cms` | 200 |  | data{counts, chart} | OK |
| GET | `m/export/download` | 200 |  | non-JSON (6047 bytes) |  |
| GET | `m/jobadmin/all_jobs` | 200 |  | data{jobs, limit, offset} | OK |
| POST | `m/jobadmin/approve_job/999999` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/jobadmin/audit_logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/jobadmin/categories` | 200 |  | data{categories} | OK |
| POST | `m/jobadmin/category_delete/999999` | 422 |  | {status, message, data, code} | Failed to delete category. |
| POST | `m/jobadmin/category_save` | 422 |  | {status, message, data, code} | Category name is required. |
| GET | `m/jobadmin/chart_data` | 200 |  | data[12] | OK |
| GET | `m/jobadmin/chart_data/test` | 422 |  | data[0] | Invalid type. |
| GET | `m/jobadmin/companies` | 200 |  | data{companies, limit, offset} | OK |
| GET | `m/jobadmin/dashboard` | 200 |  | data{stats, monthly, recent_jobs, latest_seekers, top_categories} | OK |
| POST | `m/jobadmin/email_template_delete/999999` | 404 |  | {status, message, data, code} | Template not found. |
| POST | `m/jobadmin/email_template_save` | 422 |  | {status, message, data, code} | Template key and name are required. |
| GET | `m/jobadmin/email_templates` | 200 |  | data{templates} | OK |
| GET | `m/jobadmin/export` | 404 |  | {status, message, data, code} | No data to export. |
| GET | `m/jobadmin/export/test` | 404 |  | {status, message, data, code} | No data to export. |
| POST | `m/jobadmin/feature_job/999999` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/jobadmin/pending_jobs` | 200 |  | data{jobs, limit, offset} | OK |
| POST | `m/jobadmin/reject_job/999999` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/jobadmin/reports` | 200 |  | data{type, rows} | OK |
| GET | `m/jobadmin/reports/test` | 200 |  | data{type, rows} | OK |
| GET | `m/jobadmin/seekers` | 200 |  | data{seekers, limit, offset} | OK |
| POST | `m/jobadmin/settings` | 200 |  | data{saved} | Settings saved. |
| POST | `m/jobadmin/skill_delete/999999` | 422 |  | {status, message, data, code} | Failed to delete skill. |
| POST | `m/jobadmin/skill_save` | 422 |  | {status, message, data, code} | Skill name is required. |
| GET | `m/jobadmin/skills` | 200 |  | data{skills, categories} | OK |
| POST | `m/jobadmin/toggle_seeker/999999` | 404 |  | {status, message, data, code} | Seeker not found. |
| POST | `m/jobadmin/verify_company/999999` | 404 |  | {status, message, data, code} | Company not found. |
| GET | `m/jobportal/admin/all_jobs` | 200 |  | data{jobs, limit, offset} | OK |
| POST | `m/jobportal/admin/approve_job/999999` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/jobportal/admin/audit_logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/jobportal/admin/categories` | 200 |  | data{categories} | OK |
| POST | `m/jobportal/admin/category_delete/999999` | 422 |  | {status, message, data, code} | Failed to delete category. |
| POST | `m/jobportal/admin/category_get/1` | 200 | id | data{category} | OK |
| POST | `m/jobportal/admin/category_save` | 422 |  | {status, message, data, code} | Category name is required. |
| GET | `m/jobportal/admin/chart_data/test` | 422 |  | data[0] | Invalid type. |
| GET | `m/jobportal/admin/companies` | 200 |  | data{companies, limit, offset} | OK |
| GET | `m/jobportal/admin/dashboard` | 200 |  | data{stats, monthly, recent_jobs, latest_seekers, top_categories} | OK |
| POST | `m/jobportal/admin/email_template_delete/999999` | 404 |  | {status, message, data, code} | Template not found. |
| POST | `m/jobportal/admin/email_template_save` | 422 |  | {status, message, data, code} | Template key and name are required. |
| GET | `m/jobportal/admin/email_templates` | 200 |  | data{templates} | OK |
| GET | `m/jobportal/admin/export` | 404 |  | {status, message, data, code} | No data to export. |
| GET | `m/jobportal/admin/export/test` | 404 |  | {status, message, data, code} | No data to export. |
| POST | `m/jobportal/admin/feature_job/999999` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/jobportal/admin/pending_jobs` | 200 |  | data{jobs, limit, offset} | OK |
| GET | `m/jobportal/admin/profile` | 200 |  | data{stats, monthly, recent_jobs, latest_seekers, top_categories} | OK |
| POST | `m/jobportal/admin/reject_job/999999` | 404 |  | {status, message, data, code} | Job not found. |
| GET | `m/jobportal/admin/reports` | 200 |  | data{type, rows} | OK |
| GET | `m/jobportal/admin/reports/test` | 200 |  | data{type, rows} | OK |
| GET | `m/jobportal/admin/seekers` | 200 |  | data{seekers, limit, offset} | OK |
| POST | `m/jobportal/admin/settings` | 200 |  | data{saved} | Settings saved. |
| POST | `m/jobportal/admin/skill_delete/999999` | 422 |  | {status, message, data, code} | Failed to delete skill. |
| POST | `m/jobportal/admin/skill_save` | 422 |  | {status, message, data, code} | Skill name is required. |
| GET | `m/jobportal/admin/skills` | 200 |  | data{skills, categories} | OK |
| POST | `m/jobportal/admin/toggle_seeker_status/999999` | 404 |  | {status, message, data, code} | Seeker not found. |
| POST | `m/jobportal/admin/verify_company/999999` | 404 |  | {status, message, data, code} | Company not found. |
| GET | `m/mail` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/mail/index` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/mail/logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/mail/preview` | 200 |  | data{days_config, upcoming, total_eligible} | OK |
| POST | `m/mail/save_settings` | 200 |  | data{saved} | Settings saved successfully! |
| POST | `m/mail/send_reminders` | 200 | dry_run | data{sent, failed, skipped, results} | Sent: 27 / Failed: 0 / Skipped (already sent): 0. |
| POST | `m/mail/send_test` | 200 | test_email | {status, message, data, code} | Test email sent. |
| GET | `m/msg/email_logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/msg/email_preview` | 200 |  | data{days, samples} | OK |
| POST | `m/msg/email_test` | 502 | test_email | {status, message, data, code} | SMTP send failed. |
| GET | `m/msg/wa_download_unverified` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/msg/wa_logs` | 200 |  | non-JSON (8000 bytes) |  |
| POST | `m/msg/wa_mark_sent` | 200 |  | data{status} | OK |
| GET | `m/msg/wa_preview` | 200 |  | data{days, samples} | OK |
| GET | `m/msg/wa_stats` | 200 |  | data{total, whatsapp_yes, whatsapp_no, msg_sent, pending} | OK |
| POST | `m/msg/wa_test` | 502 | test_number | {status, message, data, code} | WhatsApp send failed. |
| POST | `m/msg/wa_upload_verified` | 422 |  | {status, message, data, code} | File upload failed (field verified_file). |
| GET | `m/notifications` | 200 |  | data{notifications, total, page, per_page} | OK |
| GET | `m/notifications/get_unread` | 200 |  | {count, notifications} |  |
| GET | `m/notifications/listing` | 200 |  | data{notifications, total, page, per_page} | OK |
| POST | `m/notifications/mark_all_read` | 200 |  | {success, count} |  |
| POST | `m/notifications/mark_read` | 422 |  | {status, message, data, code} | Invalid notification ID. |
| GET | `m/notify` | 200 |  | data{notifications, total, page, per_page} | OK |
| GET | `m/notify/get_unread` | 200 |  | {count, notifications} |  |
| GET | `m/notify/listing` | 200 |  | data{notifications, total, page, per_page} | OK |
| POST | `m/notify/mark_all_read` | 200 |  | {success, count} |  |
| POST | `m/notify/mark_read` | 422 |  | {status, message, data, code} | Invalid notification ID. |
| GET | `m/payments` | 200 |  | data{payments, total, limit, offset} | OK |
| POST | `m/payments/add` | 422 |  | {status, message} | All required fields must be filled |
| POST | `m/payments/customer_lookup` | 200 | customer_id | {status, customer} |  |
| POST | `m/payments/delete` | 422 |  | {status, message, data, code} | Payment id is required. |
| POST | `m/payments/delete/999999` | 404 |  | {status, message} | Payment not found |
| GET | `m/payments/detail` | 422 |  | {status, message, data, code} | Payment id is required (?id=). |
| GET | `m/payments/detail/0` | 422 |  | {status, message, data, code} | Payment id is required (?id=). |
| POST | `m/payments/edit` | 422 |  | {status, message, data, code} | Payment id is required. |
| POST | `m/payments/edit/999999` | 404 |  | {status, message} | Payment not found |
| GET | `m/payments/list` | 200 |  | data{payments, total, limit, offset} | OK |
| GET | `m/payments/listall` | 200 |  | data{payments, total, limit, offset} | OK |
| GET | `m/profile` | 200 |  | data{branch} | OK |
| GET | `m/profile/index` | 200 |  | data{branch} | OK |
| POST | `m/profile/update` | 422 |  | {type, text} | No profile fields provided. |
| GET | `m/profile_approvals` | 200 |  | data{pending_requests, total, limit, offset} | OK |
| POST | `m/profile_approvals/approve` | 422 |  | {status, message, data, code} | Customer ID is required. |
| GET | `m/profile_approvals/index` | 200 |  | data{pending_requests, total, limit, offset} | OK |
| POST | `m/profile_approvals/reject` | 422 |  | {status, message, data, code} | Customer ID is required. |
| POST | `m/qrfield/assignment_done` | 422 |  | {type, text} | assignment_id is required. |
| GET | `m/qrfield/batch_count` | 200 |  | {count} |  |
| GET | `m/qrfield/batches` | 200 |  | data[2] | OK |
| POST | `m/qrfield/customer_done` | 422 |  | {type, text} | progress_id is required. |
| POST | `m/qrfield/customers` | 422 |  | {status, message, data, code} | assignment_id is required. |
| GET | `m/qrfield/employees` | 200 |  | data[39] | OK |
| GET | `m/qrfield/notif_count` | 200 |  | {count} |  |
| POST | `m/qrfield/notif_read` | 422 |  | {type, text} | id is required. |
| GET | `m/qrfield/notifications` | 200 |  | data[0] | OK |
| GET | `m/qrfield/tasks` | 200 |  | data{assignments} | OK |
| GET | `m/qrinfo/employeeBatchCount` | 200 |  | {count} |  |
| GET | `m/qrinfo/getBatchesDropdown` | 200 |  | data[2] | OK |
| GET | `m/qrinfo/getEmployees` | 200 |  | data[39] | OK |
| POST | `m/qrinfo/getTaskCustomers` | 422 |  | {status, message, data, code} | assignment_id is required. |
| POST | `m/qrinfo/markAssignmentComplete` | 422 |  | {type, text} | assignment_id is required. |
| POST | `m/qrinfo/markCustomerComplete` | 422 |  | {type, text} | progress_id is required. |
| POST | `m/qrinfo/markNotificationRead` | 422 |  | {type, text} | id is required. |
| GET | `m/qrinfo/myNotifications` | 200 |  | data[0] | OK |
| GET | `m/qrinfo/myTasks` | 200 |  | data{assignments} | OK |
| GET | `m/qrinfo/notificationCount` | 200 |  | {count} |  |
| GET | `m/razorpay` | 200 |  | data{settings, total_orders, paid, failed} | OK |
| GET | `m/razorpay/orders` | 200 |  | data{orders, total, page, per_page} | OK |
| POST | `m/razorpay/save_settings` | 200 |  | data{saved} | Razorpay settings saved. |
| GET | `m/renewal` | 200 |  | data{month, is_admin, section_b, chart_12m, import_logs, months, branch, month_summary} | OK |
| POST | `m/renewal/auto_ai_calls` | 200 | dry_run | data{calls_made} | No pending renewal customers with phone numbers found. |
| GET | `m/renewal/export_csv` | 200 |  | non-JSON (147 bytes) |  |
| GET | `m/renewal/get_chart_data` | 200 |  | data[6] | OK |
| GET | `m/renewal/get_detail_records` | 200 |  | data{data, count, section} | OK |
| POST | `m/renewal/import` | 422 |  | {status, message, data, code} | File upload failed (field import_file). |
| POST | `m/renewal/import_confirm` | 200 |  | data{fields} | Run import_preview first, then POST the file again with column indexes + confirm=1. |
| POST | `m/renewal/import_preview` | 422 |  | {status, message, data, code} | File upload failed (field import_file). |
| GET | `m/renewal/index` | 200 |  | data{month, is_admin, section_b, chart_12m, import_logs, months, branch, month_summary} | OK |
| GET | `m/renewal/records_list` | 200 |  | data{month, type, records, total, limit, offset} | OK |
| GET | `m/renewal/report_advance` | 200 |  | data{month, advance} | OK |
| GET | `m/renewal/report_branch_wise` | 200 |  | data{month, rows} | OK |
| GET | `m/renewal/report_employee_wise` | 200 |  | data{month, rows} | OK |
| GET | `m/renewal/report_monthly_targets` | 200 |  | data{year, targets} | OK |
| GET | `m/renewal/report_pending` | 200 |  | data{month, pending} | OK |
| GET | `m/renewal/report_pending_completed` | 200 |  | data{month, rows} | OK |
| GET | `m/renewal/report_performance` | 200 |  | data{months, performance} | OK |
| POST | `m/renewal/save_targets` | 422 |  | data[0] | Invalid data. |
| GET | `m/renewal/target_set` | 200 |  | data{month, users, user_targets, months} | OK |
| GET | `m/reports` | 200 |  | data{sales_summary, amc_summary, customer_summary, enquiry_summary, monthly_sales, monthly_amc, customer_status} | OK |
| GET | `m/reports/amc` | 200 |  | data{selected_month, selected_year, amc_summary, monthly_trend, employee_amc} | OK |
| GET | `m/reports/customer_list/test` | 200 |  | data{status_filter, customers, total, limit, offset} | OK |
| GET | `m/reports/customers` | 200 |  | data{customer_summary, status_distribution, city_distribution, software_type, software_trade, monthly_growth, subpartner_summary} | OK |
| GET | `m/reports/edition_customers/test` | 200 |  | data{type, customers, total, limit, offset} | OK |
| GET | `m/reports/export_customers` | 200 |  | non-JSON (342 bytes) |  |
| GET | `m/reports/export_sales` | 200 |  | non-JSON (91 bytes) |  |
| GET | `m/reports/get_chart_data` | 422 |  | data[0] | Invalid chart type. |
| GET | `m/reports/index` | 200 |  | data{sales_summary, amc_summary, customer_summary, enquiry_summary, monthly_sales, monthly_amc, customer_status} | OK |
| GET | `m/reports/pincode_customers/test` | 200 |  | data{pincode, customers, total, limit, offset} | OK |
| GET | `m/reports/sales` | 200 |  | data{selected_month, selected_year, sales_summary, monthly_trend, daily_sales, employee_sales} | OK |
| GET | `m/reports/subpartner_parties/test` | 200 |  | data{subpartner_code, subpartner_name, parties} | OK |
| GET | `m/reports/trade_customers/test` | 200 |  | data{trade, customers, total, limit, offset} | OK |
| GET | `m/settings` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/settings/ajax_audit_log` | 200 |  | data{key, log} | OK |
| POST | `m/settings/ajax_bulk_update` | 422 |  | {status, message, data, code} | settings map is required. |
| POST | `m/settings/ajax_get` | 422 |  | {status, message, data, code} | Setting key is required. |
| POST | `m/settings/ajax_reset` | — |  |  | SKIP: broken on web, no mobile twin (doc G) |
| POST | `m/settings/ajax_test_email` | 502 | to_email | {status, message, data, code} | SMTP send failed. |
| GET | `m/settings/ajax_test_payment` | 200 |  | data{gateway, mode} | OK |
| POST | `m/settings/ajax_test_sms` | 200 | number | data{gateway, mode} | SMS API key not configured; no message sent (web parity stub). |
| POST | `m/settings/ajax_test_whatsapp` | 502 | number | {status, message, data, code} | WhatsApp send failed. |
| POST | `m/settings/ajax_update` | 422 |  | {status, message, data, code} | Setting key is required. |
| GET | `m/settings/audit_log` | 200 |  | data{key, log} | OK |
| GET | `m/settings/bss_creds` | 200 |  | data{has_credentials, bss_username, bss_url, has_password, updated_at} | OK |
| POST | `m/settings/bss_creds_save` | 422 |  | {status, message, data, code} | At least one of bss_username, bss_password or bss_url is required. |
| POST | `m/settings/bulk_update` | 422 |  | {status, message, data, code} | settings map is required. |
| GET | `m/settings/category/test` | 200 |  | data{category, settings} | OK |
| POST | `m/settings/get` | 422 |  | {status, message, data, code} | Setting key is required. |
| GET | `m/settings/index` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/settings/razorpay_index` | 200 |  | data{settings, total_orders, paid, failed} | OK |
| GET | `m/settings/razorpay_orders` | 200 |  | data{orders, total, page, per_page} | OK |
| POST | `m/settings/razorpay_save` | 200 |  | data{saved} | Razorpay settings saved. |
| GET | `m/settings/tenant_index` | 200 |  | data{field_map, is_super, my_tenant, my_branch, tenants, firms} | OK |
| POST | `m/settings/tenant_load` | 403 |  | {status, message, data, code} | Access denied for this scope. |
| POST | `m/settings/tenant_reset` | 403 |  | {status, message, data, code} | Access denied for this scope. |
| POST | `m/settings/tenant_save` | 403 |  | {status, message, data, code} | Access denied for this scope. |
| POST | `m/settings/test_email` | 502 | to_email | {status, message, data, code} | SMTP send failed. |
| GET | `m/settings/test_payment` | 200 |  | data{gateway, mode} | OK |
| POST | `m/settings/test_sms` | 200 | number | data{gateway, mode} | SMS API key not configured; no message sent (web parity stub). |
| POST | `m/settings/test_whatsapp` | 502 | number | {status, message, data, code} | WhatsApp send failed. |
| POST | `m/settings/update` | 422 |  | {status, message, data, code} | Setting key is required. |
| GET | `m/sitecontent/index` | 200 |  | data{content, items, available} | OK |
| GET | `m/task` | 200 |  | data{tasks, total, limit, offset, can_edit_all} | OK |
| GET | `m/task/get_task/1` | 200 |  | data{id, tenant_code, title, description, assigned_to, assigned_by, priority, status…} | OK |
| GET | `m/task/listall` | 200 |  | data{tasks, total, limit, offset, can_edit_all} | OK |
| POST | `m/task/update_status` | 422 |  | {type, text} | id is required. |
| GET | `m/tasks` | 200 |  | data{tasks, total, limit, offset, can_edit_all} | OK |
| GET | `m/tasks/get_task/1` | 200 |  | data{id, tenant_code, title, description, assigned_to, assigned_by, priority, status…} | OK |
| GET | `m/tasks/index` | 200 |  | data{tasks, total, limit, offset, can_edit_all} | OK |
| GET | `m/tasks/listall` | 200 |  | data{tasks, total, limit, offset, can_edit_all} | OK |
| POST | `m/tasks/update_status` | 422 |  | {type, text} | id is required. |
| GET | `m/tenantsettings` | 200 |  | data{field_map, is_super, my_tenant, my_branch, tenants, firms} | OK |
| GET | `m/tenantsettings/index` | 200 |  | data{field_map, is_super, my_tenant, my_branch, tenants, firms} | OK |
| POST | `m/tenantsettings/load` | 403 |  | {status, message, data, code} | Access denied for this scope. |
| POST | `m/tenantsettings/reset` | 403 |  | {status, message, data, code} | Access denied for this scope. |
| POST | `m/tenantsettings/save` | 403 |  | {status, message, data, code} | Access denied for this scope. |
| GET | `m/waauto` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/waauto/index` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/waauto/logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/waauto/preview` | 200 |  | data{days_config, upcoming, total_eligible} | OK |
| POST | `m/waauto/send_birthday_wishes` | 200 | dry_run | data{sent, failed, skipped, results} | Dry run complete. |
| POST | `m/waauto/send_campaign` | 422 | dry_run | data[0] | template_id or custom_message is required. |
| POST | `m/waauto/send_reminders` | 200 | dry_run | data{sent, failed, skipped, results} | Dry run complete. |
| POST | `m/waauto/send_test` | 502 | test_number | data[0] | Send failed: Your instance has been Stopped due to non-payment. you can activate this inst |
| POST | `m/waauto/trigger_complaint_notification` | 422 |  | {status, message, data, code} | number, name, complaint_id are required. |
| POST | `m/waauto/trigger_enquiry_acknowledgment` | 422 |  | {status, message, data, code} | number, name, enquiry_id are required. |
| POST | `m/waauto/trigger_payment_receipt` | 422 |  | {status, message, data, code} | number, name, amount, purpose, receipt_no are required. |
| GET | `m/whatsapp_automation` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/whatsapp_automation/index` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/whatsapp_automation/logs` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/whatsapp_automation/preview` | 200 |  | data{days_config, upcoming, total_eligible} | OK |
| POST | `m/whatsapp_automation/send_birthday_wishes` | 200 | dry_run | data{sent, failed, skipped, results} | Dry run complete. |
| POST | `m/whatsapp_automation/send_campaign` | 422 | dry_run | data[0] | template_id or custom_message is required. |
| POST | `m/whatsapp_automation/send_reminders` | 200 | dry_run | data{sent, failed, skipped, results} | Dry run complete. |
| POST | `m/whatsapp_automation/send_test` | 502 | test_number | data[0] | Send failed: Your instance has been Stopped due to non-payment. you can activate this inst |
| POST | `m/whatsapp_automation/trigger_complaint_notification` | 422 |  | {status, message, data, code} | number, name, complaint_id are required. |
| POST | `m/whatsapp_automation/trigger_enquiry_acknowledgment` | 422 |  | {status, message, data, code} | number, name, enquiry_id are required. |
| POST | `m/whatsapp_automation/trigger_payment_receipt` | 422 |  | {status, message, data, code} | number, name, amount, purpose, receipt_no are required. |
| GET | `m/whatsapp_campaign/download_unverified` | 200 |  | non-JSON (8000 bytes) |  |
| GET | `m/whatsapp_campaign/get_stats` | 200 |  | data{total, whatsapp_yes, whatsapp_no, msg_sent, pending} | OK |
| GET | `m/whatsapp_campaign/index` | 200 |  | data{total, whatsapp_yes, whatsapp_no, msg_sent, pending} | OK |
| GET | `m/whatsapp_campaign/load_numbers` | 200 |  | data{numbers, limit, offset} | OK |
| POST | `m/whatsapp_campaign/mark_sent` | 200 |  | data{status} | OK |
| POST | `m/whatsapp_campaign/reset_campaign` | — |  |  | SKIP: acts without confirm, too risky |
| POST | `m/whatsapp_campaign/upload_verified` | 422 |  | {status, message, data, code} | File upload failed (field verified_file). |
| POST | `m/auth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |
| POST | `m/customerauth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |
| POST | `m/jobportal/auth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |

## Super admin (`user_type: staff`, platform)

| Method | Path | Status | Request fields seen | Response shape | Message / note |
|---|---|---|---|---|---|
| POST | `m/auth/login` | 200 | identifier, password, login_type | data{user_type, user_id, name, email, tenant_code, force_change, access_token, refresh_token…} | Login successful. |
| POST | `m/auth/refresh` | 200 | refresh_token | data{access_token, refresh_token, expires_in, token_type} | Token refreshed. |
| GET | `m/auth/me` | 200 |  | data{user_type, user_id, tenant_code, name, email, branch_name} | OK |
| GET | `m/admin` | 200 |  | data{tenants, plans} | OK |
| GET | `m/admin/errors` | 200 |  | non-JSON (8000 bytes) |  |
| POST | `m/admin/errors_clear` | 200 |  | data{fields} | POST confirm=1 to IRREVERSIBLY delete error log files. |
| GET | `m/admin/errors_view` | 200 |  | data{entry} | OK |
| GET | `m/admin/index` | 200 |  | data{tenants, plans} | OK |
| POST | `m/admin/tenant_delete` | 422 |  | {status, message, data, code} | tenant_code is required. |
| GET | `m/admin/tenant_plan` | 422 |  | {status, message, data, code} | Tenant code is required. |
| GET | `m/admin/tenant_plan/tenant_001` | 200 |  | data{tenant, plans} | OK |
| POST | `m/admin/tenant_plan_save` | 422 |  | {status, message, data, code} | Tenant code is required. |
| GET | `m/admin/tenants` | 200 |  | data{tenants, plans} | OK |
| POST | `m/autoassign` | 422 |  | {status, message, data, code} | Auto-assignment needs confirm=1. |
| POST | `m/autoassign/manualAssign` | 422 |  | {status, message, data, code} | Auto-assignment needs confirm=1. |
| POST | `m/autoassignment/manualAssign` | 422 |  | {status, message, data, code} | Auto-assignment needs confirm=1. |
| POST | `m/lmsfix` | — |  |  | SKIP: system repair endpoint; mutates modules/authr |
| POST | `m/lmsfix/index` | — |  |  | SKIP: system repair endpoint; mutates modules/authr |
| GET | `m/platform` | 200 |  | data{tenants, plans} | OK |
| GET | `m/platform/errors` | 200 |  | non-JSON (8000 bytes) |  |
| POST | `m/platform/errors_clear` | 200 |  | data{fields} | POST confirm=1 to IRREVERSIBLY delete error log files. |
| GET | `m/platform/errors_view` | 200 |  | data{entry} | OK |
| GET | `m/platform/index` | 200 |  | data{tenants, plans} | OK |
| GET | `m/platform/tenant_plan` | 422 |  | {status, message, data, code} | Tenant code is required. |
| GET | `m/platform/tenant_plan/tenant_001` | 200 |  | data{tenant, plans} | OK |
| POST | `m/platform/tenant_plan_save` | 422 |  | {status, message, data, code} | Tenant code is required. |
| GET | `m/platform/tenants` | 200 |  | data{tenants, plans} | OK |
| POST | `m/qradmin/batch_close` | 404 |  | {status, message, data, code} | Batch not found. |
| POST | `m/qradmin/batch_detail` | 404 |  | {status, message, data, code} | Batch not found. |
| GET | `m/qradmin/batch_new` | 200 |  | data{employees, fields} | POST fields to create a batch. |
| POST | `m/qradmin/batch_save` | 200 |  | {type, text} | Title is required. |
| GET | `m/qradmin/batch_view?id=4` | 200 | ?id | data{batch} | OK |
| GET | `m/qradmin/batches` | 200 |  | data{batches, total, limit, offset} | OK |
| GET | `m/qradmin/report` | 200 |  | data{filters} | POST filters to report_data for the breakdown. |
| POST | `m/qradmin/report_data` | 200 |  | data{batches, employee_data, filter_batch} | OK |
| GET | `m/qrinfo` | 200 |  | data{batches, total, limit, offset} | OK |
| POST | `m/qrinfo/closeTask` | 404 |  | {status, message, data, code} | Batch not found. |
| GET | `m/qrinfo/getBatches` | 200 |  | data{batches, total, limit, offset} | OK |
| POST | `m/qrinfo/getTaskDetails` | 404 |  | {status, message, data, code} | Batch not found. |
| GET | `m/qrinfo/index` | 200 |  | data{batches, total, limit, offset} | OK |
| GET | `m/qrinfo/newTask` | 200 |  | data{employees, fields} | POST fields to create a batch. |
| GET | `m/qrinfo/report` | 200 |  | data{filters} | POST filters to report_data for the breakdown. |
| POST | `m/qrinfo/reportData` | 200 |  | data{batches, employee_data, filter_batch} | OK |
| POST | `m/qrinfo/saveTask` | 200 |  | {type, text} | Title is required. |
| GET | `m/qrinfo/viewTask/999999` | 422 |  | {status, message, data, code} | Batch id is required. |
| POST | `m/sys/lms_fix` | — |  |  | SKIP: system repair endpoint; mutates modules/authr |
| POST | `m/task/addnew` | 422 |  | {type, text} | title is required. |
| POST | `m/task/delete` | 422 |  | {type, text} | id is required. |
| POST | `m/task/edit/999999` | 404 |  | {status, message, data, code} | Task not found. |
| POST | `m/tasks/addnew` | 422 |  | {type, text} | title is required. |
| POST | `m/tasks/delete` | 422 |  | {type, text} | id is required. |
| POST | `m/tasks/edit/999999` | 404 |  | {status, message, data, code} | Task not found. |
| POST | `m/waauto/save_settings` | 200 |  | data{saved} | Settings saved. |
| POST | `m/whatsapp_automation/save_settings` | 200 |  | data{saved} | Settings saved. |
| POST | `m/auth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |
| POST | `m/customerauth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |
| POST | `m/jobportal/auth/logout` | 200 | refresh_token | {status, message, data, code} | Logged out. |

