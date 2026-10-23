import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/auth/roles.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/skeleton.dart';
import '../crm_shell.dart';
import '../customers/customer_list_screen.dart';
import '../dashboard/dashboard_repository.dart';
import '../more/admin_repository.dart';
import '../more/approvals_screen.dart';
import '../notifications/notifications_screen.dart';
import '../renewals/renewals_screen.dart';

/// Everything the Today screen shows. Each part loads independently so one
/// failing module (for example a 503) does not blank the whole dashboard.
class _TodayData {
  _TodayData({
    this.leads,
    this.tickets,
    this.renewal,
    this.tasks = const [],
    this.unread = 0,
    this.pendingApprovals,
    this.failures = const [],
  });

  final LeadDashboard? leads;
  final Map<String, int>? tickets;
  final RenewalSummary? renewal;
  final List<CrmTask> tasks;
  final int unread;
  final int? pendingApprovals;
  final List<Object> failures;
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _view = GlobalKey<AsyncViewState<_TodayData>>();
  final Set<String> _doneTasks = {};
  final _unread = ValueNotifier<int>(0);

  @override
  void dispose() {
    _unread.dispose();
    super.dispose();
  }

  Future<_TodayData> _load() async {
    final repo = DashboardRepository(context.api);
    final admin = AdminRepository(context.api);
    final canApprove = context.session.can.approveSignups;
    final failures = <Object>[];
    Future<T?> soft<T>(Future<T> f) async {
      try {
        return await f;
      } on UnauthorizedException {
        rethrow;
      } catch (e) {
        failures.add(e);
        return null;
      }
    }

    final results = await Future.wait<Object?>([
      soft(repo.leadDashboard()),
      soft(repo.ticketCounts()),
      soft(repo.renewalSummary()),
      soft(repo.tasks()),
      soft(repo.unreadNotifications()),
      if (canApprove) soft(admin.approvals(offset: 0)),
    ]);
    if (failures.length >= 5) throw failures.first;
    return _TodayData(
      leads: results[0] as LeadDashboard?,
      tickets: results[1] as Map<String, int>?,
      renewal: results[2] as RenewalSummary?,
      tasks: (results[3] as PageResult<CrmTask>?)?.items ?? const [],
      unread: _unread.value = results[4] as int? ?? 0,
      pendingApprovals: canApprove
          ? (results[5] as PageResult<PendingApproval>?)?.total
          : null,
      failures: failures,
    );
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final session = context.session;
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Avatar(session.user.initials, size: 36, highlighted: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.user.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    [session.role.label, ?session.user.tenantCode].join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: k.ink3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search customers',
            icon: const Icon(Icons.search),
            onPressed: () => _open(const CustomerListScreen()),
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: ValueListenableBuilder<int>(
              valueListenable: _unread,
              builder: (_, unread, _) => Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              _view.currentState?.reload();
            },
          ),
        ],
      ),
      body: AsyncView<_TodayData>(
        key: _view,
        load: _load,
        what: 'today’s summary',
        skeleton: const SkeletonDashboard(),
        builder: (context, data) => _content(context, data),
      ),
    );
  }

  Widget _content(BuildContext context, _TodayData data) {
    final k = context.kora;
    final shell = CrmShell.of(context);
    final role = context.session.role;
    final leads = data.leads;
    final tickets = data.tickets ?? const {};
    final openTickets =
        (tickets['New Ticket'] ?? 0) +
        (tickets['Acknowledge'] ?? 0) +
        (tickets['In Progress'] ?? 0) +
        (tickets['Reopen'] ?? 0);
    final pendingOtp = tickets['Pending OTP Verification'] ?? 0;
    final followUps =
        (leads?.count('today_callback') ?? 0) +
        (leads?.count('today_demo') ?? 0);

    final attention = <_Attention>[
      if (data.tickets != null && (tickets['New Ticket'] ?? 0) > 0)
        _Attention(
          k.danger,
          '${tickets['New Ticket']} new tickets',
          'Not yet acknowledged',
          () => shell?.selectTab(2),
        ),
      if (data.tickets != null && (tickets['Reopen'] ?? 0) > 0)
        _Attention(
          k.danger,
          '${tickets['Reopen']} reopened tickets',
          'Customer reported the issue again',
          () => shell?.selectTab(2),
        ),
      if (pendingOtp > 0)
        _Attention(
          k.warn,
          '$pendingOtp tickets awaiting OTP',
          'Close them with the customer’s code',
          () => shell?.selectTab(2),
        ),
      if (followUps > 0)
        _Attention(
          k.warn,
          '$followUps follow-ups today',
          '${leads?.count('today_callback') ?? 0} call backs · ${leads?.count('today_demo') ?? 0} demos',
          () => shell?.selectTab(1),
        ),
      if ((data.pendingApprovals ?? 0) > 0)
        _Attention(
          k.accent,
          '${data.pendingApprovals} sign-ups awaiting approval',
          'Customers waiting for portal access',
          () => _open(const ApprovalsScreen()),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (data.failures.isNotEmpty)
          InlineErrorBannerCompact(
            count: data.failures.length,
            onRetry: () => _view.currentState?.reload(),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            formatLongDay(DateTime.now()),
            style: TextStyle(color: k.ink3, fontWeight: FontWeight.w500),
          ),
        ),
        const SectionLabel('Needs attention'),
        if (attention.isEmpty)
          CardGroup(
            children: [
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: k.ok),
                title: const Text('Nothing urgent right now'),
              ),
            ],
          )
        else
          CardGroup(
            children: [
              for (final a in attention)
                ListTile(
                  onTap: a.onTap,
                  leading: Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      color: a.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  title: Text(
                    a.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(a.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                ),
            ],
          ),
        if (data.renewal != null)
          _RenewalTarget(
            summary: data.renewal!,
            role: role,
            onTap: () => _open(const RenewalsScreen()),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '$followUps',
                  label: 'Follow-ups today',
                  onTap: () => shell?.selectTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: '$openTickets',
                  label: 'Open tickets',
                  onTap: () => shell?.selectTab(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: '${leads?.count('new') ?? 0}',
                  label: 'New leads',
                  onTap: () => shell?.selectTab(1),
                ),
              ),
            ],
          ),
        ),
        SectionLabel(
          'Tasks · ${data.tasks.where((t) => !t.isDone && !_doneTasks.contains(t.id)).length} open',
        ),
        if (data.tasks.isEmpty)
          CardGroup(
            children: [
              ListTile(
                title: Text(
                  'No tasks assigned',
                  style: TextStyle(color: k.ink3),
                ),
              ),
            ],
          )
        else
          CardGroup(
            children: [for (final t in data.tasks) _taskTile(context, t)],
          ),
      ],
    );
  }

  Widget _taskTile(BuildContext context, CrmTask task) {
    final k = context.kora;
    final done = task.isDone || _doneTasks.contains(task.id);
    return ListTile(
      title: Text(
        task.title,
        style: TextStyle(
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? k.mute : k.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        [
          if (task.dueDate.isNotEmpty)
            'Due ${formatDate(task.dueDate, withYear: false)}',
          if (task.priority.isNotEmpty) task.priority,
          if (task.description.isNotEmpty) task.description,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: done ? 'Done' : 'Mark done',
        icon: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? k.ok : k.mute,
        ),
        onPressed: done ? null : () => _markDone(task),
      ),
    );
  }

  Future<void> _markDone(CrmTask task) async {
    final repo = DashboardRepository(context.api);
    setState(() => _doneTasks.add(task.id));
    final ok = await runAction(context, () async {
      await repo.setTaskStatus(task.id, 'completed');
      return true;
    });
    if (!mounted) return;
    if (ok == null) {
      setState(() => _doneTasks.remove(task.id));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task marked done'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            setState(() => _doneTasks.remove(task.id));
            await runAction(
              context,
              () => repo.setTaskStatus(task.id, 'pending'),
            );
          },
        ),
      ),
    );
  }
}

