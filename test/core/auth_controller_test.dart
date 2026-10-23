import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kora_crm/core/api/api_exceptions.dart';
import 'package:kora_crm/core/auth/auth_controller.dart';
import 'package:kora_crm/core/auth/roles.dart';
import 'package:kora_crm/core/auth/session.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart' as fx;

void main() {
  late FakeBackend backend;
  late TestHarness h;

  setUp(() {
    backend = FakeBackend();
    h = TestHarness(backend);
  });

  void staffRoutes({int role = 2, bool superAdmin = false}) {
    backend.json('POST', 'm/auth/login', fx.loginStaff);
    backend.json('GET', 'm/auth/me', fx.meStaff);
    backend.json(
      'POST',
      'm/dashboard/index',
      fx.dashboardIndex(role: role, superAdmin: superAdmin),
    );
  }

  group('login and role resolution', () {
    test('staff role 2 → staff', () async {
      staffRoutes(role: 2);
      await h.auth.login(
        identifier: 'staff@example.invalid',
        password: 'x',
        kind: AccountKind.staff,
      );
      expect(h.auth.status, AuthStatus.authenticated);
      expect(h.auth.session!.role, AppRole.staff);
      final login = backend.calls('POST', 'm/auth/login').single;
      expect(login.bodyFields['login_type'], 'staff');
      expect(login.bodyFields['identifier'], 'staff@example.invalid');
    });

    test('staff role 1 → branch admin', () async {
      staffRoutes(role: 1);
      await h.auth.login(
        identifier: 'a',
        password: 'x',
        kind: AccountKind.staff,
      );
      expect(h.auth.session!.role, AppRole.branchAdmin);
    });

    test('is_super_admin → super admin', () async {
      staffRoutes(role: 1, superAdmin: true);
      await h.auth.login(
        identifier: 'a',
        password: 'x',
        kind: AccountKind.staff,
      );
      expect(h.auth.session!.role, AppRole.superAdmin);
    });

    test('role endpoint answering 403 falls back to least privilege', () async {
      backend.json('POST', 'm/auth/login', fx.loginStaff);
      backend.json('GET', 'm/auth/me', fx.meStaff);
      backend.json(
        'POST',
        'm/dashboard/index',
        fx.forbiddenComplaint,
        status: 403,
      );
      await h.auth.login(
        identifier: 'a',
        password: 'x',
        kind: AccountKind.staff,
      );
      expect(h.auth.session!.role, AppRole.staff);
    });

    test('customer login never calls the staff role endpoint', () async {
      backend.json('POST', 'm/auth/login', fx.loginCustomer);
      backend.json('GET', 'm/auth/me', fx.meCustomer);
      await h.auth.login(
        identifier: '9000000011',
        password: 'x',
        kind: AccountKind.customer,
      );
      expect(h.auth.session!.role, AppRole.customer);
      expect(backend.calls('POST', 'm/dashboard/index'), isEmpty);
      expect(
        backend.calls('POST', 'm/auth/login').single.bodyFields['login_type'],
        'customer',
      );
    });

    test('seeker login uses m/auth/seeker_login', () async {
      backend.json('POST', 'm/auth/seeker_login', fx.loginSeeker);
      backend.json('GET', 'm/auth/me', fx.meSeeker);
      await h.auth.loginSeeker(email: 'seeker@example.invalid', password: 'x');
      expect(h.auth.session!.role, AppRole.seeker);
    });

    test('tokens are stored, the password never is', () async {
      staffRoutes();
      await h.auth.login(
        identifier: 'a',
        password: 'super-secret',
        kind: AccountKind.staff,
      );
      expect(h.kv.values['access_token'], 'access-1');
      expect(h.kv.values['refresh_token'], 'refresh-1');
      expect(
        h.kv.values.values.any((v) => v.contains('super-secret')),
        isFalse,
      );
    });

    test(
      'wrong credentials surface the server message and keep nothing',
      () async {
        backend.json(
          'POST',
          'm/auth/login',
          fx.loginWrongPassword,
          status: 401,
        );
        await expectLater(
          h.auth.login(
            identifier: 'x',
            password: 'y',
            kind: AccountKind.customer,
          ),
          throwsA(
            isA<UnauthorizedException>().having(
              (e) => e.userMessage,
              'msg',
              contains('Account not found'),
            ),
          ),
        );
        expect(h.auth.status, isNot(AuthStatus.authenticated));
        expect(h.kv.values.containsKey('access_token'), isFalse);
      },
    );

    test('force_change is carried on the session', () async {
      backend.json('POST', 'm/auth/login', fx.loginForceChange);
      backend.json('GET', 'm/auth/me', fx.meCustomer);
      await h.auth.login(
        identifier: 'x',
        password: 'y',
        kind: AccountKind.customer,
      );
      expect(h.auth.session!.user.forceChange, isTrue);
    });

    test('a failure after login clears the half-made session', () async {
      backend.json('POST', 'm/auth/login', fx.loginStaff);
      backend.on(
        'GET',
        'm/auth/me',
        (_) => throw const SocketException('down'),
      );
      await expectLater(
        h.auth.login(identifier: 'a', password: 'x', kind: AccountKind.staff),
        throwsA(isA<NetworkException>()),
      );
      expect(h.kv.values.containsKey('refresh_token'), isFalse);
    });
  });

  group('restore', () {
    Future<void> seed({Duration expiresIn = const Duration(hours: 1)}) async {
      await h.kv.write('access_token', 'stored-access');
      await h.kv.write('refresh_token', 'stored-refresh');
      await h.kv.write(
        'expires_at',
        DateTime.now().add(expiresIn).toUtc().toIso8601String(),
      );
      await h.kv.write('account_kind', 'staff');
    }

    test('no stored session → unauthenticated', () async {
      await h.auth.restore();
      expect(h.auth.status, AuthStatus.unauthenticated);
      expect(backend.requests, isEmpty);
    });

    test('valid session → authenticated with server-resolved role', () async {
      await seed();
      backend.json('GET', 'm/auth/me', fx.meStaff);
      backend.json('POST', 'm/dashboard/index', fx.dashboardIndex(role: 1));
      await h.auth.restore();
      expect(h.auth.status, AuthStatus.authenticated);
      expect(h.auth.session!.role, AppRole.branchAdmin);
      expect(
        backend.calls('GET', 'm/auth/me').single.headers['Authorization'],
        'Bearer stored-access',
      );
    });

    test('expired access token is refreshed before the first call', () async {
      await seed(expiresIn: const Duration(seconds: -10));
      backend.json('POST', 'm/auth/refresh', fx.refreshOk);
      backend.json('GET', 'm/auth/me', fx.meStaff);
      backend.json('POST', 'm/dashboard/index', fx.dashboardIndex(role: 2));
      await h.auth.restore();
      expect(
        backend
            .calls('POST', 'm/auth/refresh')
            .single
            .bodyFields['refresh_token'],
        'stored-refresh',
      );
      expect(
        backend.calls('GET', 'm/auth/me').single.headers['Authorization'],
        'Bearer access-2',
      );
      expect(h.kv.values['refresh_token'], 'refresh-2');
    });

    test('rejected refresh token → signed out with a notice', () async {
      await seed(expiresIn: const Duration(seconds: -10));
      backend.json('POST', 'm/auth/refresh', fx.refreshInvalid, status: 401);
      backend.json('GET', 'm/auth/me', fx.tokenMissing, status: 401);
      await h.auth.restore();
      await Future<void>.delayed(Duration.zero);
      expect(h.auth.status, AuthStatus.unauthenticated);
      expect(h.auth.notice, contains('expired'));
      expect(h.kv.values.containsKey('refresh_token'), isFalse);
    });

    test('offline at startup keeps the session for a retry', () async {
      await seed();
      backend.on(
        'GET',
        'm/auth/me',
        (_) => throw const SocketException('offline'),
      );
      await h.auth.restore();
      expect(h.auth.status, AuthStatus.restoreFailed);
      expect(h.auth.restoreError, isA<NetworkException>());
      expect(h.kv.values['refresh_token'], 'stored-refresh');
    });
  });

  test('concurrent 401s share one refresh', () async {
    staffRoutes();
    await h.auth.login(identifier: 'a', password: 'x', kind: AccountKind.staff);
    var refreshes = 0;
    final gate = Completer<void>();
    backend.on('POST', 'm/auth/refresh', (_) async {
      refreshes++;
      await gate.future;
      return FakeBackend.respond(fx.refreshOk);
    });
    backend.on(
      'GET',
      'm/tasks/listall',
      (r) => r.headers['Authorization'] == 'Bearer access-2'
          ? FakeBackend.respond(fx.tasksEmpty)
          : FakeBackend.respond(fx.tokenMissing, status: 401),
    );
    final calls = [
      h.api.get('m/tasks/listall'),
      h.api.get('m/tasks/listall'),
      h.api.get('m/tasks/listall'),
    ];
    await Future<void>.delayed(const Duration(milliseconds: 20));
    gate.complete();
    await Future.wait(calls);
    expect(refreshes, 1);
  });

  test('logout revokes the refresh token and wipes storage', () async {
    staffRoutes();
    backend.json('POST', 'm/auth/logout', fx.logoutOk);
    await h.auth.login(identifier: 'a', password: 'x', kind: AccountKind.staff);
    await h.auth.logout();
    expect(
      backend.calls('POST', 'm/auth/logout').single.bodyFields['refresh_token'],
      'refresh-1',
    );
    expect(h.auth.status, AuthStatus.unauthenticated);
    expect(h.auth.session, isNull);
    expect(h.kv.values.containsKey('access_token'), isFalse);
    expect(h.auth.notice, isNull);
  });

  test(
    'logout still signs out locally when the server is unreachable',
    () async {
      staffRoutes();
      backend.on(
        'POST',
        'm/auth/logout',
        (_) => throw const SocketException('offline'),
      );
      await h.auth.login(
        identifier: 'a',
        password: 'x',
        kind: AccountKind.staff,
      );
      await h.auth.logout();
      expect(h.auth.status, AuthStatus.unauthenticated);
      expect(h.kv.values.containsKey('refresh_token'), isFalse);
    },
  );
}
