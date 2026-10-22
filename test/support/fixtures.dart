/// Response bodies with the exact shape of the captured inventory
/// (`urls.json`), with personal data replaced by fake values.
library;

const loginStaff = '''
{"status":"success","message":"Login successful.","data":{"user_type":"staff","user_id":"47","name":"Test Staff","email":"staff@example.invalid","tenant_code":"tenant_001","force_change":false,"access_token":"access-1","refresh_token":"refresh-1","expires_in":3600,"token_type":"Bearer"},"code":200}
''';

const loginCustomer = '''
{"status":"success","message":"Login successful.","data":{"user_type":"customer","user_id":"DEMO001","name":"Demo Customer","mobile":"9000000011","email":"demo@example.invalid","tenant_code":"tenant_001","force_change":false,"is_default":false,"access_token":"access-c","refresh_token":"refresh-c","expires_in":3600,"token_type":"Bearer"},"code":200}
''';

const loginSeeker = '''
{"status":"success","message":"Login successful.","data":{"user_type":"seeker","user_id":"4","name":"Test Seeker","email":"seeker@example.invalid","access_token":"access-s","refresh_token":"refresh-s","expires_in":3600,"token_type":"Bearer"},"code":200}
''';

const loginForceChange = '''
{"status":"success","message":"Login successful.","data":{"user_type":"customer","user_id":"DEMO002","name":"New Customer","tenant_code":"tenant_001","force_change":true,"access_token":"access-f","refresh_token":"refresh-f","expires_in":3600,"token_type":"Bearer"},"code":200}
''';

const loginWrongPassword = '''
{"status":"error","message":"Account not found. Check Mobile Number / Customer ID.","data":null,"code":401}
''';

const refreshOk = '''
{"status":"success","message":"Token refreshed.","data":{"access_token":"access-2","refresh_token":"refresh-2","expires_in":3600,"token_type":"Bearer"},"code":200}
''';

const refreshInvalid = '''
{"status":"error","message":"Invalid refresh token.","data":null,"code":401}
''';

const tokenMissing = '''
{"status":"error","message":"Authorization token missing. Send \\"Authorization: Bearer <token>\\".","data":null,"code":401}
''';

const meStaff = '''
{"status":"success","message":"OK","data":{"user_type":"staff","user_id":"47","tenant_code":"tenant_001","name":"Test Staff","email":"staff@example.invalid","branch_name":"Test Staff"},"code":200}
''';

const meCustomer = '''
{"status":"success","message":"OK","data":{"user_type":"customer","user_id":"DEMO001","tenant_code":"tenant_001","name":"Demo Customer","mobile":"9000000011","email":"demo@example.invalid"},"code":200}
''';

const meSeeker = '''
{"status":"success","message":"OK","data":{"user_type":"seeker","user_id":"4","tenant_code":"","name":"Test Seeker","mobile":"9000000002","email":"seeker@example.invalid"},"code":200}
''';

String dashboardIndex({required int role, bool superAdmin = false}) =>
    '''
{"status":"success","message":"OK","data":{"staff":{"name":"Test Staff","role":$role,"is_super_admin":$superAdmin},"counts":{"enquiries":0,"customers":0,"complaints":0,"tasks":0,"events":0},"redirect":"m/emsdashboard"},"code":200}
''';

const emsDashboard = '''
{"status":"success","message":"OK","data":{"staff":{"name":"Test Admin","role":1,"is_super_admin":false},"counts":{"new":12,"converted":3,"demo_scheduled":2,"callback":5,"demo_done":1,"not_required":0,"invalid":0,"switch_off":0,"today_demo":1,"today_callback":2,"tomorrow_demo":0,"tomorrow_callback":0},"targets":{"branch_name":"Test Admin","running":0,"sale_target":0,"sale_achieved":0,"amc_target":0,"amc_achieved":0},"all_targets":[],"charts":{"status":{"labels":["New","Converted","Demo schedule","Call back"],"values":[12,3,2,5]},"today":{"labels":["Today Demo","Today Call Back"],"values":[1,2]}}},"code":200}
''';

const cmsDashboard = '''
{"status":"success","message":"OK","data":{"counts":{"New Ticket":4,"Acknowledge":0,"In Progress":1,"Reopen":1,"Closed":9,"Reject":0,"Deleted":0,"Transfer To IT":0,"Pending OTP Verification":2},"chart":{"labels":["New Ticket"],"values":[4]}},"code":200}
''';

const renewal = '''
{"status":"success","message":"OK","data":{"month":"2026-10","is_admin":false,"section_b":{"current_month":3,"pending_done":1,"advance":2,"total":6},"chart_12m":[{"target_month":"2026-07","total_target":"233","achieved":"120"},{"target_month":"2026-08","total_target":"247","achieved":"250"}],"import_logs":[],"months":[{"value":"2026-10","label":"October 2026"},{"value":"2026-09","label":"September 2026"}],"branch":{"BranchCode":"48","BranchName":"Test Admin","btype":"1","subpartnercode":null,"subpartnername":null},"month_summary":{"target":40,"achieved":10,"pending":30,"percentage":25}},"code":200}
''';

const tasksEmpty = '''
{"status":"success","message":"OK","data":{"tasks":[],"total":0,"limit":20,"offset":0,"can_edit_all":false},"code":200}
''';

const unreadZero = '{"count":0,"notifications":[]}';

