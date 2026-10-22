import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/skeleton.dart';
import 'customer_repository.dart';

class _PaymentsData {
  const _PaymentsData(this.payments, this.renewals);

  final CustomerPayments payments;
  final List<CustomerPayment> renewals;
}

/// `m/customer/payments` and `m/customer/renewals`. Online payment is not
/// offered: it needs the Razorpay SDK and a configured key, and the
/// inventory shows `razorpay_configured: false`.
class CustomerPaymentsScreen extends StatelessWidget {
  const CustomerPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CustomerPortalRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: AsyncView<_PaymentsData>(
        load: () async {
          final r = await Future.wait([repo.payments(), repo.renewals()]);
          return _PaymentsData(
            r[0] as CustomerPayments,
            r[1] as List<CustomerPayment>,
          );
        },
        what: 'payments',
        skeleton: const SkeletonDashboard(),
        builder: (context, d) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: formatRupees(d.payments.totalPaid),
                      label: 'Total paid',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      value: formatRupees(d.payments.pending),
                      label: 'Pending',
                      color: d.payments.pending > 0 ? k.warn : null,
                    ),
                  ),
                ],
              ),
            ),
            const SectionLabel('Payment history'),
            if (d.payments.payments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No payments yet.',
                  style: TextStyle(color: k.ink3),
                ),
              )
            else
              CardGroup(
                children: [
                  for (final p in d.payments.payments) _row(context, p),
                ],
              ),
            const SectionLabel('Renewals'),
            if (d.renewals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No renewals on record.',
                  style: TextStyle(color: k.ink3),
                ),
              )
            else
              CardGroup(
                children: [for (final p in d.renewals) _row(context, p)],
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, CustomerPayment p) => ListTile(
    title: Text(
      formatRupees(p.amount),
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      [
        formatDate(p.date),
        if (p.method.isNotEmpty) p.method,
        if (p.description.isNotEmpty) p.description,
      ].join(' · '),
    ),
    trailing: Text(p.status, style: TextStyle(color: context.kora.ink3)),
  );
}
