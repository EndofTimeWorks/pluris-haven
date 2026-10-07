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
    expect(normalized.counts['groups'], 1);
    expect(normalized.counts['group_members'], 1);
    expect(normalized.counts['fronts'], 1);
    expect(normalized.counts['notes'], 1);
    expect(normalized.counts['avatar_assets'], 1);
    expect(normalized.counts['custom_fields'], 0);
    expect(normalized.counts['raw_payloads'], 1);
    expect(normalized.archiveJson, contains('pluralport_extensions'));
    expect(normalized.archiveJson, contains('source-m1'));
    final archive = jsonDecode(normalized.archiveJson) as Map<String, Object?>;
    final payload = (archive['raw_payloads'] as List).single;
    final payloadJson = (payload as Map<String, Object?>)['payload_json'];
    expect(payloadJson, contains('"unknown": true'));
    expect(payloadJson, contains('"future_shape": true'));
    expect(normalized.archiveJson, contains('local-avatar:a1'));
  });

  test('exports the documented envelope and reports archive-only data', () {
    final exported = encodePluralPortFromLocalArchive(
      jsonEncode({
        'format': 'pluris_haven.local_archive',
        'version': 1,
        'system': {'id': 's1', 'name': 'River House'},
        'members': [
          {'id': 'm1', 'display_name': 'Iris', 'pronouns': 'they/them'},
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
        'notes': const <Object?>[],
        'avatar_assets': const <Object?>[],
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
    expect((envelope['members'] as List), hasLength(1));
    expect((envelope['group_memberships'] as List), hasLength(1));
    expect((envelope['front_periods'] as List), hasLength(1));
    expect((envelope['warnings'] as List), hasLength(1));
    expect(exported, contains('preserve me'));
    expect(exported, contains('Caretaker'));
    expect(exported, contains('Host'));
    expect(envelope, isNot(contains('taxonomy_terms')));
    expect(envelope, isNot(contains('custom_fields')));
    expect(exported, contains('extensions'));
  });
}
