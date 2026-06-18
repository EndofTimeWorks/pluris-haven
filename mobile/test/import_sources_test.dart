import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_archive_mapper.dart';
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
  "folders": [{"id": "g1", "name": "Main"}],
  "members": [
    {
      "id": "m1",
      "name": "Iris",
      "pronouns": "she/they",
      "folderId": "g1",
      "pluralKitId": "pk-member"
    }
  ],
  "frontHistory": [
    {
      "id": "f1",
      "startedAt": "2026-01-01T12:00:00Z",
      "endedAt": "2026-01-01T13:00:00Z",
      "members": ["m1"]
    }
  ],
  "notes": [{"id": "n1", "title": "Grounding", "body": "Drink water"}],
  "messages": [{"id": "msg1", "body": "Check in"}]
}
''',
    );

    expect(archive.counts['members'], 1);
    expect(archive.counts['groups'], 1);
    expect(archive.counts['fronts'], 1);
    expect(archive.counts['front_members'], 1);
    expect(archive.counts['notes'], 1);
    expect(archive.counts['messages'], 1);
    expect(archive.archiveJson, contains('"display_name": "Iris"'));
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

  test('decodes PluralSpace zip export and normalizes nested data', () {
    final zip = Archive()
      ..addFile(
        ArchiveFile.string(
          'manifest.json',
          jsonEncode({'system_name': 'PluralSpace System'}),
        ),
      )
      ..addFile(
        ArchiveFile.string(
          'data.json',
          jsonEncode({
            'members': [
              {'id': 'psm1', 'name': 'River', 'pronouns': 'they/them'},
            ],
            'member_groups': [
              {'id': 'psg1', 'name': 'Crew'},
            ],
            'fronts': [
              {
                'id': 'psf1',
                'member_id': 'psm1',
                'started_at': '2026-01-02T10:00:00Z',
                'ended_at': '2026-01-02T11:00:00Z',
                'comment': 'Fronting',
              },
            ],
            'journal_entries': [
              {'id': 'j1', 'title': 'Day', 'content': 'Went okay.'},
            ],
            'chat_channels': [
              {
                'name': 'Main',
                'messages': [
                  {'id': 'c1', 'member_id': 'psm1', 'content': 'hi'},
                ],
              },
            ],
          }),
        ),
      );
    final bytes = ZipEncoder().encodeBytes(zip);

    final payload = decodeImportFileBytes(
      fileName: 'pluralspace-export.zip',
      bytes: bytes,
    );
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.pluralSpace,
      fileName: payload.fileName,
      text: payload.text,
      importedAt: DateTime.utc(2026),
    );

    expect(
      payload.warnings,
      contains('Read data.json from PluralSpace zip export.'),
    );
    expect(archive.counts['members'], 1);
    expect(archive.counts['groups'], 1);
    expect(archive.counts['fronts'], 1);
    expect(archive.counts['front_members'], 1);
    expect(archive.counts['notes'], 1);
    expect(archive.counts['messages'], 1);
    expect(archive.archiveJson, contains('"name": "PluralSpace System"'));
    expect(archive.archiveJson, contains('Main\\nhi'));
  });

  test('normalizes decrypted Prism JSON shapes', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.prism,
      fileName: 'prism.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "systemSettings": [{"systemName": "Prism System"}],
  "headmates": [
    {"id": "h1", "name": "Sage", "notes": "Likes tea", "pluralkitId": "abcde"}
  ],
  "memberGroups": [
    {"id": "mg1", "name": "Inner"}
  ],
  "frontSessions": [
    {"id": "fs1", "headmateId": "h1", "startedAt": "2026-01-03T09:00:00Z"}
  ],
  "memberBoardPosts": [
    {"id": "mb1", "targetMemberId": "h1", "content": "wall note"}
  ]
}
''',
    );

    expect(archive.counts['members'], 1);
    expect(archive.counts['groups'], 1);
    expect(archive.counts['fronts'], 1);
    expect(archive.counts['front_members'], 1);
    expect(archive.counts['messages'], 1);
    expect(archive.archiveJson, contains('"name": "Prism System"'));
    expect(archive.archiveJson, contains('"pluralkit_id": "abcde"'));
  });
}
