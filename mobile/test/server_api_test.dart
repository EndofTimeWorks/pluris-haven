import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pluris_haven/data/backup/encrypted_backup_snapshot.dart';
import 'package:pluris_haven/data/security/master_key_store.dart';
import 'package:pluris_haven/data/server/server_account_controller.dart';
import 'package:pluris_haven/data/server/server_api.dart';

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

      await controller.logout();
      expect(controller.signedIn, isFalse);
      expect(storage.values.values, isNot(contains('access')));
      expect(storage.values.values, isNot(contains('refresh')));
    },
  );
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

class FakeServerApi extends ServerApi {
  FakeServerApi()
    : super(
        baseUri: Uri.parse('https://haven.example'),
        client: MockClient((_) async => http.Response('{}', 200)),
      );

  final uploadedChunks = <List<int>>[];
  final snapshotRows = <ServerBackupSnapshot>[];

  @override
  Future<ServerDescriptor> descriptor() async => const ServerDescriptor(
    name: 'Test Haven',
    publicUrl: 'https://haven.example',
    registrationEnabled: true,
    friendsEnabled: true,
    capabilities: {'accounts', 'encrypted_backup_chunks', 'friend_requests'},
  );

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
  Future<ServerAccount> me(String token) async => ServerAccount(
    id: 'user',
    email: 'test@example.com',
    displayName: 'Test',
    createdAt: DateTime.utc(2026, 8, 9),
  );

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
  Future<ServerBackupSnapshot> createBackupSnapshot(
    String token, {
    required String snapshotId,
    required String manifestSha256,
    required int chunkCount,
    required int totalBytes,
    required DateTime createdAt,
  }) async {
    final row = ServerBackupSnapshot(
      snapshotId: snapshotId,
      manifestSha256: manifestSha256,
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
