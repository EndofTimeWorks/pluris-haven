import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pluris_haven/data/backup/encrypted_backup_snapshot.dart';
import 'package:pluris_haven/data/security/master_key_store.dart';
import 'package:pluris_haven/data/server/server_account_controller.dart';
import 'package:pluris_haven/data/server/server_api.dart';

class _StreamingClient extends http.BaseClient {
  _StreamingClient(this._response);

  final http.StreamedResponse _response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      _response.stream,
      _response.statusCode,
      contentLength: _response.contentLength,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      persistentConnection: _response.persistentConnection,
      reasonPhrase: _response.reasonPhrase,
      request: request,
    );
  }
}

void main() {
  test('server origins require HTTPS except for loopback development', () {
    expect(
      () => ServerApi(baseUri: Uri.parse('http://example.com')),
      throwsFormatException,
    );
    expect(
      () => ServerApi(baseUri: Uri.parse('https://user@example.com')),
      throwsFormatException,
    );
    expect(
      () => ServerApi(baseUri: Uri.parse('https://example.com/prefix')),
      throwsFormatException,
    );
    expect(
      ServerApi(baseUri: Uri.parse('http://127.0.0.1:8000')).baseUri,
      Uri.parse('http://127.0.0.1:8000/'),
    );
  });

  test('registration sends JSON and does not follow redirects', () async {
    late http.Request captured;
    final api = ServerApi(
      baseUri: Uri.parse('https://haven.example'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'access_token': 'access',
            'refresh_token': 'refresh',
            'expires_in': 900,
            'friend_code': 'ABCD-EFGH-IJKL-MNPQ',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final tokens = await api.register(
      email: 'test@example.com',
      password: 'correct horse battery staple',
      displayName: 'Test',
      deviceName: 'Phone',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/v1/auth/register');
    expect(captured.followRedirects, isFalse);
    expect(jsonDecode(captured.body)['device_name'], 'Phone');
    expect(tokens.friendCode, 'ABCD-EFGH-IJKL-MNPQ');
  });

  test(
    'password change sends both passwords to the authenticated endpoint',
    () async {
      late http.Request captured;
      final api = ServerApi(
        baseUri: Uri.parse('https://haven.example'),
        client: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'detail': 'Password changed'}), 200);
        }),
      );

      await api.changePassword(
        'access-token',
        currentPassword: 'correct horse battery staple',
        newPassword: 'new correct horse battery staple',
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/v1/auth/password');
      expect(captured.headers['authorization'], 'Bearer access-token');
      expect(jsonDecode(captured.body), {
        'current_password': 'correct horse battery staple',
        'new_password': 'new correct horse battery staple',
      });
    },
  );

  test('security history uses cursor query parameters', () async {
    late http.Request captured;
    final api = ServerApi(
      baseUri: Uri.parse('https://haven.example'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode([
            {
              'id': 7,
              'event_type': 'password_changed',
              'occurred_at': '2026-08-15T20:00:00Z',
            },
          ]),
          200,
        );
      }),
    );

    final events = await api.securityEvents(
      'access-token',
      limit: 5,
      beforeId: 9,
    );

    expect(captured.url.path, '/v1/auth/security-events');
    expect(captured.url.queryParameters, {'limit': '5', 'before_id': '9'});
    expect(captured.headers['authorization'], 'Bearer access-token');
    expect(events.single.id, 7);
    expect(events.single.eventType, 'password_changed');
  });

  test('refresh sends the retry nonce with the old token', () async {
    late http.Request captured;
    final api = ServerApi(
      baseUri: Uri.parse('https://haven.example'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
            'expires_in': 900,
          }),
          200,
        );
      }),
    );

    await api.refresh(
      'old-refresh-token-that-is-long-enough',
      rotationNonce: 'stable-client-retry-nonce',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/v1/auth/refresh');
    expect(jsonDecode(captured.body), {
      'refresh_token': 'old-refresh-token-that-is-long-enough',
      'rotation_nonce': 'stable-client-retry-nonce',
    });
  });

  test('backup upload sends opaque bytes and their declared digest', () async {
    late http.Request captured;
    final api = ServerApi(
      baseUri: Uri.parse('https://haven.example'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'snapshot_id': 'snapshot',
            'index': 0,
            'sha256': 'a' * 64,
            'size': request.bodyBytes.length,
          }),
          200,
        );
      }),
    );

    await api.putBackupChunk(
      'token',
      snapshotId: 'snapshot',
      index: 0,
      ciphertext: utf8.encode('ph1:ciphertext'),
      sha256: 'a' * 64,
    );

    expect(captured.headers['authorization'], 'Bearer token');
    expect(captured.headers['x-content-sha256'], 'a' * 64);
    expect(captured.bodyBytes, utf8.encode('ph1:ciphertext'));
  });

  test('API errors preserve detail and retry-after', () async {
    final api = ServerApi(
      baseUri: Uri.parse('https://haven.example'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'Too many friend requests'}),
          429,
          headers: {'retry-after': '17'},
        ),
      ),
    );

    try {
      await api.sendFriendRequest('token', 'ABCD');
      fail('request should fail');
    } on ServerApiException catch (error) {
      expect(error.message, 'Too many friend requests');
      expect(error.statusCode, 429);
      expect(error.retryAfter, const Duration(seconds: 17));
    }
  });

  test('server responses are rejected before unbounded buffering', () async {
    final client = _StreamingClient(
      http.StreamedResponse(
        Stream<List<int>>.fromIterable([utf8.encode('1234'), utf8.encode('5')]),
        200,
      ),
    );
    final api = ServerApi(
      baseUri: Uri.parse('https://haven.example'),
      client: client,
      maximumResponseBytes: 4,
    );

    await expectLater(
      api.descriptor(),
      throwsA(
        isA<ServerApiException>().having(
          (error) => error.message,
          'message',
          contains('size limit'),
        ),
      ),
    );
  });

  test('blocking uses the authenticated friends endpoint', () async {
    late http.Request captured;
    final api = ServerApi(
      baseUri: Uri.parse('https://haven.example'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'user': {'id': 'blocked-user', 'display_name': 'Blocked'},
            'created_at': '2026-08-09T00:00:00Z',
          }),
          201,
        );
      }),
    );

    final block = await api.blockUser('token', 'blocked-user');

    expect(captured.method, 'POST');
    expect(captured.url.path, '/v1/friends/blocks');
    expect(captured.headers['authorization'], 'Bearer token');
    expect(jsonDecode(captured.body), {'user_id': 'blocked-user'});
    expect(block.user.id, 'blocked-user');
  });

  test(
    'account controller stores sessions and uploads encrypted chunks',
    () async {
      final storage = MemoryServerStorage();
      final api = FakeServerApi();
      final controller = ServerAccountController(
        storage: storage,
        apiFactory: (_) => api,
      );

      await controller.connect('https://haven.example');
      await controller.login(
        email: 'test@example.com',
        password: 'correct horse battery staple',
        deviceName: 'Phone',
      );

      expect(controller.signedIn, isTrue);
      expect(controller.account?.email, 'test@example.com');
      expect(storage.values.values, containsAll(['access', 'refresh']));

      await controller.changePassword(
        currentPassword: 'correct horse battery staple',
        newPassword: 'new correct horse battery staple',
      );
      expect(api.passwordChanged, isTrue);

      await controller.uploadBackup(
        EncryptedBackupSnapshot(
          snapshotId: 'mobile-test',
          createdAt: DateTime.utc(2026, 8, 9),
          chunkSize: 1024,
          chunks: const [
            EncryptedBackupChunk(
              index: 0,
              ciphertext: 'ph1:ciphertext',
              sha256:
                  'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            ),
          ],
        ),
      );

      expect(api.uploadedChunks, [utf8.encode('ph1:ciphertext')]);
      expect(controller.uploadCompletedChunks, 1);

      api
        ..rejectAccess = true
        ..failNextRefresh = true;
      await controller.refreshAll();
      expect(controller.error, isNotNull);

      final recovered = ServerAccountController(
        storage: storage,
        apiFactory: (_) => api,
      );
      await recovered.initialize();
      expect(recovered.error, isNull);
      expect(recovered.signedIn, isTrue);
      expect(api.refreshNonces, hasLength(2));
      expect(api.refreshNonces[1], api.refreshNonces[0]);

      await recovered.logout();
      expect(recovered.signedIn, isFalse);
      expect(storage.values.values, isNot(contains('access')));
      expect(storage.values.values, isNot(contains('refresh')));
    },
  );

  test('startup network failures preserve stored server tokens', () async {
    final storage = MemoryServerStorage();
    final initial = ServerAccountController(
      storage: storage,
      apiFactory: (_) => FakeServerApi(),
    );
    await initial.connect('https://haven.example');
    await initial.login(
      email: 'test@example.com',
      password: 'correct horse battery staple',
      deviceName: 'Phone',
    );

    final unavailableApi = FakeServerApi()..failDescriptor = true;
    final unavailable = ServerAccountController(
      storage: storage,
      apiFactory: (_) => unavailableApi,
    );
    await unavailable.initialize();

    expect(unavailable.error, isNotNull);
    expect(storage.values.values, containsAll(['access', 'refresh']));

    final recovered = ServerAccountController(
      storage: storage,
      apiFactory: (_) => FakeServerApi(),
    );
    await recovered.initialize();

    expect(recovered.error, isNull);
    expect(recovered.signedIn, isTrue);
  });

  test('startup refresh rejection clears stored server tokens', () async {
    final storage = MemoryServerStorage();
    final initial = ServerAccountController(
      storage: storage,
      apiFactory: (_) => FakeServerApi(),
    );
    await initial.connect('https://haven.example');
    await initial.login(
      email: 'test@example.com',
      password: 'correct horse battery staple',
      deviceName: 'Phone',
    );

    final revoked = FakeServerApi()
      ..rejectAccess = true
      ..rejectRefresh = true;
    final controller = ServerAccountController(
      storage: storage,
      apiFactory: (_) => revoked,
    );

    await controller.initialize();

    expect(controller.error, isNotNull);
    expect(controller.signedIn, isFalse);
    expect(storage.values, isNot(contains('access')));
    expect(storage.values, isNot(contains('refresh')));
  });

  test('startup storage failures are reported without escaping', () async {
    final controller = ServerAccountController(storage: FailingReadStorage());

    await expectLater(controller.initialize(), completes);

    expect(controller.error, isNotNull);
  });
}

