import '../../core/api/api_client.dart';
import '../../core/api/api_response.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/json.dart';
import '../crm/tickets/ticket_repository.dart';

/// `amc_info` block shared by `m/customer` and `m/customer/online_payment`.
class AmcInfo {
  const AmcInfo({
    required this.hasAmc,
    required this.dueDate,
    required this.daysLeft,
    required this.status,
    required this.billAmount,
    required this.softwareType,
  });

  factory AmcInfo.fromJson(JsonMap j) => AmcInfo(
    hasAmc: boolOf(j, const ['has_amc']),
    dueDate: str(j, const ['due_date']),
    daysLeft: intOf(j, const ['days_left']),
    status: str(j, const ['status']),
    billAmount: doubleOf(j, const ['bill_amount']),
    softwareType: str(j, const ['software_type']),
  );

  final bool hasAmc;
  final String dueDate;
  final int daysLeft;
  final String status;
  final double billAmount;
  final String softwareType;
}

/// `GET m/customer` (verified shape).
class CustomerHome {
  const CustomerHome({
    required this.customerId,
    required this.name,
    required this.city,
    required this.amc,
    required this.complaintCounts,
    required this.recentComplaints,
    required this.recentPayments,
    required this.referralBalance,
    required this.unreadNotifications,
  });

  factory CustomerHome.fromJson(JsonMap d) {
    final customer = asMap(d['customer']);
    return CustomerHome(
      customerId: str(d, const [
        'customer_id',
      ], str(customer, const ['Customer_ID'])),
      name: str(d, const [
        'customer_name',
      ], str(customer, const ['Party_Name'], 'Customer')),
      city: str(customer, const ['City']),
      amc: AmcInfo.fromJson(asMap(d['amc_info'])),
      complaintCounts: asMap(d['complaints_count'])
          .map((k, v) => MapEntry(k, parseInt(v) ?? 0)),
      recentComplaints: asMapList(d['recent_complaints'])
          .map(Ticket.fromJson)
          .toList(),
      recentPayments: asMapList(d['recent_payments'])
          .map(CustomerPayment.fromJson)
          .toList(),
      referralBalance: doubleOf(d, const ['referral_balance']),
      unreadNotifications: intOf(d, const ['unread_notifications']),
    );
  }

  final String customerId;
  final String name;
  final String city;
  final AmcInfo amc;
  final Map<String, int> complaintCounts;
  final List<Ticket> recentComplaints;
  final List<CustomerPayment> recentPayments;
  final double referralBalance;
  final int unreadNotifications;
}

class CustomerPayment {
  const CustomerPayment({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
    required this.status,
    required this.description,
  });

  factory CustomerPayment.fromJson(JsonMap j) => CustomerPayment(
    id: str(j, const ['id', 'receipt_id']),
    amount: str(j, const ['amount']),
    date: str(j, const ['payment_date', 'created_at']),
    method: str(j, const ['payment_method']),
    status: str(j, const ['status']),
    description: str(j, const ['description', 'purpose']),
  );

  final String id;
  final String amount;
  final String date;
  final String method;
  final String status;
  final String description;
}

class CustomerPayments {
  const CustomerPayments({
    required this.payments,
    required this.totalPaid,
    required this.pending,
  });

  final List<CustomerPayment> payments;
  final double totalPaid;
  final double pending;
}

class CustomerProfile {
  const CustomerProfile({
    required this.fields,
    required this.pendingChanges,
    required this.partyStatus,
    required this.totalComplaints,
    required this.resolvedComplaints,
    required this.referralCount,
  });

  final JsonMap fields;
  final bool pendingChanges;
  final String partyStatus;
  final int totalComplaints;
  final int resolvedComplaints;
  final int referralCount;
}

/// `m/customer/qrcode` (verified). `qr_image` points at the retired Google
/// Charts QR API, so the app renders `qr_url` itself.
class CustomerQr {
  const CustomerQr({
    required this.url,
    required this.customerId,
    required this.customerName,
    required this.company,
    required this.referralAmount,
    required this.stats,
  });

