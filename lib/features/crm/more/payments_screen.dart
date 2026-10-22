import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../customers/customer_detail_screen.dart';
import 'admin_repository.dart';

/// Read-only payment history (`m/customerpayments`). Recording payments is
/// not offered: `m/customerpayments/add` only answers "All required fields
/// must be filled" and its fields are not documented.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: PagedListView<Payment>(
        what: 'payments',
        fetch: (offset) => repo.payments(offset: offset),
        empty: (_) => const EmptyView(
          icon: Icons.payments_outlined,
          title: 'No payments recorded',
        ),
        itemBuilder: (context, p, _) => ListTile(
          title: Text(
            p.customerName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              formatDate(p.date),
              if (p.method.isNotEmpty) p.method,
              if (p.status.isNotEmpty) p.status,
            ].join(' · '),
          ),
          trailing: Text(
            formatRupees(p.amount),
            style: TextStyle(fontWeight: FontWeight.w700, color: k.ink),
          ),
          onTap: p.customerId.isEmpty
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailScreen(
                      customerId: p.customerId,
                      name: p.customerName,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
