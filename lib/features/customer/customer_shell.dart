import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'customer_account_screen.dart';
import 'customer_home_screen.dart';
import 'customer_payments_screen.dart';
import 'customer_tickets_screen.dart';

/// Customer portal: Home · Tickets · Payments · Account.
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => CustomerShellState();

  static CustomerShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<CustomerShellState>();
}

class CustomerShellState extends State<CustomerShell> {
  int _index = 0;
  final _visited = <int>{0};
  final _navigators = List.generate(4, (_) => GlobalKey<NavigatorState>());

  void selectTab(int index) {
    if (index == _index) {
      _navigators[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  Widget _root(int i) => switch (i) {
    0 => const CustomerHomeScreen(),
    1 => const CustomerTicketsScreen(),
    2 => const CustomerPaymentsScreen(),
    _ => const CustomerAccountScreen(),
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
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < 4; i++)
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(Icons.confirmation_number),
              label: 'Tickets',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Payments',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
