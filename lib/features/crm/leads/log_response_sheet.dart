import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/api/api_exceptions.dart';
import 'lead_repository.dart';

/// `POST m/enquiry/response` (ecode, res, resdate, cmnt). Outcome and next
/// follow-up take two taps; the comment is optional.
class LogResponseSheet extends StatefulWidget {
  const LogResponseSheet({
    super.key,
    required this.lead,
    required this.repository,
  });

  final Lead lead;
  final LeadRepository repository;

  @override
  State<LogResponseSheet> createState() => _LogResponseSheetState();
}

class _LogResponseSheetState extends State<LogResponseSheet> {
  late String _status = leadStatuses.contains(widget.lead.status)
      ? widget.lead.status
      : 'Call Back';
  int _next = 0;
  DateTime? _customDate;
  final _comment = TextEditingController();
  bool _busy = false;
  String? _error;

  static const _nextOptions = [
    'Tomorrow',
    'In 3 days',
    'Next week',
    'Pick date',
    'No follow-up',
  ];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  DateTime? get _nextDate {
    final today = DateUtils.dateOnly(DateTime.now());
    return switch (_next) {
      0 => today.add(const Duration(days: 1)),
      1 => today.add(const Duration(days: 3)),
      2 => today.add(const Duration(days: 7)),
      3 => _customDate,
      _ => null,
    };
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _customDate ?? now.add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _customDate = picked);
  }

  Future<void> _save() async {
    if (_next == 3 && _customDate == null) {
      setState(() => _error = 'Pick a follow-up date');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await widget.repository.respond(
        ecode: widget.lead.id,
        status: _status,
        nextFollowUp: _nextDate,
        comment: _comment.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } on TimeoutApiException {
      if (mounted) {
        setState(
          () => _error = 'No response from the server. It may have been saved — check the lead before retrying.',
        );
      }
    } catch (e) {
      // Keep the sheet open with the user's input so they can retry.
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log response', style: context.text.titleLarge),
            Text(widget.lead.name, style: TextStyle(color: k.ink3)),
            const SizedBox(height: 16),
            const Text(
              'Outcome',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in leadStatuses)
                  ChoiceChip(
                    label: Text(s),
                    selected: _status == s,
                    showCheckmark: false,
                    labelStyle: TextStyle(color: _status == s ? k.base : k.ink),
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _status = s),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Next follow-up',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _nextOptions.length; i++)
                  ChoiceChip(
                    label: Text(
                      i == 3 && _customDate != null
                          ? '${_customDate!.day}/${_customDate!.month}/${_customDate!.year}'
                          : _nextOptions[i],
                    ),
                    selected: _next == i,
                    showCheckmark: false,
                    labelStyle: TextStyle(color: _next == i ? k.base : k.ink),
                    onSelected: _busy
                        ? null
                        : (_) {
                            setState(() => _next = i);
                            if (i == 3) _pickDate();
                          },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comment,
              enabled: !_busy,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Comment (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: k.danger)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Save response'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