class _Attention {
  const _Attention(this.color, this.title, this.subtitle, this.onTap);

  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _RenewalTarget extends StatelessWidget {
  const _RenewalTarget({
    required this.summary,
    required this.role,
    required this.onTap,
  });

  final RenewalSummary summary;
  final AppRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final pace = now.day / daysInMonth;
    final ratio = summary.target > 0 ? summary.achieved / summary.target : 0.0;
    final scope = role == AppRole.staff ? 'Your target' : 'Branch target';
    return Column(
      children: [
        SectionLabel(
          '${formatMonthKey(summary.month)} renewals · $scope',
          trailing: TextButton(onPressed: onTap, child: const Text('Details')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCount(summary.achieved),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'of ${formatCount(summary.target)} renewals',
                            style: TextStyle(color: k.ink3),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(ratio * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: k.accent,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ProgressBar(value: ratio, marker: pace),
                    const SizedBox(height: 8),
                    Text(
                      summary.target <= 0
                          ? 'No target set for this month'
                          : ratio >= pace
                          ? 'On pace · ▏ marks today’s pace'
                          : 'Behind pace · ▏ marks today’s pace',
                      style: TextStyle(
                        fontSize: 12,
                        color: summary.target > 0 && ratio < pace
                            ? k.warn
                            : k.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact "some sections failed" notice used on dashboards.
class InlineErrorBannerCompact extends StatelessWidget {
  const InlineErrorBannerCompact({
    super.key,
    required this.count,
    required this.onRetry,
  });

  final int count;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Material(
      color: k.warnContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: k.warnInk),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                count == 1
                    ? 'One section couldn’t load'
                    : '$count sections couldn’t load',
                style: TextStyle(color: k.warnInk, fontSize: 13),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
