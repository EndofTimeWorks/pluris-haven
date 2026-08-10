import 'dart:convert';

import 'package:http/http.dart' as http;

import 'import_sources.dart';

class PluralKitLiveClient {
  PluralKitLiveClient({
    http.Client? client,
    this.pageDelay = const Duration(milliseconds: 600),
    this.maxSwitches = 10000,
  }) : _client = client ?? http.Client();

  static final Uri _origin = Uri.parse('https://api.pluralkit.me/v2/');
  final http.Client _client;
  final Duration pageDelay;
  final int maxSwitches;

  Future<String> fetchArchiveJson(String token) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      throw const FormatException('Enter a PluralKit token first.');
    }

    final shape = const PluralKitLiveImportShape();
    final system = await _getObject(shape.systemEndpoint, trimmedToken);
    final members = await _getList(shape.membersEndpoint, trimmedToken);
    final groups = await _getList(shape.groupsEndpoint, trimmedToken);
    final switches = await _getSwitches(shape.switchesEndpoint, trimmedToken);

    return jsonEncode({
      'system': system,
      'members': members,
      'groups': groups,
      'switches': switches,
    });
  }

  Future<List<Object?>> _getSwitches(String path, String token) async {
    final switches = <Object?>[];
    var nextPath = path;

    while (switches.length < maxSwitches) {
      final page = await _getList(nextPath, token);
      if (page.isEmpty) break;
      switches.addAll(page.take(maxSwitches - switches.length));
      if (page.length < 100 || switches.length >= maxSwitches) break;

      final last = page.last;
      if (last is! Map<String, Object?>) break;
      final before = last['timestamp'];
      if (before is! String || before.isEmpty) break;
      nextPath =
          '/systems/@me/switches?limit=100&before=${Uri.encodeQueryComponent(before)}';
      await Future<void>.delayed(pageDelay);
    }

    return switches;
  }

  Future<Map<String, Object?>> _getObject(String path, String token) async {
    final decoded = await _get(path, token);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('PluralKit returned an unexpected object.');
    }
    return decoded;
  }

  Future<List<Object?>> _getList(String path, String token) async {
    final decoded = await _get(path, token);
    if (decoded is! List<Object?>) {
      throw const FormatException('PluralKit returned an unexpected list.');
    }
    return decoded;
  }

  Future<Object?> _get(String path, String token) async {
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    final request = http.Request('GET', _origin.resolve(relativePath))
      ..followRedirects = false
      ..headers['Authorization'] = token
      ..headers['Accept'] = 'application/json';
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 20));
    final bytes = await response.stream.toBytes();

    if (response.statusCode >= 300 && response.statusCode < 400) {
      throw const FormatException(
        'PluralKit redirected the request; import stopped.',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const FormatException('PluralKit rejected that token.');
    }
    if (response.statusCode == 429) {
      throw const FormatException(
        'PluralKit rate-limited the import. Wait, then retry.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(
        'PluralKit request failed (${response.statusCode}).',
      );
    }

    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const FormatException('PluralKit returned invalid JSON.');
    }
  }
}
