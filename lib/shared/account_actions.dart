import 'package:flutter/material.dart';

import '../app/app_config.dart';
import '../app/app_scope.dart';

/// Asks before signing out; logout revokes the refresh token on the server
/// and wipes local session data.
Future<void> confirmSignOut(BuildContext context) async {
  final auth = AppScope.of(context).auth;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Sign out?'),
      content: Text(
        'You will need your password or a code to sign in to ${AppConfig.appName} again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (ok == true) await auth.logout();
}

/// Theme picker shared by every portal's settings screen.
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.of(context).theme;
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Expanded(child: Text('Theme')),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {theme.mode},
              onSelectionChanged: (s) => theme.set(s.first),
            ),
          ],
        ),
      ),
    );
  }
}
