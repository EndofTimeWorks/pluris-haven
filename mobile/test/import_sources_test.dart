import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_archive_mapper.dart';
import 'package:pluris_haven/data/import/import_file_decoder.dart';
import 'package:pluris_haven/data/import/import_plan.dart';
import 'package:pluris_haven/data/import/import_preview.dart';
import 'package:pluris_haven/data/import/import_sources.dart';

void main() {
  test('defines the initial importer surface', () {
    expect(
      ImportSource.values.map((source) => source.label),
      containsAll([
        'Simply Plural',
        'Pluris Haven archive',
        'PluralKit file',
        'PluralKit live',
        'Tupperbox',
        'PluralSpace',
        'Prism',
      ]),
    );

    expect(ImportSource.prism.inputKinds, [ImportInputKind.encryptedFile]);
    expect(ImportSource.plurisHavenArchive.jobSource, 'plurishaven_archive');
    expect(
      ImportSource.pluralKitLive.dedupeKeys,
      containsAll(['PluralKit UUIDs', 'PluralKit short IDs']),
    );
    expect(ImportSource.pluralKitLive.jobSource, 'pluralkit_api');
    expect(ImportSource.tupperbox.jobSource, 'tupperbox_file');
  });

  test('documents the PluralKit live import shape', () {
    const shape = PluralKitLiveImportShape();

    expect(shape.authHeaderName, 'Authorization');
    expect(shape.systemEndpoint, '/systems/@me');
    expect(shape.membersEndpoint, '/systems/@me/members');
    expect(shape.groupsEndpoint, '/systems/@me/groups?with_members=true');
    expect(shape.switchesEndpoint, '/systems/@me/switches?limit=100');
    expect(shape.pageDelay, const Duration(milliseconds: 600));
  });

  test('builds an import plan for every source', () {
    for (final source in ImportSource.values) {
      final plan = importPlanFor(source);

      expect(plan.source, source);
      expect(plan.steps, isNotEmpty);
      expect(plan.previewCounts, isNotEmpty);
      expect(plan.privacyNotes, isNotEmpty);
    }

    expect(importPlanFor(ImportSource.prism).requiresPassphrase, isTrue);
    expect(importPlanFor(ImportSource.pluralKitLive).requiresToken, isTrue);
    expect(importPlanFor(ImportSource.simplyPlural).canPreviewOffline, isTrue);
    expect(
      importPlanFor(ImportSource.plurisHavenArchive).status.label,
      'ready',
    );
  });

  test('guesses import source from file name and preview', () {
    expect(
      guessImportSourceFromFile(
        fileName: 'backup.json',
        textPreview: '{"format":"pluris_haven.local_archive","version":1}',
      ).source,
      ImportSource.plurisHavenArchive,
    );
    expect(
      guessImportSourceFromFile(fileName: 'Simply Plural export.json').source,
      ImportSource.simplyPlural,
    );
    expect(
      guessImportSourceFromFile(fileName: 'system.prism').source,
      ImportSource.prism,
    );
    expect(
      guessImportSourceFromFile(
        fileName: 'export.json',
        textPreview: '{"switches":[],"members":[],"pluralkit":true}',
      ).source,
      ImportSource.pluralKitFile,
    );
    expect(
      guessImportSourceFromFile(
        fileName: 'unknown.json',
        textPreview: '{"members":[],"groups":[]}',
      ).source,
      isNull,
    );
  });

  test('previews Pluris Haven archive counts', () {
    final preview = previewImportText(
      fileName: 'pluris-haven.json',
      text: '''
{
  "format": "pluris_haven.local_archive",
  "version": 1,
  "members": [{"id": "m1"}, {"id": "m2"}],
  "groups": [{"id": "g1"}],
  "notes": [],
  "fronts": [{"id": "f1"}],
  "front_members": [{"session_id": "f1", "member_id": "m1"}],
  "import_records": [],
  "preferences": [{"key": "theme_mode"}]
}
''',
    );

    expect(preview.source, ImportSource.plurisHavenArchive);
    expect(preview.canApply, isTrue);
    expect(preview.counts['members'], 2);
    expect(preview.counts['groups'], 1);
    expect(preview.counts['fronts'], 1);
    expect(preview.counts['preferences'], 1);
  });

  test('extracts the import JSON from a zipped backup', () {
    final archive = Archive()
      ..addFile(ArchiveFile.string('avatars/avatar-1.png', 'not json'))
      ..addFile(
        ArchiveFile.string(
          'Simply Plural Export/export.json',
          jsonEncode({
            'members': [
              {'id': 'm1', 'name': 'Iris'},
            ],
            'frontHistory': [],
          }),
        ),
      );

    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final decoded = decodeImportFileBytes(
      fileName: 'Simply Plural Backup.zip',
      bytes: bytes,
    );

    expect(decoded, isNotNull);
    expect(decoded!.displayName, contains('export.json'));
    expect(decoded.text, contains('"Iris"'));
    expect(decoded.avatarAssets, hasLength(1));
    expect(decoded.avatarAssets.single.id, 'avatar-1');
    expect(decoded.avatarAssets.single.mimeType, 'image/png');
  });

  test('previews invalid archive as not applyable', () {
    final preview = previewImportText(
      fileName: 'bad.json',
      text: '{"format":"pluris_haven.local_archive","version":99}',
      selectedSource: ImportSource.plurisHavenArchive,
    );

    expect(preview.canApply, isFalse);
    expect(
      preview.warningsAndErrors.map((event) => event.message),
      contains('Unsupported archive version: 99.'),
    );
  });

  test('normalizes Simply Plural exports into local archive records', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "system": {"name": "EndofTimee"},
  "folders": [
    {"id": "g1", "name": "Main", "parent": "root"},
    {"id": "g2", "name": "Nested", "parent": "g1"}
  ],
  "members": [
    {
      "id": "m1",
      "name": "Iris",
      "pronouns": "she/they",
      "folderId": "g2",
      "pluralKitId": "pk-member"
    }
  ],
  "frontHistory": [
    {
      "id": "f1",
      "startedAt": "2026-01-01T12:00:00Z",
      "endedAt": "2026-01-01T13:00:00Z",
      "member_ids": ["m1"]
    }
  ],
  "notes": [{"id": "n1", "title": "Grounding", "body": "Drink water"}],
  "messages": [{"id": "msg1", "body": "Check in"}]
}
''',
    );

    expect(archive.counts['members'], 1);
    expect(archive.counts['groups'], 2);
    expect(archive.counts['fronts'], 1);
    expect(archive.counts['front_members'], 1);
    expect(archive.counts['notes'], 1);
    expect(archive.counts['messages'], 1);
    expect(archive.archiveJson, contains('"display_name": "Iris"'));
    expect(
      archive.archiveJson,
      contains('"parent_group_id": "simplyplural_file-group-g1"'),
    );
    expect(
      archive.archiveJson,
      contains('"folder_id": "simplyplural_file-group-g2"'),
    );
    expect(archive.archiveJson, contains('"source": "simplyplural_file"'));
  });

  test('normalizes Simply Plural map-keyed collections', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-map.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "users": {
    "u1": {"username": "SP Test System"}
  },
  "members": {
    "spm1": {"_id": "spm1", "name": "SpAlice", "desc": "First member"}
  }
}
''',
    );

    expect(archive.counts['members'], 1);
    expect(archive.archiveJson, contains('"name": "SP Test System"'));
    expect(archive.archiveJson, contains('"display_name": "SpAlice"'));
    expect(archive.archiveJson, contains('"description": "First member"'));
  });

  test('normalizes Simply Plural epoch and Firebase timestamps', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-dates.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {
      "id": "m1",
      "name": "Iris",
      "createdAt": {"_seconds": 1767225600, "_nanoseconds": 250000000}
    }
  ],
  "frontHistory": [
    {
      "id": "f1",
      "startedAt": 1767229200000,
      "endedAt": "1767232800",
      "members": ["m1"]
    }
  ]
}
''',
    );

    expect(archive.counts['members'], 1);
    expect(archive.counts['fronts'], 1);
    expect(
      archive.archiveJson,
      contains('"created_at": "2026-01-01T00:00:00.250Z"'),
    );
    expect(
      archive.archiveJson,
      contains('"started_at": "2026-01-01T01:00:00.000Z"'),
    );
    expect(
      archive.archiveJson,
      contains('"ended_at": "2026-01-01T02:00:00.000Z"'),
    );
  });

  test('warns and skips dangling Simply Plural import references', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-dangling.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {"_id": "m1", "name": "Iris", "folderId": "missing-group"}
  ],
  "groups": [
    {"_id": "g1", "name": "Main", "parent": "missing-parent"}
  ],
  "frontHistory": [
    {"_id": "front1", "member": "missing-member", "startTime": 1767225600000},
    {"_id": "front2", "startTime": 1767225600000}
  ],
  "reminders": [
    {"_id": "reminder1", "name": "No schedule"}
  ],
  "messages": [
    {"_id": "message1", "body": "Hello", "writer": "missing-member"}
  ]
}
''',
    );

    expect(archive.counts['members'], 1);
    expect(archive.counts['groups'], 1);
    expect(archive.counts['fronts'], 1);
    expect(archive.counts['front_members'], 0);
    expect(archive.counts['reminders'], 0);
    expect(
      archive.warnings,
      contains('Member "Iris" ignored missing group "missing-group".'),
    );
    expect(
      archive.warnings,
      contains('Group "Main" ignored missing parent "missing-parent".'),
    );
    expect(
      archive.warnings,
      contains('Front #1 ignored missing member "missing-member".'),
    );
    expect(
      archive.warnings,
      contains('Skipped front #2: no member ids or custom label.'),
    );
    expect(
      archive.warnings,
      contains('Skipped reminder #1: missing title or schedule.'),
    );
    expect(
      archive.warnings,
      contains('Ignored missing member reference "missing-member".'),
    );
    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    final member = (decoded['members'] as List).single as Map<String, dynamic>;
    final group = (decoded['groups'] as List).single as Map<String, dynamic>;
    final message =
        (decoded['messages'] as List).single as Map<String, dynamic>;
    expect(member['folder_id'], isNull);
    expect(group['parent_group_id'], isNull);
    expect(message['member_id'], isNull);
  });

  test('keeps custom-labeled fronts and swaps backwards intervals', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-custom-front.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "frontHistory": [
    {
      "_id": "custom-front",
      "custom": "Asleep",
      "startTime": 1767229200000,
      "endTime": 1767225600000
    }
  ]
}
''',
    );

    expect(archive.counts['fronts'], 1);
    expect(archive.counts['front_members'], 0);
    expect(archive.archiveJson, contains('"label": "Asleep"'));
    expect(
      archive.archiveJson,
      contains('"started_at": "2026-01-01T00:00:00.000Z"'),
    );
    expect(
      archive.archiveJson,
      contains('"ended_at": "2026-01-01T01:00:00.000Z"'),
    );
    expect(
      archive.warnings,
      contains('Front #1 ended before it started; swapped start and end.'),
    );
  });

  test(
    'normalizes richer Simply Plural export collections without data loss',
    () {
      final archive = normalizeImportTextToLocalArchive(
        source: ImportSource.simplyPlural,
        fileName: 'sp-rich.json',
        importedAt: DateTime.utc(2026),
        text: '''
{
  "users": [
    {
      "_id": "system-user",
      "username": "SP System",
      "fields": {"field1": "tea"},
      "lastOperationTime": 1767225600000
    }
  ],
  "members": [
    {
      "_id": "m1",
      "name": "Iris",
      "avatarUuid": "avatar-1",
      "info": {"field1": "20s"},
      "lastOperationTime": 1767225600000
    }
  ],
  "groups": [
    {
      "_id": "g1",
      "name": "Main",
      "members": ["m1"]
    }
  ],
  "customFields": [
    {"_id": "field1", "name": "Age", "type": "text"}
  ],
  "customFronts": [
    {"_id": "cf1", "name": "Asleep", "color": "7B61FF"}
  ],
  "boardMessages": [
    {
      "_id": "b1",
      "title": "Board",
      "message": "Check supplies",
      "writtenBy": "m1",
      "writtenAt": 1767225600000
    }
  ],
  "chatMessages": [
    {
      "_id": "c1",
      "message": "hi",
      "channel": "general",
      "writer": "m1",
      "writtenAt": 1767225600000
    }
  ],
  "comments": [
    {
      "_id": "comment1",
      "collection": "frontHistory",
      "documentId": "front1",
      "text": "front note",
      "time": 1767225600000
    }
  ],
  "repeatedReminders": [
    {
      "_id": "r1",
      "name": "Meds",
      "message": "Take meds",
      "dayInterval": 1,
      "lastOperationTime": 1767225600000
    }
  ],
  "frontHistory": [
    {
      "_id": "front1",
      "member": "m1",
      "custom": false,
      "startTime": 1767225600000,
      "endTime": 1767229200000
    }
  ],
  "privacyBuckets": [
    {"_id": "bucket1", "name": "Trusted"}
  ]
}
''',
      );

      expect(archive.counts['members'], 2);
      expect(archive.counts['groups'], 1);
      expect(archive.counts['custom_fields'], 1);
      expect(archive.counts['custom_field_values'], 2);
      expect(archive.counts['messages'], 3);
      expect(archive.counts['reminders'], 1);
      expect(archive.counts['fronts'], 1);
      expect(archive.counts['front_members'], 1);
      expect(archive.counts['avatar_assets'], 0);
      expect(archive.counts['raw_payloads'], 11);
      expect(
        archive.archiveJson,
        contains('"avatar_url": "sp-avatar:avatar-1"'),
      );
      expect(
        archive.archiveJson,
        contains('"folder_id": "simplyplural_file-group-g1"'),
      );
      expect(archive.archiveJson, contains('"is_custom_front": true'));
      expect(archive.archiveJson, contains('"name": "Age"'));
      expect(archive.archiveJson, contains('"value": "20s"'));
      expect(archive.archiveJson, contains('"value": "tea"'));
      expect(
        archive.archiveJson,
        isNot(contains('"title": "Imported custom fields"')),
      );
      expect(
        archive.archiveJson,
        isNot(contains('"title": "Imported custom fronts"')),
      );
      expect(archive.archiveJson, contains('"collection": "customFields"'));
      expect(archive.archiveJson, contains('"collection": "customFronts"'));
      expect(archive.archiveJson, contains('"collection": "privacyBuckets"'));
      expect(archive.archiveJson, contains('"body": "Board\\nCheck supplies"'));
    },
  );

  test('embeds zipped Simply Plural avatar bytes in normalized archive', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [{"_id": "m1", "name": "Iris", "avatarUuid": "avatar-1"}]
}
''',
      avatarAssets: [
        ImportAvatarAsset(
          id: 'avatar-1',
          name: 'avatars/avatar-1.png',
          mimeType: 'image/png',
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ],
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    expect(decoded['avatar_assets'], hasLength(1));
    expect(archive.counts['avatar_assets'], 1);
    expect(archive.archiveJson, contains('"bytes_base64": "AQIDBA=="'));
  });

  test('normalizes PluralKit export switches into front intervals', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.pluralKitFile,
      fileName: 'pk.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "system": {"name": "Local"},
  "members": [
    {"uuid": "aaa-bbb", "name": "Blue", "color": "3366ff"}
  ],
  "groups": [
    {"uuid": "grp", "name": "Subsystem"}
  ],
  "switches": [
    {"id": "s1", "timestamp": "2026-01-01T10:00:00Z", "members": ["aaa-bbb"]},
    {"id": "s2", "timestamp": "2026-01-01T11:00:00Z", "members": []}
  ]
}
''',
    );

    expect(archive.counts['members'], 1);
    expect(archive.counts['groups'], 1);
    expect(archive.counts['fronts'], 2);
    expect(archive.counts['front_members'], 1);
    expect(
      archive.archiveJson,
      contains('"ended_at": "2026-01-01T11:00:00.000Z"'),
    );
    expect(archive.archiveJson, contains('"color_hex": "#3366ff"'));
  });

  test('uses Simply Plural document IDs instead of shared account UID', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {"_id": "member-a", "uid": "system-account", "name": "Iris"},
    {"_id": "member-b", "uid": "system-account", "name": "River"}
  ],
  "frontHistory": [
    {
      "_id": "front-a",
      "uid": "system-account",
      "member": "member-b",
      "startTime": 1767225600000
    }
  ]
}
''',
    );

    expect(archive.counts['members'], 2);
    expect(
      archive.archiveJson,
      contains('"id": "simplyplural_file-member-member-a"'),
    );
    expect(
      archive.archiveJson,
      contains('"member_id": "simplyplural_file-member-member-b"'),
    );
    expect(
      archive.archiveJson,
      contains('"session_id": "simplyplural_file-front-front-a"'),
    );
  });

  test('normalizes Tupperbox tuppers as members', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.tupperbox,
      fileName: 'tuppers.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "tuppers": [
    {"id": "t1", "name": "Echo", "avatar_url": "https://example.invalid/e.png"}
  ]
}
''',
    );

    expect(archive.counts['members'], 1);
    expect(archive.archiveJson, contains('"display_name": "Echo"'));
    expect(archive.archiveJson, contains('"source": "tupperbox_file"'));
  });
}
