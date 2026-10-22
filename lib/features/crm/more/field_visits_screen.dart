import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import 'admin_repository.dart';

/// QR field-visit assignments (`m/qrfield/tasks`).
class FieldVisitsScreen extends StatelessWidget {
  const FieldVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Field visits')),
      body: AsyncView<List<FieldAssignment>>(
        load: repo.fieldAssignments,
        what: 'field visits',
        skeleton: const SkeletonList(),
        isEmpty: (list) => list.isEmpty,
        empty: (_) => const EmptyView(
          icon: Icons.qr_code_2,
          title: 'No field visits assigned',
          message: 'QR sticker batches assigned to you appear here.',
        ),
        builder: (context, list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(indent: 16),
          itemBuilder: (context, i) {
            final a = list[i];
            final ratio = a.total > 0 ? a.completed / a.total : 0.0;
            return ListTile(
              title: Text(
                a.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (a.dueDate.isNotEmpty)
                        'Due ${formatDate(a.dueDate, withYear: false)}',
                      if (a.total > 0) '${a.completed} of ${a.total} done',
                      if (a.status.isNotEmpty) a.status,
                    ].join(' · '),
                    style: TextStyle(color: k.ink3),
                  ),
                  if (a.total > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ProgressBar(value: ratio, height: 6),
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: a.id.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _AssignmentScreen(assignment: a),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _AssignmentScreen extends StatefulWidget {
  const _AssignmentScreen({required this.assignment});

  final FieldAssignment assignment;

  @override
  State<_AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<_AssignmentScreen> {
  final _view = GlobalKey<AsyncViewState<List<FieldCustomer>>>();
  final Set<String> _done = {};
  final Set<String> _saving = {};

  AdminRepository get _repo => AdminRepository(context.api);

  Future<void> _markDone(FieldCustomer c) async {
    setState(() => _saving.add(c.progressId));
    final ok = await runAction(context, () async {
      await _repo.markFieldCustomerDone(c.progressId);
      return true;
    }, success: '${c.name} marked done');
    if (!mounted) return;
    setState(() {
      _saving.remove(c.progressId);
      if (ok == true) _done.add(c.progressId);
    });
  }

  Future<void> _submit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit this batch?'),
        content: const Text(
          'Your admin will be notified to review and close it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await runAction(
      context,
      () => _repo.submitAssignment(widget.assignment.id),
      successOf: (m) => m,
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: Text(widget.assignment.title)),
      body: AsyncView<List<FieldCustomer>>(
        key: _view,
        load: () => _repo.fieldCustomers(widget.assignment.id),
        what: 'customers',
        skeleton: const SkeletonList(),
        isEmpty: (list) => list.isEmpty,
        empty: (_) => const EmptyView(title: 'No customers in this assignment'),
        builder: (context, list) {
          final pending = list
              .where((c) => !c.done && !_done.contains(c.progressId))
              .length;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${list.length - pending} of ${list.length} visited',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ProgressBar(
                      value: list.isEmpty
                          ? 0
                          : (list.length - pending) / list.length,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stick the QR on the billing counter, scan once to confirm, then mark done.',
                      style: TextStyle(fontSize: 12, color: k.ink3),
                    ),
                  ],
                ),
              ),
              for (final c in list)
                ListTile(
                  title: Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: c.address.isEmpty ? null : Text(c.address),
                  trailing: c.done || _done.contains(c.progressId)
                      ? StatusLabel('Done', color: k.ok)
                      : _saving.contains(c.progressId)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FilledButton.tonal(
                          onPressed: c.progressId.isEmpty
                              ? null
                              : () => _markDone(c),
                          child: const Text('Done'),
                        ),
                ),
              if (pending == 0)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit batch'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