class MemoryServerStorage implements SecureValueStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class FailingReadStorage implements SecureValueStore {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => throw StateError('Unavailable');

  @override
  Future<void> write(String key, String value) async {}
}

class FakeServerApi extends ServerApi {
  FakeServerApi()
    : super(
        baseUri: Uri.parse('https://haven.example'),
        client: MockClient((_) async => http.Response('{}', 200)),
      );

  final uploadedChunks = <List<int>>[];
  final snapshotRows = <ServerBackupSnapshot>[];
  final refreshNonces = <String?>[];
  bool passwordChanged = false;
  bool rejectAccess = false;
  bool rejectRefresh = false;
  bool failNextRefresh = false;
  bool failDescriptor = false;

  @override
  Future<ServerDescriptor> descriptor() async {
    if (failDescriptor) {
      throw const ServerApiException('Server unavailable.');
    }
    return const ServerDescriptor(
      name: 'Test Haven',
      publicUrl: 'https://haven.example',
      registrationEnabled: true,
      friendsEnabled: true,
      capabilities: {
        'accounts',
        'encrypted_backup_chunks',
        'friend_requests',
        'security_events_v1',
      },
    );
  }

  @override
  Future<ServerTokens> login({
    required String email,
    required String password,
    required String deviceName,
  }) async => const ServerTokens(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresIn: 900,
  );

