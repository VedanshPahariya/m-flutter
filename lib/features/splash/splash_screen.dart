import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_config.dart';
import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/api/api_exceptions.dart';
import 'app_logo.dart';

/// Shown while the stored session is checked (`m/auth/refresh` when the
/// access token has expired, then `m/auth/me`), and when that check could
/// not reach the server. It never waits on purpose and never loads
/// dashboard data.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.restoreError, this.configError});

  final ApiException? restoreError;
  final String? configError;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    // After 3 s the copy changes so a slow network never looks frozen.
    _slowTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const AppLogo(size: 64),
              const SizedBox(height: 16),
              Text(
                AppConfig.appName,
                textAlign: TextAlign.center,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),
              if (widget.configError != null)
                _ConfigError(message: widget.configError!)
              else if (widget.restoreError != null)
                _RestoreFailed(error: widget.restoreError!)
              else ...[
                SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _slow
                      ? 'Still connecting… the server is slow today.'
                      : 'Restoring your session…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: k.ink3),
                ),
              ],
              const Spacer(flex: 4),
              Text(
                'v${AppConfig.appVersion}',
                style: TextStyle(color: k.mute, fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestoreFailed extends StatelessWidget {
  const _RestoreFailed({required this.error});

  final ApiException error;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final auth = AppScope.of(context).auth;
    final offline = error is NetworkException || error is TimeoutApiException;
    return Column(
      children: [
        Icon(
          offline ? Icons.cloud_off_outlined : Icons.error_outline,
          size: 40,
          color: k.mute,
        ),
        const SizedBox(height: 12),
        Text(
          offline ? 'You’re offline' : 'Couldn’t restore your session',
          style: context.text.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          error.userMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: k.ink3),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: auth.restore, child: const Text('Retry')),
        const SizedBox(height: 8),
        TextButton(
          onPressed: auth.abandonStoredSession,
          child: const Text('Sign in with another account'),
        ),
      ],
    );
  }
}

class _ConfigError extends StatelessWidget {
  const _ConfigError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Column(
      children: [
        Icon(Icons.settings_outlined, size: 40, color: k.danger),
        const SizedBox(height: 12),
        Text('App is not configured', style: context.text.titleMedium),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: k.ink3),
        ),
      ],
    );
  }
}
