import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/auth/auth_controller.dart';
import '../core/auth/roles.dart';
import '../features/auth/password_change_required_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/crm/crm_shell.dart';
import '../features/customer/customer_shell.dart';
import '../features/seeker/seeker_shell.dart';
import '../features/splash/splash_screen.dart';
import 'app_config.dart';
import 'app_scope.dart';
import 'app_theme.dart';

class KoraApp extends StatefulWidget {
  const KoraApp({
    super.key,
    required this.api,
    required this.auth,
    required this.theme,
    this.restoreOnStart = true,
  });

  final ApiClient api;
  final AuthController auth;
  final ThemeController theme;
  final bool restoreOnStart;

  @override
  State<KoraApp> createState() => _KoraAppState();
}

class _KoraAppState extends State<KoraApp> {
  @override
  void initState() {
    super.initState();
    widget.theme.load();
    if (widget.restoreOnStart && AppConfig.validate() == null) {
      widget.auth.restore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: widget.api,
      auth: widget.auth,
      theme: widget.theme,
      child: ListenableBuilder(
        listenable: widget.theme,
        builder: (context, _) => MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: widget.theme.mode,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Chooses the top-level experience from the auth state.
///
/// Each branch is a separate subtree, so signing out or an expired session
/// discards every protected screen and its navigation stack at once. Nothing
/// protected is built while the session is still being restored.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final configError = AppConfig.validate();
    if (configError != null) {
      return SplashScreen(configError: configError);
    }
    final auth = AppScope.of(context).auth;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final Widget child = switch (auth.status) {
          AuthStatus.restoring => const SplashScreen(),
          AuthStatus.restoreFailed => SplashScreen(
            restoreError: auth.restoreError,
          ),
          AuthStatus.unauthenticated => const SignInFlow(),
          AuthStatus.authenticated => _home(auth),
        };
        // Swapped without a cross-fade on purpose: an outgoing protected
        // screen must never rebuild after the session has been cleared.
        return KeyedSubtree(
          key: ValueKey(
            '${auth.status}-${auth.session?.user.userId}-${auth.session?.role}',
          ),
          child: child,
        );
      },
    );
  }

  Widget _home(AuthController auth) {
    final session = auth.session!;
    if (session.user.forceChange) {
      return const PasswordChangeRequiredScreen();
    }
    return switch (session.role) {
      AppRole.customer => const CustomerShell(),
      AppRole.seeker => const SeekerShell(),
      AppRole.staff ||
      AppRole.branchAdmin ||
      AppRole.superAdmin => const CrmShell(),
    };
  }
}