const approvalsEmpty = '''
{"status":"success","message":"OK","data":{"pending_requests":[],"total":0,"limit":20,"offset":0},"code":200}
''';

/// Two rows in the verified `m/complaint/list` shape.
const complaintList = '''
{"status":"success","message":"OK","data":{"complaints":[
{"cId":"12","tenant_code":"tenant_001","ctcord":"28","bcode":"33","cName":"Sample Traders","cAddrs":"Main Road, Kanpur","cType":"General","cDate":"2026-07-20","source":"Direct","cContact":"9000000101","cstatus":"New Ticket","response":"New Ticket","respdate":null,"comments":"","addUID":null,"addTimeStamp":"2026-07-20 01:14:30","asgn":"Staff One","assigned_at":null,"assignTo":null,"priority":"Medium","resolution":null,"closedDate":null,"customer_id":"10677","partner_id":"P1","partner_name":null,"qr_token":null,"can_reopen":"1","closure_otp":null,"otp_generated_at":null,"otp_verified":"0","closed_at":null,"closed_by":null,"closed_by_uid":null},
{"cId":"9","tenant_code":"tenant_001","ctcord":"0","bcode":"0","cName":"Example Pharma","cAddrs":null,"cType":"Technical","cDate":"2026-07-18","source":"Customer Portal","cContact":"9000000102","cstatus":"New Ticket","response":"New Ticket","respdate":null,"comments":"Printer not detected","addUID":null,"addTimeStamp":"2026-07-18 19:28:52","asgn":null,"assigned_at":null,"assignTo":null,"priority":"High","resolution":null,"closedDate":null,"customer_id":"1017602","partner_id":null,"partner_name":null,"qr_token":null,"can_reopen":"1","closure_otp":null,"otp_generated_at":null,"otp_verified":"0","closed_at":null,"closed_by":null,"closed_by_uid":null}
],"total":9,"limit":20,"offset":0,"current_status":"New Ticket","show_all":null},"code":200}
''';

const enquiryListEmpty = '''
{"status":"success","message":"OK","data":{"enquiries":[],"total":0,"limit":20,"offset":0,"filters":{"fl":null,"vl":null,"st":null,"dr":"0","etyp":null,"date_type":null,"show_all":null}},"code":200}
''';

const reports = '''
{"status":"success","message":"OK","data":{"sales_summary":{"current_month":"0","last_month":"0","total":"32","software":"18","renewal":"14"},"amc_summary":{"current_month":"0","last_month":"0","total":"11","due_this_month":"248","overdue":"968"},"customer_summary":{"total":"5404","running":"3012","suspended":"0","closed":"0","expiring_this_month":"248"},"enquiry_summary":{"total":"43997","new":"11068","converted":"32","month_converted":"0","month_total":"0","conversion_rate":0},"monthly_sales":[],"monthly_amc":[{"month":"2026-06","total_renewals":"11"}],"customer_status":[{"status":"Running","total":"3012"},{"status":null,"total":"5"}]},"code":200}
''';

const customerHome = '''
{"status":"success","message":"OK","data":{"customer_id":"DEMO001","customer_name":"Demo Customer","customer":{"Customer_ID":"DEMO001","Party_Name":"Demo Customer","Contact_Person":"Demo Customer","Mobile":"9000000011","AltMobile":null,"EmailID":"demo@example.invalid","Address":null,"City":"Lucknow","State":"UP","Pincode":null,"GstNo":null,"Party_Status":null,"is_active":"1","is_default_password":"0","force_password_change":"0"},"amc_info":{"has_amc":false,"due_date":null,"days_left":0,"status":"No AMC Record","bill_amount":0,"software_type":""},"complaints_count":{"New Ticket":0,"In Progress":0,"Closed":0,"Reopen":0},"qr_token":"QRtoken","recent_payments":[],"recent_complaints":[],"renewals":[],"referral_balance":"0.00","unread_notifications":0},"code":200}
''';

const tenants = '''
{"status":"success","message":"OK","data":{"tenants":[{"id":"1","tenant_code":"tenant_001","company_name":"Example Co","contact_email":"owner@example.invalid","contact_phone":"9000000000","subscription_status":"active","plan_name":"Enterprise","plan_price":"1499.00","subscription_start":"2026-08-04","subscription_expiry":"2027-08-04","max_branches":"100","max_users":"500","max_customers":"100000","is_default":"1","status":"1","user_count":"41"}],"plans":{}},"code":200}
''';

const legacyDone = '''
{"type":"done","text":"OK","data":{"id":"1","tenant_code":"tenant_001","title":"wallet","description":"wallet activation","assigned_to":"0","assigned_by":"1","priority":"low","status":"pending","due_date":"2026-06-30"}}
''';

const legacyError200 = '{"type":"error","text":"Title is required."}';
const checkMobileFalse = '{"exists":false}';
const forbiddenComplaint =
    '{"status":"error","message":"Not authorized for this complaint.","data":null,"code":403}';
const employeeUnavailable =
    '{"status":"error","message":"Employee module is unavailable (empmaster table missing).","data":null,"code":503}';
const needsCompany =
    '{"status":"error","message":"Create a company profile first.","data":{"needs_company":true},"code":409}';
const validation422 =
    '{"status":"error","message":"sname and phone are required.","data":null,"code":422}';
const logoutOk =
    '{"status":"success","message":"Logged out.","data":null,"code":200}';
