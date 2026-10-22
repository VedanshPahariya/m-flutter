import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/paged_list.dart';

/// A renewal record. `records_list` was empty in every sample, so keys are
/// read tolerantly using the party-master names seen in the renewal
/// reminder preview (`Party_Name`, `Mobile`, `Due_On`).
class RenewalRecord {
  const RenewalRecord({
    required this.customerId,
    required this.name,
    required this.mobile,
    required this.dueOn,
    required this.status,
    required this.amount,
  });

  factory RenewalRecord.fromJson(JsonMap j) => RenewalRecord(
    customerId: str(j, const [
      'Customer_ID',
      'customer_id',
      'license_no',
      'licence_no',
    ]),
    name: str(j, const [
      'Party_Name',
      'party_name',
      'name',
      'customer_name',
    ], 'Customer'),
    mobile: str(j, const ['Mobile', 'mobile', 'phone']),
    dueOn: str(j, const ['Due_On', 'due_on', 'due_date']),
    status: str(j, const ['status', 'Party_Status', 'renewal_status']),
    amount: str(j, const ['amount', 'bill_amount', 'Bill_Amount']),
  );

  final String customerId;
  final String name;
  final String mobile;
  final String dueOn;
  final String status;
  final String amount;
}

/// Result of a reminder run or dry run (`send_renewal_messages`).
class ReminderRun {
  const ReminderRun({
    required this.message,
    required this.sent,
    required this.failed,
    required this.recipients,
  });

  factory ReminderRun.fromJson(Object? json) {
    final data = dataMap(json);
    return ReminderRun(
      message: messageOf(json),
      sent: intOf(data, const ['sent']),
      failed: intOf(data, const ['failed']),
      recipients: asMapList(data['results'])
          .map(
            (r) => (
              str(r, const ['name'], 'Customer'),
              str(r, const ['due_on']),
              str(r, const ['status']),
            ),
          )
          .toList(),
    );
  }

  final String message;
  final int sent;
  final int failed;

  /// (name, due date, status) per customer.
  final List<(String, String, String)> recipients;
}

class RenewalRepository {
  const RenewalRepository(this._api);

  final ApiClient _api;
  static const pageSize = 20;

  Future<PageResult<RenewalRecord>> records({
    required String month,
    required int offset,
    String type = 'all',
  }) async {
    final json = await _api.get(
      Endpoints.renewalRecords,
      query: {
        'month': month,
        'type': type,
        'limit': pageSize,
        'offset': offset,
      },
    );
    final items = dataList(
      json,
      'records',
    ).map(RenewalRecord.fromJson).toList();
    return PageResult(
      items: items,
      total: PageInfo.from(dataMap(json), loaded: offset + items.length).total,
    );
  }

  /// Dry run: the backend reports who would be messaged without sending.
  Future<ReminderRun> previewReminders() async => ReminderRun.fromJson(
    await _api.post(
      Endpoints.renewalMsgSend,
      body: {'dry_run': 1},
      timeout: const Duration(seconds: 90),
    ),
  );

  /// Real send. Never retried automatically.
  Future<ReminderRun> sendReminders() async => ReminderRun.fromJson(
    await _api.post(
      Endpoints.renewalMsgSend,
      timeout: const Duration(minutes: 3),
    ),
  );
}
