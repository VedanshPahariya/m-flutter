/// Every backend path used by the app, relative to [AppConfig.apiBaseUrl].
///
/// Paths come from `urls.json`. Where the backend exposes the same controller
/// under two names (for example `m/complaint` and `m/complaintmaster`), the
/// shorter alias is used. Request field names are documented next to each
/// path with their source:
///
/// * [verified]  seen in a captured request body or a `fields` list
/// * [error-msg] named by the backend's own 422 message
/// * [prototype] listed in the HTML prototype's endpoint notes
/// * [inferred]  not captured; derived from a sibling endpoint or the record
///               shape. These are the first thing to check if a call fails.
///
/// docs/API_VERIFICATION.md lists the status of every endpoint.
class Endpoints {
  const Endpoints._();

  // ---------------------------------------------------------------- auth
  /// POST identifier, password, login_type=staff|customer [verified]
  static const login = 'm/auth/login';

  /// POST email, password [verified]
  static const seekerLogin = 'm/auth/seeker_login';

  /// POST full_name, email, phone, password, confirm_password [error-msg]
  static const seekerRegister = 'm/auth/seeker_register';

  /// POST email [verified]
  static const seekerForgot = 'm/auth/seeker_forgot';

  /// POST email [verified]
  static const staffForgot = 'm/auth/staff_forgot';

  /// POST identifier [verified]. Customer accounts only. The success body was
  /// not captured; `pending_token` is named by verifyOTP.
  static const sendOtp = 'm/auth/sendOTP';

  /// POST pending_token, otp [verified]
  static const verifyOtp = 'm/auth/verifyOTP';

  /// POST refresh_token [verified]. Rotates both tokens.
  static const refresh = 'm/auth/refresh';

  /// GET [verified]
  static const me = 'm/auth/me';

  /// POST refresh_token [verified]
  static const logout = 'm/auth/logout';

  // ------------------------------------------------------- staff: common
  /// POST (no fields) [verified]. Returns staff.role (1 admin, 2 staff) and
  /// staff.is_super_admin; used to resolve the CRM role.
  static const staffDashboard = 'm/dashboard/index';

  /// GET [verified]. Lead counts, targets and chart series.
  static const emsDashboard = 'm/emsdashboard';

  /// GET [verified]. Complaint counts by status.
  static const cmsDashboard = 'm/cmsdashboard';

  /// GET [verified]. Branch (= user) profile.
  static const profile = 'm/profile';

  /// GET [verified]. Sales, AMC, customer and enquiry summaries.
  static const reports = 'm/reports';

  // ---------------------------------------------------------------- leads
  /// GET limit, offset, show_all, st, fl, vl, etyp, dr, date_type
  /// [verified: echoed in `filters`]
  static const enquiryList = 'm/enquiry/list';
  static String enquiryDetail(String id) => 'm/enquiry/detail/$id';

  /// GET [verified]. Returns the accepted fields and branch list.
  static const enquiryForm = 'm/enquiry/addNewFrm';

  /// POST sname*, phone*, bcode, sdate, etyp, sts, srs, cmnt, asgn, eAddrs
  /// [verified: addNewFrm fields]
  static const enquiryAdd = 'm/enquiry/add';

  /// POST mobile [verified]
  static const enquiryCheckMobile = 'm/enquiry/check_mobile';

  /// POST ecode*, res, resdate, asgn, cmnt [error-msg + prototype]
  static const enquiryResponse = 'm/enquiry/response';

  /// POST id [verified]
  static const enquiryCallStart = 'm/enquiry/call_start';
  static const enquiryCallEnd = 'm/enquiry/call_end';

  /// POST id, phone [error-msg]
  static const enquiryAiCall = 'm/enquiry/ai_call';

  /// POST id [error-msg]. Branch admin only.
  static const enquiryDelete = 'm/enquiry/del';

  // -------------------------------------------------------------- tickets
  /// POST status, show_all, limit, offset [prototype + echoed]
  static const complaintList = 'm/complaint/list';
  static String complaintDetail(String id) => 'm/complaint/detail/$id';

  /// POST cid [verified]
  static const complaintOtpGenerate = 'm/complaint/otp_generate';

  /// POST cid, otp [inferred from otp_generate + "Complaint ID and OTP are
  /// required"]
  static const complaintOtpVerify = 'm/complaint/otp_verify';

  /// POST cid, resolution [inferred: "Complaint ID required"]
  static const complaintClose = 'm/complaint/close';

  /// POST cid, response, comments [inferred from the complaint record keys;
  /// backend only says "Missing required fields"]
  static const complaintResponse = 'm/complaint/response';

  /// POST customer_id [verified]
  static const complaintCustomerLookup = 'm/complaint/customer_lookup';

