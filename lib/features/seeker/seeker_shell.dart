import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'seeker_applications_screen.dart';
import 'seeker_jobs_screen.dart';
import 'seeker_profile_screen.dart';
import 'seeker_saved_screen.dart';

/// Job seeker portal: Jobs · Applications · Saved · Profile.
class SeekerShell extends StatefulWidget {
  const SeekerShell({super.key});

  @override
  State<SeekerShell> createState() => _SeekerShellState();
}

class _SeekerShellState extends State<SeekerShell> {
  int _index = 0;
  final _visited = <int>{0};
  final _navigators = List.generate(4, (_) => GlobalKey<NavigatorState>());

  Widget _root(int i) => switch (i) {
    0 => const SeekerJobsScreen(),
    1 => const SeekerApplicationsScreen(),
    2 => const SeekerSavedScreen(),
    _ => const SeekerProfileScreen(),
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
          onDestinationSelected: (i) {
            if (i == _index) {
              _navigators[i].currentState?.popUntil((r) => r.isFirst);
              return;
            }
            setState(() {
              _index = i;
              _visited.add(i);
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work),
              label: 'Jobs',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Applications',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
