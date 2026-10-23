import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/launch.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../crm/tickets/ticket_list_screen.dart';
import '../crm/tickets/ticket_repository.dart';
import 'customer_repository.dart';

/// The customer's complaints (`m/customer/complaints`). Closed complaints
/// can be reopened (`m/customer/reopenComplaint`, field `cid`).
///
/// Raising a new complaint is not offered: `m/customer/createComplaint` was
/// skipped in the inventory and its fields are unknown. Customers are
/// pointed to support instead.
class CustomerTicketsScreen extends StatefulWidget {
  const CustomerTicketsScreen({super.key});

  @override
  State<CustomerTicketsScreen> createState() => _CustomerTicketsScreenState();
}

class _CustomerTicketsScreenState extends State<CustomerTicketsScreen> {
  final _view = GlobalKey<AsyncViewState<List<Ticket>>>();

  Future<void> _reopen(Ticket t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reopen this complaint?'),
        content: Text('${t.code} will go back to the support team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reopen'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final message = await runAction(
      context,
      () => CustomerPortalRepository(context.api).reopen(t.id),
      successOf: (m) => m,
    );
    if (message != null) _view.currentState?.reload();
  }

  Future<void> _contactSupport() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final qr = await CustomerPortalRepository(context.api).qr();
      final phone = _supportPhone(qr.company);
      if (phone.isEmpty || !await dialPhone(phone)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Support number unavailable')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Couldn’t load the support number')),
      );
    }
  }

  static String _supportPhone(Map<String, dynamic> company) =>
      (company['mobile'] ?? company['mobile2'] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My tickets'),
        actions: [
          TextButton.icon(
            onPressed: _contactSupport,
            icon: const Icon(Icons.support_agent),
            label: const Text('Support'),
          ),
        ],
      ),
      body: AsyncView<List<Ticket>>(
        key: _view,
        load: CustomerPortalRepository(context.api).complaints,
        what: 'your tickets',
        skeleton: const SkeletonList(),
        isEmpty: (l) => l.isEmpty,
        empty: (_) => EmptyView(
          icon: Icons.check_circle_outline,
          title: 'No tickets',
          message: 'Need help? Call support or scan the QR sticker on your billing counter to raise a ticket.',
          action: FilledButton.tonal(
            onPressed: _contactSupport,
            child: const Text('Call support'),
          ),
        ),
        builder: (context, list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(indent: 16),
          itemBuilder: (context, i) {
            final t = list[i];
            return ListTile(
              title: Text(
                t.comments.isNotEmpty ? t.comments : '${t.category} issue',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    StatusLabel(
                      t.status,
                      color: ticketStatusColor(context, t.status),
                    ),
                    Text(
                      '  ·  ${t.code} · ${formatDate(t.date, withYear: false)}',
                      style: TextStyle(color: k.ink3, fontSize: 13),
                    ),
                  ],
                ),
              ),
              trailing: t.isClosed
                  ? TextButton(
                      onPressed: () => _reopen(t),
                      child: const Text('Reopen'),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