  @override
  Future<ServerAccount> me(String token) async {
    if (rejectAccess && token != 'access-refreshed') {
      throw const ServerApiException('Expired', statusCode: 401);
    }
    return ServerAccount(
      id: 'user',
      email: 'test@example.com',
      displayName: 'Test',
      createdAt: DateTime.utc(2026, 8, 9),
    );
  }

  @override
  Future<ServerTokens> refresh(
    String refreshToken, {
    String? rotationNonce,
  }) async {
    refreshNonces.add(rotationNonce);
    if (rejectRefresh) {
      throw const ServerApiException('Revoked', statusCode: 401);
    }
    if (failNextRefresh) {
      failNextRefresh = false;
      throw const ServerApiException('Network response was lost.');
    }
    return const ServerTokens(
      accessToken: 'access-refreshed',
      refreshToken: 'refresh-refreshed',
      expiresIn: 900,
    );
  }

  @override
  Future<List<ServerSession>> sessions(String token) async => [
    ServerSession(
      id: 'session',
      deviceName: 'Phone',
      lastUsedAt: DateTime.utc(2026, 8, 9),
      expiresAt: DateTime.utc(2026, 9, 9),
      current: true,
    ),
  ];

  @override
  Future<List<ServerSecurityEvent>> securityEvents(
    String token, {
    int limit = 20,
    int? beforeId,
  }) async => [
    ServerSecurityEvent(
      id: 1,
      eventType: 'password_changed',
      occurredAt: DateTime.utc(2026, 8, 15),
    ),
  ];

