import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/paged_list.dart';

/// An enquiry ("lead").
///
/// No populated enquiry row exists in the captured inventory (every
/// `m/enquiry/list` sample was empty), so the keys below are read
/// tolerantly: the column names accepted by `m/enquiry/add` (`sname`,
/// `phone`, `sts`, `srs`, `etyp`, `asgn`, `cmnt`, `sdate`, `eAddrs`) and the
/// `ecode` id required by `m/enquiry/response`, with common alternatives.
class Lead {
  const Lead({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.type,
    required this.source,
    required this.owner,
    required this.date,
    required this.nextFollowUp,
    required this.comment,
    required this.address,
    required this.raw,
  });

  factory Lead.fromJson(JsonMap j) => Lead(
    id: str(j, const ['ecode', 'eCode', 'id', 'eid', 'eId', 'enquiry_id']),
    name: str(j, const [
      'sname',
      'sName',
      'name',
      'customer_name',
      'cName',
    ], 'Unnamed'),
    phone: str(j, const ['phone', 'sContact', 'mobile', 'eContact', 'contact']),
    status: str(j, const ['sts', 'response', 'status', 'res']),
    type: str(j, const ['etyp', 'type', 'enquiry_type', 'softwaretype']),
    source: str(j, const ['srs', 'source']),
    owner: str(j, const ['asgn', 'assigned_to', 'assign_name']),
    date: str(j, const ['sdate', 'edate', 'created_at', 'addTimeStamp']),
    nextFollowUp: str(j, const [
      'resdate',
      'respdate',
      'next_followup',
      'followup_date',
    ]),
    comment: str(j, const ['cmnt', 'comments', 'comment']),
    address: str(j, const ['eAddrs', 'address', 'cAddrs']),
    raw: j,
  );

  final String id;
  final String name;
  final String phone;
  final String status;
  final String type;
  final String source;
  final String owner;
  final String date;
  final String nextFollowUp;
  final String comment;
  final String address;
  final JsonMap raw;
}

/// One follow-up entry in a lead's history.
class LeadActivity {
  const LeadActivity({
    required this.title,
    required this.when,
    required this.text,
    required this.by,
  });

  factory LeadActivity.fromJson(JsonMap j) => LeadActivity(
    title: str(j, const ['res', 'response', 'sts', 'status', 'type'], 'Update'),
    when: str(j, const [
      'resdate',
      'respdate',
      'created_at',
      'date',
      'addTimeStamp',
    ]),
    text: str(j, const ['cmnt', 'comments', 'comment', 'remarks']),
    by: str(j, const ['asgn', 'by', 'added_by', 'user_name']),
  );

  final String title;
  final String when;
  final String text;
  final String by;
}

class LeadDetail {
  const LeadDetail({required this.lead, required this.activity});

  final Lead lead;
  final List<LeadActivity> activity;
}

class BranchOption {
  const BranchOption(this.code, this.name);

  final String code;
  final String name;
}

/// `m/enquiry/addNewFrm`: the fields the backend accepts plus defaults.
class LeadForm {
  const LeadForm({
    required this.branches,
    required this.defaults,
    required this.fields,
  });

  final List<BranchOption> branches;
  final JsonMap defaults;
  final JsonMap fields;
}

/// Lead outcomes offered in "Log response".
///
/// Inferred: the backend's status keys (from `m/emsdashboard` counts:
/// new, converted, demo_scheduled, callback, demo_done, not_required,
/// invalid, switch_off) rendered as the labels used by its charts.
const leadStatuses = [
  'New',
  'Call Back',
  'Demo Schedule',
  'Demo Done',
  'Converted',
  'Not Required',
  'Invalid',
  'Switch Off',
];

class LeadRepository {
  const LeadRepository(this._api);

  final ApiClient _api;
  static const pageSize = 20;

