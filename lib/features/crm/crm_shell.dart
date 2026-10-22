import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'insights/insights_screen.dart';
import 'leads/lead_list_screen.dart';
import 'more/more_screen.dart';
import 'tickets/ticket_list_screen.dart';
import 'today/today_screen.dart';

/// Bottom navigation for staff, branch admins and super admins:
/// Today · Leads · Tickets · Insights · More (from the prototype).
///
/// Tabs are built the first time they are opened, so startup only loads the
/// Today dashboard. Each tab keeps its own navigator, so opening a lead and
/// switching tabs does not lose the place.
class CrmShell extends StatefulWidget {
  const CrmShell({super.key});

  @override
  State<CrmShell> createState() => CrmShellState();

  static CrmShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<CrmShellState>();
}

class CrmShellState extends State<CrmShell> {
  int _index = 0;
  final _visited = <int>{0};
  final _navigators = List.generate(5, (_) => GlobalKey<NavigatorState>());

  static const _tabs = [
    (Icons.today_outlined, Icons.today, 'Today'),
    (Icons.person_search_outlined, Icons.person_search, 'Leads'),
    (Icons.confirmation_number_outlined, Icons.confirmation_number, 'Tickets'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Insights'),
    (Icons.menu, Icons.menu, 'More'),
  ];

  void selectTab(int index) {
    if (index == _index) {
      // Re-selecting a tab returns to its root screen.
      _navigators[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  Widget _root(int index) => switch (index) {
    0 => const TodayScreen(),
    1 => const LeadListScreen(),
    2 => const TicketListScreen(),
    3 => const InsightsScreen(),
    _ => const MoreScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navigators[_index].currentState;
        if (nav != null && nav.canPop()) {
          // maybePop lets the page's own PopScope run (e.g. to return a result).
          nav.maybePop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        } else {
          // At the root of Today: let Android close the app.
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              _visited.contains(i)
                  ? Navigator(
                      key: _navigators[i],
                      onGenerateRoute: (_) =>
                          MaterialPageRoute(builder: (_) => _root(i)),
                    )
                  : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: selectTab,
          destinations: [
            for (final (icon, selected, label) in _tabs)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selected),
                label: label,
              ),
          ],
        ),
      ),
    );
  }
}
