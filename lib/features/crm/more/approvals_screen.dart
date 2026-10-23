import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import 'admin_repository.dart';

/// Pending customer sign-ups (`m/approvals/pending`), approved or rejected
/// inline. Staff see an explanation instead of the list.
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final _list = GlobalKey<PagedListViewState<PendingApproval>>();
  final Map<String, bool> _decided = {};

  Future<void> _decide(PendingApproval p, bool approve) async {
    if (!approve) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Reject sign-up?'),
          content: Text('${p.name} will not get portal access.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final message = await runAction(
      context,
      () => AdminRepository(context.api).decide(p.customerId, approve: approve),
      successOf: (m) => '${p.name}: $m',
    );
    if (message != null && mounted) {
      setState(() => _decided[p.customerId] = approve);
    }
  }

  @override
  Widget build(BuildContext context) {
    final can = context.session.can;
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: !can.approveSignups
          ? const MessageView(
              icon: Icons.lock_outline,
              title: 'Only branch admins can approve sign-ups',
              message:
                  'Ask your branch admin, or sign in with an admin account.',
            )
          : PagedListView<PendingApproval>(
              key: _list,
              what: 'approvals',
              fetch: (offset) =>
                  AdminRepository(context.api).approvals(offset: offset),
              empty: (_) => const EmptyView(
                icon: Icons.how_to_reg_outlined,
                title: 'No pending sign-ups',
                message: 'Approved customers get portal access and a QR code.',
              ),
              itemBuilder: (context, p, _) {
                final decision = _decided[p.customerId];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (p.when.isNotEmpty)
                            Text(
                              formatAge(p.when),
                              style: TextStyle(fontSize: 12, color: k.ink3),
                            ),
                        ],
                      ),
                      if (p.contact.isNotEmpty)
                        Text(p.contact, style: TextStyle(color: k.ink3)),
                      if (p.source.isNotEmpty)
                        Text(
                          p.source,
                          style: TextStyle(color: k.ink3, fontSize: 13),
                        ),
                      const SizedBox(height: 10),
                      if (decision == null)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _decide(p, false),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _decide(p, true),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        )
                      else
                        StatusLabel(
                          decision ? 'Approved' : 'Rejected',
                          color: decision ? k.ok : k.danger,
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
