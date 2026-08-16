import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pluris_haven/data/import/pluralkit_live_client.dart';

void main() {
  test('fetches the live archive with an ephemeral auth header', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      expect(request.headers['Authorization'], 'pk;secret');
      return switch (request.url.path) {
        '/v2/systems/@me' => http.Response('{"id":"system"}', 200),
        '/v2/systems/@me/members' => http.Response('[{"id":"member"}]', 200),
        '/v2/systems/@me/groups' => http.Response('[]', 200),
        '/v2/systems/@me/switches' => http.Response('[]', 200),
        _ => http.Response('not found', 404),
      };
    });

    final archive = await PluralKitLiveClient(
      client: client,
    ).fetchArchiveJson(' pk;secret ');
    final decoded = jsonDecode(archive) as Map<String, Object?>;

    expect(
      paths,
      containsAll(<String>[
        '/v2/systems/@me',
        '/v2/systems/@me/members',
        '/v2/systems/@me/groups',
        '/v2/systems/@me/switches',
      ]),
    );
    expect(decoded['members'], hasLength(1));
    expect(archive, isNot(contains('pk;secret')));
  });

  test('paginates switches and obeys the configured cap', () async {
    var switchRequests = 0;
    final client = MockClient((request) async {
      if (!request.url.path.endsWith('/switches')) {
        return http.Response(
          request.url.path.endsWith('/systems/@me') ? '{}' : '[]',
          200,
        );
      }
      switchRequests++;
      final page = List<Object?>.generate(
        100,
        (index) => <String, Object?>{
          'id': '$switchRequests-$index',
          'timestamp':
              '2026-01-${switchRequests.toString().padLeft(2, '0')}T00:00:00Z',
          'members': const <Object?>[],
        },
      );
      return http.Response(jsonEncode(page), 200);
    });

    final archive = await PluralKitLiveClient(
      client: client,
      pageDelay: Duration.zero,
      maxSwitches: 150,
    ).fetchArchiveJson('token');
    final decoded = jsonDecode(archive) as Map<String, Object?>;

    expect(decoded['switches'], hasLength(150));
    expect(switchRequests, 2);
  });

  test('rejects redirects without forwarding the token', () async {
    final client = MockClient((request) async => http.Response('', 302));

    expect(
      () => PluralKitLiveClient(client: client).fetchArchiveJson('token'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('redirected'),
        ),
      ),
    );
  });

  test('rejects a declared response above the byte limit', () async {
    final client = MockClient.streaming((request, bodyStream) async {
      return http.StreamedResponse(
        const Stream<List<int>>.empty(),
        200,
        contentLength: 9,
      );
    });

    expect(
      () => PluralKitLiveClient(
        client: client,
        maximumResponseBytes: 8,
      ).fetchArchiveJson('token'),
      throwsA(isA<PluralKitResponseTooLargeException>()),
    );
  });

  test('rejects a chunked response above the byte limit', () async {
    final client = MockClient.streaming((request, bodyStream) async {
      return http.StreamedResponse(
        Stream<List<int>>.fromIterable(const [
          [91, 123, 125],
          [44, 123, 125, 93],
        ]),
        200,
      );
    });

    expect(
      () => PluralKitLiveClient(
        client: client,
        maximumResponseBytes: 6,
      ).fetchArchiveJson('token'),
      throwsA(isA<PluralKitResponseTooLargeException>()),
    );
  });
}
