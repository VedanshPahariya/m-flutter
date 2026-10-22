import 'package:flutter/material.dart';

import '../../../app/app_config.dart';
import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/api/api_response.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/auth/roles.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../shared/account_actions.dart';

/// Profile from `m/profile` plus the session context.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.session;
    final k = context.kora;
    final api = context.api;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: AsyncView<JsonMap>(
        load: () async =>
            asMap(dataMap(await api.get(Endpoints.profile))['branch']),
        what: 'your profile',
        skeleton: const SkeletonDetail(),
        builder: (context, branch) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Avatar(session.user.initials, size: 56, highlighted: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.user.name, style: context.text.titleLarge),
                        if (session.user.email != null)
                          Text(
                            session.user.email!,
                            style: TextStyle(color: k.ink3),
                          ),
                        Text(
                          str(branch, const ['CPMphone', 'CPTel']),
                          style: TextStyle(color: k.ink3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionLabel('WORKSPACE'),
            CardGroup(
              children: [
                KeyValueRow('Role', session.role.label),
                KeyValueRow('Tenant code', session.user.tenantCode ?? ''),
                KeyValueRow('User ID', session.user.userId, mono: true),
                KeyValueRow('City', str(branch, const ['city', 'location'])),
                if (str(branch, const ['subpartnername']).isNotEmpty)
                  KeyValueRow('Partner', str(branch, const ['subpartnername'])),
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
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${AppConfig.appName} ${AppConfig.appVersion} · ${Uri.parse(AppConfig.apiBaseUrl).host}',
                style: TextStyle(fontSize: 12, color: k.mute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
