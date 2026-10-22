import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../api/api_exceptions.dart';

/// Centered icon, title, message and optional actions.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // Scrollable so pull-to-refresh still works on empty and error states.
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 44, color: iconColor ?? k.mute),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.text.titleMedium,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(color: k.ink3),
                    ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => MessageView(
    icon: icon,
    title: title,
    message: message,
    actions: [?action],
  );
}

/// Maps each failure class to its own icon, title and retry policy.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry, this.what});

  final Object error;
  final VoidCallback? onRetry;

  /// Optional subject, for example "leads", used in the title.
  final String? what;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final subject = what == null ? 'this' : what!;
    final (IconData icon, String title, bool retry) = switch (error) {
      NetworkException() => (Icons.cloud_off_outlined, 'You’re offline', true),
      TimeoutApiException() => (
        Icons.hourglass_bottom,
        'The server is slow',
        true,
      ),
      ForbiddenException() => (Icons.lock_outline, 'No access', false),
      NotFoundException() => (Icons.search_off, 'Not found', false),
      UnauthorizedException() => (Icons.schedule, 'Session expired', false),
      ServerException(statusCode: 503) => (
        Icons.construction_outlined,
        'Temporarily unavailable',
        true,
      ),
      ServerException() => (
        Icons.error_outline,
        'Couldn’t load $subject',
        true,
      ),
      UnexpectedResponseException() => (
        Icons.report_gmailerrorred_outlined,
        'Couldn’t read the response',
        true,
      ),
      ValidationException() || ConflictException() => (
        Icons.info_outline,
        'Couldn’t load $subject',
        true,
      ),
      _ => (Icons.error_outline, 'Couldn’t load $subject', true),
    };
    return MessageView(
      icon: icon,
      iconColor: error is ForbiddenException ? k.mute : k.danger,
      title: title,
      message: describeError(error),
      actions: [
        if (retry && onRetry != null)
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
      ],
    );
  }
}

/// Thin banner shown above content that is still visible after a refresh
/// failed, so existing data is not thrown away.
class InlineErrorBanner extends StatelessWidget {
  const InlineErrorBanner({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final offline = error is NetworkException || error is TimeoutApiException;
    return Material(
      color: k.warnContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        child: Row(
          children: [
            Icon(
              offline ? Icons.cloud_off_outlined : Icons.error_outline,
              size: 18,
              color: k.warnInk,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                offline
                    ? 'Offline · showing the last loaded data'
                    : describeError(error),
                style: TextStyle(color: k.warnInk, fontSize: 13),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
