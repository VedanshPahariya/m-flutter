import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/paged_list.dart';

/// `m/emsdashboard`: lead counts and the caller's targets.
class LeadDashboard {
  const LeadDashboard({
    required this.counts,
    required this.branchName,
    required this.saleTarget,
    required this.saleAchieved,
    required this.amcTarget,
    required this.amcAchieved,
  });

  factory LeadDashboard.fromJson(JsonMap data) {
    final targets = asMap(data['targets']);
    return LeadDashboard(
      counts: asMap(data['counts'])
          .map((k, v) => MapEntry(k, parseInt(v) ?? 0)),
      branchName: str(targets, const ['branch_name']),
      saleTarget: doubleOf(targets, const ['sale_target']),
      saleAchieved: doubleOf(targets, const ['sale_achieved']),
      amcTarget: doubleOf(targets, const ['amc_target']),
      amcAchieved: doubleOf(targets, const ['amc_achieved']),
    );
  }

  final Map<String, int> counts;
  final String branchName;
  final double saleTarget;
  final double saleAchieved;
  final double amcTarget;
  final double amcAchieved;

  int count(String key) => counts[key] ?? 0;
}

/// `m/renewal?month=`: monthly summary against target.
class RenewalSummary {
  const RenewalSummary({
    required this.month,
    required this.isAdmin,
    required this.target,
    required this.achieved,
    required this.pending,
    required this.percentage,
    required this.currentMonth,
    required this.pendingDone,
    required this.advance,
    required this.total,
    required this.months,
    required this.chart,
  });

  factory RenewalSummary.fromJson(JsonMap data) {
    final summary = asMap(data['month_summary']);
    final b = asMap(data['section_b']);
    return RenewalSummary(
      month: str(data, const ['month']),
      isAdmin: boolOf(data, const ['is_admin']),
      target: doubleOf(summary, const ['target']),
      achieved: doubleOf(summary, const ['achieved']),
      pending: doubleOf(summary, const ['pending']),
      percentage: doubleOf(summary, const ['percentage']),
      currentMonth: intOf(b, const ['current_month']),
      pendingDone: intOf(b, const ['pending_done']),
      advance: intOf(b, const ['advance']),
      total: intOf(b, const ['total']),
      months: asMapList(data['months'])
          .map((m) => (str(m, const ['value']), str(m, const ['label'])))
          .where((m) => m.$1.isNotEmpty)
          .toList(),
      chart: asMapList(data['chart_12m']).map(TargetPoint.fromJson).toList(),
    );
  }

  final String month;
  final bool isAdmin;
  final double target;
  final double achieved;
  final double pending;
  final double percentage;
  final int currentMonth;
  final int pendingDone;
  final int advance;
  final int total;
  final List<(String, String)> months;
  final List<TargetPoint> chart;
}

/// One month of renewal target vs achieved (`chart_12m`, `get_chart_data`).
class TargetPoint {
  const TargetPoint({
    required this.month,
    required this.target,
    required this.achieved,
  });

  factory TargetPoint.fromJson(JsonMap j) => TargetPoint(
    month: str(j, const ['target_month', 'month']),
    target: doubleOf(j, const ['total_target', 'target']),
    achieved: doubleOf(j, const ['achieved']),
  );

  final String month;
  final double target;
  final double achieved;
}

/// `m/reports`: tenant-wide summaries.
class ReportsSummary {
  const ReportsSummary({
    required this.sales,
    required this.amc,
    required this.customers,
    required this.enquiries,
    required this.customerStatus,
    required this.monthlyAmc,
  });

  factory ReportsSummary.fromJson(JsonMap data) => ReportsSummary(
    sales: asMap(data['sales_summary']),
    amc: asMap(data['amc_summary']),
    customers: asMap(data['customer_summary']),
    enquiries: asMap(data['enquiry_summary']),
    customerStatus: asMapList(data['customer_status'])
        .map(
          (r) =>
              (str(r, const ['status'], 'Unknown'), intOf(r, const ['total'])),
        )
        .toList(),
    monthlyAmc: asMapList(data['monthly_amc'])
        .map(
          (r) => (str(r, const ['month']), intOf(r, const ['total_renewals'])),
        )
        .toList(),
  );

  final JsonMap sales;
  final JsonMap amc;
  final JsonMap customers;
  final JsonMap enquiries;
  final List<(String, int)> customerStatus;
  final List<(String, int)> monthlyAmc;
}

/// A task from `m/tasks/listall` (shape from `m/task/get_task/{id}`).
class CrmTask {
  const CrmTask({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
  });

  factory CrmTask.fromJson(JsonMap j) => CrmTask(
    id: str(j, const ['id']),
    title: str(j, const ['title'], 'Task'),
    description: str(j, const ['description']),
    priority: str(j, const ['priority']),
    status: str(j, const ['status'], 'pending'),
    dueDate: str(j, const ['due_date']),
  );

  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String dueDate;

  bool get isDone =>
      const ['completed', 'done', 'closed'].contains(status.toLowerCase());
}

class DashboardRepository {
  const DashboardRepository(this._api);

  final ApiClient _api;

  Future<LeadDashboard> leadDashboard() async =>
      LeadDashboard.fromJson(dataMap(await _api.get(Endpoints.emsDashboard)));

  Future<RenewalSummary> renewalSummary({String? month}) async =>
      RenewalSummary.fromJson(
        dataMap(await _api.get(Endpoints.renewal, query: {'month': ?month})),
      );

  Future<List<TargetPoint>> renewalChart() async =>
      dataList(await _api.get(Endpoints.renewalChart))
          .map(TargetPoint.fromJson)
          .toList();

  Future<ReportsSummary> reports() async =>
      ReportsSummary.fromJson(dataMap(await _api.get(Endpoints.reports)));

  Future<Map<String, int>> ticketCounts() async {
    final data = dataMap(await _api.get(Endpoints.cmsDashboard));
    return asMap(data['counts']).map((k, v) => MapEntry(k, parseInt(v) ?? 0));
  }

  Future<PageResult<CrmTask>> tasks({int offset = 0, int limit = 20}) async {
    final json = await _api.get(
      Endpoints.tasks,
      query: {'limit': limit, 'offset': offset},
    );
    final items = dataList(json, 'tasks').map(CrmTask.fromJson).toList();
    return PageResult(
      items: items,
      total: PageInfo.from(dataMap(json), loaded: items.length).total,
    );
  }

  /// Marks a task done. `status` is inferred; the backend names only `id`.
  Future<void> setTaskStatus(String id, String status) =>
      _api.post(Endpoints.taskUpdateStatus, body: {'id': id, 'status': status});

  Future<int> unreadNotifications() async {
    final json = await _api.get(Endpoints.notificationsUnread);
    return intOf(asMap(json), const ['count']);
  }
}
