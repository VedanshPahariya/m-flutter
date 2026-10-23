import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/json.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../shared/account_actions.dart';
import 'customer_qr_screen.dart';
import 'customer_repository.dart';

/// Profile (`m/customer/profile`), referrals, notifications and sign-out.
/// Profile editing is not offered: `m/customer/updateProfile` only answered
/// "No changes provided" and its accepted fields are unknown.
class CustomerAccountScreen extends StatelessWidget {
  const CustomerAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CustomerPortalRepository(context.api);
    final k = context.kora;
    void open(Widget s) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => s));
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: AsyncView<CustomerProfile>(
        load: repo.profile,
        what: 'your profile',
        skeleton: const SkeletonDetail(),
        builder: (context, p) {
          final f = p.fields;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Avatar(
                      initialsOf(str(f, const ['Party_Name'], 'C')),
                      size: 56,
                      highlighted: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            str(f, const ['Party_Name']),
                            style: context.text.titleLarge,
                          ),
                          Text(
                            'Customer ID ${str(f, const ['Customer_ID'])}',
                            style: TextStyle(color: k.ink3),
                          ),
                          if (p.partyStatus.isNotEmpty)
                            StatusLabel(
                              p.partyStatus,
                              color: p.partyStatus == 'Active' ? k.ok : k.warn,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (p.pendingChanges)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'A profile change is waiting for approval.',
                    style: TextStyle(color: k.warnInk),
                  ),
                ),
              const SectionLabel('CONTACT'),
              CardGroup(
                children: [
                  KeyValueRow(
                    'Contact person',
                    str(f, const ['Contact_Person']),
                  ),
                  KeyValueRow('Mobile', str(f, const ['Mobile']), mono: true),
                  KeyValueRow(
                    'Alt. mobile',
                    str(f, const ['AltMobile']),
                    mono: true,
                  ),
                  KeyValueRow('Email', str(f, const ['EmailID'])),
                  KeyValueRow(
                    'Address',
                    [
                      str(f, const ['Address']),
                      str(f, const ['City']),
                      str(f, const ['State']),
                      str(f, const ['Pincode']),
                    ].where((s) => s.isNotEmpty).join(', '),
                  ),
                  KeyValueRow('GST no.', str(f, const ['GstNo']), mono: true),
                ],
              ),
              const SectionLabel('ACTIVITY'),
              CardGroup(
                children: [
                  KeyValueRow(
                    'Tickets',
                    '${p.totalComplaints} total · ${p.resolvedComplaints} resolved',
                  ),
                  KeyValueRow('Referrals', '${p.referralCount}'),
                ],
              ),
              const SectionLabel('MORE'),
              CardGroup(
                children: [
                  ListTile(
                    leading: const Icon(Icons.qr_code_2),
                    title: const Text('My QR code'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => open(const CustomerQrScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.card_giftcard),
                    title: const Text('Referral earnings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => open(const _ReferralsScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => open(const _NotificationsScreen()),
                  ),
                ],
              ),
              const SectionLabel('PREFERENCES'),
              const CardGroup(children: [ThemeSelector()]),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: k.danger,
                    side: BorderSide(color: k.danger),
                  ),
                  onPressed: () => confirmSignOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReferralsScreen extends StatelessWidget {
  const _ReferralsScreen();

  @override
  Widget build(BuildContext context) {
    final repo = CustomerPortalRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Referral earnings')),
      body: AsyncView<ReferralSummary>(
        load: repo.referrals,
        what: 'referrals',
        skeleton: const SkeletonList(),
        builder: (context, r) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: formatRupees(r.balance),
                      label: 'Balance',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatTile(
                      value: formatRupees(r.totalEarned),
                      label: 'Earned',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatTile(
                      value: formatRupees(r.pending),
                      label: 'Pending',
                    ),
                  ),
                ],
              ),
            ),
            const SectionLabel('History'),
            if (r.earnings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No referral earnings yet. Share your QR code to refer other businesses.',
                  style: TextStyle(color: k.ink3),
                ),
              )
            else
              CardGroup(
                children: [
                  for (final e in r.earnings)
                    ListTile(
                      title: Text(e.name),
                      subtitle: Text(
                        [
                          formatDate(e.date),
                          if (e.status.isNotEmpty) e.status,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        formatRupees(e.amount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen();

  @override
  Widget build(BuildContext context) {
    final repo = CustomerPortalRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: AsyncView<List<CustomerNotification>>(
        load: repo.notifications,
        what: 'notifications',
        skeleton: const SkeletonList(),
        isEmpty: (l) => l.isEmpty,
        empty: (_) => const EmptyView(
          icon: Icons.notifications_none,
          title: 'You’re all caught up',
        ),
        builder: (context, list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(indent: 16),
          itemBuilder: (context, i) => ListTile(
            title: Text(
              list[i].title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: list[i].body.isEmpty ? null : Text(list[i].body),
            trailing: Text(
              formatAge(list[i].when),
              style: TextStyle(fontSize: 12, color: k.ink3),
            ),
          ),
        ),
      ),
    );
  }
}
