import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../customers/customer_detail_screen.dart';
import '../customers/customer_list_screen.dart';
import '../dashboard/dashboard_repository.dart';
import 'renewal_repository.dart';

/// Month view of AMC renewals against target (`m/renewal?month=`), the
/// month's records, and one bulk action: WhatsApp reminders, always
/// previewed with `dry_run=1` before sending.
class RenewalsScreen extends StatefulWidget {
  const RenewalsScreen({super.key});

  @override
  State<RenewalsScreen> createState() => _RenewalsScreenState();
}

class _RenewalsScreenState extends State<RenewalsScreen> {
  String? _month;
  List<(String, String)> _months = const [];

  Future<void> _remind() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) =>
          _ReminderSheet(repository: RenewalRepository(context.api)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryRepo = DashboardRepository(context.api);
    final recordsRepo = RenewalRepository(context.api);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renewals'),
        actions: [
          TextButton.icon(
            onPressed: _remind,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Reminders'),
          ),
        ],
      ),
      body: AsyncView<RenewalSummary>(
        key: ValueKey(_month),
        load: () async {
          final s = await summaryRepo.renewalSummary(month: _month);
          if (s.months.isNotEmpty && _months.isEmpty) _months = s.months;
          return s;
        },
        what: 'renewals',
        skeleton: const SkeletonDashboard(),
        builder: (context, s) => PagedListView<RenewalRecord>(
          key: ValueKey('records-${s.month}'),
          what: 'renewal records',
          fetch: (offset) =>
              recordsRepo.records(month: s.month, offset: offset),
          header: (context, total) => _Header(
            summary: s,
            months: _months,
            onMonth: (m) => setState(() => _month = m),
          ),
          empty: (_) => ListView(
            children: [
              _Header(
                summary: s,
                months: _months,
                onMonth: (m) => setState(() => _month = m),
              ),
              const SizedBox(
                height: 260,
                child: EmptyView(
                  title: 'No renewal records this month',
                  icon: Icons.autorenew,
                ),
              ),
            ],
          ),
          itemBuilder: (context, r, _) {
            final (tone, label) = amcTone(context, r.dueOn);
            return ListTile(
              title: Text(
                r.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [r.customerId, r.status].where((x) => x.isNotEmpty).join(' · '),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (r.amount.isNotEmpty)
                    Text(
                      formatRupees(r.amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  StatusLabel(label, color: tone, bold: false),
                ],
              ),
              onTap: r.customerId.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailScreen(
                          customerId: r.customerId,
                          name: r.name,
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.summary,
    required this.months,
    required this.onMonth,
  });

  final RenewalSummary summary;
  final List<(String, String)> months;
  final ValueChanged<String> onMonth;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final index = months.indexWhere((m) => m.$1 == summary.month);
    final ratio = summary.target > 0 ? summary.achieved / summary.target : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
              onPressed: index >= 0 && index < months.length - 1
                  ? () => onMonth(months[index + 1].$1)
                  : null,
            ),
            Text(
              formatMonthKey(summary.month),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            IconButton(
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
              onPressed: index > 0 ? () => onMonth(months[index - 1].$1) : null,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
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
                          'of ${formatCount(summary.target)} target',
                          style: TextStyle(color: k.ink3),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${summary.percentage.round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: k.accent,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ProgressBar(value: ratio),
                  const SizedBox(height: 6),
                  Text(
                    '${formatCount(summary.pending)} pending',
                    style: TextStyle(fontSize: 12, color: k.ink3),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${summary.currentMonth}',
                  label: 'This month',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  value: '${summary.pendingDone}',
                  label: 'Pending done',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(value: '${summary.advance}', label: 'Advance'),
              ),
            ],
          ),
        ),
        const SectionLabel('Records'),
      ],
    );
  }
}

/// Dry run first, then an explicit confirm. The send is never retried
/// automatically because a timeout does not mean messages were not sent.
class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.repository});

  final RenewalRepository repository;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  ReminderRun? _preview;
  ReminderRun? _result;
  Object? _error;
  bool _busy = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await widget.repository.previewReminders();
      if (mounted) setState(() => _preview = preview);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final result = await widget.repository.sendReminders();
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final preview = _preview;
    final int willSend;
    if (preview == null) {
      willSend = 0;
    } else if (preview.recipients.isEmpty) {
      willSend = preview.sent;
    } else {
      willSend = preview.recipients.where((r) => r.$3 == 'would_send').length;
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send renewal reminders', style: context.text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'WhatsApp reminders to customers with AMC due.',
              style: TextStyle(color: k.ink3),
            ),
            const SizedBox(height: 16),
            if (_busy)
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Checking who would receive a reminder…',
                    style: TextStyle(color: k.ink3),
                  ),
                ],
              )
            else if (_result != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.task_alt,
                    color: _result!.failed == 0 ? k.ok : k.warn,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _result!.message.isNotEmpty
                          ? _result!.message
                          : '${_result!.sent} sent, ${_result!.failed} failed',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ] else if (_error != null && preview == null) ...[
              Text(describeError(_error!), style: TextStyle(color: k.danger)),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _loadPreview,
                child: const Text('Try again'),
              ),
            ] else if (preview != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: k.sunken,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DRY RUN RESULT',
                      style: TextStyle(
                        fontSize: 11,
                        color: k.ink3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: k.ok, size: 18),
                        const SizedBox(width: 8),
                        Text('$willSend customers would receive the reminder'),
                      ],
                    ),
                    if (preview.failed > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.do_not_disturb_on,
                            color: k.mute,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text('${preview.failed} would be skipped'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (preview.recipients.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final r in preview.recipients)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.$1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                formatDate(r.$2, withYear: false),
                                style: TextStyle(color: k.ink3, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Messages are sent from the branch WhatsApp number and can’t be recalled.',
                style: TextStyle(fontSize: 12, color: k.ink3),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error is TimeoutApiException
                      ? 'No response from the server. Some messages may have been sent — do not resend right away.'
                      : describeError(_error!),
                  style: TextStyle(color: k.danger),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _sending ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _sending ||
                              willSend == 0 ||
                              _error is TimeoutApiException
                          ? null
                          : _send,
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text('Send to $willSend'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
