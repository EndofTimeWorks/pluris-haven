import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/data/local_api/local_api_controller.dart';

import 'test_repository.dart';

void main() {
  test('keeps client tokens encrypted and enforces read scopes', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = testRepository(database);
    final controller = LocalApiController(repository);
    addTearDown(() async {
      await controller.close();
      await database.close();
    });
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'River'));

    final initially = await controller.status();
    expect(initially.enabled, isFalse);
    expect(initially.isListening, isFalse);

    final status = await controller.enable();
    expect(status.enabled, isTrue);
    expect(status.origin, isNotNull);

    final credential = await controller.createClient(
      label: 'Test integration',
      scopes: const {LocalApiScope.membersRead},
    );
    final clients = await controller.listClients();
    expect(clients.single.label, 'Test integration');
    final stored = await (database.select(
      database.appPreferences,
    )..where((row) => row.key.equals('local_api.clients.v1'))).getSingle();
    expect(stored.value, startsWith('v2:'));
    expect(stored.value, isNot(contains(credential.token)));

    final members = await _get(status.origin!, '/v1/members', credential.token);
    expect(members.statusCode, HttpStatus.ok);
    expect(jsonDecode(members.body), {
      'members': [
        {
          'id': isA<String>(),
          'name': 'River',
          'pronouns': null,
          'archived': false,
        },
      ],
    });

    final system = await _get(status.origin!, '/v1/system', credential.token);
    expect(system.statusCode, HttpStatus.forbidden);
    expect(jsonDecode(system.body), {
      'error': {'code': 'scope_required'},
    });

    final invalid = await _get(status.origin!, '/v1/members', 'not-a-token');
    expect(invalid.statusCode, HttpStatus.unauthorized);
    expect(jsonDecode(invalid.body), {
      'error': {'code': 'invalid_client'},
    });

    await controller.revokeClient(credential.client.id);
    final revoked = await _get(status.origin!, '/v1/members', credential.token);
    expect(revoked.statusCode, HttpStatus.unauthorized);
  });

  test('keeps health unauthenticated and rejects unsupported routes', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = testRepository(database);
    final controller = LocalApiController(repository);
    addTearDown(() async {
      await controller.close();
      await database.close();
    });
    await repository.ensureLocalSystem();
    final status = await controller.enable();

    final health = await _get(status.origin!, '/v1/health', null);
    expect(health.statusCode, HttpStatus.ok);
    expect(jsonDecode(health.body), {'version': 'v1', 'status': 'ok'});

    final missing = await _get(status.origin!, '/v1/missing', null);
    expect(missing.statusCode, HttpStatus.unauthorized);

    final client = HttpClient();
    addTearDown(client.close);
    final request = await client.postUrl(
      status.origin!.replace(path: '/v1/health'),
    );
    final response = await request.close();
    expect(response.statusCode, HttpStatus.methodNotAllowed);
    expect(jsonDecode(await utf8.decodeStream(response)), {
      'error': {'code': 'method_not_allowed'},
    });
  });

  test('rejects a rebinding host header on the loopback listener', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = testRepository(database);
    final controller = LocalApiController(repository);
    addTearDown(() async {
      await controller.close();
      await database.close();
    });
    await repository.ensureLocalSystem();
    final status = await controller.enable();

    final response = await _get(
      status.origin!,
      '/v1/health',
      null,
      host: 'integration.example',
    );
    expect(response.statusCode, HttpStatus.badRequest);
    expect(jsonDecode(response.body), {
      'error': {'code': 'invalid_host'},
    });
  });

  test(
    'keeps the configured endpoint stable across listener restarts',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final repository = testRepository(database);
      final first = LocalApiController(repository);
      final second = LocalApiController(repository);
      addTearDown(() async {
        await first.close();
        await second.close();
        await database.close();
      });
      await repository.ensureLocalSystem();

      final enabled = await first.enable();
      final origin = enabled.origin;
      expect(origin, isNotNull);

      await first.close();
      final restarted = await first.startIfEnabled();
      expect(restarted.origin, origin);

      await first.close();
      final afterRestart = await second.startIfEnabled();
      expect(afterRestart.origin, origin);
    },
  );

  test('serializes lifecycle changes around an in-flight start', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = testRepository(database);
    final listeners = <_DelayedListener>[];
    final controller = LocalApiController(
      repository,
      listenerFactory: (_, _) {
        final listener = _DelayedListener(
          delayStart: listeners.isEmpty,
          port: 41123,
        );
        listeners.add(listener);
        return listener;
      },
    );
    addTearDown(() async {
      await controller.close();
      await database.close();
    });
    await repository.ensureLocalSystem();

    final enabling = controller.enable();
    await Future<void>.delayed(Duration.zero);
    await listeners.single.started.future;
    final closing = controller.close();
    listeners.single.releaseStart();
    await Future.wait([enabling, closing]);

    expect((await controller.status()).isListening, isFalse);
    expect(listeners.single.stopCalls, 1);

    final restarted = await controller.startIfEnabled();
    expect(restarted.isListening, isTrue);
    expect(listeners, hasLength(2));

    await Future.wait([
      controller.startIfEnabled(),
      controller.startIfEnabled(),
    ]);
    expect(listeners, hasLength(2));

    await Future.wait([controller.close(), controller.close()]);
    expect((await controller.status()).isListening, isFalse);
    expect(listeners.last.stopCalls, 1);

    await controller.setAccessAllowed(true);
    expect((await controller.status()).isListening, isTrue);
    await controller.setAccessAllowed(false);
    expect((await controller.status()).isListening, isFalse);
  });
}

Future<_Response> _get(
  Uri origin,
  String path,
  String? token, {
  String? host,
}) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(origin.replace(path: path));
    if (host != null) {
      request.headers.set(HttpHeaders.hostHeader, host);
    }
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    final response = await request.close();
    return _Response(response.statusCode, await utf8.decodeStream(response));
  } finally {
    client.close();
  }
}

class _Response {
  const _Response(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

class _DelayedListener implements LocalApiListener {
  _DelayedListener({required this.delayStart, required this.port});

  final bool delayStart;
  @override
  final int port;
  final started = Completer<void>();
  final _startRelease = Completer<void>();
  var stopCalls = 0;

  @override
  Future<void> start(int requestedPort) async {
    expect(requestedPort, anyOf(0, port));
    started.complete();
    if (delayStart) await _startRelease.future;
  }

  void releaseStart() => _startRelease.complete();

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }
}
