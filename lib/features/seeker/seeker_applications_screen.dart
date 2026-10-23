import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/json.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import 'seeker_repository.dart';

/// `m/seeker/applications` and `m/seeker/interviews`.
class SeekerApplicationsScreen extends StatelessWidget {
  const SeekerApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My applications'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Applications'),
              Tab(text: 'Interviews'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ApplicationsTab(), _InterviewsTab()],
        ),
      ),
    );
  }
}

class _ApplicationsTab extends StatefulWidget {
  const _ApplicationsTab();

  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> {
  final _view = GlobalKey<AsyncViewState<(List<Application>, JsonMap)>>();

  Future<void> _withdraw(Application a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw application?'),
        content: Text('Your application for ${a.jobTitle} will be withdrawn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final m = await runAction(
      context,
      () => SeekerRepository(context.api).withdraw(a.id),
      successOf: (m) => m,
    );
    if (m != null) _view.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return AsyncView<(List<Application>, JsonMap)>(
      key: _view,
      load: SeekerRepository(context.api).applications,
      what: 'applications',
      skeleton: const SkeletonList(),
      isEmpty: (d) => d.$1.isEmpty,
      empty: (_) => const EmptyView(
        icon: Icons.assignment_outlined,
        title: 'No applications yet',
        message: 'Jobs you apply for appear here with their status.',
      ),
      builder: (context, d) => ListView.separated(
        itemCount: d.$1.length,
        separatorBuilder: (_, _) => const Divider(indent: 16),
        itemBuilder: (context, i) {
          final a = d.$1[i];
          return ListTile(
            title: Text(
              a.jobTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                a.company,
                'Applied ${formatDate(a.appliedAt, withYear: false)}',
              ].where((s) => s.isNotEmpty).join(' · '),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusLabel(
                  a.status,
                  color: a.status == 'rejected'
                      ? k.danger
                      : (a.status == 'selected' ? k.ok : k.accent),
                ),
                if (a.canWithdraw && a.id.isNotEmpty)
                  GestureDetector(
                    onTap: () => _withdraw(a),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Withdraw',
                        style: TextStyle(color: k.danger, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InterviewsTab extends StatelessWidget {
  const _InterviewsTab();

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return AsyncView<(List<Interview>, List<Interview>)>(
      load: SeekerRepository(context.api).interviews,
      what: 'interviews',
      skeleton: const SkeletonList(),
      isEmpty: (d) => d.$1.isEmpty && d.$2.isEmpty,
      empty: (_) => const EmptyView(
        icon: Icons.event_outlined,
        title: 'No interviews scheduled',
      ),
      builder: (context, d) {
        Widget tile(Interview i) => ListTile(
          leading: Icon(Icons.event, color: k.accent),
          title: Text(
            i.jobTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              i.company,
              formatDate(i.when),
              i.mode,
            ].where((s) => s.isNotEmpty).join(' · '),
          ),
          trailing: i.status.isEmpty ? null : Text(i.status),
        );
        return ListView(
          children: [
            if (d.$1.isNotEmpty) ...[
              const SectionLabel('Upcoming'),
              CardGroup(children: [for (final i in d.$1) tile(i)]),
            ],
            if (d.$2.isNotEmpty) ...[
              const SectionLabel('All interviews'),
              CardGroup(children: [for (final i in d.$2) tile(i)]),
            ],
          ],
        );
      },
    );
  }
}
