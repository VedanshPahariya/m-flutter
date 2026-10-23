import 'package:flutter_test/flutter_test.dart';
import 'package:kora_crm/app/app_config.dart';
import 'package:kora_crm/core/auth/roles.dart';
import 'package:kora_crm/core/auth/session.dart';
import 'package:kora_crm/core/utils/format.dart';
import 'package:kora_crm/core/utils/json.dart';

void main() {
  group('resolveStaffRole', () {
    test('maps the backend values', () {
      expect(resolveStaffRole(role: 1), AppRole.branchAdmin);
      expect(resolveStaffRole(role: '1'), AppRole.branchAdmin);
      expect(resolveStaffRole(role: 2), AppRole.staff);
      expect(resolveStaffRole(role: 1, isSuperAdmin: true), AppRole.superAdmin);
      expect(resolveStaffRole(role: 2, isSuperAdmin: '1'), AppRole.superAdmin);
    });

    test('unknown or missing values get least privilege', () {
      expect(resolveStaffRole(), AppRole.staff);
      expect(resolveStaffRole(role: 'admin'), AppRole.staff);
      expect(resolveStaffRole(role: 7, isSuperAdmin: false), AppRole.staff);
    });
  });

  group('Permissions', () {
    test('staff cannot use admin actions', () {
      const p = Permissions(AppRole.staff);
      expect(p.deleteLead, isFalse);
      expect(p.approveSignups, isFalse);
      expect(p.toggleTeamMembers, isFalse);
      expect(p.autoAssignTickets, isFalse);
      expect(p.platformAdmin, isFalse);
      expect(p.viewPayments, isTrue);
    });

    test('branch admin gets branch actions but not platform', () {
      const p = Permissions(AppRole.branchAdmin);
      expect(p.deleteLead, isTrue);
      expect(p.approveSignups, isTrue);
      expect(p.autoAssignTickets, isFalse);
      expect(p.platformAdmin, isFalse);
    });

    test('super admin gets everything', () {
      const p = Permissions(AppRole.superAdmin);
      expect(p.autoAssignTickets, isTrue);
      expect(p.platformAdmin, isTrue);
      expect(p.deleteLead, isTrue);
    });

    test('customers and seekers have no CRM permissions', () {
      for (final r in [AppRole.customer, AppRole.seeker]) {
        expect(r.isCrm, isFalse);
        expect(Permissions(r).viewPayments, isFalse);
        expect(Permissions(r).deleteLead, isFalse);
      }
    });
  });

  group('AuthTokens', () {
    test('parse login data and expiry', () {
      final now = DateTime(2026, 10, 1, 12);
      final t = AuthTokens.fromData({
        'access_token': 'a',
        'refresh_token': 'r',
        'expires_in': 3600,
      }, now: now);
      expect(t.expiresAt, DateTime(2026, 10, 1, 13));
      expect(t.expiresWithin(const Duration(seconds: 60), now: now), isFalse);
      expect(t.expiresWithin(const Duration(minutes: 61), now: now), isTrue);
    });

    test('missing access token is rejected', () {
      expect(
        () => AuthTokens.fromData({'refresh_token': 'r'}),
        throwsFormatException,
      );
    });

    test('round-trips through storage', () {
      final t = AuthTokens(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.utc(2026, 1, 1),
      );
      final back = AuthTokens.fromStorage(t.toStorage())!;
      expect(back.accessToken, 'a');
      expect(back.expiresAt.toUtc(), DateTime.utc(2026, 1, 1));
    });
  });

  group('json helpers', () {
    test('read loosely typed PHP values', () {
      final m = {
        'n': '48',
        'f': '1499.00',
        'b': '0',
        'e': '',
        'nul': null,
        'name': 'X',
      };
      expect(intOf(m, ['n']), 48);
      expect(doubleOf(m, ['f']), 1499.0);
      expect(boolOf(m, ['b'], true), isFalse);
      expect(str(m, ['nul', 'e', 'name']), 'X');
      expect(strOrNull(m, ['missing']), isNull);
    });

    test('dates in both backend formats', () {
      expect(parseDate('2026-07-20'), DateTime(2026, 7, 20));
      expect(
        parseDate('2026-07-20 01:14:30'),
        DateTime(2026, 7, 20, 1, 14, 30),
      );
      expect(parseDate('20/07/2026'), DateTime(2026, 7, 20));
      expect(parseDate('0000-00-00'), isNull);
      expect(parseDate(null), isNull);
    });
  });

  group('format', () {
    test('Indian currency grouping', () {
      expect(formatRupees(1234567), '₹12,34,567');
      expect(formatRupees('53000.00'), '₹53,000');
      expect(formatRupees(999.5), '₹999.50');
      expect(formatCount('43997'), '43,997');
    });

    test('phone masking keeps only the last four digits', () {
      expect(maskPhone('9000003921'), '•••• ••3921');
    });

    test('month keys', () {
      expect(formatMonthKey('2026-10'), 'October 2026');
      expect(shortMonthKey('2026-08'), 'Aug');
    });
  });

  group('AppConfig', () {
    test('defaults are production-safe', () {
      expect(AppConfig.appName, isNotEmpty);
      expect(AppConfig.environment, AppEnvironment.production);
      expect(AppConfig.apiBaseUrl, startsWith('https://'));
      expect(AppConfig.apiBaseUrl, endsWith('/'));
      expect(AppConfig.apiBaseUrl, isNot(contains('localhost')));
      expect(AppConfig.validate(), isNull);
      expect(AppConfig.bodyEncoding, 'form');
    });
  });
}
