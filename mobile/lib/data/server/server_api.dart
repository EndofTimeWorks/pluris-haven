import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ServerApiException implements Exception {
  const ServerApiException(this.message, {this.statusCode, this.retryAfter});

  final String message;
  final int? statusCode;
  final Duration? retryAfter;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class ServerDescriptor {
  const ServerDescriptor({
    required this.name,
    required this.publicUrl,
    required this.registrationEnabled,
    required this.friendsEnabled,
    required this.capabilities,
  });

  final String name;
  final String publicUrl;
  final bool registrationEnabled;
  final bool friendsEnabled;
  final Set<String> capabilities;

  factory ServerDescriptor.fromJson(Map<String, dynamic> json) {
    return ServerDescriptor(
      name: _string(json, 'name'),
      publicUrl: _string(json, 'public_url'),
      registrationEnabled: json['registration_enabled'] == true,
      friendsEnabled: json['friends_enabled'] == true,
      capabilities: Set.unmodifiable(
        _list(json, 'capabilities').map((value) => value.toString()),
      ),
    );
  }
}

class ServerTokens {
  const ServerTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.friendCode,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String? friendCode;

  factory ServerTokens.fromJson(Map<String, dynamic> json) {
    return ServerTokens(
      accessToken: _string(json, 'access_token'),
      refreshToken: _string(json, 'refresh_token'),
      expiresIn: _integer(json, 'expires_in'),
      friendCode: json['friend_code'] as String?,
    );
  }
}

class ServerAccount {
  const ServerAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  factory ServerAccount.fromJson(Map<String, dynamic> json) {
    return ServerAccount(
      id: _string(json, 'id'),
      email: _string(json, 'email'),
      displayName: _string(json, 'display_name'),
      createdAt: DateTime.parse(_string(json, 'created_at')),
    );
  }
}

class ServerSession {
  const ServerSession({
    required this.id,
    required this.deviceName,
    required this.lastUsedAt,
    required this.expiresAt,
    required this.current,
  });

  final String id;
  final String deviceName;
  final DateTime lastUsedAt;
  final DateTime expiresAt;
  final bool current;

  factory ServerSession.fromJson(Map<String, dynamic> json) {
    return ServerSession(
      id: _string(json, 'id'),
      deviceName: _string(json, 'device_name'),
      lastUsedAt: DateTime.parse(_string(json, 'last_used_at')),
      expiresAt: DateTime.parse(_string(json, 'expires_at')),
      current: json['current'] == true,
    );
  }
}

class ServerSecurityEvent {
  const ServerSecurityEvent({
    required this.id,
    required this.eventType,
    required this.occurredAt,
  });

  final int id;
  final String eventType;
  final DateTime occurredAt;

  factory ServerSecurityEvent.fromJson(Map<String, dynamic> json) {
    return ServerSecurityEvent(
      id: _integer(json, 'id'),
      eventType: _string(json, 'event_type'),
      occurredAt: DateTime.parse(_string(json, 'occurred_at')),
    );
  }
}

class ServerBackupSnapshot {
  const ServerBackupSnapshot({
    required this.snapshotId,
    required this.manifestSha256,
    this.format,
    this.version,
    this.chunkSize,
    required this.chunkCount,
    required this.uploadedChunks,
    required this.totalBytes,
    required this.uploadedBytes,
    required this.createdAt,
  });

  final String snapshotId;
  final String manifestSha256;
  final String? format;
  final int? version;
  final int? chunkSize;
  final int chunkCount;
  final int uploadedChunks;
  final int totalBytes;
  final int uploadedBytes;
  final DateTime createdAt;

  bool get complete =>
      uploadedChunks == chunkCount && uploadedBytes == totalBytes;

  factory ServerBackupSnapshot.fromJson(Map<String, dynamic> json) {
    return ServerBackupSnapshot(
      snapshotId: _string(json, 'snapshot_id'),
      manifestSha256: _string(json, 'manifest_sha256'),
      format: json['format'] as String?,
      version: json['version'] as int?,
      chunkSize: json['chunk_size'] as int?,
      chunkCount: _integer(json, 'chunk_count'),
      uploadedChunks: _integer(json, 'uploaded_chunks'),
      totalBytes: _integer(json, 'total_bytes'),
      uploadedBytes: _integer(json, 'uploaded_bytes'),
      createdAt: DateTime.parse(_string(json, 'created_at')),
    );
  }
}

class ServerPublicUser {
  const ServerPublicUser({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory ServerPublicUser.fromJson(Map<String, dynamic> json) {
    return ServerPublicUser(
      id: _string(json, 'id'),
      displayName: _string(json, 'display_name'),
    );
  }
}

class ServerFriendRequest {
  const ServerFriendRequest({
    required this.id,
    required this.direction,
    required this.status,
    required this.user,
    required this.createdAt,
  });

  final String id;
  final String direction;
  final String status;
  final ServerPublicUser user;
  final DateTime createdAt;

  factory ServerFriendRequest.fromJson(Map<String, dynamic> json) {
    return ServerFriendRequest(
      id: _string(json, 'id'),
      direction: _string(json, 'direction'),
      status: _string(json, 'status'),
      user: ServerPublicUser.fromJson(_object(json, 'user')),
      createdAt: DateTime.parse(_string(json, 'created_at')),
    );
  }
}

class ServerFriend {
  const ServerFriend({required this.friendshipId, required this.user});

  final String friendshipId;
  final ServerPublicUser user;

  factory ServerFriend.fromJson(Map<String, dynamic> json) {
    return ServerFriend(
      friendshipId: _string(json, 'friendship_id'),
      user: ServerPublicUser.fromJson(_object(json, 'user')),
    );
  }
}

class ServerBlock {
  const ServerBlock({required this.user, required this.createdAt});

  final ServerPublicUser user;
  final DateTime createdAt;

  factory ServerBlock.fromJson(Map<String, dynamic> json) {
    return ServerBlock(
      user: ServerPublicUser.fromJson(_object(json, 'user')),
      createdAt: DateTime.parse(_string(json, 'created_at')),
    );
  }
}

class ServerApi {
  ServerApi({
    required Uri baseUri,
    http.Client? client,
    Duration? timeout,
    int maximumResponseBytes = 16 * 1024 * 1024,
  }) : assert(maximumResponseBytes > 0),
       baseUri = normalizeServerUri(baseUri),
       _client = client ?? http.Client(),
       _timeout = timeout ?? const Duration(seconds: 20),
       _maximumResponseBytes = maximumResponseBytes;

  final Uri baseUri;
  final http.Client _client;
  final Duration _timeout;
  final int _maximumResponseBytes;

  static Uri normalizeServerUri(Uri value) {
    final isLoopback =
        value.host == 'localhost' ||
        value.host == '127.0.0.1' ||
        value.host == '::1';
    if (value.host.isEmpty ||
        (value.scheme != 'https' && !(isLoopback && value.scheme == 'http')) ||
        value.userInfo.isNotEmpty ||
        value.hasQuery ||
        value.hasFragment ||
        (value.path.isNotEmpty && value.path != '/')) {
      throw const FormatException(
        'Use an HTTPS server origin, or HTTP only for a loopback development server.',
      );
    }
    return value.replace(path: '/', query: null, fragment: null);
  }

  Future<ServerDescriptor> descriptor() async {
    final response = await _request('GET', '/.well-known/pluris-haven');
    return ServerDescriptor.fromJson(_decodeObject(response));
  }

  Future<ServerTokens> register({
    required String email,
    required String password,
    required String displayName,
    required String deviceName,
  }) async {
    final response = await _request(
      'POST',
      '/v1/auth/register',
      jsonBody: {
        'email': email,
        'password': password,
        'display_name': displayName,
        'device_name': deviceName,
      },
    );
    return ServerTokens.fromJson(_decodeObject(response));
  }

  Future<ServerTokens> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final response = await _request(
      'POST',
      '/v1/auth/login',
      jsonBody: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      },
    );
    return ServerTokens.fromJson(_decodeObject(response));
  }

  Future<void> requestPasswordReset(String email) async {
    await _request(
      'POST',
      '/v1/auth/password/reset-request',
      jsonBody: {'email': email},
    );
  }

  Future<ServerTokens> refresh(
    String refreshToken, {
    String? rotationNonce,
  }) async {
    final response = await _request(
      'POST',
      '/v1/auth/refresh',
      jsonBody: {
        'refresh_token': refreshToken,
        'rotation_nonce': ?rotationNonce,
      },
    );
    return ServerTokens.fromJson(_decodeObject(response));
  }

  Future<ServerAccount> me(String token) async {
    final response = await _request('GET', '/v1/auth/me', token: token);
    return ServerAccount.fromJson(_decodeObject(response));
  }

  Future<List<ServerSession>> sessions(String token) async {
    final response = await _request('GET', '/v1/auth/sessions', token: token);
    return [
      for (final row in _decodeList(response))
        ServerSession.fromJson(_asObject(row)),
    ];
  }

  Future<List<ServerSecurityEvent>> securityEvents(
    String token, {
    int limit = 20,
    int? beforeId,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (beforeId != null) {
      query['before_id'] = '$beforeId';
    }
    final response = await _request(
      'GET',
      Uri(path: '/v1/auth/security-events', queryParameters: query).toString(),
      token: token,
    );
    return [
      for (final row in _decodeList(response))
        ServerSecurityEvent.fromJson(_asObject(row)),
    ];
  }

  Future<void> revokeSession(String token, String sessionId) async {
    await _request('DELETE', '/v1/auth/sessions/$sessionId', token: token);
  }

  Future<void> logout(String token) async {
    await _request('POST', '/v1/auth/logout', token: token);
  }

  Future<void> changePassword(
    String token, {
    required String currentPassword,
    required String newPassword,
  }) async {
    await _request(
      'POST',
      '/v1/auth/password',
      token: token,
      jsonBody: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<void> deleteAccount(String token, String password) async {
    await _request(
      'DELETE',
      '/v1/auth/account',
      token: token,
      jsonBody: {'password': password},
    );
  }

  Future<List<ServerBackupSnapshot>> backupSnapshots(String token) async {
    final response = await _request(
      'GET',
      '/v1/backups/snapshots',
      token: token,
    );
    return [
      for (final row in _decodeList(response))
        ServerBackupSnapshot.fromJson(_asObject(row)),
    ];
  }

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
    final response = await _request(
      'POST',
      '/v1/backups/snapshots',
      token: token,
      jsonBody: {
        'snapshot_id': snapshotId,
        'manifest_sha256': manifestSha256,
        'format': format,
        'version': version,
        'chunk_size': chunkSize,
        'chunk_count': chunkCount,
        'total_bytes': totalBytes,
        'created_at': createdAt.toUtc().toIso8601String(),
      },
    );
    return ServerBackupSnapshot.fromJson(_decodeObject(response));
  }

  Future<void> putBackupChunk(
    String token, {
    required String snapshotId,
    required int index,
    required List<int> ciphertext,
    required String sha256,
  }) async {
    await _request(
      'PUT',
      '/v1/backups/snapshots/$snapshotId/chunks/$index',
      token: token,
      body: ciphertext,
      headers: {
        'Content-Type': 'application/octet-stream',
        'X-Content-SHA256': sha256,
      },
    );
  }

  Future<List<int>> getBackupChunk(
    String token, {
    required String snapshotId,
    required int index,
  }) async {
    final response = await _request(
      'GET',
      '/v1/backups/snapshots/$snapshotId/chunks/$index',
      token: token,
      headers: {'Accept': 'application/octet-stream'},
    );
    return response.bodyBytes;
  }

  Future<void> deleteBackupSnapshot(String token, String snapshotId) async {
    await _request('DELETE', '/v1/backups/snapshots/$snapshotId', token: token);
  }

  Future<String> rotateFriendCode(String token) async {
    final response = await _request(
      'POST',
      '/v1/friends/code/rotate',
      token: token,
    );
    return _string(_decodeObject(response), 'friend_code');
  }

  Future<List<ServerFriendRequest>> friendRequests(String token) async {
    final response = await _request(
      'GET',
      '/v1/friends/requests',
      token: token,
    );
    return [
      for (final row in _decodeList(response))
        ServerFriendRequest.fromJson(_asObject(row)),
    ];
  }

  Future<List<ServerFriend>> friends(String token) async {
    final response = await _request('GET', '/v1/friends', token: token);
    return [
      for (final row in _decodeList(response))
        ServerFriend.fromJson(_asObject(row)),
    ];
  }

  Future<ServerFriendRequest> sendFriendRequest(
    String token,
    String friendCode,
  ) async {
    final response = await _request(
      'POST',
      '/v1/friends/requests',
      token: token,
      jsonBody: {'friend_code': friendCode},
    );
    return ServerFriendRequest.fromJson(_decodeObject(response));
  }

  Future<void> respondToFriendRequest(
    String token,
    String requestId,
    String action,
  ) async {
    if (!const {'accept', 'decline', 'cancel'}.contains(action)) {
      throw ArgumentError.value(action, 'action');
    }
    await _request(
      'POST',
      '/v1/friends/requests/$requestId/$action',
      token: token,
    );
  }

  Future<void> removeFriend(String token, String friendshipId) async {
    await _request('DELETE', '/v1/friends/$friendshipId', token: token);
  }

  Future<List<ServerBlock>> blocks(String token) async {
    final response = await _request('GET', '/v1/friends/blocks', token: token);
    return [
      for (final row in _decodeList(response))
        ServerBlock.fromJson(_asObject(row)),
    ];
  }

  Future<ServerBlock> blockUser(String token, String userId) async {
    final response = await _request(
      'POST',
      '/v1/friends/blocks',
      token: token,
      jsonBody: {'user_id': userId},
    );
    return ServerBlock.fromJson(_decodeObject(response));
  }

  Future<void> unblockUser(String token, String userId) async {
    await _request('DELETE', '/v1/friends/blocks/$userId', token: token);
  }

  Future<http.Response> _request(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? jsonBody,
    List<int>? body,
    Map<String, String>? headers,
  }) async {
    final request = http.Request(method, baseUri.resolve(path));
    request.followRedirects = false;
    request.headers.addAll({'Accept': 'application/json', ...?headers});
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (jsonBody != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(jsonBody);
    } else if (body != null) {
      request.bodyBytes = body;
    }
    late final http.StreamedResponse streamed;
    late final http.Response response;
    try {
      streamed = await _client.send(request).timeout(_timeout);
      final declaredLength = streamed.contentLength;
      if (declaredLength != null && declaredLength > _maximumResponseBytes) {
        throw const FormatException('Server response exceeds the size limit.');
      }
      final builder = BytesBuilder(copy: false);
      await streamed.stream
          .forEach((chunk) {
            if (builder.length > _maximumResponseBytes - chunk.length) {
              throw const FormatException(
                'Server response exceeds the size limit.',
              );
            }
            builder.add(chunk);
          })
          .timeout(_timeout);
      response = http.Response.bytes(
        builder.takeBytes(),
        streamed.statusCode,
        headers: streamed.headers,
        isRedirect: streamed.isRedirect,
        persistentConnection: streamed.persistentConnection,
        reasonPhrase: streamed.reasonPhrase,
        request: streamed.request,
      );
    } on Object catch (error) {
      throw ServerApiException('Could not reach the server: $error');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final retrySeconds = int.tryParse(response.headers['retry-after'] ?? '');
      throw ServerApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
        retryAfter: retrySeconds == null
            ? null
            : Duration(seconds: retrySeconds),
      );
    }
    return response;
  }
}

String _errorMessage(http.Response response) {
  try {
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic> && body['detail'] is String) {
      return body['detail'] as String;
    }
  } on FormatException {
    // Fall through to a bounded generic error.
  }
  return 'Server request failed (${response.statusCode}).';
}

Map<String, dynamic> _decodeObject(http.Response response) {
  final decoded = jsonDecode(response.body);
  return _asObject(decoded);
}

List<dynamic> _decodeList(http.Response response) {
  final decoded = jsonDecode(response.body);
  if (decoded is! List<dynamic>) {
    throw const FormatException('Server returned an invalid list.');
  }
  return decoded;
}

Map<String, dynamic> _asObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Server returned an invalid object.');
  }
  return value;
}

Map<String, dynamic> _object(Map<String, dynamic> json, String key) {
  return _asObject(json[key]);
}

List<dynamic> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List<dynamic>) {
    throw FormatException('Server field $key is invalid.');
  }
  return value;
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Server field $key is invalid.');
  }
  return value;
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Server field $key is invalid.');
  }
  return value;
}
