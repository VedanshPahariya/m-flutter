import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/launch.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import 'admin_repository.dart';

/// Users visible to the caller (`m/branch/listall`; this backend stores
/// users as "branches"). Admins can activate/deactivate others with
/// `m/branch/changeStatus`; the list is reloaded afterwards so the switch
/// always reflects the server's state.
///
/// The prototype used `m/employee/*`, but that module answers 503
/// "Employee module is unavailable" in the inventory.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _list = GlobalKey<PagedListViewState<TeamMember>>();

  Future<void> _toggle(TeamMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          m.active ? 'Deactivate ${m.name}?' : 'Reactivate ${m.name}?',
        ),
        content: Text(
          m.active
              ? 'They will no longer be able to sign in.'
              : 'They will be able to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(m.active ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final done = await runAction(context, () async {
      await AdminRepository(context.api).toggleMember(m.id);
      return true;
    }, success: 'Status updated for ${m.name}');
    if (done == true) _list.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.session;
    final canToggle = session.can.toggleTeamMembers;
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: Text(canToggle ? 'Team' : 'Directory')),
      body: PagedListView<TeamMember>(
        key: _list,
        what: 'the team',
        fetch: (offset) => AdminRepository(context.api).team(offset: offset),
        empty: (_) => const EmptyView(
          icon: Icons.group_outlined,
          title: 'No team members visible',
        ),
        header: canToggle
            ? null
            : (context, _) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Only branch admins can activate or deactivate people.',
                  style: TextStyle(color: k.ink3, fontSize: 13),
                ),
              ),
        itemBuilder: (context, m, _) {
          final self = m.id == session.user.userId;
          return ListTile(
            leading: Avatar(initialsOf(m.name)),
            title: Text(
              m.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                m.isAdmin ? 'Admin' : 'Staff',
                if (m.city.isNotEmpty) m.city,
                if (!m.active) 'Inactive',
              ].join(' · '),
            ),
            onTap: m.mobile.isEmpty ? null : () => dialPhone(m.mobile),
            trailing: canToggle && !self
                ? Switch(value: m.active, onChanged: (_) => _toggle(m))
                : (m.active ? null : StatusLabel('Inactive', color: k.mute)),
          );
        },
      ),
    );
  }
}
