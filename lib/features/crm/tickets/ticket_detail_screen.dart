import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/launch.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../customers/customer_detail_screen.dart';
import 'ticket_close_screen.dart';
import 'ticket_list_screen.dart';
import 'ticket_repository.dart';

/// Status, priority and owner first, then responses; actions in a fixed
/// bottom bar. Detail comes from `m/complaint/detail/{id}`; when the server
/// refuses (403 "Not authorized for this complaint") that message is shown.
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticket});

  final Ticket ticket;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _view = GlobalKey<AsyncViewState<TicketDetail>>();
  bool _changed = false;
  Ticket? _current;

  TicketRepository get _repo => TicketRepository(context.api);

  Future<TicketDetail> _load() async {
    TicketDetail detail;
    try {
      detail = await _repo.detail(widget.ticket.id, fallback: widget.ticket);
    } on NetworkException {
      detail = TicketDetail(ticket: widget.ticket, responses: const []);
    } on TimeoutApiException {
      detail = TicketDetail(ticket: widget.ticket, responses: const []);
    }
    // The bottom bar depends on the latest status (open vs closed).
    if (mounted) setState(() => _current = detail.ticket);
    return detail;
  }

  Future<void> _respond(Ticket ticket) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _ResponseSheet(ticket: ticket, repository: _repo),
    );
    if (saved == true) {
      _changed = true;
      _view.currentState?.reload();
    }
  }

  Future<void> _close(Ticket ticket) async {
    final closed = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => TicketCloseScreen(ticket: ticket)),
    );
    if (closed == true) {
      _changed = true;
      _view.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.ticket.code)),
        body: AsyncView<TicketDetail>(
          key: _view,
          load: _load,
          what: 'this ticket',
          skeleton: const SkeletonDetail(),
          builder: (context, detail) => _body(context, detail),
        ),
        bottomNavigationBar: _bottomBar(context),
      ),
    );
  }

  Widget? _bottomBar(BuildContext context) {
    final ticket = _current ?? widget.ticket;
    final k = context.kora;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: k.raised,
          border: Border(top: BorderSide(color: k.line)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: ticket.isClosed
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified, color: k.ok),
                  const SizedBox(width: 8),
                  Text(
                    ticket.otpVerified
                        ? 'Closed · verified by customer OTP'
                        : 'Closed',
                    style: TextStyle(color: k.ok, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respond(ticket),
                      child: const Text('Add response'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _close(ticket),
                      icon: const Icon(Icons.verified_outlined, size: 20),
                      label: const Text('Close with OTP'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _body(BuildContext context, TicketDetail detail) {
    final k = context.kora;
    final t = detail.ticket;
    final staff = !context.session.can.seeAllRecords;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.comments.isNotEmpty ? t.comments : '${t.category} issue',
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  StatusLabel(
                    t.status,
                    color: ticketStatusColor(context, t.status),
                  ),
                  StatusLabel(
                    '${t.priority} priority',
                    color: ticketPriorityColor(context, t.priority),
                    bold: false,
                  ),
                  Text(
                    'Opened ${formatAge(t.createdAt)} ago',
                    style: TextStyle(color: k.ink3, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionLabel('Customer'),
        CardGroup(
          children: [
            ListTile(
              title: Text(
                t.customerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  if (t.customerId.isNotEmpty) 'ID ${t.customerId}',
                  if (t.contact.isNotEmpty) t.contact,
                ].join(' · '),
              ),
              trailing: t.customerId.isNotEmpty
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: t.customerId.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailScreen(
                          customerId: t.customerId,
                          name: t.customerName,
                        ),
                      ),
                    ),
            ),
            if (t.contact.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.call_outlined),
                title: const Text('Call customer'),
                onTap: () => dialPhone(t.contact),
              ),
            if (t.address.isNotEmpty) KeyValueRow('Address', t.address),
          ],
        ),
        const SectionLabel('Ticket'),
        CardGroup(
          children: [
            KeyValueRow(
              'Category',
              [
                t.category,
                if (t.source.isNotEmpty) 'via ${t.source}',
              ].join(' · '),
            ),
            KeyValueRow('Date', formatDate(t.date)),
            KeyValueRow(
              'Assigned',
              t.isUnassigned ? 'Unassigned' : t.assignee,
              trailing: staff
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: k.mute),
                        const SizedBox(width: 4),
                        Text(
                          'Admins reassign',
                          style: TextStyle(fontSize: 12, color: k.mute),
                        ),
                      ],
                    )
                  : null,
            ),
            if (t.partnerName.isNotEmpty) KeyValueRow('Partner', t.partnerName),
            if (t.resolution.isNotEmpty)
              KeyValueRow('Resolution', t.resolution),
          ],
        ),
        const SectionLabel('Responses'),
        if (detail.responses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('No responses yet.', style: TextStyle(color: k.ink3)),
          )
        else
          CardGroup(
            children: [
              for (final r in detail.responses)
                ListTile(
                  leading: Avatar(initialsOf(r.who), size: 32),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.who,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        formatDate(r.when, withYear: false),
                        style: TextStyle(fontSize: 12, color: k.ink3),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    [r.status, r.text].where((s) => s.isNotEmpty).join(' · '),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ResponseSheet extends StatefulWidget {
  const _ResponseSheet({required this.ticket, required this.repository});

  final Ticket ticket;
  final TicketRepository repository;

  @override
  State<_ResponseSheet> createState() => _ResponseSheetState();
}

class _ResponseSheetState extends State<_ResponseSheet> {
  late String _status = ticketResponseStatuses.contains(widget.ticket.status)
      ? widget.ticket.status
      : 'In Progress';
  final _comment = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_comment.text.trim().length < 3) {
      setState(() => _error = 'Describe what was done');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await widget.repository.respond(
        cid: widget.ticket.id,
        status: _status,
        comment: _comment.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } on TimeoutApiException {
      if (mounted) {
        setState(
          () => _error = 'No response from the server. It may have been saved — refresh the ticket before retrying.',
        );
      }
    } catch (e) {
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
            Text('Add response', style: context.text.titleLarge),
            Text(
              '${widget.ticket.code} · ${widget.ticket.customerName}',
              style: TextStyle(color: k.ink3),
            ),
            const SizedBox(height: 16),
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in ticketResponseStatuses)
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
            TextField(
              controller: _comment,
              enabled: !_busy,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'What was done?'),
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