  /// POST confirm=1 [error-msg]. Super admin.
  static const autoAssign = 'm/autoassign';

  // ------------------------------------------------------------ customers
  /// POST search, page [prototype]
  static const customerDirectory = 'm/customerdir/list';

  /// POST customer_id [verified]
  static const customerById = 'm/customerpayments/getCustomerById';
  static String walletCheck(String customerId) =>
      'm/bss/check_wallet/$customerId';

  /// GET limit, offset [verified]. Admin and staff.
  static const payments = 'm/customerpayments';

  // ------------------------------------------------------------- renewals
  /// GET month=yyyy-MM [prototype]
  static const renewal = 'm/renewal';

  /// GET month, type, limit, offset [verified: echoed]
  static const renewalRecords = 'm/renewal/records_list';
  static const renewalChart = 'm/renewal/get_chart_data';

  /// GET reminder_type, limit, offset [verified fields list]
  static const renewalMsgPreview = 'm/bulkmsg/get_renewal_msg_customers';

  /// POST dry_run=1 previews [verified]; without dry_run it sends [inferred].
  static const renewalMsgSend = 'm/bulkmsg/send_renewal_messages';

  // ---------------------------------------------------------------- tasks
  /// GET limit, offset [verified]
  static const tasks = 'm/tasks/listall';

  /// POST id, status [id: error-msg; status: inferred]
  static const taskUpdateStatus = 'm/tasks/update_status';

  // -------------------------------------------------------- notifications
  /// GET page [prototype]
  static const notifications = 'm/notifications/listing';
  static const notificationsUnread = 'm/notifications/get_unread';

  /// POST id [inferred: "Invalid notification ID."]
  static const notificationMarkRead = 'm/notifications/mark_read';
  static const notificationsMarkAll = 'm/notifications/mark_all_read';

  // ---------------------------------------------------------- field (QR)
  static const fieldTasks = 'm/qrfield/tasks';

  /// POST assignment_id [error-msg]
  static const fieldCustomers = 'm/qrfield/customers';

  /// POST progress_id [error-msg]
  static const fieldCustomerDone = 'm/qrfield/customer_done';

  /// POST assignment_id [error-msg]
  static const fieldAssignmentDone = 'm/qrfield/assignment_done';

  // ------------------------------------------------------ admin: approvals
  static const approvalsPending = 'm/approvals/pending';

  /// POST customer_id [inferred: "Customer ID is required."]
  static const approvalsApprove = 'm/approvals/approve';
  static const approvalsReject = 'm/approvals/reject';

  // ----------------------------------------------------------- admin: team
  /// GET limit, offset [verified]. In this backend a "branch" is a user.
  static const branchList = 'm/branch/listall';

  /// POST id [error-msg]. Toggles a user's status.
  static const branchChangeStatus = 'm/branch/changeStatus';

  // ------------------------------------------------- super admin: platform
  static const tenants = 'm/admin/tenants';
  static String tenantPlan(String code) => 'm/admin/tenant_plan/$code';
  static const errorLog = 'm/admin/errors';
  static const qrBatches = 'm/qradmin/batches';

  // ----------------------------------------------------- customer portal
  static const customerHome = 'm/customer';
  static const customerProfile = 'm/customer/profile';
  static const customerComplaints = 'm/customer/complaints';
  static const customerPayments = 'm/customer/payments';
  static const customerRenewals = 'm/customer/renewals';
  static const customerQr = 'm/customer/qrcode';
  static const customerReferrals = 'm/customer/referral_earnings';

  /// POST [verified: called as POST in the inventory]
  static const customerNotifications = 'm/customer/notifications';

  /// POST cid [error-msg]
  static const customerReopenComplaint = 'm/customer/reopenComplaint';

  // -------------------------------------------------------- job portal
  /// GET keyword, city, job_type, limit, offset [verified: echoed filters]
  static const jobs = 'm/jobs';
  static String jobDetail(String id) => 'm/jobs/detail/$id';
  static String jobsByCategory(String slug) => 'm/jobs/category/$slug';
  static const seekerDashboard = 'm/seeker/dashboard';
  static const seekerApplications = 'm/seeker/applications';
  static const seekerInterviews = 'm/seeker/interviews';
  static const seekerSavedJobs = 'm/seeker/saved_jobs';
  static const seekerProfile = 'm/seeker/public_profile';
  static String seekerApply(String jobId) => 'm/seeker/apply/$jobId';
  static String seekerSaveJob(String jobId) => 'm/seeker/save_job/$jobId';
  static String seekerWithdraw(String applicationId) =>
      'm/seeker/withdraw_application/$applicationId';
}