  Future<PageResult<Lead>> list({
    required int offset,
    bool showAll = false,
    String? status,
  }) async {
    final json = await _api.get(
      Endpoints.enquiryList,
      query: {
        'limit': pageSize,
        'offset': offset,
        if (showAll) 'show_all': 1,
        if (status != null && status.isNotEmpty) 'st': status,
      },
    );
    final data = dataMap(json);
    final items = dataList(json, 'enquiries').map(Lead.fromJson).toList();
    return PageResult(
      items: items,
      total: PageInfo.from(data, loaded: offset + items.length).total,
    );
  }

  Future<LeadDetail> detail(String id, {Lead? fallback}) async {
    final data = dataMap(await _api.get(Endpoints.enquiryDetail(id)));
    final record = asMap(data['enquiry'] ?? data['lead'] ?? data['record']);
    final lead = record.isNotEmpty
        ? Lead.fromJson(record)
        : (fallback ?? Lead.fromJson(data));
    final history = asMapList(
      data['responses'] ??
          data['history'] ??
          data['followups'] ??
          data['activity'],
    ).map(LeadActivity.fromJson).toList();
    return LeadDetail(lead: lead, activity: history);
  }

  Future<LeadForm> form() async {
    final data = dataMap(await _api.get(Endpoints.enquiryForm));
    return LeadForm(
      branches: asMapList(data['branches'])
          .map(
            (b) => BranchOption(
              str(b, const ['BranchCode']),
              str(b, const ['BranchName']).trim(),
            ),
          )
          .where((b) => b.code.isNotEmpty)
          .toList(),
      defaults: asMap(data['defaults']),
      fields: asMap(data['fields']),
    );
  }

  /// True when an enquiry with this mobile already exists.
  Future<bool> mobileExists(String mobile) async {
    final json = await _api.post(
      Endpoints.enquiryCheckMobile,
      body: {'mobile': mobile},
    );
    return boolOf(asMap(json), const ['exists']) ||
        boolOf(dataMap(json), const ['exists']);
  }

  Future<String> add({
    required String name,
    required String phone,
    String? enquiryType,
    String? source,
    String? comment,
    String? address,
    String? branchCode,
    required DateTime date,
  }) async {
    final json = await _api.post(
      Endpoints.enquiryAdd,
      body: {
        'sname': name.trim(),
        'phone': phone.trim(),
        'sdate': _ddmmyyyy(date),
        if (enquiryType != null && enquiryType.isNotEmpty) 'etyp': enquiryType,
        if (source != null && source.isNotEmpty) 'srs': source,
        if (comment != null && comment.trim().isNotEmpty)
          'cmnt': comment.trim(),
        if (address != null && address.trim().isNotEmpty)
          'eAddrs': address.trim(),
        if (branchCode != null && branchCode.isNotEmpty) 'bcode': branchCode,
      },
    );
    final message = messageOf(json);
    return message.isEmpty ? 'Lead saved' : message;
  }

  Future<String> respond({
    required String ecode,
    required String status,
    DateTime? nextFollowUp,
    String? comment,
  }) async {
    final json = await _api.post(
      Endpoints.enquiryResponse,
      body: {
        'ecode': ecode,
        'res': status,
        if (nextFollowUp != null) 'resdate': _ddmmyyyy(nextFollowUp),
        if (comment != null && comment.trim().isNotEmpty)
          'cmnt': comment.trim(),
      },
    );
    final message = messageOf(json);
    return message.isEmpty ? 'Response logged' : message;
  }

  /// Starts call tracking; the server matches it to [callEnded].
  Future<void> callStarted(String id) =>
      _api.post(Endpoints.enquiryCallStart, body: {'id': id});

  Future<void> callEnded(String id) =>
      _api.post(Endpoints.enquiryCallEnd, body: {'id': id});

  Future<String> aiCall(String id, String phone) async {
    final json = await _api.post(
      Endpoints.enquiryAiCall,
      body: {'id': id, 'phone': phone},
      timeout: const Duration(seconds: 60),
    );
    final message = messageOf(json);
    return message.isEmpty ? 'AI call queued' : message;
  }

  Future<void> delete(String id) =>
      _api.post(Endpoints.enquiryDelete, body: {'id': id});

  static String _ddmmyyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
