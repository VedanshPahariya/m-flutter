import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/api/api_response.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/paged_list.dart';

/// A complaint ("ticket"). Keys verified from `m/complaint/list` samples.
class Ticket {
  const Ticket({
    required this.id,
    required this.customerName,
    required this.contact,
    required this.address,
    required this.category,
    required this.date,
    required this.createdAt,
    required this.source,
    required this.status,
    required this.comments,
    required this.assignee,
    required this.priority,
    required this.resolution,
    required this.customerId,
    required this.partnerName,
    required this.otpVerified,
  });

  factory Ticket.fromJson(JsonMap j) => Ticket(
    id: str(j, const ['cId', 'cid', 'id']),
    customerName: str(j, const [
      'cName',
      'customer_name',
      'name',
    ], 'Unknown customer'),
    contact: str(j, const ['cContact', 'phone', 'mobile']),
    address: str(j, const ['cAddrs', 'address']),
    category: str(j, const ['cType', 'type'], 'General'),
    date: str(j, const ['cDate', 'date']),
    createdAt: str(j, const ['addTimeStamp', 'created_at', 'cDate']),
    source: str(j, const ['source']),
    status: str(j, const ['cstatus', 'status', 'response'], 'New Ticket'),
    comments: str(j, const ['comments', 'comment', 'description']),
    assignee: str(j, const ['asgn', 'assignTo', 'assigned_to']),
    priority: str(j, const ['priority'], 'Medium'),
    resolution: str(j, const ['resolution']),
    customerId: str(j, const ['customer_id']),
    partnerName: str(j, const ['partner_name']),
    otpVerified: boolOf(j, const ['otp_verified']),
  );

  final String id;
  final String customerName;
  final String contact;
  final String address;
  final String category;
  final String date;
  final String createdAt;
  final String source;
  final String status;
  final String comments;
  final String assignee;
  final String priority;
  final String resolution;
  final String customerId;
  final String partnerName;
  final bool otpVerified;

  String get code => 'CMP-$id';
  bool get isClosed => status.toLowerCase() == 'closed';
  bool get isUnassigned => assignee.isEmpty;
}

class TicketResponse {
  const TicketResponse({
    required this.who,
    required this.when,
    required this.text,
    required this.status,
  });

  factory TicketResponse.fromJson(JsonMap j) => TicketResponse(
    who: str(j, const ['by', 'user_name', 'asgn', 'added_by', 'name'], 'Staff'),
    when: str(j, const ['created_at', 'respdate', 'date', 'addTimeStamp']),
    text: str(j, const [
      'comments',
      'comment',
      'response_text',
      'remarks',
      'text',
    ]),
    status: str(j, const ['response', 'status', 'cstatus']),
  );

  final String who;
  final String when;
  final String text;
  final String status;
}

class TicketDetail {
  const TicketDetail({required this.ticket, required this.responses});

  final Ticket ticket;
  final List<TicketResponse> responses;
}

/// Complaint statuses, verified from `m/cmsdashboard`.
const ticketStatuses = [
  'New Ticket',
  'Acknowledge',
  'In Progress',
  'Reopen',
  'Pending OTP Verification',
  'Transfer To IT',
  'Closed',
  'Reject',
];

/// Statuses a staff member can set with "Add response". Closing goes
/// through the OTP flow instead.
const ticketResponseStatuses = [
  'Acknowledge',
  'In Progress',
  'Transfer To IT',
  'Reject',
];

class TicketRepository {
  const TicketRepository(this._api);

  final ApiClient _api;
  static const pageSize = 20;

  Future<PageResult<Ticket>> list({
    required String status,
    required int offset,
    bool showAll = false,
  }) async {
    final json = await _api.post(
      Endpoints.complaintList,
      body: {
        'status': status,
        'limit': pageSize,
        'offset': offset,
        if (showAll) 'show_all': 1,
      },
    );
    final items = dataList(json, 'complaints').map(Ticket.fromJson).toList();
    return PageResult(
      items: items,
      total: PageInfo.from(dataMap(json), loaded: offset + items.length).total,
    );
  }

  /// Counts per status from `m/cmsdashboard`.
  Future<Map<String, int>> counts() async {
    final data = dataMap(await _api.get(Endpoints.cmsDashboard));
    final counts = asMap(data['counts']);
    return counts.map((k, v) => MapEntry(k, parseInt(v) ?? 0));
  }

  Future<TicketDetail> detail(String id, {Ticket? fallback}) async {
    final data = dataMap(await _api.get(Endpoints.complaintDetail(id)));
    final record = asMap(data['complaint'] ?? data['ticket']);
    final Ticket ticket;
    if (record.isNotEmpty) {
      ticket = Ticket.fromJson(record);
    } else if (data.containsKey('cId')) {
      ticket = Ticket.fromJson(data);
    } else if (fallback != null) {
      ticket = fallback;
    } else {
      throw const UnexpectedResponseException('Complaint detail has no record');
    }
    final responses = asMapList(
      data['responses'] ?? data['history'] ?? data['logs'],
    ).map(TicketResponse.fromJson).toList();
    return TicketDetail(ticket: ticket, responses: responses);
  }

  Future<String> respond({
    required String cid,
    required String status,
    required String comment,
  }) async {
    final json = await _api.post(
      Endpoints.complaintResponse,
      body: {'cid': cid, 'response': status, 'comments': comment.trim()},
    );
    final message = messageOf(json);
    return message.isEmpty ? 'Response added' : message;
  }

  Future<String> sendClosureOtp(String cid) async {
    final json = await _api.post(
      Endpoints.complaintOtpGenerate,
      body: {'cid': cid},
    );
    final message = messageOf(json);
    return message.isEmpty ? 'Code sent to the customer' : message;
  }

  Future<void> verifyClosureOtp({required String cid, required String otp}) =>
      _api.post(Endpoints.complaintOtpVerify, body: {'cid': cid, 'otp': otp});

  Future<String> close({
    required String cid,
    required String resolution,
  }) async {
    final json = await _api.post(
      Endpoints.complaintClose,
      body: {'cid': cid, 'resolution': resolution.trim()},
    );
    final message = messageOf(json);
    return message.isEmpty ? 'Ticket closed' : message;
  }

  Future<String> autoAssign() async {
    final json = await _api.post(
      Endpoints.autoAssign,
      body: {'confirm': 1},
      timeout: const Duration(seconds: 90),
    );
    final message = messageOf(json);
    return message.isEmpty ? 'Unassigned tickets were auto-assigned' : message;
  }
}
