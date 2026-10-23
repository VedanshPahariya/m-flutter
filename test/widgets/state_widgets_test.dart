import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kora_crm/app/app_scope.dart';
import 'package:kora_crm/app/app_theme.dart';
import 'package:kora_crm/core/api/api_exceptions.dart';
import 'package:kora_crm/core/auth/roles.dart';
import 'package:kora_crm/core/auth/session.dart';
import 'package:kora_crm/core/widgets/async_view.dart';
import 'package:kora_crm/core/widgets/paged_list.dart';
import 'package:kora_crm/core/widgets/skeleton.dart';
import 'package:kora_crm/core/widgets/state_views.dart';
import 'package:kora_crm/features/crm/tickets/ticket_detail_screen.dart';
import 'package:kora_crm/features/crm/tickets/ticket_repository.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart' as fx;

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  group('AsyncView', () {
    testWidgets('fast responses never flash the skeleton', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncView<String>(
            load: () async => 'hello',
            skeleton: const SkeletonList(),
            builder: (_, d) => Text(d),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SkeletonList), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('slow responses show the skeleton, then data', (tester) async {
      final c = Completer<String>();
      await tester.pumpWidget(
        _wrap(
          AsyncView<String>(
            load: () => c.future,
            skeleton: const SkeletonList(),
            builder: (_, d) => Text(d),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SkeletonList), findsOneWidget);
      c.complete('loaded');
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonList), findsNothing);
      expect(find.text('loaded'), findsOneWidget);
    });

    testWidgets('empty result is distinct from an error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncView<List<int>>(
            load: () async => [],
            isEmpty: (l) => l.isEmpty,
            empty: (_) => const EmptyView(title: 'No leads yet'),
            builder: (_, _) => const Text('list'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No leads yet'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('network error offers retry which recovers', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          AsyncView<String>(
            load: () async {
              calls++;
              if (calls == 1) throw const NetworkException();
              return 'back online';
            },
            builder: (_, d) => Text(d),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('You’re offline'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('back online'), findsOneWidget);
    });

    testWidgets('permission denied has no retry button', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncView<String>(
            load: () async =>
                throw const ForbiddenException('Admin access required.'),
            builder: (_, d) => Text(d),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No access'), findsOneWidget);
      expect(find.text('Admin access required.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('server errors hide internal details', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncView<String>(
            load: () async => throw const ServerException(
              'empmaster table missing',
              statusCode: 503,
            ),
            builder: (_, d) => Text(d),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Temporarily unavailable'), findsOneWidget);
      expect(find.textContaining('empmaster'), findsNothing);
    });

    testWidgets('a failed refresh keeps the old data visible', (tester) async {
      final key = GlobalKey<AsyncViewState<String>>();
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          AsyncView<String>(
            key: key,
            load: () async {
              calls++;
              if (calls > 1) throw const TimeoutApiException();
              return 'first load';
            },
            builder: (_, d) => ListView(children: [Text(d)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await key.currentState!.reload();
      await tester.pumpAndSettle();
      expect(find.text('first load'), findsOneWidget);
      expect(
        find.textContaining('Offline · showing the last loaded data'),
        findsOneWidget,
      );
    });
  });

  group('PagedListView', () {
    testWidgets('loads the next page when scrolled to the end', (tester) async {
      final offsets = <int>[];
      await tester.pumpWidget(
        _wrap(
          PagedListView<int>(
            fetch: (offset) async {
              offsets.add(offset);
              return PageResult(
                items: List.generate(20, (i) => offset + i),
                total: 40,
              );
            },
            itemBuilder: (_, i, _) =>
                SizedBox(height: 60, child: Text('row $i')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(offsets, [0, 20]);
      // The second page pushed the footer down; scroll to it.
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(offsets, [0, 20], reason: 'no request after the last page');
      expect(find.text('40 records'), findsOneWidget);
    });

    testWidgets('a failed later page keeps rows and offers retry', (
      tester,
    ) async {
      var fail = true;
      await tester.pumpWidget(
        _wrap(
          PagedListView<int>(
            fetch: (offset) async {
              if (offset > 0 && fail) {
                fail = false;
                throw const NetworkException();
              }
              return PageResult(
                items: List.generate(20, (i) => offset + i),
                total: 40,
              );
            },
            itemBuilder: (_, i, _) =>
                SizedBox(height: 60, child: Text('row $i')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.text('row 19'),
        findsOneWidget,
        reason: 'loaded rows are kept',
      );
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('40 records'), findsOneWidget);
    });

    testWidgets('empty first page shows the empty state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PagedListView<int>(
            fetch: (_) async => const PageResult(items: [], total: 0),
            empty: (_) => const EmptyView(title: 'No tickets'),
            itemBuilder: (_, i, _) => Text('$i'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No tickets'), findsOneWidget);
    });
  });

  testWidgets('ticket detail shows the server’s permission message', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..json(
        'GET',
        'm/complaint/detail/12',
        fx.forbiddenComplaint,
        status: 403,
      );
    final h = TestHarness(backend);
    // Sign in as staff so the screen has a session.
    backend
      ..json('POST', 'm/auth/login', fx.loginStaff)
      ..json('GET', 'm/auth/me', fx.meStaff)
      ..json('POST', 'm/dashboard/index', fx.dashboardIndex(role: 2));
    await h.auth.login(identifier: 'a', password: 'b', kind: AccountKind.staff);
    expect(h.auth.session!.role, AppRole.staff);

    final ticket = Ticket.fromJson({
      'cId': '12',
      'cName': 'Sample Traders',
      'cstatus': 'New Ticket',
    });
    await tester.pumpWidget(
      AppScope(
        api: h.api,
        auth: h.auth,
        theme: h.theme,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: TicketDetailScreen(ticket: ticket),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No access'), findsOneWidget);
    expect(find.text('Not authorized for this complaint.'), findsOneWidget);
  });
}
