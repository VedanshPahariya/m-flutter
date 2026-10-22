import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/auth/roles.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../dashboard/dashboard_repository.dart';
import '../today/today_screen.dart';

class _InsightsData {
  _InsightsData({
    this.reports,
    this.leads,
    this.tickets,
    this.chart = const [],
    this.failures = 0,
  });

  final ReportsSummary? reports;
  final LeadDashboard? leads;
  final Map<String, int>? tickets;
  final List<TargetPoint> chart;
  final int failures;
}

/// KPIs and charts from verified endpoints: `m/reports`,
/// `m/renewal/get_chart_data`, `m/emsdashboard` and `m/cmsdashboard`.
/// The data scope (own records vs branch vs tenant) is decided by the
/// server for the signed-in role.
///
/// Charts are drawn with plain widgets instead of a charting package to keep
/// the APK small.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _view = GlobalKey<AsyncViewState<_InsightsData>>();

  Future<_InsightsData> _load(BuildContext context) async {
    final repo = DashboardRepository(context.api);
    var failures = 0;
    final errors = <Object>[];
    Future<T?> soft<T>(Future<T> f) async {
      try {
        return await f;
      } on UnauthorizedException {
        rethrow;
      } catch (e) {
        failures++;
        errors.add(e);
        return null;
      }
    }

    final r = await Future.wait<Object?>([
      soft(repo.reports()),
      soft(repo.leadDashboard()),
      soft(repo.ticketCounts()),
      soft(repo.renewalChart()),
    ]);
    if (failures == 4) throw errors.first;
    return _InsightsData(
      reports: r[0] as ReportsSummary?,
      leads: r[1] as LeadDashboard?,
      tickets: r[2] as Map<String, int>?,
      chart: r[3] as List<TargetPoint>? ?? const [],
      failures: failures,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.session.role;
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: AsyncView<_InsightsData>(
        key: _view,
        load: () => _load(context),
        what: 'insights',
        skeleton: const SkeletonDashboard(),
        builder: (context, d) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (d.failures > 0)
              InlineErrorBannerCompact(
                count: d.failures,
                onRetry: () => _view.currentState?.reload(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Icon(
                    role == AppRole.staff
                        ? Icons.lock_outline
                        : Icons.calendar_today_outlined,
                    size: 16,
                    color: k.ink3,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    role == AppRole.staff
                        ? 'Figures the server shares with your role'
                        : 'Figures for your organisation',
                    style: TextStyle(color: k.ink3, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (d.reports != null) ..._kpis(context, d.reports!),
            if (d.chart.isNotEmpty) ...[
              const SectionLabel('Renewals vs target · by month'),
              _TargetChart(points: d.chart),
            ],
            if (d.leads != null) ...[
              const SectionLabel('Lead pipeline'),
              _HBarList(
                rows: [
                  ('New', d.leads!.count('new')),
                  ('Call back', d.leads!.count('callback')),
                  ('Demo scheduled', d.leads!.count('demo_scheduled')),
                  ('Demo done', d.leads!.count('demo_done')),
                  ('Converted', d.leads!.count('converted')),
                  ('Not required', d.leads!.count('not_required')),
                  ('Invalid', d.leads!.count('invalid')),
                  ('Switched off', d.leads!.count('switch_off')),
                ],
                color: k.accent,
              ),
            ],
            if (d.tickets != null && d.tickets!.isNotEmpty) ...[
              const SectionLabel('Tickets by status'),
              _HBarList(
                rows: d.tickets!.entries.map((e) => (e.key, e.value)).toList(),
                color: k.warn,
              ),
            ],
            if (d.reports != null && d.reports!.customerStatus.isNotEmpty) ...[
              const SectionLabel('Customers by status'),
              _HBarList(rows: d.reports!.customerStatus, color: k.ink3),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _kpis(BuildContext context, ReportsSummary r) {
    final tiles = <(String, String, String)>[
      (
        'Customers',
        formatCount(r.customers['total']),
        '${formatCount(r.customers['running'])} running',
      ),
      (
        'AMC due this month',
        formatCount(r.amc['due_this_month']),
        '${formatCount(r.amc['overdue'])} overdue',
      ),
      (
        'Enquiries',
        formatCount(r.enquiries['total']),
        '${formatCount(r.enquiries['new'])} new',
      ),
      (
        'Conversion',
        '${doubleOf(r.enquiries, const ['conversion_rate']).toStringAsFixed(1)}%',
        '${formatCount(r.enquiries['converted'])} converted',
      ),
      (
        'Sales',
        formatCount(r.sales['total']),
        '${formatCount(r.sales['current_month'])} this month',
      ),
      (
        'Renewals',
        formatCount(r.amc['total']),
        '${formatCount(r.amc['current_month'])} this month',
      ),
    ];
    final k = context.kora;
    return [
      const SectionLabel('Key figures'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.75,
          children: [
            for (final (label, value, sub) in tiles)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 12, color: k.ink3),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        sub,
                        style: TextStyle(fontSize: 12, color: k.ink3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

class _TargetChart extends StatelessWidget {
  const _TargetChart({required this.points});

  final List<TargetPoint> points;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final shown = points.length > 6
        ? points.sublist(points.length - 6)
        : points;
    final maxValue = shown.fold<double>(
      1,
      (m, p) => [m, p.target, p.achieved].reduce((a, b) => a > b ? a : b),
    );
    const height = 140.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            children: [
              SizedBox(
                height: height + 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final p in shown)
                      Expanded(
                        child: Semantics(
                          label:
                              '${formatMonthKey(p.month)}: ${p.achieved.round()} of ${p.target.round()}',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                formatCount(p.achieved),
                                style: TextStyle(fontSize: 10, color: k.ink3),
                              ),
                              const SizedBox(height: 2),
                              SizedBox(
                                height: height,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: height * (p.target / maxValue),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: k.control),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    Container(
                                      width: 14,
                                      height: height * (p.achieved / maxValue),
                                      decoration: BoxDecoration(
                                        color:
                                            p.achieved >= p.target &&
                                                p.target > 0
                                            ? k.ok
                                            : k.accent,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final p in shown)
                    Expanded(
                      child: Text(
                        shortMonthKey(p.month),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: k.ink3),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(color: k.accent, label: 'Achieved'),
                  const SizedBox(width: 16),
                  _Legend(color: k.control, label: 'Target', outlined: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: outlined ? null : color,
          border: outlined ? Border.all(color: color) : null,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, color: context.kora.ink3)),
    ],
  );
}

class _HBarList extends StatelessWidget {
  const _HBarList({required this.rows, required this.color});

  final List<(String, int)> rows;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final maxValue = rows.fold<int>(1, (m, r) => r.$2 > m ? r.$2 : m);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 118,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: ProgressBar(
                          value: value / maxValue,
                          color: color,
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          formatCount(value),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            color: k.ink2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