  final String url;
  final String customerId;
  final String customerName;
  final JsonMap company;
  final double referralAmount;
  final JsonMap stats;
}

class Referral {
  const Referral({
    required this.name,
    required this.amount,
    required this.status,
    required this.date,
  });

  factory Referral.fromJson(JsonMap j) => Referral(
    name: str(j, const [
      'referred_name',
      'name',
      'Party_Name',
      'customer_name',
    ], 'Referral'),
    amount: str(j, const ['amount', 'earning']),
    status: str(j, const ['status']),
    date: str(j, const ['created_at', 'date']),
  );

  final String name;
  final String amount;
  final String status;
  final String date;
}

class ReferralSummary {
  const ReferralSummary({
    required this.earnings,
    required this.totalEarned,
    required this.pending,
    required this.balance,
  });

  final List<Referral> earnings;
  final double totalEarned;
  final double pending;
  final double balance;
}

class CustomerNotification {
  const CustomerNotification({
    required this.title,
    required this.body,
    required this.when,
  });

  factory CustomerNotification.fromJson(JsonMap j) => CustomerNotification(
    title: str(j, const ['title', 'subject', 'type'], 'Notification'),
    body: str(j, const ['message', 'body', 'text']),
    when: str(j, const ['created_at', 'date']),
  );

  final String title;
  final String body;
  final String when;
}

class CustomerPortalRepository {
  const CustomerPortalRepository(this._api);

  final ApiClient _api;

  Future<CustomerHome> home() async =>
      CustomerHome.fromJson(dataMap(await _api.get(Endpoints.customerHome)));

  Future<List<Ticket>> complaints() async => dataList(
    await _api.get(Endpoints.customerComplaints),
    'complaints',
  ).map(Ticket.fromJson).toList();

  Future<String> reopen(String cid) async {
    final json = await _api.post(
      Endpoints.customerReopenComplaint,
      body: {'cid': cid},
    );
    final message = messageOf(json);
    return message.isEmpty ? 'Complaint reopened' : message;
  }

  Future<CustomerPayments> payments() async {
    final data = dataMap(await _api.get(Endpoints.customerPayments));
    return CustomerPayments(
      payments: asMapList(data['payments'])
          .map(CustomerPayment.fromJson)
          .toList(),
      totalPaid: doubleOf(data, const ['total_paid']),
      pending: doubleOf(data, const ['pending_amount']),
    );
  }

  Future<List<CustomerPayment>> renewals() async => dataList(
    await _api.get(Endpoints.customerRenewals),
    'renewals',
  ).map(CustomerPayment.fromJson).toList();

  Future<CustomerProfile> profile() async {
    final d = dataMap(await _api.get(Endpoints.customerProfile));
    return CustomerProfile(
      fields: asMap(d['customer']),
      pendingChanges: d['pending_changes'] != null,
      partyStatus: str(d, const ['party_status']),
      totalComplaints: intOf(d, const ['total_complaints']),
      resolvedComplaints: intOf(d, const ['resolved_complaints']),
      referralCount: intOf(d, const ['referral_count']),
    );
  }

  Future<CustomerQr> qr() async {
    final d = dataMap(await _api.get(Endpoints.customerQr));
    return CustomerQr(
      url: str(d, const ['qr_url']),
      customerId: str(d, const ['customer_id']),
      customerName: str(d, const ['customer_name']),
      company: asMap(d['company']),
      referralAmount: doubleOf(d, const ['referral_amount']),
      stats: asMap(d['stats']),
    );
  }

  Future<ReferralSummary> referrals() async {
    final d = dataMap(await _api.get(Endpoints.customerReferrals));
    return ReferralSummary(
      earnings: asMapList(d['earnings']).map(Referral.fromJson).toList(),
      totalEarned: doubleOf(d, const ['total_earned']),
      pending: doubleOf(d, const ['pending_earnings']),
      balance: doubleOf(d, const ['referral_balance']),
    );
  }

  Future<List<CustomerNotification>> notifications() async => dataList(
    await _api.post(Endpoints.customerNotifications),
    'notifications',
  ).map(CustomerNotification.fromJson).toList();
}
