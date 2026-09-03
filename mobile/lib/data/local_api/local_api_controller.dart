import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../local/app_database.dart';
import '../local/haven_repository.dart';
import '../local/local_id.dart';
import '../security/haven_crypto.dart';

enum LocalApiScope {
  systemRead('system.read'),
  membersRead('members.read'),
  frontsRead('fronts.read');

  const LocalApiScope(this.value);

  final String value;
}

class LocalApiClient {
  const LocalApiClient({
    required this.id,
    required this.label,
    required this.scopes,
    required this.createdAt,
    this.revokedAt,
  });

  final String id;
  final String label;
  final Set<LocalApiScope> scopes;
  final DateTime createdAt;
  final DateTime? revokedAt;

  bool get isRevoked => revokedAt != null;
}

class LocalApiClientCredential {
  const LocalApiClientCredential({required this.client, required this.token});

  final LocalApiClient client;

  /// Display this only once, at the time the client is created.
  final String token;
}

abstract interface class LocalApiListener {
  int get port;

  Future<void> start(int port);
  Future<void> stop();
}

typedef LocalApiListenerFactory =
    LocalApiListener Function(
      HavenRepository repository,
      Future<LocalApiClient?> Function(String token) authenticate,
    );

class LocalApiStatus {
  const LocalApiStatus({
    required this.enabled,
    this.port,
    required this.isListening,
  });

  final bool enabled;
  final int? port;

  Uri? get origin => port == null ? null : Uri.http('127.0.0.1:$port');

  final bool isListening;
}

/// A native-device, loopback-only API controller.
///
/// The service is deliberately not started at construction. Call [enable] as
/// the result of an explicit user action, and create narrowly-scoped client
/// grants before another local process can read private data.
class LocalApiController {
  LocalApiController(
    this._repository, {
    LocalApiListenerFactory? listenerFactory,
  }) : _database = _repository.database,
       _crypto = _repository.crypto,
       _listenerFactory = listenerFactory ?? _createListener;

  static const _enabledKey = 'local_api.enabled';
  static const _portKey = 'local_api.port';
  static const _clientsKey = 'local_api.clients.v1';
  static const _clientsAad = 'pluris-haven:local-api:v1:clients';

  final LocalHavenRepository _repository;
  final AppDatabase _database;
  final HavenCrypto _crypto;
  final LocalApiListenerFactory _listenerFactory;
  LocalApiListener? _service;
  Future<void> _lifecycle = Future.value();

  Future<LocalApiStatus> status() async {
    final enabled = await _readEnabled();
    final port = await _readPort();
    return LocalApiStatus(
      enabled: enabled,
      port: port,
      isListening: _service != null,
    );
  }

  Future<LocalApiStatus> enable() => _enqueue(() async {
    final port = await _start();
    await _writePreference(_enabledKey, 'true');
    return LocalApiStatus(enabled: true, port: port, isListening: true);
  });

  Future<void> disable() => _enqueue(() async {
    final service = _service;
    _service = null;
    await service?.stop();
    await _writePreference(_enabledKey, 'false');
  });

  /// Restores an explicitly enabled service after the repository is available.
  /// Binding failure is contained: the persisted preference is retained, but
  /// the API does not claim to be listening.
  Future<LocalApiStatus> startIfEnabled() => _enqueue(() async {
    if (!await _readEnabled()) {
      return const LocalApiStatus(enabled: false, isListening: false);
    }
    try {
      final port = await _start();
      return LocalApiStatus(enabled: true, port: port, isListening: true);
    } on SocketException {
      return LocalApiStatus(
        enabled: true,
        port: await _readPort(),
        isListening: false,
      );
    }
  });

  /// Stops the listener without changing the user's explicit enable choice.
  Future<void> close() => _enqueue(() async {
    final service = _service;
    _service = null;
    await service?.stop();
  });

  /// Reconciles listener access with the App Lock lifecycle.
  Future<void> setAccessAllowed(bool allowed) async {
    if (allowed) {
      await startIfEnabled();
    } else {
      await close();
    }
  }

