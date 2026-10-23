import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kora_crm/app/app.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart' as fx;

void main() {
  late FakeBackend backend;
  late TestHarness h;

  setUp(() {
    backend = FakeBackend();
    h = TestHarness(backend);
  });

  Widget app({bool restore = true}) => KoraApp(
    api: h.api,
    auth: h.auth,
    theme: h.theme,
    restoreOnStart: restore,
  );

  void todayRoutes() {
    backend
      ..json('GET', 'm/emsdashboard', fx.emsDashboard)
      ..json('GET', 'm/cmsdashboard', fx.cmsDashboard)
      ..json('GET', 'm/renewal', fx.renewal)
      ..json('GET', 'm/tasks/listall', fx.tasksEmpty)
      ..json('GET', 'm/notifications/get_unread', fx.unreadZero)
      ..json('GET', 'm/approvals/pending', fx.approvalsEmpty);
  }

  Future<void> seedStoredSession(String kind) async {
    await h.kv.write('access_token', 'stored');
    await h.kv.write('refresh_token', 'stored-refresh');
    await h.kv.write(
      'expires_at',
      DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String(),
    );
    await h.kv.write('account_kind', kind);
  }

  Future<void> signInStaff(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'staff@example.invalid',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
  }

  testWidgets('splash stays up while the session is being restored', (
    tester,
  ) async {
    await seedStoredSession('staff');
    final gate = Completer<void>();
    backend.on('GET', 'm/auth/me', (_) async {
      await gate.future;
      return FakeBackend.respond(fx.meStaff);
    });
    backend.json('POST', 'm/dashboard/index', fx.dashboardIndex(role: 2));
    todayRoutes();

    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Restoring your session…'), findsOneWidget);
    expect(
      find.text('Today'),
      findsNothing,
      reason: 'no protected UI before restore completes',
    );

    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('server is slow'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Needs attention'), findsOneWidget);
  });

  testWidgets('offline restore offers retry instead of hanging', (
    tester,
  ) async {
    await seedStoredSession('staff');
    backend.on(
      'GET',
      'm/auth/me',
      (_) => throw const SocketException('offline'),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('You’re offline'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(h.kv.values['refresh_token'], 'stored-refresh');
  });

  testWidgets('sign-in validates input before calling the server', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('sign-in shows the server message and keeps the input', (
    tester,
  ) async {
    backend.json('POST', 'm/auth/login', fx.loginWrongPassword, status: 401);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mobile number or customer ID'),
      '9999',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Account not found'), findsOneWidget);
    expect(find.text('9999'), findsOneWidget);
  });

  testWidgets('staff sees the CRM shell without admin sections', (
    tester,
  ) async {
    backend
      ..json('POST', 'm/auth/login', fx.loginStaff)
      ..json('GET', 'm/auth/me', fx.meStaff)
      ..json('POST', 'm/dashboard/index', fx.dashboardIndex(role: 2));
    todayRoutes();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await signInStaff(tester);

    for (final label in ['Today', 'Leads', 'Tickets', 'Insights', 'More']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('4 new tickets'), findsOneWidget);
    expect(
      backend.calls('GET', 'm/approvals/pending'),
      isEmpty,
      reason: 'staff cannot approve',
    );

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('BRANCH ADMIN'), findsNothing);
    expect(find.text('PLATFORM'), findsNothing);
    expect(find.text('Directory'), findsOneWidget);
  });

  testWidgets('branch admin sees admin sections, super admin also platform', (
    tester,
  ) async {
    backend
      ..json('POST', 'm/auth/login', fx.loginStaff)
      ..json('GET', 'm/auth/me', fx.meStaff)
      ..json('POST', 'm/dashboard/index', fx.dashboardIndex(role: 1));
    todayRoutes();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await signInStaff(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('BRANCH ADMIN'), findsOneWidget);
    expect(find.text('PLATFORM'), findsNothing);

    // Sign out, then in again as super admin.
    backend.json('POST', 'm/auth/logout', fx.logoutOk);
    await h.auth.logout();
    await tester.pumpAndSettle();
    backend.json(
      'POST',
      'm/dashboard/index',
      fx.dashboardIndex(role: 1, superAdmin: true),
    );
    await signInStaff(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Tenants'), 200);
    expect(find.text('PLATFORM'), findsOneWidget);
    expect(find.text('Tenants'), findsOneWidget);
  });

  testWidgets('customer lands in the customer portal', (tester) async {
    backend
      ..json('POST', 'm/auth/login', fx.loginCustomer)
      ..json('GET', 'm/auth/me', fx.meCustomer)
      ..json('GET', 'm/customer', fx.customerHome);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mobile number or customer ID'),
      '9000000011',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Demo Customer'), findsOneWidget);
    expect(find.text('Leads'), findsNothing);
    expect(backend.calls('POST', 'm/dashboard/index'), isEmpty);
  });

  testWidgets('force_change blocks the app until the password is changed', (
    tester,
  ) async {
    backend
      ..json('POST', 'm/auth/login', fx.loginForceChange)
      ..json('GET', 'm/auth/me', fx.meCustomer);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mobile number or customer ID'),
      'x',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'y');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Set a new password'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('expired session returns to sign-in with a notice', (
    tester,
  ) async {
    backend
      ..json('POST', 'm/auth/login', fx.loginStaff)
      ..json('GET', 'm/auth/me', fx.meStaff)
      ..json('POST', 'm/dashboard/index', fx.dashboardIndex(role: 2));
    todayRoutes();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await signInStaff(tester);
    expect(find.text('Needs attention'), findsOneWidget);

    backend
      ..json('GET', 'm/complaint/list', fx.tokenMissing, status: 401)
      ..json('POST', 'm/complaint/list', fx.tokenMissing, status: 401)
      ..json('GET', 'm/cmsdashboard', fx.tokenMissing, status: 401)
      ..json('POST', 'm/auth/refresh', fx.refreshInvalid, status: 401);
    await tester.tap(find.text('Tickets'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
    expect(find.textContaining('session has expired'), findsOneWidget);
    expect(h.kv.values.containsKey('refresh_token'), isFalse);
  });
}