  @override
  Future<List<ServerBackupSnapshot>> backupSnapshots(String token) async =>
      List.unmodifiable(snapshotRows);

  @override
  Future<List<ServerFriendRequest>> friendRequests(String token) async =>
      const [];

  @override
  Future<List<ServerFriend>> friends(String token) async => const [];

  @override
  Future<List<ServerBlock>> blocks(String token) async => const [];

  @override
  Future<void> changePassword(
    String token, {
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordChanged = true;
  }

  @override
  Future<ServerBackupSnapshot> createBackupSnapshot(
    String token, {
    required String snapshotId,
    required String manifestSha256,
    required String format,
    required int version,
    required int chunkSize,
    required int chunkCount,
    required int totalBytes,
    required DateTime createdAt,
  }) async {
    final row = ServerBackupSnapshot(
      snapshotId: snapshotId,
      manifestSha256: manifestSha256,
      format: format,
      version: version,
      chunkSize: chunkSize,
      chunkCount: chunkCount,
      uploadedChunks: 0,
      totalBytes: totalBytes,
      uploadedBytes: 0,
      createdAt: createdAt,
    );
    snapshotRows.add(row);
    return row;
  }

  @override
  Future<void> putBackupChunk(
    String token, {
    required String snapshotId,
    required int index,
    required List<int> ciphertext,
    required String sha256,
  }) async {
    uploadedChunks.add(ciphertext);
    final original = snapshotRows.singleWhere(
      (row) => row.snapshotId == snapshotId,
    );
    snapshotRows
      ..remove(original)
      ..add(
        ServerBackupSnapshot(
          snapshotId: original.snapshotId,
          manifestSha256: original.manifestSha256,
          format: original.format,
          version: original.version,
          chunkSize: original.chunkSize,
          chunkCount: original.chunkCount,
          uploadedChunks: original.uploadedChunks + 1,
          totalBytes: original.totalBytes,
          uploadedBytes: original.uploadedBytes + ciphertext.length,
          createdAt: original.createdAt,
        ),
      );
  }

  @override
  Future<void> logout(String token) async {}
}
