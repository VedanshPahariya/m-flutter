import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kora_crm/core/api/api_client.dart';
import 'package:kora_crm/core/api/api_exceptions.dart';
import 'package:kora_crm/core/api/api_response.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart' as fx;

class _Tokens implements TokenProvider {
  String token = 'old';
  int refreshCalls = 0;
  bool refreshSucceeds = true;
  String? expiredWith;

  @override
  Future<String?> validAccessToken() async => token;

  @override
  Future<bool> refreshAfterUnauthorized(String? rejectedToken) async {
    refreshCalls++;
    if (refreshSucceeds) token = 'new';
    return refreshSucceeds;
  }

  @override
  void onSessionExpired(String message) => expiredWith = message;
}

void main() {
  late FakeBackend backend;
  late ApiClient api;

  setUp(() {
    backend = FakeBackend();
    api = backend.api();
  });

  group('success envelopes', () {
    test('standard {status, message, data, code}', () async {
      backend.json('GET', 'm/complaint/list', fx.complaintList);
      final json = await api.get('m/complaint/list');
      expect(dataList(json, 'complaints'), hasLength(2));
      expect(PageInfo.from(dataMap(json)).total, 9);
    });

    test('legacy {type: done, text, data}', () async {
      backend.json('GET', 'm/task/get_task/1', fx.legacyDone);
      final json = await api.get('m/task/get_task/1');
      expect(dataMap(json)['title'], 'wallet');
    });

    test('bare object without envelope', () async {
      backend.json('POST', 'm/enquiry/check_mobile', fx.checkMobileFalse);
      final json = await api.post(
        'm/enquiry/check_mobile',
        body: {'mobile': '9000000003'},
      );
      expect(dataMap(json)['exists'], false);
    });

    test('empty list is data, not an error', () async {
      backend.json('GET', 'm/enquiry/list', fx.enquiryListEmpty);
      final json = await api.get('m/enquiry/list');
      expect(dataList(json, 'enquiries'), isEmpty);
    });

    test('PHP notice printed before the JSON is tolerated', () async {
      backend.json(
        'GET',
        'm/x',
        '<br/>Notice: Undefined index\n{"status":"success","data":{"a":1}}',
      );
      expect(dataMap(await api.get('m/x'))['a'], 1);
    });
  });

  group('errors', () {
    test('HTTP 200 with {"type":"error"} is an application error', () async {
      backend.json('POST', 'm/qradmin/batch_save', fx.legacyError200);
      await expectLater(
        api.post('m/qradmin/batch_save'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Title is required.',
          ),
        ),
      );
    });

    test('HTTP 200 with status:error and code 403 maps to Forbidden', () async {
      backend.json(
        'GET',
        'm/y',
        '{"status":"error","message":"Nope","data":null,"code":403}',
      );
      await expectLater(api.get('m/y'), throwsA(isA<ForbiddenException>()));
    });

    test('422 validation keeps the server message for the user', () async {
      backend.json('POST', 'm/enquiry/add', fx.validation422, status: 422);
      await expectLater(
        api.post('m/enquiry/add'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.userMessage,
            'userMessage',
            'sname and phone are required.',
          ),
        ),
      );
    });

    test('403, 404 and 409 map to their types', () async {
      backend.json('GET', 'a', fx.forbiddenComplaint, status: 403);
      backend.json(
        'GET',
        'b',
        '{"status":"error","message":"Enquiry not found.","data":null,"code":404}',
        status: 404,
      );
      backend.json('GET', 'c', fx.needsCompany, status: 409);
      await expectLater(api.get('a'), throwsA(isA<ForbiddenException>()));
      await expectLater(api.get('b'), throwsA(isA<NotFoundException>()));
      await expectLater(
        api.get('c'),
        throwsA(
          isA<ConflictException>().having(
            (e) => (e.data as Map)['needs_company'],
            'needs_company',
            true,
          ),
        ),
      );
    });

    test('5xx never shows internal server text to the user', () async {
      backend.json('GET', 'm/employee', fx.employeeUnavailable, status: 503);
      await expectLater(
        api.get('m/employee'),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'status', 503)
              .having(
                (e) => e.userMessage.contains('empmaster'),
                'leaks internals',
                false,
              ),
        ),
      );
    });

    test('non-JSON success body is an unexpected response', () async {
      backend.on(
        'GET',
        'm/download',
        (_) => http.Response('PK\u0003\u0004binary', 200),
      );
      await expectLater(
        api.get('m/download'),
        throwsA(isA<UnexpectedResponseException>()),
      );
    });

    test('connection failure becomes NetworkException', () async {
      backend.on(
        'GET',
        'm/z',
        (_) => throw const SocketException('Connection refused'),
      );
      await expectLater(api.get('m/z'), throwsA(isA<NetworkException>()));
    });

    test('slow server becomes TimeoutApiException', () async {
      final slowApi = backend.api(
        readTimeout: const Duration(milliseconds: 50),
      );
      backend.on('GET', 'm/slow', (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return FakeBackend.respond('{}');
      });
      await expectLater(
        slowApi.get('m/slow'),
        throwsA(isA<TimeoutApiException>()),
      );
    });
  });

  group('retries', () {
    test('GET is retried once after a transient network error', () async {
      var attempts = 0;
      backend.on('GET', 'm/flaky', (_) {
        attempts++;
        if (attempts == 1) throw const SocketException('reset');
        return FakeBackend.respond('{"status":"success","data":{"ok":true}}');
      });
      expect(dataMap(await api.get('m/flaky'))['ok'], true);
      expect(attempts, 2);
    });

    test('POST is never retried automatically', () async {
      var attempts = 0;
      backend.on('POST', 'm/enquiry/add', (_) {
        attempts++;
        throw const SocketException('reset');
      });
      await expectLater(
        api.post('m/enquiry/add'),
        throwsA(isA<NetworkException>()),
      );
      expect(attempts, 1);
    });
  });

  group('auth', () {
    test('sends bearer token and form-encoded body', () async {
      final tokens = _Tokens();
      api.tokens = tokens;
      backend.json(
        'POST',
        'm/enquiry/response',
        '{"status":"success","message":"Saved","data":null}',
      );
      await api.post(
        'm/enquiry/response',
        body: {'ecode': '5', 'res': 'Converted', 'skip': null},
      );
      final req = backend.requests.single;
      expect(req.headers['Authorization'], 'Bearer old');
      expect(
        req.headers['content-type'],
        startsWith('application/x-www-form-urlencoded'),
      );
      expect(req.bodyFields, {'ecode': '5', 'res': 'Converted'});
    });

    test('public calls do not send the token', () async {
      api.tokens = _Tokens();
      backend.json('GET', 'm/jobs', '{"status":"success","data":{"jobs":[]}}');
      await api.get('m/jobs', auth: false);
      expect(
        backend.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('401 triggers one refresh and a retry with the new token', () async {
      final tokens = _Tokens();
      api.tokens = tokens;
      backend.on(
        'GET',
        'm/auth/me',
        (r) => r.headers['Authorization'] == 'Bearer new'
            ? FakeBackend.respond(fx.meStaff)
            : FakeBackend.respond(fx.tokenMissing, status: 401),
      );
      final json = await api.get('m/auth/me');
      expect(dataMap(json)['user_id'], '47');
      expect(tokens.refreshCalls, 1);
      expect(backend.requests, hasLength(2));
    });

    test('401 with a failed refresh expires the session', () async {
      final tokens = _Tokens()..refreshSucceeds = false;
      api.tokens = tokens;
      backend.json('GET', 'm/auth/me', fx.tokenMissing, status: 401);
      await expectLater(
        api.get('m/auth/me'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(tokens.expiredWith, isNotNull);
    });

    test('a second 401 after refreshing does not loop', () async {
      final tokens = _Tokens();
      api.tokens = tokens;
      backend.json('GET', 'm/auth/me', fx.tokenMissing, status: 401);
      await expectLater(
        api.get('m/auth/me'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(tokens.refreshCalls, 1);
      expect(backend.requests, hasLength(2));
    });
  });

  test('describeError hides unknown exceptions', () {
    expect(describeError(StateError('boom')), isNot(contains('boom')));
  });
}
