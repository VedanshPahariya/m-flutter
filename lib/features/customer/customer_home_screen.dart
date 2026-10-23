import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/skeleton.dart';
import 'customer_qr_screen.dart';
import 'customer_repository.dart';
import 'customer_shell.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CustomerPortalRepository(context.api);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'My QR code',
            icon: const Icon(Icons.qr_code_2),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CustomerQrScreen())),
          ),
        ],
      ),
      body: AsyncView<CustomerHome>(
        load: repo.home,
        what: 'your account',
        skeleton: const SkeletonDashboard(),
        builder: (context, h) => _body(context, h),
      ),
    );
  }

  Widget _body(BuildContext context, CustomerHome h) {
    final k = context.kora;
    final shell = CustomerShell.of(context);
    final amc = h.amc;
    final Color tone = !amc.hasAmc
        ? k.mute
        : amc.daysLeft < 0
        ? k.danger
        : amc.daysLeft <= 30
        ? k.warn
        : k.ok;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${h.name}',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                [
                  'Customer ID ${h.customerId}',
                  if (h.city.isNotEmpty) h.city,
                ].join(' · '),
                style: TextStyle(color: k.ink3),
              ),
            ],
          ),
        ),
        const SectionLabel('AMC'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusLabel(
                    amc.status.isEmpty ? 'No AMC record' : amc.status,
                    color: tone,
                  ),
                  if (amc.hasAmc) ...[
                    const SizedBox(height: 10),
                    Text(
                      amc.daysLeft >= 0
                          ? '${amc.daysLeft} days left'
                          : 'Expired ${-amc.daysLeft} days ago',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        if (amc.dueDate.isNotEmpty)
                          'Due ${formatDate(amc.dueDate)}',
                        if (amc.billAmount > 0) formatRupees(amc.billAmount),
                        if (amc.softwareType.isNotEmpty) amc.softwareType,
                      ].join(' · '),
                      style: TextStyle(color: k.ink3),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      'Contact support to set up an annual maintenance contract.',
                      style: TextStyle(color: k.ink3),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SectionLabel('Tickets'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final key in const [
                'New Ticket',
                'In Progress',
                'Reopen',
                'Closed',
              ]) ...[
                Expanded(
                  child: StatTile(
                    value: '${h.complaintCounts[key] ?? 0}',
                    label: key == 'New Ticket' ? 'New' : key,
                    onTap: () => shell?.selectTab(1),
                  ),
                ),
                if (key != 'Closed') const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SectionLabel('Referrals'),
        CardGroup(
          children: [
            ListTile(
              leading: Icon(Icons.card_giftcard, color: k.accent),
              title: Text(
                'Referral balance ${formatRupees(h.referralBalance)}',
              ),
              subtitle: const Text('Share your QR code to earn on referrals'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerQrScreen()),
              ),
            ),
          ],
        ),
        if (h.recentPayments.isNotEmpty) ...[
          const SectionLabel('Recent payments'),
          CardGroup(
            children: [
              for (final p in h.recentPayments.take(3))
                ListTile(
                  title: Text(
                    formatRupees(p.amount),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    [
                      formatDate(p.date),
                      if (p.method.isNotEmpty) p.method,
                    ].join(' · '),
                  ),
                  trailing: Text(p.status),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
