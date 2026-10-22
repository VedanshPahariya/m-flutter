import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../api/api_exceptions.dart';

/// Runs a user-triggered mutation and reports the outcome in a snackbar.
///
/// Returns the result, or null when it failed. A timeout is reported as
/// "may have been saved" because the server may still have applied it;
/// mutations are never retried automatically.
Future<T?> runAction<T>(
  BuildContext context,
  Future<T> Function() action, {
  String? success,
  String Function(T result)? successOf,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await action();
    final text = successOf?.call(result) ?? success;
    if (text != null && text.isNotEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
    return result;
  } on TimeoutApiException {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'No response from the server. The change may still have been '
            'saved — refresh before trying again.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(describeError(e))));
  }
  return null;
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Small uppercase section heading used between cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.kora.ink3,
                letterSpacing: 0.2,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A coloured dot followed by a label, used for statuses.
class StatusLabel extends StatelessWidget {
  const StatusLabel(
    this.text, {
    super.key,
    required this.color,
    this.bold = true,
  });

  final String text;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rounded card that groups rows, as in the prototype.
class CardGroup extends StatelessWidget {
  const CardGroup({super.key, required this.children, this.margin});

  final List<Widget> children;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) items.add(const Divider(indent: 14));
    }
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: items),
      ),
    );
  }
}

/// Label on the left, value on the right.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(
    this.label,
    this.value, {
    super.key,
    this.trailing,
    this.mono = false,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: k.ink3, fontSize: 14)),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Circle with initials.
class Avatar extends StatelessWidget {
  const Avatar(
    this.initials, {
    super.key,
    this.size = 40,
    this.highlighted = false,
  });

  final String initials;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? k.accent : k.sunken,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: highlighted ? k.raised : k.ink,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Large number with a caption, used in stat strips.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
    this.color,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color ?? k.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                style: TextStyle(fontSize: 12, color: k.ink3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal progress bar with an optional marker (for "today's pace").
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.marker,
    this.color,
    this.height = 8,
  });

  final double value;
  final double? marker;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        height: height + 6,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: k.track,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
            Container(
              height: height,
              width: c.maxWidth * v,
              decoration: BoxDecoration(
                color: color ?? k.accent,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
            if (marker != null)
              Positioned(
                left: (c.maxWidth * marker!.clamp(0.0, 1.0)) - 1,
                child: Container(width: 2, height: height + 6, color: k.ink),
              ),
          ],
        ),
      ),
    );
  }
}

/// Search field matching the prototype's rounded search bar.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                    onSubmitted?.call('');
                  },
                ),
        ),
      ),
    );
  }
}

/// Button that shows a spinner and disables itself while [onPressed] runs,
/// preventing duplicate submissions.
class BusyButton extends StatefulWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tonal = false,
    this.danger = false,
  });

  final String label;
  final Future<void> Function()? onPressed;
  final IconData? icon;
  final bool tonal;
  final bool danger;

  @override
  State<BusyButton> createState() => _BusyButtonState();
}

class _BusyButtonState extends State<BusyButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final child = _busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(widget.label, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
    final onPressed = widget.onPressed == null || _busy ? null : _run;
    if (widget.tonal) {
      return FilledButton.tonal(onPressed: onPressed, child: child);
    }
    return FilledButton(
      style: widget.danger
          ? FilledButton.styleFrom(backgroundColor: k.danger)
          : null,
      onPressed: onPressed,
      child: child,
    );
  }
}
