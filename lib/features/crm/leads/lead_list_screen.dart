import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import 'lead_detail_screen.dart';
import 'lead_new_screen.dart';
import 'lead_repository.dart';

Color leadStatusColor(BuildContext context, String status) {
  final k = context.kora;
  final s = status.toLowerCase();
  if (s.contains('convert')) return k.ok;
  if (s.contains('demo')) return k.violet;
  if (s.contains('call')) return k.warn;
  if (s.contains('new')) return k.accent;
  if (s.contains('invalid') ||
      s.contains('not') ||
      s.contains('lost') ||
      s.contains('switch')) {
    return k.mute;
  }
  return k.ink3;
}

/// `GET m/enquiry/list`, 20 rows per page. Status chips map to the `st`
/// filter; branch admins can include every branch with `show_all`.
class LeadListScreen extends StatefulWidget {
  const LeadListScreen({super.key});

  @override
  State<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends State<LeadListScreen> {
  String? _status;
  bool _showAll = false;
  int _total = -1;
  Key _listKey = UniqueKey();

  void _reset() => setState(() {
    _listKey = UniqueKey();
    _total = -1;
  });

  Future<void> _openNew() async {
    final created = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LeadNewScreen()));
    if (created == true) _reset();
  }

  @override
  Widget build(BuildContext context) {
    final can = context.session.can;
    final repo = LeadRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Leads'),
            if (_total >= 0) ...[
              const SizedBox(width: 8),
              Text(
                formatCount(_total),
                style: TextStyle(
                  color: k.mute,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (can.seeAllRecords)
            IconButton(
              tooltip: _showAll ? 'Showing all branches' : 'Showing my branch',
              icon: Icon(_showAll ? Icons.groups : Icons.group_outlined),
              onPressed: () {
                _showAll = !_showAll;
                _reset();
                showMessage(
                  context,
                  _showAll ? 'Showing all branches' : 'Showing your branch',
                );
              },
            ),
          IconButton(
            tooltip: 'New lead',
            icon: const Icon(Icons.add),
            onPressed: _openNew,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final status in [null, ...leadStatuses])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status ?? 'All'),
                      selected: _status == status,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: _status == status ? k.base : k.ink,
                      ),
                      onSelected: (_) {
                        _status = status;
                        _reset();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: PagedListView<Lead>(
              key: _listKey,
              what: 'leads',
              fetch: (offset) async {
                final page = await repo.list(
                  offset: offset,
                  showAll: _showAll,
                  status: _status,
                );
                if (mounted && offset == 0) setState(() => _total = page.total);
                return page;
              },
              empty: (_) => EmptyView(
                icon: Icons.inbox_outlined,
                title: _status == null ? 'No leads yet' : 'No “$_status” leads',
                message: 'New enquiries from the website, QR requests and walk-ins appear here.',
                action: FilledButton.tonal(
                  onPressed: _openNew,
                  child: const Text('Add lead'),
                ),
              ),
              itemBuilder: (context, lead, _) => _LeadRow(
                lead: lead,
                onTap: () async {
                  final deleted = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => LeadDetailScreen(lead: lead),
                    ),
                  );
                  if (deleted == true) _reset();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.lead, required this.onTap});

  final Lead lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    final when = lead.nextFollowUp.isNotEmpty ? lead.nextFollowUp : lead.date;
    final meta = [
      if (lead.type.isNotEmpty) lead.type,
      if (lead.owner.isNotEmpty) lead.owner else 'Unassigned',
    ];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (when.isNotEmpty)
                  Text(
                    formatDate(when, withYear: false),
                    style: TextStyle(fontSize: 12, color: k.ink3),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (lead.status.isNotEmpty)
                  StatusLabel(
                    lead.status,
                    color: leadStatusColor(context, lead.status),
                  ),
                if (lead.status.isNotEmpty && meta.isNotEmpty)
                  Text('  ·  ', style: TextStyle(color: k.mute)),
                Expanded(
                  child: Text(
                    meta.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: k.ink3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
