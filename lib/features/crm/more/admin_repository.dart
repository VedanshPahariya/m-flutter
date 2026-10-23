import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/paged_list.dart';

/// A user account. In this backend users are stored as "branches"
/// (`BranchCode` is the user id, `btype` 1 = admin, 2 = staff).
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.city,
    required this.active,
    required this.isAdmin,
  });

  factory TeamMember.fromJson(JsonMap j) => TeamMember(
    id: str(j, const ['BranchCode']),
    name: str(j, const ['BranchName', 'ContactPerson'], 'User').trim(),
    email: str(j, const ['BranchEmail']),
    mobile: str(j, const ['CPMphone', 'CPTel']),
    city: str(j, const ['city', 'location']),
    active: boolOf(j, const ['status'], true),
    isAdmin: str(j, const ['btype']) == '1',
  );

  final String id;
  final String name;
  final String email;
  final String mobile;
  final String city;
  final bool active;
  final bool isAdmin;
}

/// A pending customer sign-up. Shape not captured (always empty).
class PendingApproval {
  const PendingApproval({
    required this.customerId,
    required this.name,
    required this.contact,
    required this.source,
    required this.when,
  });

  factory PendingApproval.fromJson(JsonMap j) => PendingApproval(
    customerId: str(j, const ['customer_id', 'Customer_ID', 'id']),
    name: str(j, const [
      'Party_Name',
      'party_name',
      'name',
      'company_name',
    ], 'New customer'),
    contact: [
      str(j, const ['Contact_Person', 'contact_person']),
      str(j, const ['Mobile', 'mobile', 'phone']),
    ].where((s) => s.isNotEmpty).join(' · '),
    source: str(j, const ['source', 'request_type']),
    when: str(j, const ['requested_at', 'created_at', 'pending_requested_at']),
  );

  final String customerId;
  final String name;
  final String contact;
  final String source;
  final String when;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    required this.unread,
  });

  factory AppNotification.fromJson(JsonMap j) => AppNotification(
    id: str(j, const ['id', 'notification_id']),
    title: str(j, const ['title', 'subject', 'type'], 'Notification'),
    body: str(j, const ['message', 'body', 'text', 'description']),
    when: str(j, const ['created_at', 'date', 'time']),
    unread: !boolOf(j, const ['is_read', 'read', 'seen']),
  );

  final String id;
  final String title;
  final String body;
  final String when;
  final bool unread;
}

/// A QR field-visit assignment (`m/qrfield/tasks`). Shape not captured.
class FieldAssignment {
  const FieldAssignment({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.total,
    required this.completed,
    required this.status,
  });

  factory FieldAssignment.fromJson(JsonMap j) => FieldAssignment(
    id: str(j, const ['assignment_id', 'id']),
    title: str(j, const ['title', 'batch_title', 'batch_name'], 'Assignment'),
    dueDate: str(j, const ['due_date']),
    total: intOf(j, const ['total_customers', 'customer_count', 'total']),
    completed: intOf(j, const [
      'completed_customers',
      'completed_count',
      'completed',
    ]),
    status: str(j, const ['status']),
  );

  final String id;
  final String title;
  final String dueDate;
  final int total;
  final int completed;
  final String status;
}

class FieldCustomer {
  const FieldCustomer({
    required this.progressId,
    required this.name,
    required this.address,
    required this.done,
  });

  factory FieldCustomer.fromJson(JsonMap j) => FieldCustomer(
    progressId: str(j, const ['progress_id', 'id']),
    name: str(j, const [
      'Party_Name',
      'party_name',
      'customer_name',
      'name',
    ], 'Customer'),
    address: str(j, const ['Address', 'address', 'City', 'city']),
    done:
        boolOf(j, const ['is_completed', 'completed', 'done']) ||
        str(j, const ['status']).toLowerCase() == 'completed',
  );

  final String progressId;
  final String name;
  final String address;
  final bool done;
}

class Payment {
  const Payment({
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.method,
    required this.status,
  });

  factory Payment.fromJson(JsonMap j) => Payment(
    customerId: str(j, const ['customer_id']),
    customerName: str(j, const ['customer_name', 'name'], 'Customer'),
    amount: str(j, const ['amount']),
    date: str(j, const ['payment_date', 'created_at']),
    method: str(j, const ['payment_method']),
    status: str(j, const ['status']),
  );

  final String customerId;
  final String customerName;
  final String amount;
  final String date;
  final String method;
  final String status;
}

class Tenant {
  const Tenant({
    required this.code,
    required this.name,
    required this.plan,
    required this.status,
    required this.expiry,
    required this.users,
    required this.email,
  });

  factory Tenant.fromJson(JsonMap j) => Tenant(
    code: str(j, const ['tenant_code']),
    name: str(j, const ['company_name'], 'Tenant'),
    plan: str(j, const ['plan_name']),
    status: str(j, const ['subscription_status']),
    expiry: str(j, const ['subscription_expiry']),
    users: intOf(j, const ['user_count']),
    email: str(j, const ['contact_email']),
  );

  final String code;
  final String name;
  final String plan;
  final String status;
  final String expiry;
  final int users;
  final String email;
}

class ErrorLogEntry {
  const ErrorLogEntry({
    required this.time,
    required this.level,
    required this.message,
    required this.location,
  });