  Future<int> _start() async {
    final existing = _service;
    if (existing != null) return existing.port;
    final configuredPort = await _readPort();
    final service = _listenerFactory(_repository, _authenticateClient);
    await service.start(configuredPort ?? 0);
    _service = service;
    if (configuredPort == null) {
      await _writePreference(_portKey, service.port.toString());
    }
    return service.port;
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _lifecycle.then((_) => operation());
    _lifecycle = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  Future<List<LocalApiClient>> listClients() async => _loadClients().then(
    (clients) => clients.map((client) => client.client).toList(growable: false),
  );

  Future<LocalApiClientCredential> createClient({
    required String label,
    required Set<LocalApiScope> scopes,
  }) async {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      throw const FormatException('Client name is required.');
    }
    if (scopes.isEmpty) {
      throw const FormatException('Choose at least one local API scope.');
    }
    final now = DateTime.now().toUtc();
    final client = LocalApiClient(
      id: newLocalId('local-api-client'),
      label: normalizedLabel,
      scopes: Set.unmodifiable(scopes),
      createdAt: now,
    );
    final token = _newToken();
    final clients = await _loadClients();
    clients.add(
      _StoredLocalApiClient(
        client: client,
        tokenFingerprint: await _crypto.credentialFingerprint(token),
      ),
    );
    await _saveClients(clients);
    return LocalApiClientCredential(client: client, token: token);
  }

  Future<void> revokeClient(String clientId) async {
    final clients = await _loadClients();
    final index = clients.indexWhere((client) => client.client.id == clientId);
    if (index == -1 || clients[index].client.isRevoked) return;
    final old = clients[index];
    clients[index] = _StoredLocalApiClient(
      client: LocalApiClient(
        id: old.client.id,
        label: old.client.label,
        scopes: old.client.scopes,
        createdAt: old.client.createdAt,
        revokedAt: DateTime.now().toUtc(),
      ),
      tokenFingerprint: old.tokenFingerprint,
    );
    await _saveClients(clients);
  }

  Future<LocalApiClient?> _authenticateClient(String token) async {
    if (token.isEmpty) return null;
    final fingerprint = await _crypto.credentialFingerprint(token);
    for (final client in await _loadClients()) {
      if (!client.client.isRevoked &&
          _fixedTimeEquals(client.tokenFingerprint, fingerprint)) {
        return client.client;
      }
    }
    return null;
  }

  Future<bool> _readEnabled() async {
    final row =
        await (_database.select(_database.appPreferences)
              ..where((preference) => preference.key.equals(_enabledKey)))
            .getSingleOrNull();
    return row?.value == 'true';
  }

  Future<int?> _readPort() async {
    final row =
        await (_database.select(_database.appPreferences)
              ..where((preference) => preference.key.equals(_portKey)))
            .getSingleOrNull();
    return int.tryParse(row?.value ?? '');
  }

