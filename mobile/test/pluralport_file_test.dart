import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_archive_mapper.dart';
import 'package:pluris_haven/data/import/import_plan.dart';
import 'package:pluris_haven/data/import/import_preview.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/import/pluralport_codec.dart';

void main() {
  test('validates and detects a PluralPort Draft v0.1 file', () {
    const text = '''
{
  "pluralport_version": "0.1",
  "exported_at": "2026-10-07T00:00:00Z",
  "producer": {"app": "Example", "app_version": "1.0.0", "app_id": "com.example.app"},
  "capabilities": {"modules": ["systems", "members"]},
  "systems": [],
  "members": [],
  "extensions": {},
  "warnings": []
}
''';

    expect(() => decodePluralPortEnvelope(text), returnsNormally);
    final guess = guessImportSourceFromFile(
      fileName: 'example-pluralport.json',
      textPreview: text,
    );
    expect(guess.source, ImportSource.pluralPort);
    expect(guess.isConfident, isTrue);
  });

  test('rejects unsupported versions and malformed envelopes', () {
    expect(
      () => decodePluralPortEnvelope('{"pluralport_version":"0.2"}'),
      throwsFormatException,
    );
    expect(
      () => decodePluralPortEnvelope('''
{
  "pluralport_version": "0.1",
  "exported_at": "not-a-date",
  "producer": {"app": "Example", "app_version": "1", "app_id": "example"},
  "capabilities": {"modules": []}
}
'''),
      throwsFormatException,
    );
    final preview = previewImportText(
      fileName: 'bad-pluralport.json',
      text: '''
{
  "pluralport_version": "0.2",
  "exported_at": "2026-10-07T00:00:00Z",
  "producer": {"app": "Example", "app_version": "1", "app_id": "example"},
  "capabilities": {"modules": []}
}
''',
    );
    expect(preview.source, ImportSource.pluralPort);
    expect(preview.canApply, isFalse);
    expect(preview.events.single.stage, ImportPreviewStage.validate);
    expect(
      () => decodePluralPortEnvelope('''
{
  "pluralport_version": "0.1",
  "exported_at": "2026-10-07T00:00:00",
  "producer": {"app": "Example", "app_version": "1", "app_id": "example"},
  "capabilities": {"modules": []}
}
'''),
      throwsFormatException,
    );
    expect(
      () => decodePluralPortEnvelope('''
{
  "pluralport_version": "0.1",
  "exported_at": "2026-10-07T00:00:00-00:00",
  "producer": {"app": "Example", "app_version": "1", "app_id": "example"},
  "capabilities": {"modules": []}
}
'''),
      throwsFormatException,
    );
    expect(
      () => decodePluralPortEnvelope('''
{
  "pluralport_version": "0.1",
  "exported_at": "2026-10-07T00:00:00Z",
  "producer": {"app": "Example", "app_version": "1", "app_id": "example"},
  "capabilities": {"modules": ["members"]},
  "members": ["not-an-object"]
}
'''),
      throwsFormatException,
    );
    expect(
      () => decodePluralPortEnvelope('''
{
  "pluralport_version": "0.1",
  "exported_at": "2026-10-07T00:00:00Z",
  "producer": {"app": "Example", "app_version": "1", "app_id": "example"},
  "capabilities": {"modules": ["fronting"]},
  "front_periods": [{"id":"f1","started_at":"2026-10-07T00:00:00"}]
}
'''),
      throwsFormatException,
    );
  });

  test('imports documented records and preserves original records', () {
    final normalized = normalizeImportTextToLocalArchive(
      source: ImportSource.pluralPort,
      fileName: 'pluralport.json',
      importedAt: DateTime.utc(2026, 10, 7),
      text: '''
{
  "pluralport_version": "0.1",
  "exported_at": "2026-10-07T00:00:00Z",
  "producer": {"app": "Example", "app_version": "1.0.0", "app_id": "com.example.app"},
  "capabilities": {"modules": ["systems", "members", "groups", "fronting", "notes"]},
  "systems": [{"id":"s1","name":"River House","extensions":{"com.example.app":{"unknown":true}}}],
  "members": [{"id":"m1","system_id":"s1","name":"Iris","avatar_asset_id":"a1","source_refs":[{"app":"com.example.app","collection":"members","id":"source-m1"}]}],
  "groups": [{"id":"g1","system_id":"s1","name":"Main"}],
  "group_memberships": [{"id":"gm1","group_id":"g1","member_id":"m1"}],
  "custom_fields": [{"id":"cf1","name":"Role","future_shape":true}],
  "custom_field_values": [{"id":"cfv1","field_id":"cf1","subject_id":"m1","value":"Host"}],
  "front_periods": [{"id":"f1","system_id":"s1","started_at":"2026-10-07T00:00:00Z","assignments":[{"member_id":"m1","front_role":"primary"}]}],
  "notes": [{"id":"n1","system_id":"s1","member_id":"m1","title":"Hello","body":"World"}],
  "assets": [{"id":"a1","name":"iris.png","mime_type":"image/png","extensions":{"pluris_haven":{"bytes_base64":"AQID"}}}],
  "extensions": {"com.example.app":{"future":{"kept":true}}},
  "warnings": []
}
''',
    );

    expect(normalized.counts['members'], 1);
    expect(normalized.counts['groups'], 0);
    expect(normalized.counts['group_members'], 0);
    expect(normalized.counts['fronts'], 1);
    expect(normalized.counts['notes'], 0);
    expect(normalized.counts['avatar_assets'], 0);
    expect(normalized.counts['custom_fields'], 0);
    expect(normalized.counts['raw_payloads'], 1);
    expect(normalized.archiveJson, contains('pluralport_extensions'));
    expect(normalized.archiveJson, contains('source-m1'));
    final archive = jsonDecode(normalized.archiveJson) as Map<String, Object?>;
    final payload = (archive['raw_payloads'] as List).single;
    final payloadJson = (payload as Map<String, Object?>)['payload_json'];
    expect(payloadJson, contains('"unknown": true'));
    expect(payloadJson, contains('"future_shape": true'));
    expect(payloadJson, contains('"group_memberships"'));
    expect(payloadJson, contains('"bytes_base64": "AQID"'));

    final reexported = decodePluralPortEnvelope(
      encodePluralPortFromLocalArchive(
        normalized.archiveJson,
        appVersion: '0.3.0-pre-alpha.4',
        exportedAt: DateTime.utc(2026, 10, 7),
      ),
    );
    final reexportedMember =
        (reexported['members'] as List).single as Map<String, Object?>;
    expect(
      (reexportedMember['source_refs'] as List).whereType<Map>().any(
        (sourceRef) =>
            sourceRef['app'] == 'com.example.app' &&
            sourceRef['collection'] == 'members' &&
            sourceRef['id'] == 'source-m1',
      ),
      isTrue,
    );
  });

  test('exports the documented envelope and reports archive-only data', () {
    final exported = encodePluralPortFromLocalArchive(
      jsonEncode({
        'format': 'pluris_haven.local_archive',
        'version': 1,
        'system': {
          'id': 's1',
          'name': 'River House',
          'avatar_url': 'local-avatar:a1',
          'created_at': '2026-10-07T00:00:00Z',
        },
        'members': [
          {
            'id': 'm1',
            'display_name': 'Iris',
            'pronouns': 'they/them',
            'avatar_url': 'local-avatar:a1',
            'pluralkit_id': 'abcde',
            'privacy': 'private',
          },
        ],
        'groups': [
          {'id': 'g1', 'name': 'Main'},
        ],
        'group_members': [
          {'group_id': 'g1', 'member_id': 'm1'},
        ],
        'fronts': [
          {'id': 'f1', 'started_at': '2026-10-07T00:00:00Z', 'ended_at': null},
        ],
        'front_members': [
          {'session_id': 'f1', 'member_id': 'm1'},
        ],
        'notes': [
          {'id': 'n1', 'title': 'Grounding', 'body': 'Drink water'},
        ],
        'avatar_assets': [
          {'id': 'a1', 'mime_type': 'image/png', 'bytes_base64': 'AQID'},
        ],
        'tags': [
          {'id': 't1', 'name': 'Caretaker'},
        ],
        'member_tags': [
          {'tag_id': 't1', 'member_id': 'm1'},
        ],
        'custom_fields': [
          {'id': 'cf1', 'name': 'Role'},
        ],
        'custom_field_values': [
          {'id': 'cfv1', 'field_id': 'cf1', 'member_id': 'm1', 'value': 'Host'},
        ],
        'journals': [
          {'id': 'j1', 'body': 'preserve me'},
        ],
      }),
      appVersion: '0.3.0-pre-alpha.4',
      exportedAt: DateTime.utc(2026, 10, 7),
    );
    final envelope = decodePluralPortEnvelope(exported);

    expect(envelope['pluralport_version'], '0.1');
    expect(envelope['exported_at'], '2026-10-07T00:00:00.000Z');
    expect((envelope['members'] as List), hasLength(1));
    expect((envelope['front_periods'] as List), hasLength(1));
    expect((envelope['warnings'] as List), hasLength(1));
    expect(exported, contains('preserve me'));
    expect(exported, contains('Caretaker'));
    expect(exported, contains('Host'));
    expect(envelope, isNot(contains('taxonomy_terms')));
    expect(envelope, isNot(contains('custom_fields')));
    expect(envelope, isNot(contains('groups')));
    expect(envelope, isNot(contains('group_memberships')));
    expect(envelope, isNot(contains('notes')));
    expect(envelope, isNot(contains('assets')));
    final system = (envelope['systems'] as List).single as Map<String, Object?>;
    expect(system, isNot(contains('avatar_asset_id')));
    final member = (envelope['members'] as List).single as Map<String, Object?>;
    final sourceRefs = member['source_refs'] as List;
    expect(
      sourceRefs.whereType<Map>().any(
        (sourceRef) =>
            sourceRef['app'] == 'pluralkit' &&
            sourceRef['collection'] == 'members' &&
            sourceRef['id'] == 'abcde',
      ),
      isTrue,
    );
    expect(member, isNot(contains('avatar_asset_id')));
    expect(exported, contains('Grounding'));
    expect(exported, contains('bytes_base64'));
    expect(exported, contains('extensions'));
  });

  test('normalizes caller-supplied export time to UTC', () {
    final envelope = decodePluralPortEnvelope(
      encodePluralPortFromLocalArchive(
        jsonEncode({
          'format': 'pluris_haven.local_archive',
          'version': 1,
          'system': {'id': 's1', 'name': 'River House'},
          'members': const <Object?>[],
          'fronts': const <Object?>[],
          'front_members': const <Object?>[],
        }),
        appVersion: '0.3.0-pre-alpha.4',
        exportedAt: DateTime.parse('2026-10-07T01:30:00+01:00'),
      ),
    );

    expect(envelope['exported_at'], '2026-10-07T00:30:00.000Z');
  });
}
