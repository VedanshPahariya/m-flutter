import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_config.dart';
import '../../app/app_scope.dart';
import '../../app/app_theme.dart';

/// Shown when login returns `force_change: true`.
///
/// The mobile password-change endpoints (`m/customer/forceChangePassword`,
/// `m/customerauth/changePassword`, ...) were deliberately not exercised in
/// the captured inventory, so their request fields are unknown. Rather than
/// guess and risk locking the user out, the app blocks access and sends the
/// user to the web portal, which owns this flow today.
class PasswordChangeRequiredScreen extends StatelessWidget {
  const PasswordChangeRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final auth = AppScope.of(context).auth;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(Icons.lock_reset, size: 48, color: k.accent),
                const SizedBox(height: 16),
                Text(
                  'Set a new password',
                  textAlign: TextAlign.center,
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account requires a new password before you continue. '
                  'Please change it on the web portal, then sign in here again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: k.ink3),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(AppConfig.apiBaseUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open web portal'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: auth.logout,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
