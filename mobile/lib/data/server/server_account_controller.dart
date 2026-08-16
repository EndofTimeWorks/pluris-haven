import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../backup/encrypted_backup_snapshot.dart';
import '../security/master_key_store.dart';
import 'server_api.dart';

typedef ServerApiFactory = ServerApi Function(Uri baseUri);

class ServerAccountController extends ChangeNotifier {
  ServerAccountController({
    SecureValueStore? storage,
    ServerApiFactory? apiFactory,
  }) : _storage = storage ?? const PlatformSecureValueStore(),
       _apiFactory = apiFactory ?? ((baseUri) => ServerApi(baseUri: baseUri));

  static const _serverUrlKey = 'pluris_haven.server.url.v1';
  static const _accessTokenKey = 'pluris_haven.server.access_token.v1';
  static const _refreshTokenKey = 'pluris_haven.server.refresh_token.v1';
  static const _refreshRetryStateKey =
      'pluris_haven.server.refresh_retry_state.v1';

  final SecureValueStore _storage;
  final ServerApiFactory _apiFactory;

  ServerApi? _api;
  ServerDescriptor? descriptor;
  ServerAccount? account;
  List<ServerSession> sessions = const [];
  List<ServerSecurityEvent> securityEvents = const [];
  List<ServerBackupSnapshot> backups = const [];
  List<ServerFriendRequest> friendRequests = const [];
  List<ServerFriend> friends = const [];
  List<ServerBlock> blocks = const [];
  String? friendCode;
  String? error;
  String? status;
  bool busy = false;
  int uploadCompletedChunks = 0;
  int uploadTotalChunks = 0;

  String? _accessToken;
  String? _refreshToken;
  Future<void>? _refreshInFlight;
  String? _refreshRetryToken;
  String? _refreshRetryNonce;

  bool get connected => _api != null && descriptor != null;
  bool get signedIn => account != null && _accessToken != null;
  Uri? get serverUri => _api?.baseUri;

  Future<void> initialize() async {
    try {
      final rawUrl = await _storage.read(_serverUrlKey);
      _accessToken = await _storage.read(_accessTokenKey);
      _refreshToken = await _storage.read(_refreshTokenKey);
      await _loadRefreshRetryState();
      if (rawUrl == null || rawUrl.isEmpty) {
        return;
      }
      _api = _apiFactory(Uri.parse(rawUrl));
      descriptor = await _api!.descriptor();
      if (_accessToken != null && _refreshToken != null) {
        await refreshAll();
      }
    } on Object catch (caught) {
      error = _message(caught);
    } finally {
      notifyListeners();
    }
  }

  Future<void> connect(String serverUrl) async {
    await _run(() async {
      final api = _apiFactory(Uri.parse(serverUrl.trim()));
      final discovered = await api.descriptor();
      _api = api;
      descriptor = discovered;
      await _storage.write(_serverUrlKey, api.baseUri.toString());
      await _clearTokens();
      status = 'Connected to ${discovered.name}.';
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String deviceName,
  }) async {
    await _run(() async {
      final tokens = await _requireApi().register(
        email: email.trim(),
        password: password,
        displayName: displayName.trim(),
        deviceName: deviceName.trim(),
      );
      friendCode = tokens.friendCode;
      await _saveTokens(tokens);
      await _refreshAllAuthenticated();
      status = 'Account created.';
    });
  }

  Future<void> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    await _run(() async {
      final tokens = await _requireApi().login(
        email: email.trim(),
        password: password,
        deviceName: deviceName.trim(),
      );
      await _saveTokens(tokens);
      await _refreshAllAuthenticated();
      status = 'Signed in.';
    });
  }

  Future<void> refreshAll() async {
    await _run(_refreshAllAuthenticated);
  }

  Future<void> logout() async {
    await _run(() async {
      try {
        await _authenticated((api, token) => api.logout(token));
      } on ServerApiException catch (caught) {
        if (!caught.isUnauthorized) rethrow;
      }
      await _clearTokens();
      status = 'Signed out. Local data was not changed.';
    });
  }

  Future<void> disconnect() async {
    await _run(() async {
      await _clearTokens();
      await _storage.delete(_serverUrlKey);
      _api = null;
      descriptor = null;
      status = 'Server disconnected. Local data was not changed.';
    });
  }

