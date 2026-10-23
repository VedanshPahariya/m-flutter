import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import 'ticket_detail_screen.dart';
import 'ticket_repository.dart';

Color ticketPriorityColor(BuildContext context, String priority) {
  final k = context.kora;
  return switch (priority.toLowerCase()) {
    'high' || 'urgent' || 'critical' => k.danger,
    'medium' => k.warn,
    _ => k.mute,
  };
}

Color ticketStatusColor(BuildContext context, String status) {
  final k = context.kora;
  return switch (status.toLowerCase()) {
    'closed' => k.ok,
    'in progress' || 'acknowledge' => k.accent,
    'reopen' || 'reject' => k.danger,
    'pending otp verification' => k.violet,
    _ => k.warn,
  };
}

/// `POST m/complaint/list` per status tab, with counts from
/// `m/cmsdashboard`. Admins can include other people's tickets
/// (`show_all`); super admins can auto-assign.
class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    'New Ticket',
    'Acknowledge',
    'In Progress',
    'Reopen',
    'Pending OTP Verification',
    'Transfer To IT',
    'Closed',
  ];

  late final TabController _tabController = TabController(
    length: _tabs.length,
    vsync: this,
  );
  Map<String, int> _counts = const {};
  bool _showAll = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    try {
      final counts = await TicketRepository(context.api).counts();
      if (mounted) setState(() => _counts = counts);
    } catch (_) {
      // Counts are decorative; the lists show their own errors.
    }
  }

  void _refreshAll() {
    setState(() => _generation++);
    _loadCounts();
  }

  Future<void> _autoAssign() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Auto-assign tickets?'),
        content: const Text(
          'Unassigned tickets will be distributed by the server’s auto-assignment rules.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Auto-assign'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await runAction(
      context,
      () => TicketRepository(context.api).autoAssign(),
      successOf: (m) => m,
    );
    if (result != null) _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final can = context.session.can;
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          if (can.autoAssignTickets)
            TextButton.icon(
              onPressed: _autoAssign,
              icon: const Icon(Icons.bolt),
              label: const Text('Auto-assign'),
            ),
          if (can.seeAllRecords)
            IconButton(
              tooltip: _showAll ? 'Showing all tickets' : 'Showing my tickets',
              icon: Icon(_showAll ? Icons.groups : Icons.group_outlined),
              onPressed: () {
                setState(() {
                  _showAll = !_showAll;
                  _generation++;
                });
                showMessage(
                  context,
                  _showAll ? 'Showing all tickets' : 'Showing tickets for you',
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: k.ink,
          unselectedLabelColor: k.ink3,
          indicatorColor: k.ink,
          tabs: [
            for (final t in _tabs)
              Tab(
                text: _counts[t] != null
                    ? '${t == 'Pending OTP Verification' ? 'Awaiting OTP' : t} · ${formatCount(_counts[t])}'
                    : (t == 'Pending OTP Verification' ? 'Awaiting OTP' : t),
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final status in _tabs)
            _TicketTab(
              key: ValueKey('$status-$_showAll-$_generation'),
              status: status,
              showAll: _showAll,
              onChanged: _refreshAll,
            ),
        ],
      ),
    );
  }
}

class _TicketTab extends StatefulWidget {
  const _TicketTab({
    super.key,
    required this.status,
    required this.showAll,
    required this.onChanged,
  });

  final String status;
  final bool showAll;
  final VoidCallback onChanged;

  @override
  State<_TicketTab> createState() => _TicketTabState();
}

class _TicketTabState extends State<_TicketTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = TicketRepository(context.api);
    return PagedListView<Ticket>(
      what: 'tickets',
      fetch: (offset) => repo.list(
        status: widget.status,
        offset: offset,
        showAll: widget.showAll,
      ),
      empty: (_) => EmptyView(
        icon: widget.status == 'Closed'
            ? Icons.inbox_outlined
            : Icons.check_circle_outline,
        title:
            'No ${widget.status == 'Pending OTP Verification' ? 'tickets awaiting OTP' : '“${widget.status}” tickets'}',
        message: widget.status == 'New Ticket'
            ? 'New tickets from customers and QR scans appear here.'
            : null,
      ),
      itemBuilder: (context, ticket, _) => TicketRow(
        ticket: ticket,
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticket: ticket),
            ),
          );
          if (changed == true) widget.onChanged();
        },
      ),
    );
  }
}

class TicketRow extends StatelessWidget {
  const TicketRow({super.key, required this.ticket, required this.onTap});

  final Ticket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final subject = ticket.comments.isNotEmpty
        ? ticket.comments
        : '${ticket.category} issue';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 52,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: ticketPriorityColor(context, ticket.priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ticket.code,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: k.ink3,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatAge(ticket.createdAt),
                        style: TextStyle(fontSize: 12, color: k.ink3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${ticket.customerName} · ${ticket.priority}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: k.ink3),
                        ),
                      ),
                      if (ticket.isUnassigned)
                        Text(
                          'Unassigned',
                          style: TextStyle(
                            fontSize: 12,
                            color: k.warn,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Avatar(initialsOf(ticket.assignee), size: 24),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
