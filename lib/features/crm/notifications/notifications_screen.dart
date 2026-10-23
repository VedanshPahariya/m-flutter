import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../more/admin_repository.dart';

/// `m/notifications/listing`, unread items marked; tapping marks one read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _list = GlobalKey<PagedListViewState<AppNotification>>();
  final Set<String> _read = {};
  bool _allRead = false;

  AdminRepository get _repo => AdminRepository(context.api);

  Future<void> _markAll() async {
    final ok = await runAction(context, () async {
      await _repo.markAllRead();
      return true;
    }, success: 'All notifications marked read');
    if (ok == true && mounted) setState(() => _allRead = true);
  }

  void _open(AppNotification n) {
    if (!n.unread || _allRead || _read.contains(n.id) || n.id.isEmpty) return;
    setState(() => _read.add(n.id));
    _repo.markRead(n.id).catchError((_) {
      if (mounted) setState(() => _read.remove(n.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: _markAll, child: const Text('Mark all read')),
        ],
      ),
      body: PagedListView<AppNotification>(
        key: _list,
        what: 'notifications',
        fetch: (offset) => _repo.notifications(offset: offset),
        empty: (_) => const EmptyView(
          icon: Icons.notifications_none,
          title: 'You’re all caught up',
        ),
        itemBuilder: (context, n, _) {
          final unread = n.unread && !_allRead && !_read.contains(n.id);
          return ListTile(
            onTap: () => _open(n),
            tileColor: unread ? k.raised : null,
            leading: Icon(
              unread ? Icons.circle : Icons.notifications_none,
              size: unread ? 10 : 22,
              color: unread ? k.accent : k.mute,
            ),
            title: Text(
              n.title,
              style: TextStyle(
                fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            subtitle: n.body.isEmpty ? null : Text(n.body),
            trailing: Text(
              formatAge(n.when),
              style: TextStyle(fontSize: 12, color: k.ink3),
            ),
          );
        },
      ),
    );
  }
}
