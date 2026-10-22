import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/launch.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import 'lead_list_screen.dart';
import 'lead_repository.dart';
import 'log_response_sheet.dart';

/// Contact actions first, then details, then history (prototype order).
///
/// Calls are logged with `m/enquiry/call_start` before dialling and
/// `m/enquiry/call_end` when the user returns to the app.
class LeadDetailScreen extends StatefulWidget {
  const LeadDetailScreen({super.key, required this.lead});

  final Lead lead;

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen>
    with WidgetsBindingObserver {
  final _view = GlobalKey<AsyncViewState<LeadDetail>>();
  String? _activeCallId;

  LeadRepository get _repo => LeadRepository(context.api);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _activeCallId != null) {
      final id = _activeCallId!;
      _activeCallId = null;
      unawaited(_repo.callEnded(id).catchError((_) {}));
    }
  }

  Future<LeadDetail> _load() async {
    if (widget.lead.id.isEmpty) {
      return LeadDetail(lead: widget.lead, activity: const []);
    }
    try {
      return await _repo.detail(widget.lead.id, fallback: widget.lead);
    } on NotFoundException {
      rethrow;
    } on ApiException catch (e) {
      // Offline or slow: still show the row we already have, with a note.
      if (e is NetworkException || e is TimeoutApiException) {
        return LeadDetail(lead: widget.lead, activity: const []);
      }
      rethrow;
    }
  }

  Future<void> _call(Lead lead) async {
    if (lead.phone.isEmpty) {
      return showMessage(context, 'No phone number on this lead');
    }
    try {
      await _repo.callStarted(lead.id);
      _activeCallId = lead.id;
    } catch (_) {
      // Logging is best effort; the call itself must not be blocked.
    }
    if (!mounted) return;
    final ok = await dialPhone(lead.phone);
    if (!ok && mounted) showMessage(context, 'Couldn’t open the dialer');
  }

  Future<void> _aiCall(Lead lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start an AI call?'),
        content: Text(
          'An automated follow-up call will be placed to ${lead.phone}. The result is logged on the lead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start call'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await runAction(
      context,
      () => _repo.aiCall(lead.id, lead.phone),
      successOf: (m) => m,
    );
  }

  Future<void> _logResponse(Lead lead) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => LogResponseSheet(lead: lead, repository: _repo),
    );
    if (saved == true) _view.currentState?.reload();
  }

  Future<void> _delete(Lead lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this lead?'),
        content: Text(
          '${lead.name} and its response history will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.kora.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await runAction(context, () async {
      await _repo.delete(lead.id);
      return true;
    }, success: '${lead.name} deleted');
    if (result == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lead.id.isEmpty ? 'Lead' : 'ENQ-${widget.lead.id}'),
      ),
      body: AsyncView<LeadDetail>(
        key: _view,
        load: _load,
        what: 'this lead',
        skeleton: const SkeletonDetail(),
        builder: (context, detail) => _body(context, detail),
      ),
    );
  }

  Widget _body(BuildContext context, LeadDetail detail) {
    final k = context.kora;
    final lead = detail.lead;
    final can = context.session.can;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lead.name,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (lead.phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                SelectableText(
                  lead.phone,
                  style: TextStyle(color: k.ink3, fontFamily: 'monospace'),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (lead.status.isNotEmpty)
                    StatusLabel(
                      lead.status,
                      color: leadStatusColor(context, lead.status),
                    ),
                  if (lead.type.isNotEmpty)
                    Text('· ${lead.type}', style: TextStyle(color: k.ink3)),
                  if (lead.source.isNotEmpty)
                    Text('· ${lead.source}', style: TextStyle(color: k.ink3)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _ActionButton(
                icon: Icons.call,
                label: 'Call',
                onTap: () => _call(lead),
              ),
              _ActionButton(
                icon: Icons.chat_outlined,
                label: 'WhatsApp',
                onTap: () async {
                  if (!await openWhatsApp(lead.phone) && context.mounted) {
                    showMessage(context, 'Couldn’t open WhatsApp');
                  }
                },
              ),
              _ActionButton(
                icon: Icons.edit_note,
                label: 'Log response',
                onTap: () => _logResponse(lead),
              ),
              _ActionButton(
                icon: Icons.support_agent,
                label: 'AI call',
                onTap: () => _aiCall(lead),
              ),
            ],
          ),
        ),
        if (lead.nextFollowUp.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.schedule, color: k.accent),
                title: const Text('Next follow-up'),
                subtitle: Text(formatDate(lead.nextFollowUp)),
                trailing: TextButton(
                  onPressed: () => _logResponse(lead),
                  child: const Text('Reschedule'),
                ),
              ),
            ),
          ),
        const SectionLabel('Details'),
        CardGroup(
          children: [
            KeyValueRow(
              'Owner',
              lead.owner.isEmpty ? 'Unassigned' : lead.owner,
            ),
            KeyValueRow('Enquiry for', lead.type),
            KeyValueRow('Source', lead.source),
            KeyValueRow('Enquiry date', formatDate(lead.date)),
            if (lead.address.isNotEmpty) KeyValueRow('Address', lead.address),
            if (lead.comment.isNotEmpty) KeyValueRow('Comment', lead.comment),
          ],
        ),
        const SectionLabel('Activity'),
        if (detail.activity.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No responses logged yet.',
              style: TextStyle(color: k.ink3),
            ),
          )
        else
          CardGroup(
            children: [
              for (final a in detail.activity)
                ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          a.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        formatDate(a.when, withYear: false),
                        style: TextStyle(fontSize: 12, color: k.ink3),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    [a.text, a.by].where((s) => s.isNotEmpty).join('\n'),
                  ),
                ),
            ],
          ),
        if (can.deleteLead && lead.id.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: k.danger,
                side: BorderSide(color: k.danger),
              ),
              onPressed: () => _delete(lead),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete lead'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: k.raised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: k.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(icon, color: k.accent),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