  Future<void> deleteAccount(String password) async {
    await _run(() async {
      await _authenticated((api, token) => api.deleteAccount(token, password));
      await _clearTokens();
      status = 'Server account deleted. Local data was not changed.';
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _run(() async {
      await _authenticated(
        (api, token) => api.changePassword(
          token,
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );
      await _refreshAllAuthenticated();
    });
  }

  Future<void> revokeSession(String sessionId) async {
    await _run(() async {
      await _authenticated((api, token) => api.revokeSession(token, sessionId));
      await _refreshAllAuthenticated();
      status = 'Session revoked.';
    });
  }

  Future<void> uploadBackup(EncryptedBackupSnapshot snapshot) async {
    await _run(() async {
      final manifestBytes = utf8.encode(jsonEncode(snapshot.toJson()));
      final manifestSha = await _sha256(manifestBytes);
      final totalBytes = snapshot.chunks.fold<int>(
        0,
        (total, chunk) => total + utf8.encode(chunk.ciphertext).length,
      );
      uploadCompletedChunks = 0;
      uploadTotalChunks = snapshot.chunks.length;
      notifyListeners();

      await _authenticated((api, token) async {
        try {
          await api.createBackupSnapshot(
            token,
            snapshotId: snapshot.snapshotId,
            manifestSha256: manifestSha,
            chunkCount: snapshot.chunks.length,
            totalBytes: totalBytes,
            createdAt: snapshot.createdAt,
          );
        } on ServerApiException catch (caught) {
          if (caught.statusCode != 409) rethrow;
          final existing = (await api.backupSnapshots(
            token,
          )).where((row) => row.snapshotId == snapshot.snapshotId);
          if (existing.isEmpty ||
              existing.first.manifestSha256 != manifestSha ||
              existing.first.chunkCount != snapshot.chunks.length ||
              existing.first.totalBytes != totalBytes) {
            throw const ServerApiException(
              'A different backup already uses this snapshot identifier.',
              statusCode: 409,
            );
          }
        }

        for (final chunk in snapshot.chunks) {
          await api.putBackupChunk(
            token,
            snapshotId: snapshot.snapshotId,
            index: chunk.index,
            ciphertext: utf8.encode(chunk.ciphertext),
            sha256: chunk.sha256,
          );
          uploadCompletedChunks += 1;
          notifyListeners();
        }
      });
      backups = await _authenticated(
        (api, token) => api.backupSnapshots(token),
      );
      status = 'Encrypted backup uploaded.';
    });
  }

  Future<void> deleteBackup(String snapshotId) async {
    await _run(() async {
      await _authenticated(
        (api, token) => api.deleteBackupSnapshot(token, snapshotId),
      );
      backups = await _authenticated(
        (api, token) => api.backupSnapshots(token),
      );
      status = 'Backup deleted.';
    });
  }

  Future<void> rotateFriendCode() async {
    await _run(() async {
      friendCode = await _authenticated(
        (api, token) => api.rotateFriendCode(token),
      );
      status = 'Friend code rotated.';
    });
  }

  Future<void> sendFriendRequest(String code) async {
    await _run(() async {
      await _authenticated(
        (api, token) => api.sendFriendRequest(token, code.trim()),
      );
      await _refreshFriends();
      status = 'Friend request sent.';
    });
  }

  Future<void> respondToFriendRequest(String requestId, String action) async {
    await _run(() async {
      await _authenticated(
        (api, token) => api.respondToFriendRequest(token, requestId, action),
      );
      await _refreshFriends();
      status = 'Friend request updated.';
    });
  }

  Future<void> removeFriend(String friendshipId) async {
    await _run(() async {
      await _authenticated(
        (api, token) => api.removeFriend(token, friendshipId),
      );
      await _refreshFriends();
      status = 'Friend removed.';
    });
  }

  Future<void> blockUser(String userId) async {
    await _run(() async {
      await _authenticated((api, token) => api.blockUser(token, userId));
      await _refreshFriends();
      status = 'User blocked.';
    });
  }

  Future<void> unblockUser(String userId) async {
    await _run(() async {
      await _authenticated((api, token) => api.unblockUser(token, userId));
      await _refreshFriends();
      status = 'User unblocked.';
    });
  }

  Future<void> _refreshAllAuthenticated() async {
    account = await _authenticated((api, token) => api.me(token));
    sessions = await _authenticated((api, token) => api.sessions(token));
    securityEvents =
        descriptor?.capabilities.contains('security_events_v1') == true
        ? await _authenticated((api, token) => api.securityEvents(token))
        : const [];
    backups = await _authenticated((api, token) => api.backupSnapshots(token));
    if (descriptor?.friendsEnabled == true) {
      await _refreshFriends();
    } else {
      friendRequests = const [];
      friends = const [];
      blocks = const [];
    }
  }

  Future<void> _refreshFriends() async {
    friendRequests = await _authenticated(
      (api, token) => api.friendRequests(token),
    );
    friends = await _authenticated((api, token) => api.friends(token));
    blocks = await _authenticated((api, token) => api.blocks(token));
  }

  Future<T> _authenticated<T>(
    Future<T> Function(ServerApi api, String accessToken) action,
  ) async {
    final api = _requireApi();
    final accessToken = _accessToken;
    if (accessToken == null) {
      throw const ServerApiException('Sign in first.', statusCode: 401);
    }
    try {
      return await action(api, accessToken);
    } on ServerApiException catch (caught) {
      if (!caught.isUnauthorized || _refreshToken == null) rethrow;
      await _refreshTokensOnce(api);
      return action(api, _accessToken!);
    }
  }

  Future<void> _refreshTokensOnce(ServerApi api) {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      return Future<void>.error(
        const ServerApiException('Sign in first.', statusCode: 401),
      );
    }
    final refresh = _refreshWithRetryNonce(api, refreshToken);
    _refreshInFlight = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<void> _saveTokens(ServerTokens tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    await _storage.write(_accessTokenKey, tokens.accessToken);
    await _storage.write(_refreshTokenKey, tokens.refreshToken);
    await _clearRefreshRetryState();
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _refreshRetryToken = null;
    _refreshRetryNonce = null;
    account = null;
    sessions = const [];
    securityEvents = const [];
    backups = const [];
    friendRequests = const [];
    friends = const [];
    blocks = const [];
    friendCode = null;
    await _storage.delete(_accessTokenKey);
    await _storage.delete(_refreshTokenKey);
    await _storage.delete(_refreshRetryStateKey);
  }

  Future<void> _refreshWithRetryNonce(
    ServerApi api,
    String refreshToken,
  ) async {
    final rotationNonce = await _rotationNonceFor(refreshToken);
    final tokens = await api.refresh(
      refreshToken,
      rotationNonce: rotationNonce,
    );
    await _saveTokens(tokens);
  }

  Future<String> _rotationNonceFor(String refreshToken) async {
    if (_refreshRetryToken == refreshToken && _refreshRetryNonce != null) {
      return _refreshRetryNonce!;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final nonce = base64UrlEncode(bytes).replaceAll('=', '');
    _refreshRetryToken = refreshToken;
    _refreshRetryNonce = nonce;
    await _storage.write(
      _refreshRetryStateKey,
      jsonEncode({'refresh_token': refreshToken, 'rotation_nonce': nonce}),
    );
    return nonce;
  }

  Future<void> _loadRefreshRetryState() async {
    final stored = await _storage.read(_refreshRetryStateKey);
    if (stored == null) return;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      final token = decoded['refresh_token'];
      final nonce = decoded['rotation_nonce'];
      if (token is! String || nonce is! String || token != _refreshToken) {
        throw const FormatException();
      }
      _refreshRetryToken = token;
      _refreshRetryNonce = nonce;
    } on FormatException {
      await _clearRefreshRetryState();
    }
  }

  Future<void> _clearRefreshRetryState() async {
    await _storage.delete(_refreshRetryStateKey);
    _refreshRetryToken = null;
    _refreshRetryNonce = null;
  }

  ServerApi _requireApi() {
    final api = _api;
    if (api == null) {
      throw const ServerApiException('Connect to a server first.');
    }
    return api;
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (busy) return;
    busy = true;
    error = null;
    status = null;
    notifyListeners();
    try {
      await operation();
    } on Object catch (caught) {
      error = _message(caught);
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

Future<String> _sha256(List<int> bytes) async {
  final digest = await Sha256().hash(bytes);
  return digest.bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

String _message(Object error) {
  if (error is ServerApiException || error is FormatException) {
    return error.toString();
  }
  return 'The operation failed. Try again.';
}
