import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kora_crm/app/app_scope.dart';
import 'package:kora_crm/core/api/api_client.dart';
import 'package:kora_crm/core/auth/auth_controller.dart';
import 'package:kora_crm/core/storage/secure_store.dart';

typedef Responder = FutureOr<http.Response> Function(http.Request request);

/// Deterministic in-memory backend. Routes are keyed `"METHOD path"`
/// (path relative to the API base, without query string).
class FakeBackend {
  final Map<String, Responder> routes = {};
  final List<http.Request> requests = [];

  void on(String method, String path, Responder responder) =>
      routes['$method $path'] = responder;

  void json(String method, String path, String body, {int status = 200}) =>
      on(method, path, (_) => respond(body, status: status));

  static http.Response respond(String body, {int status = 200}) =>
      http.Response(
        body,
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  List<http.Request> calls(String method, String path) =>
      requests.where((r) => r.method == method && _path(r) == path).toList();

  static String _path(http.Request r) =>
      r.url.path.startsWith('/') ? r.url.path.substring(1) : r.url.path;

  MockClient get client => MockClient((request) async {
    requests.add(request);
    final handler = routes['${request.method} ${_path(request)}'];
    if (handler == null) {
      return respond(
        '{"status":"error","message":"No route","data":null,"code":404}',
        status: 404,
      );
    }
    return handler(request);
  });

  ApiClient api({Duration readTimeout = const Duration(seconds: 5)}) =>
      ApiClient(
        baseUrl: 'https://api.test/',
        httpClient: client,
        readTimeout: readTimeout,
        retryDelay: Duration.zero,
      );
}

class TestHarness {
  TestHarness(this.backend) {
    api = backend.api();
    kv = MemoryKeyValueStore();
    store = SessionStore(kv);
    auth = AuthController(api: api, store: store);
    theme = ThemeController(store);
  }

  final FakeBackend backend;
  late final ApiClient api;
  late final MemoryKeyValueStore kv;
  late final SessionStore store;
  late final AuthController auth;
  late final ThemeController theme;
}