  Future<void> _writePreference(String key, String value) => _database
      .into(_database.appPreferences)
      .insertOnConflictUpdate(
        AppPreferencesCompanion.insert(
          key: key,
          value: value,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

  Future<List<_StoredLocalApiClient>> _loadClients() async {
    final row =
        await (_database.select(_database.appPreferences)
              ..where((preference) => preference.key.equals(_clientsKey)))
            .getSingleOrNull();
    if (row == null) return [];
    final cleartext = await _crypto.decrypt(row.value, aad: _clientsAad);
    final decoded = jsonDecode(cleartext!) as List<Object?>;
    return [
      for (final value in decoded)
        if (value is Map<String, Object?>)
          _StoredLocalApiClient.fromJson(value),
    ];
  }

  Future<void> _saveClients(List<_StoredLocalApiClient> clients) async {
    final encrypted = await _crypto.encrypt(
      jsonEncode([for (final client in clients) client.toJson()]),
      aad: _clientsAad,
    );
    await _writePreference(_clientsKey, encrypted!);
  }

  String _newToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

LocalApiListener _createListener(
  HavenRepository repository,
  Future<LocalApiClient?> Function(String token) authenticate,
) => _LocalApiService(repository, authenticate);

bool _fixedTimeEquals(String left, String right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
  }
  return difference == 0;
}

class _StoredLocalApiClient {
  const _StoredLocalApiClient({
    required this.client,
    required this.tokenFingerprint,
  });

  final LocalApiClient client;
  final String tokenFingerprint;

  factory _StoredLocalApiClient.fromJson(Map<String, Object?> json) {
    final scopes = <LocalApiScope>{
      for (final value in (json['scopes'] as List<Object?>? ?? const []))
        for (final scope in LocalApiScope.values)
          if (scope.value == value) scope,
    };
    return _StoredLocalApiClient(
      client: LocalApiClient(
        id: json['id']! as String,
        label: json['label']! as String,
        scopes: Set.unmodifiable(scopes),
        createdAt: DateTime.parse(json['created_at']! as String).toUtc(),
        revokedAt: json['revoked_at'] is String
            ? DateTime.parse(json['revoked_at']! as String).toUtc()
            : null,
      ),
      tokenFingerprint: json['token_fingerprint']! as String,
    );
  }

  Map<String, Object?> toJson() => {
    'id': client.id,
    'label': client.label,
    'scopes': client.scopes.map((scope) => scope.value).toList(),
    'created_at': client.createdAt.toIso8601String(),
    'revoked_at': client.revokedAt?.toIso8601String(),
    'token_fingerprint': tokenFingerprint,
  };
}

class _LocalApiService implements LocalApiListener {
  _LocalApiService(this._repository, this._authenticate);

  final HavenRepository _repository;
  final Future<LocalApiClient?> Function(String token) _authenticate;
  HttpServer? _server;

  @override
  int get port => _server!.port;

  @override
  Future<void> start(int port) async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    unawaited(_serve());
  }

  @override
  Future<void> stop() async => _server?.close(force: true);

  Future<void> _serve() async {
    await for (final request in _server!) {
      unawaited(_handle(request));
    }
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method != 'GET') {
        return _error(request, 405, 'method_not_allowed');
      }
      final path = request.uri.path;
      if (path == '/v1/health') {
        return _json(request, 200, {'version': 'v1', 'status': 'ok'});
      }
      final client = await _authenticate(_bearerToken(request));
      if (client == null) return _error(request, 401, 'invalid_client');
      if (path == '/v1/system') {
        if (!_hasScope(client, LocalApiScope.systemRead)) {
          return _scopeError(request);
        }
        final value = await _repository.watchHomeSnapshot().first;
        return _json(request, 200, {
          'id': localSystemId,
          'name': value.systemName,
          'member_count': value.memberCount,
          'group_count': value.groupCount,
          'note_count': value.noteCount,
        });
      }
      if (path == '/v1/members') {
        if (!_hasScope(client, LocalApiScope.membersRead)) {
          return _scopeError(request);
        }
        final members = await _repository.watchMembers().first;
        return _json(request, 200, {
          'members': [
            for (final member in members)
              {
                'id': member.id,
                'name': member.displayName,
                'pronouns': member.pronouns,
                'archived': member.archived,
              },
          ],
        });
      }
      if (path == '/v1/front') {
        if (!_hasScope(client, LocalApiScope.frontsRead)) {
          return _scopeError(request);
        }
        final members = await _repository.watchCurrentFrontMembers().first;
        return _json(request, 200, {
          'members': [
            for (final member in members)
              {'id': member.id, 'name': member.displayName},
          ],
        });
      }
      return _error(request, 404, 'not_found');
    } on Object {
      return _error(request, 500, 'internal_error');
    }
  }

  bool _hasScope(LocalApiClient client, LocalApiScope scope) =>
      client.scopes.contains(scope);

  String _bearerToken(HttpRequest request) {
    final value = request.headers.value(HttpHeaders.authorizationHeader);
    return value?.startsWith('Bearer ') == true ? value!.substring(7) : '';
  }

  Future<void> _scopeError(HttpRequest request) =>
      _error(request, 403, 'scope_required');

  Future<void> _error(HttpRequest request, int status, String code) =>
      _json(request, status, {
        'error': {'code': code},
      });

  Future<void> _json(HttpRequest request, int status, Object body) async {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    request.response.write(jsonEncode(body));
    await request.response.close();
  }
}
