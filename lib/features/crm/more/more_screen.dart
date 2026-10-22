import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/auth/roles.dart';
import '../../../core/widgets/common.dart';
import '../customers/customer_list_screen.dart';
import '../renewals/renewals_screen.dart';
import 'approvals_screen.dart';
import 'field_visits_screen.dart';
import 'payments_screen.dart';
import 'platform_screens.dart';
import '../../../shared/account_actions.dart';
import 'settings_screen.dart';
import 'team_screen.dart';

/// Secondary modules grouped by job. Modules the role can't use are hidden,
/// not disabled (prototype rule); the server still enforces access.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.session;
    final can = session.can;
    final k = context.kora;
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    Widget tile(
      IconData icon,
      String title,
      Widget screen, {
      String? subtitle,
    }) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => open(screen),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Card(
              child: ListTile(
                leading: Avatar(session.user.initials, highlighted: true),
                title: Text(
                  session.user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [session.role.label, ?session.user.tenantCode].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(const SettingsScreen()),
              ),
            ),
          ),
          const SectionLabel('RECORDS'),
          CardGroup(
            children: [
              tile(
                Icons.storefront_outlined,
                'Customers',
                const CustomerListScreen(),
              ),
              tile(Icons.autorenew, 'Renewals', const RenewalsScreen()),
              tile(Icons.qr_code_2, 'Field visits', const FieldVisitsScreen()),
              if (can.viewPayments)
                tile(
                  Icons.payments_outlined,
                  'Payments',
                  const PaymentsScreen(),
                ),
            ],
          ),
          if (can.approveSignups) ...[
            const SectionLabel('BRANCH ADMIN'),
            CardGroup(
              children: [
                tile(
                  Icons.how_to_reg_outlined,
                  'Approvals',
                  const ApprovalsScreen(),
                ),
                tile(Icons.group_outlined, 'Team', const TeamScreen()),
              ],
            ),
          ] else ...[
            const SectionLabel('TEAM'),
            CardGroup(
              children: [
                tile(Icons.group_outlined, 'Directory', const TeamScreen()),
              ],
            ),
          ],
          if (can.platformAdmin) ...[
            const SectionLabel('PLATFORM'),
            CardGroup(
              children: [
                tile(
                  Icons.apartment_outlined,
                  'Tenants',
                  const TenantsScreen(),
                ),
                tile(
                  Icons.qr_code_scanner,
                  'QR batches',
                  const QrBatchesScreen(),
                ),
                tile(
                  Icons.bug_report_outlined,
                  'Error log',
                  const ErrorLogScreen(),
                ),
              ],
            ),
          ],
          const SectionLabel('ACCOUNT'),
          CardGroup(
            children: [
              tile(
                Icons.settings_outlined,
                'Profile & settings',
                const SettingsScreen(),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: k.danger),
                title: Text('Sign out', style: TextStyle(color: k.danger)),
                onTap: () => confirmSignOut(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
