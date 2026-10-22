import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import 'admin_repository.dart';

/// Super-admin, read-only views of the platform endpoints. Destructive
/// platform actions (tenant delete, error-log clearing, plan changes) are
/// intentionally not exposed in the mobile app.
class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Tenants')),
      body: AsyncView<List<Tenant>>(
        load: repo.tenants,
        what: 'tenants',
        skeleton: const SkeletonList(),
        isEmpty: (l) => l.isEmpty,
        empty: (_) => const EmptyView(
          icon: Icons.apartment_outlined,
          title: 'No tenants',
        ),
        builder: (context, list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(indent: 16),
          itemBuilder: (context, i) {
            final t = list[i];
            final expiry = DateTime.tryParse(t.expiry);
            final expired = expiry != null && expiry.isBefore(DateTime.now());
            return ListTile(
              title: Text(
                t.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${t.code} · ${t.plan} · ${t.users} users\n${t.email}',
              ),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusLabel(
                    t.status,
                    color: t.status == 'active' && !expired ? k.ok : k.danger,
                  ),
                  Text(
                    expired
                        ? 'Expired ${formatDate(t.expiry)}'
                        : 'Until ${formatDate(t.expiry)}',
                    style: TextStyle(fontSize: 12, color: k.ink3),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class QrBatchesScreen extends StatelessWidget {
  const QrBatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('QR batches')),
      body: PagedListView<QrBatch>(
        what: 'QR batches',
        fetch: (offset) => repo.qrBatches(offset: offset),
        empty: (_) => const EmptyView(
          icon: Icons.qr_code_scanner,
          title: 'No QR batches',
        ),
        itemBuilder: (context, b, _) {
          final ratio = b.totalCustomers > 0
              ? b.completedCustomers / b.totalCustomers
              : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    StatusLabel(
                      b.priority.isEmpty ? b.status : b.priority,
                      color: b.priority == 'urgent' ? k.danger : k.ink3,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatCount(b.completedCustomers)} of ${formatCount(b.totalCustomers)} customers · due ${formatDate(b.dueDate)}',
                  style: TextStyle(color: k.ink3, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ProgressBar(value: ratio, height: 6),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ErrorLogScreen extends StatelessWidget {
  const ErrorLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Error log')),
      body: AsyncView<List<ErrorLogEntry>>(
        load: repo.errorLog,
        what: 'the error log',
        skeleton: const SkeletonList(),
        isEmpty: (l) => l.isEmpty,
        empty: (_) => const EmptyView(
          icon: Icons.check_circle_outline,
          title: 'No errors logged',
        ),
        builder: (context, list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(indent: 16),
          itemBuilder: (context, i) {
            final e = list[i];
            return ListTile(
              leading: Icon(
                e.level == 'ERROR' ? Icons.error_outline : Icons.warning_amber,
                color: e.level == 'ERROR' ? k.danger : k.warn,
              ),
              title: Text(
                e.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [e.time, if (e.location.isNotEmpty) e.location].join('\n'),
              ),
            );
          },
        ),
      ),
    );
  }
}