  factory ErrorLogEntry.fromJson(JsonMap j) {
    final details = asMap(j['details']);
    return ErrorLogEntry(
      time: str(j, const ['time', 'date']),
      level: str(j, const ['level'], 'ERROR'),
      message: str(j, const ['message']),
      location: [
        str(details, const ['file']),
        str(details, const ['line']),
        str(details, const ['uri']),
      ].where((s) => s.isNotEmpty).join(' · '),
    );
  }

  final String time;
  final String level;
  final String message;
  final String location;
}

class QrBatch {
  const QrBatch({
    required this.id,
    required this.title,
    required this.priority,
    required this.dueDate,
    required this.status,
    required this.totalCustomers,
    required this.completedCustomers,
  });

  factory QrBatch.fromJson(JsonMap j) => QrBatch(
    id: str(j, const ['id', 'batch_id']),
    title: str(j, const ['title'], 'Batch'),
    priority: str(j, const ['priority']),
    dueDate: str(j, const ['due_date']),
    status: str(j, const ['status', 'batch_status']),
    totalCustomers: intOf(j, const ['total_customers']),
    completedCustomers: intOf(j, const ['completed_customers']),
  );

  final String id;
  final String title;
  final String priority;
  final String dueDate;
  final String status;
  final int totalCustomers;
  final int completedCustomers;
}

/// Secondary CRM modules: team, approvals, notifications, field visits,
/// payments and the super-admin platform views.
class AdminRepository {
  const AdminRepository(this._api);

  final ApiClient _api;

  Future<PageResult<TeamMember>> team({required int offset}) async {
    final json = await _api.get(
      Endpoints.branchList,
      query: {'limit': 50, 'offset': offset},
    );
    final items = dataList(json, 'branches').map(TeamMember.fromJson).toList();
    return PageResult(
      items: items,
      total: PageInfo.from(dataMap(json), loaded: offset + items.length).total,
    );
  }

  Future<void> toggleMember(String id) =>
      _api.post(Endpoints.branchChangeStatus, body: {'id': id});

  Future<PageResult<PendingApproval>> approvals({required int offset}) async {
    final json = await _api.get(
      Endpoints.approvalsPending,
      query: {'limit': 20, 'offset': offset},
    );
    final items = dataList(
      json,
      'pending_requests',
    ).map(PendingApproval.fromJson).toList();
    return PageResult(
      items: items,
      total: PageInfo.from(dataMap(json), loaded: offset + items.length).total,
    );
  }

  Future<String> decide(String customerId, {required bool approve}) async {
    final json = await _api.post(
      approve ? Endpoints.approvalsApprove : Endpoints.approvalsReject,
      body: {'customer_id': customerId},
    );
    final message = messageOf(json);
    return message.isNotEmpty ? message : (approve ? 'Approved' : 'Rejected');
  }

  Future<PageResult<AppNotification>> notifications({
    required int offset,
  }) async {
    const perPage = 50;
    final json = await _api.get(
      Endpoints.notifications,
      query: {'page': offset ~/ perPage + 1},
    );
    final items = dataList(
      json,
      'notifications',
    ).map(AppNotification.fromJson).toList();
    return PageResult(
      items: items,
      total: PageInfo.from(
        dataMap(json),
        fallbackLimit: perPage,
        loaded: offset + items.length,
      ).total,
    );
  }

  Future<void> markRead(String id) =>
      _api.post(Endpoints.notificationMarkRead, body: {'id': id});

  Future<void> markAllRead() => _api.post(Endpoints.notificationsMarkAll);

  Future<List<FieldAssignment>> fieldAssignments() async {
    final json = await _api.get(Endpoints.fieldTasks);
    return dataList(json, 'assignments').map(FieldAssignment.fromJson).toList();
  }

  Future<List<FieldCustomer>> fieldCustomers(String assignmentId) async {
    final json = await _api.post(
      Endpoints.fieldCustomers,
      body: {'assignment_id': assignmentId},
    );
    final data = dataMap(json);
    final list = data['customers'] is List
        ? asMapList(data['customers'])
        : dataList(json);
    return list.map(FieldCustomer.fromJson).toList();
  }

  Future<void> markFieldCustomerDone(String progressId) =>
      _api.post(Endpoints.fieldCustomerDone, body: {'progress_id': progressId});

  Future<String> submitAssignment(String assignmentId) async {
    final json = await _api.post(
      Endpoints.fieldAssignmentDone,
      body: {'assignment_id': assignmentId},
    );
    final message = messageOf(json);
    return message.isEmpty ? 'Assignment submitted' : message;
  }

  Future<PageResult<Payment>> payments({required int offset}) async {
    final json = await _api.get(
      Endpoints.payments,
      query: {'limit': 20, 'offset': offset},
    );
    final items = dataList(json, 'payments').map(Payment.fromJson).toList();
    return PageResult(
      items: items,
      total: PageInfo.from(dataMap(json), loaded: offset + items.length).total,
    );
  }

  Future<List<Tenant>> tenants() async => dataList(
    await _api.get(Endpoints.tenants),
    'tenants',
  ).map(Tenant.fromJson).toList();

  Future<List<ErrorLogEntry>> errorLog() async => dataList(
    await _api.get(Endpoints.errorLog),
    'entries',
  ).map(ErrorLogEntry.fromJson).toList();

  Future<PageResult<QrBatch>> qrBatches({required int offset}) async {
    final json = await _api.get(
      Endpoints.qrBatches,
      query: {'limit': 20, 'offset': offset},
    );
    final items = dataList(json, 'batches').map(QrBatch.fromJson).toList();
    return PageResult(
      items: items,
      total: PageInfo.from(dataMap(json), loaded: offset + items.length).total,
    );
  }
}
