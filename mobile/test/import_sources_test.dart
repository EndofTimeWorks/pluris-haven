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
  test('normalizes and previews imports on background isolates', () async {
    const text = '{"members":[{"id":"m1","name":"Iris"}]}';
    final normalized = await normalizeImportTextToLocalArchiveInBackground(
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
      text: text,
      importedAt: DateTime.utc(2026),
    );
    final preview = await previewImportTextInBackground(
      fileName: 'sp.json',
      text: text,
      selectedSource: ImportSource.simplyPlural,
    );

    expect(normalized.counts['members'], 1);
    expect(preview.counts['members'], 1);
    expect(preview.canApply, isTrue);
  });

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
    expect(ImportSource.simplyPlural.status, ImporterStatus.ready);
    expect(ImportSource.pluralKitFile.status, ImporterStatus.ready);
    expect(ImportSource.tupperbox.status, ImporterStatus.ready);
    expect(ImportSource.pluralSpace.status, ImporterStatus.ready);
    expect(ImportSource.prism.status, ImporterStatus.planned);
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
    expect(
      importPlanFor(ImportSource.simplyPlural).privacyNotes,
      contains(
        'Avatar ZIPs stay offline. Remote avatar URLs may be fetched during import so they can be stored locally.',
      ),
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

  test('extracts the import JSON from a zipped backup', () async {
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
    final decoded = await decodeImportFileBytes(
      fileName: 'Simply Plural Backup.zip',
      bytes: bytes,
    );

    expect(decoded.displayName, contains('export.json'));
    expect(decoded.text, contains('"Iris"'));
    expect(decoded.avatarAssets, hasLength(1));
    expect(decoded.avatarAssets.single.id, 'avatar-1');
    expect(decoded.avatarAssets.single.mimeType, 'image/png');
  });

  test('extracts avatar-only Simply Plural backup zips', () async {
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          '7f066fa379e74fc784007375037c1154a3a3946f76ef6b401c9b9371a4a85a93.png',
          4,
          [1, 2, 3, 4],
        ),
      );

    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final decoded = await decodeImportFileBytes(
      fileName: 'Avatars_system.zip',
      bytes: bytes,
    );

    expect(decoded.text, '{}');
    expect(decoded.avatarAssets, hasLength(1));
    expect(
      decoded.avatarAssets.single.id,
      '7f066fa379e74fc784007375037c1154a3a3946f76ef6b401c9b9371a4a85a93',
    );
    expect(decoded.avatarAssets.single.mimeType, 'image/png');
  });

  test('reports an empty malformed ZIP as unsupported', () async {
    await expectLater(
      decodeImportFileBytes(
        fileName: 'broken.zip',
        bytes: Uint8List.fromList([0x50, 0x4b, 0x03, 0x04, 0x00]),
      ),
      throwsA(
        isA<ImportFileDecodeException>().having(
          (error) => error.failure,
          'failure',
          ImportFileDecodeFailure.unsupportedZip,
        ),
      ),
    );
  });

  test('rejects ZIP entries whose declared expansion is too large', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('export.json', 50 * 1024 * 1024 + 1, [0x7b, 0x7d]));

    await expectLater(
      decodeImportFileBytes(
        fileName: 'oversized.zip',
        bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
      ),
      throwsA(
        isA<ImportFileDecodeException>().having(
          (error) => error.failure,
          'failure',
          ImportFileDecodeFailure.zipExpansionTooLarge,
        ),
      ),
    );
  });

  test('preflights expansion for unsupported ZIP entries', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('unused.bin', 50 * 1024 * 1024 + 1, const [0x00]))
      ..addFile(ArchiveFile.string('export.json', '{"members":[]}'));

    await expectLater(
      decodeImportFileBytes(
        fileName: 'oversized-unused-entry.zip',
        bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
      ),
      throwsA(
        isA<ImportFileDecodeException>().having(
          (error) => error.failure,
          'failure',
          ImportFileDecodeFailure.zipExpansionTooLarge,
        ),
      ),
    );
  });

  test('stops ZIP parsing at the entry-count limit', () async {
    final archive = Archive();
    for (var index = 0; index <= 10_000; index++) {
      archive.addFile(ArchiveFile.string('unused/$index.txt', ''));
    }

    await expectLater(
      decodeImportFileBytes(
        fileName: 'too-many-entries.zip',
        bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
      ),
      throwsA(
        isA<ImportFileDecodeException>().having(
          (error) => error.failure,
          'failure',
          ImportFileDecodeFailure.tooManyZipEntries,
        ),
      ),
    );
  });

  test('rejects malformed UTF-8 instead of replacing private text', () async {
    await expectLater(
      decodeImportFileBytes(
        fileName: 'invalid.json',
        bytes: Uint8List.fromList([0x7b, 0x22, 0xff, 0x22, 0x7d]),
      ),
      throwsA(
        isA<ImportFileDecodeException>().having(
          (error) => error.failure,
          'failure',
          ImportFileDecodeFailure.invalidUtf8,
        ),
      ),
    );
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

  test('does not treat raw-only payload preservation as applyable', () {
    final preview = previewImportText(
      fileName: 'unknown.json',
      text: '{"securityLogs":[{"id":"log1"}]}',
      selectedSource: ImportSource.simplyPlural,
    );

    expect(preview.canApply, isFalse);
    expect(preview.counts['raw_payloads'], 1);
    expect(
      preview.warningsAndErrors.map((event) => event.message),
      contains('No importable records were recognized.'),
    );
    expect(
      preview.warningsAndErrors.map((event) => event.message),
      contains(
        'Preserved 1 original source collection as raw payloads for export/debug: securityLogs. Mapped records still import normally; raw copies do not create notes, messages, or members.',
      ),
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

  test('keeps distinct non-ASCII source member IDs distinct', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'unicode-ids.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {"id": "猫", "name": "Mochi"},
    {"id": "犬", "name": "Kuma"}
  ]
}
''',
    );
    final decoded = jsonDecode(archive.archiveJson) as Map<String, Object?>;
    final members = decoded['members'] as List<Object?>;
    final memberIds = members
        .cast<Map<String, Object?>>()
        .map((member) => member['id'])
        .toSet();

    expect(archive.counts['members'], 2);
    expect(memberIds, hasLength(2));
    expect(
      memberIds.any((id) => id != 'simplyplural_file-member-unknown'),
      isTrue,
    );
  });

  test('keeps same-name records that have no source IDs', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'same-name-no-ids.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {"name": "Alex", "description": "First member"},
    {"name": "Alex", "description": "Second member"}
  ],
  "groups": [
    {"name": "Shared", "description": "First group"},
    {"name": "Shared", "description": "Second group"}
  ],
  "customFields": [
    {"name": "Role", "type": "text", "description": "First field"},
    {"name": "Role", "type": "text", "description": "Second field"}
  ],
  "customFronts": [
    {"name": "Blurry", "description": "First front"},
    {"name": "Blurry", "description": "Second front"}
  ]
}
''',
    );
    final decoded = jsonDecode(archive.archiveJson) as Map<String, Object?>;

    List<Map<String, Object?>> records(String key) =>
        (decoded[key] as List<Object?>).cast<Map<String, Object?>>();

    for (final key in const [
      'members',
      'groups',
      'custom_fields',
      'named_fronts',
    ]) {
      final values = records(key);
      expect(values, hasLength(2), reason: key);
      expect(values.map((value) => value['id']).toSet(), hasLength(2));
    }
    expect(
      records('members').map((member) => member['description']),
      containsAll(['First member', 'Second member']),
    );
    expect(
      records('groups').map((group) => group['description']),
      containsAll(['First group', 'Second group']),
    );
    expect(
      records('named_fronts').map((front) => front['description']),
      containsAll(['First front', 'Second front']),
    );
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

  test('normalizes Simply Plural privacy buckets and member assignments', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-privacy.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "privacyBuckets": [
    {"_id": "b1", "name": "Trusted", "desc": "Close people", "color": "12ab34"}
  ],
  "members": [
    {"_id": "m1", "name": "Iris", "buckets": ["b1"]}
  ]
}
''',
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    final buckets = (decoded['privacy_buckets'] as List)
        .cast<Map<String, dynamic>>();
    final links = (decoded['privacy_bucket_members'] as List)
        .cast<Map<String, dynamic>>();
    expect(buckets.single['name'], 'Trusted');
    expect(buckets.single['color_hex'], '#12ab34');
    expect(links.single, {
      'bucket_id': 'simplyplural_file-privacy-bucket-b1',
      'member_id': 'simplyplural_file-member-m1',
    });
  });

  test('keeps external notes and journals in separate sections', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-notes-journals.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {"_id": "m1", "name": "Iris"}
  ],
  "notes": [
    {
      "_id": "note1",
      "member": "m1",
      "title": "Member note",
      "note": "This belongs on the Notes screen.",
      "date": 1767225600000
    }
  ],
  "journals": [
    {
      "_id": "journal1",
      "member": "m1",
      "title": "System journal",
      "body": "This belongs in Journals.",
      "visibility": "private",
      "createdAt": 1767229200000
    }
  ]
}
''',
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    final notes = (decoded['notes'] as List).cast<Map<String, dynamic>>();
    final journals = (decoded['journals'] as List).cast<Map<String, dynamic>>();

    expect(archive.counts['notes'], 1);
    expect(archive.counts['journals'], 1);
    expect(notes.single['id'], 'simplyplural_file-note-note1');
    expect(notes.single['member_id'], 'simplyplural_file-member-m1');
    expect(notes.single['title'], 'Member note');
    expect(notes.single['body'], 'This belongs on the Notes screen.');
    expect(journals.single['id'], 'simplyplural_file-journal-journal1');
    expect(journals.single['member_id'], 'simplyplural_file-member-m1');
    expect(journals.single['title'], 'System journal');
    expect(journals.single['body'], 'This belongs in Journals.');
    expect(journals.single['visibility'], 'private');
  });

  test('rewrites Simply Plural member placeholders in imported text', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-mentions.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {
      "_id": "m1",
      "name": "Iris",
      "desc": "Usually checks in with <###@m2###>."
    },
    {
      "_id": "m2",
      "name": "River",
      "info": {"field1": "Ask <###@m1###> first."}
    }
  ],
  "customFields": [
    {"_id": "field1", "name": "Contact"}
  ],
  "notes": [
    {
      "_id": "note1",
      "member": "m1",
      "title": "Plan",
      "note": "Loop in <###@m2###>."
    }
  ],
  "boardMessages": [
    {
      "_id": "board1",
      "title": "Heads up",
      "message": "For <###@m1###>."
    }
  ],
  "frontHistory": [
    {
      "_id": "front1",
      "member": "m1",
      "custom": false,
      "customStatus": "<###@m2###> nearby",
      "startTime": 1767225600000
    }
  ],
  "comments": [
    {
      "_id": "comment1",
      "collection": "frontHistory",
      "documentId": "front1",
      "text": "Checked with <###@m1###>."
    }
  ]
}
''',
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    final members = (decoded['members'] as List).cast<Map<String, dynamic>>();
    final customFieldValues = (decoded['custom_field_values'] as List)
        .cast<Map<String, dynamic>>();
    final notes = (decoded['notes'] as List).cast<Map<String, dynamic>>();
    final messages = (decoded['messages'] as List).cast<Map<String, dynamic>>();
    final fronts = (decoded['fronts'] as List).cast<Map<String, dynamic>>();

    expect(
      jsonEncode({
        'members': members,
        'custom_field_values': customFieldValues,
        'notes': notes,
        'messages': messages,
        'fronts': fronts,
      }),
      isNot(contains('<###@')),
    );
    expect(members.first['description'], 'Usually checks in with @River.');
    expect(customFieldValues.single['value'], 'Ask @Iris first.');
    expect(notes.single['body'], 'Loop in @River.');
    expect(messages.single['body'], contains('For @Iris.'));
    expect(fronts.single['status_note'], '@River nearby\nChecked with @Iris.');
  });

  test('normalizes Simply Plural custom field values by source type', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-field-types.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {
      "_id": "m1",
      "name": "Iris",
      "info": {
        "colorField": "FF3366",
        "dateField": 1767225600000
      }
    }
  ],
  "customFields": [
    {"_id": "colorField", "name": "Aura color", "type": 1},
    {"_id": "dateField", "name": "Known since", "type": 6}
  ]
}
''',
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    final fields = (decoded['custom_fields'] as List)
        .cast<Map<String, dynamic>>();
    final values = (decoded['custom_field_values'] as List)
        .cast<Map<String, dynamic>>();
    final valuesByField = {
      for (final value in values) value['field_id'] as String: value['value'],
    };

    expect(
      fields.singleWhere(
        (field) => field['name'] == 'Aura color',
      )['field_type'],
      'text',
    );
    expect(
      fields.singleWhere(
        (field) => field['name'] == 'Known since',
      )['field_type'],
      'date',
    );
    expect(
      valuesByField['simplyplural_file-custom-field-colorfield'],
      '#ff3366',
    );
    expect(
      valuesByField['simplyplural_file-custom-field-datefield'],
      '2026-01-01T00:00:00.000Z',
    );
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

  test('does not create a self-parenting imported group', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'self-parent-group.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "groups": [
    {"id": "same-group", "name": "Loop", "parentId": "same-group"}
  ]
}
''',
    );
    final decoded = jsonDecode(archive.archiveJson) as Map<String, Object?>;
    final groups = decoded['groups']! as List<Object?>;
    final group = groups.single! as Map<String, Object?>;

    expect(group['parent_group_id'], isNull);
    expect(
      archive.warnings,
      contains('Group "Loop" ignored itself as its parent.'),
    );
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
    'keeps Simply Plural front status notes separate from custom fronts',
    () {
      final archive = normalizeImportTextToLocalArchive(
        source: ImportSource.simplyPlural,
        fileName: 'sp-front-status-notes.json',
        importedAt: DateTime.utc(2026),
        text: '''
{
  "members": [{"_id": "m1", "name": "Iris"}],
  "frontStatuses": [{"_id": "cf1", "name": "Asleep"}],
  "frontHistory": [
    {
      "_id": "member-front",
      "member": "m1",
      "custom": false,
      "customStatus": "blurry",
      "startTime": 1767225600000
    },
    {
      "_id": "custom-front",
      "member": "cf1",
      "custom": true,
      "customStatus": "Asleep",
      "startTime": 1767229200000
    }
  ]
}
''',
      );

      final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
      final fronts = (decoded['fronts'] as List).cast<Map<String, dynamic>>();
      final memberFront = fronts.singleWhere(
        (front) => front['status_note'] == 'blurry',
      );
      final customFront = fronts.singleWhere(
        (front) => front['label'] == 'Asleep',
      );

      expect(memberFront['label'], isNull);
      expect(memberFront['status_note'], 'blurry');
      expect(customFront['label'], 'Asleep');
      expect(customFront['status_note'], isNull);
    },
  );

  test('imports Simply Plural front statuses without creating alters', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-front-statuses.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {"_id": "m1", "name": "Iris"}
  ],
  "frontStatuses": [
    {
      "_id": "status-safe",
      "name": "01: SAFE: Safe",
      "color": "#0299b8",
      "desc": "body feels ok",
      "lastOperationTime": 1737432000000
    }
  ],
  "frontHistory": [
    {
      "_id": "front-status-row",
      "custom": true,
      "member": "status-safe",
      "startTime": 1737432000000,
      "endTime": 1737435600000,
      "lastOperationTime": 1737435600000
    }
  ]
}
''',
    );

    expect(archive.counts['members'], 1);
    expect(archive.counts['named_fronts'], 1);
    expect(archive.counts['named_front_members'], 0);
    expect(archive.counts['fronts'], 1);
    expect(archive.counts['front_members'], 0);
    expect(archive.archiveJson, contains('"display_name": "Iris"'));
    expect(archive.archiveJson, isNot(contains('"display_name": "01: SAFE')));
    expect(archive.archiveJson, contains('"custom_label": "01: SAFE: Safe"'));
    expect(archive.archiveJson, contains('"label": "01: SAFE: Safe"'));
    expect(archive.archiveJson, contains('"color_hex": "#0299b8"'));
    expect(
      archive.archiveJson,
      contains('"updated_at": "2025-01-21T05:00:00.000Z"'),
    );
  });

  test('moves Simply Plural member-shaped custom fronts out of alters', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-member-shaped-custom-fronts.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {"_id": "m1", "name": "Iris"},
    {
      "_id": "cf-asleep",
      "name": "Asleep",
      "custom": true,
      "color": "7B61FF",
      "desc": "system state"
    }
  ],
  "frontHistory": [
    {
      "_id": "front-custom",
      "custom": true,
      "member": "cf-asleep",
      "startTime": 1767225600000
    }
  ]
}
''',
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    final members = (decoded['members'] as List).cast<Map<String, dynamic>>();
    final namedFronts = (decoded['named_fronts'] as List)
        .cast<Map<String, dynamic>>();
    final fronts = (decoded['fronts'] as List).cast<Map<String, dynamic>>();

    expect(archive.counts['members'], 1);
    expect(archive.counts['named_fronts'], 1);
    expect(archive.counts['fronts'], 1);
    expect(archive.counts['front_members'], 0);
    expect(members.single['display_name'], 'Iris');
    expect(namedFronts.single['custom_label'], 'Asleep');
    expect(namedFronts.single['description'], 'system state');
    expect(fronts.single['label'], 'Asleep');
    expect(archive.archiveJson, isNot(contains('"display_name": "Asleep"')));
  });

  test('normalizes object-shaped front member references', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-object-front-refs.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {"_id": "m1", "name": "Iris"},
    {"_id": "m2", "name": "River"}
  ],
  "frontHistory": [
    {
      "_id": "front-object",
      "custom": false,
      "member": {"_id": "m1"},
      "startTime": 1767225600000
    },
    {
      "_id": "front-list",
      "custom": false,
      "members": [{"id": "m1"}, {"memberId": "m2"}],
      "startTime": 1767229200000
    }
  ]
}
''',
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    final links = (decoded['front_members'] as List)
        .cast<Map<String, dynamic>>();

    expect(archive.counts['members'], 2);
    expect(archive.counts['fronts'], 2);
    expect(archive.counts['front_members'], 3);
    expect(
      links.map((link) => link['member_id']),
      containsAll([
        'simplyplural_file-member-m1',
        'simplyplural_file-member-m2',
      ]),
    );
  });

  test('labels Simply Plural fronts that reference deleted records', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-deleted-front-refs.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {"_id": "m1", "name": "Iris"}
  ],
  "frontStatuses": [
    {"_id": "status-safe", "name": "Safe"}
  ],
  "frontHistory": [
    {
      "_id": "member-front",
      "custom": false,
      "member": "m1",
      "startTime": 1767225600000
    },
    {
      "_id": "status-front",
      "custom": true,
      "member": "status-safe",
      "startTime": 1767229200000
    },
    {
      "_id": "deleted-status-front",
      "custom": true,
      "member": "deleted-status",
      "startTime": 1767232800000
    },
    {
      "_id": "deleted-member-front",
      "custom": false,
      "member": "deleted-member",
      "startTime": 1767236400000
    }
  ]
}
''',
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    final fronts = (decoded['fronts'] as List).cast<Map<String, dynamic>>();

    expect(archive.counts['members'], 1);
    expect(archive.counts['named_fronts'], 1);
    expect(archive.counts['fronts'], 4);
    expect(archive.counts['front_members'], 1);
    expect(fronts.map((front) => front['label']), contains('Safe'));
    expect(
      fronts.map((front) => front['label']),
      contains('Deleted custom front'),
    );
    expect(fronts.map((front) => front['label']), contains('Deleted member'));
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
      "birthday": "02-03",
      "emoji": "*",
      "privacy": "trusted",
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

      final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
      final fronts = (decoded['fronts'] as List).cast<Map<String, dynamic>>();

      expect(archive.counts['members'], 1);
      expect(archive.counts['groups'], 1);
      expect(archive.counts['group_members'], 1);
      expect(archive.counts['custom_fields'], 1);
      expect(archive.counts['custom_field_values'], 2);
      expect(archive.counts['messages'], 2);
      expect(archive.counts['reminders'], 1);
      expect(archive.counts['fronts'], 1);
      expect(archive.counts['front_members'], 1);
      expect(archive.counts['named_fronts'], 1);
      expect(archive.counts['avatar_assets'], 0);
      expect(archive.counts['raw_payloads'], 0);
      expect(
        archive.archiveJson,
        contains(
          '"avatar_url": "https://serve.apparyllis.com/avatars/system-user/avatar-1"',
        ),
      );
      expect(
        archive.archiveJson,
        contains('"folder_id": "simplyplural_file-group-g1"'),
      );
      expect(
        archive.archiveJson,
        contains('"group_id": "simplyplural_file-group-g1"'),
      );
      expect(archive.archiveJson, isNot(contains('"is_custom_front": true')));
      expect(archive.archiveJson, contains('"custom_label": "Asleep"'));
      expect(archive.archiveJson, contains('"color_hex": "#7b61ff"'));
      expect(archive.archiveJson, contains('"birthday": "02-03"'));
      expect(archive.archiveJson, contains('"emoji": "*"'));
      expect(archive.archiveJson, contains('"privacy": "trusted"'));
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
      expect(
        archive.archiveJson,
        isNot(contains('"collection": "customFields"')),
      );
      expect(
        archive.archiveJson,
        isNot(contains('"collection": "customFronts"')),
      );
      expect(
        archive.archiveJson,
        isNot(contains('"collection": "privacyBuckets"')),
      );
      expect(archive.archiveJson, contains('"body": "Board\\nCheck supplies"'));
      expect(fronts.single['status_note'], 'front note');
      expect(
        archive.archiveJson,
        isNot(contains('"body": "front note\\nSource: frontHistory"')),
      );
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

  test(
    'warns when Simply Plural preview has remote avatars without zip bytes',
    () {
      final preview = previewImportText(
        fileName: 'sp-avatar.json',
        selectedSource: ImportSource.simplyPlural,
        text: '''
{
  "users": [{"_id": "owner1", "username": "SP System"}],
  "members": [{"_id": "m1", "name": "Iris", "avatarUuid": "avatar-1"}]
}
''',
      );

      expect(preview.counts['avatar_refs'], 1);
      expect(
        preview.warningsAndErrors.map((event) => event.message),
        contains(
          'Avatar links may be downloaded during import so they can be kept locally. Attach the Simply Plural avatar ZIP to avoid remote avatar fetches.',
        ),
      );
    },
  );

  test('prefers attached Simply Plural avatar bytes over remote URLs', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [
    {
      "_id": "m1",
      "name": "Iris",
      "avatarUrl": "https://serve.apparyllis.com/avatars/owner/avatar-1",
      "avatarUuid": "avatar-1"
    }
  ]
}
''',
      avatarAssets: [
        ImportAvatarAsset(
          id: 'avatar-1',
          name: 'avatar-1.png',
          mimeType: 'image/png',
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ],
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    final members = (decoded['members'] as List).cast<Map<String, dynamic>>();
    expect(members.single['avatar_url'], 'sp-avatar:avatar-1');
    expect(jsonEncode(members.single), isNot(contains('serve.apparyllis.com')));
  });

  test('preserves unmapped Simply Plural collections as raw payloads', () {
    final text = '''
{
  "users": [{"_id": "system-user", "username": "SP System"}],
  "members": [{"_id": "m1", "name": "Iris"}],
  "securityLogs": [{"_id": "log1", "action": "login"}],
  "friends": [{"_id": "friend1", "name": "Trusted"}],
  "tokens": [{"_id": "token1", "name": "Bot"}],
  "usage": [{"_id": "usage1", "kind": "daily"}],
  "socketNotifications": [],
  "verifiedKeys": []
}
''';
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-full.json',
      importedAt: DateTime.utc(2026),
      text: text,
    );
    final preview = previewImportText(
      fileName: 'sp-full.json',
      text: text,
      selectedSource: ImportSource.simplyPlural,
    );

    expect(archive.counts['raw_payloads'], 4);
    expect(preview.canApply, isTrue);
    expect(
      preview.warningsAndErrors.map((event) => event.message),
      contains(
        'Preserved 4 original source collections as raw payloads for export/debug: securityLogs, friends, tokens, usage. Mapped records still import normally; raw copies do not create notes, messages, or members.',
      ),
    );
    expect(archive.archiveJson, contains('"collection": "securityLogs"'));
    expect(archive.archiveJson, contains('"collection": "friends"'));
    expect(archive.archiveJson, contains('"collection": "tokens"'));
    expect(archive.archiveJson, contains('"collection": "usage"'));
    expect(archive.archiveJson, isNot(contains('"collection": "users"')));
    expect(archive.archiveJson, isNot(contains('"collection": "members"')));
    expect(
      archive.archiveJson,
      isNot(contains('"collection": "verifiedKeys"')),
    );
  });

  test('warns and clamps overlong imported fields', () {
    String repeat(String value, int count) => List.filled(count, value).join();

    final longName = repeat('N', 150);
    final longText = repeat('T', 6000);
    final longJournal = repeat('J', 21000);
    final text = jsonEncode({
      'members': [
        {
          '_id': 'm1',
          'name': longName,
          'pronouns': repeat('p', 150),
          'desc': longText,
        },
      ],
      'customFields': [
        {'_id': 'field1', 'name': repeat('f', 150), 'type': 0},
      ],
      'notes': [
        {'_id': 'n1', 'title': repeat('n', 250), 'note': longText},
      ],
      'journals': [
        {'_id': 'j1', 'title': repeat('j', 250), 'body': longJournal},
      ],
      'messages': [
        {'_id': 'msg1', 'body': longText},
      ],
      'repeatedReminders': [
        {
          '_id': 'r1',
          'name': repeat('r', 200),
          'message': repeat('r', 3000),
          'schedule': 'daily ${repeat('s', 600)}',
        },
      ],
      'polls': [
        {
          '_id': 'poll1',
          'question': repeat('q', 600),
          'desc': repeat('d', 2200),
          'options': [
            for (var index = 0; index < 25; index++)
              {'_id': 'opt$index', 'name': repeat('o', 300)},
          ],
        },
      ],
      'frontHistory': [
        {
          '_id': 'front1',
          'startedAt': '2026-01-01T12:00:00Z',
          'members': ['m1'],
          'statusNote': repeat('f', 3000),
        },
      ],
    });
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-long.json',
      importedAt: DateTime.utc(2026),
      text: text,
    );
    final preview = previewImportText(
      fileName: 'sp-long.json',
      text: text,
      selectedSource: ImportSource.simplyPlural,
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, dynamic>;
    final members = (decoded['members'] as List).cast<Map<String, dynamic>>();
    final notes = (decoded['notes'] as List).cast<Map<String, dynamic>>();
    final journals = (decoded['journals'] as List).cast<Map<String, dynamic>>();
    final messages = (decoded['messages'] as List).cast<Map<String, dynamic>>();
    final reminders = (decoded['reminders'] as List)
        .cast<Map<String, dynamic>>();
    final polls = (decoded['polls'] as List).cast<Map<String, dynamic>>();
    final options = (decoded['poll_options'] as List)
        .cast<Map<String, dynamic>>();
    final fronts = (decoded['fronts'] as List).cast<Map<String, dynamic>>();

    expect(
      archive.warnings,
      contains('1 member name will be shortened to 100 characters.'),
    );
    expect(
      archive.warnings,
      contains('1 poll option list will be trimmed to 20 entries.'),
    );
    expect(
      preview.warningsAndErrors.map((event) => event.message),
      contains('1 member name will be shortened to 100 characters.'),
    );
    expect(members.single['display_name'], hasLength(100));
    expect(members.single['pronouns'], hasLength(100));
    expect(members.single['description'], hasLength(5000));
    expect(notes.single['title'], hasLength(200));
    expect(notes.single['body'], hasLength(5000));
    expect(journals.single['body'], hasLength(20000));
    expect(messages.single['body'], hasLength(5000));
    expect(reminders.single['title'], hasLength(120));
    expect(reminders.single['body'], hasLength(2000));
    expect(polls.single['question'], hasLength(500));
    expect(polls.single['description'], hasLength(2000));
    expect(options, hasLength(20));
    expect(
      options.singleWhere((option) => option['position'] == 0)['body'],
      hasLength(200),
    );
    expect(fronts.single['status_note'], hasLength(2000));
    expect(preview.canApply, isTrue);
  });

  test('normalizes Simply Plural colors and avatar UUID fallbacks', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-avatar.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "users": [{"_id": "owner1", "username": "SP System"}],
  "members": [
    {
      "_id": "m1",
      "name": "Iris",
      "color": "#ff0088ff",
      "avatarUuid": "avatar-1"
    }
  ],
  "frontStatuses": [
    {"_id": "cf1", "name": "Asleep", "color": "7B61FF", "avatarUuid": "avatar-2"}
  ]
}
''',
    );

    expect(archive.counts['avatar_refs'], 2);
    expect(archive.counts['named_fronts'], 1);
    expect(archive.archiveJson, contains('"color_hex": "#0088ff"'));
    expect(archive.archiveJson, contains('"custom_label": "Asleep"'));
    expect(archive.archiveJson, contains('"color_hex": "#7b61ff"'));
    expect(
      archive.archiveJson,
      contains('https://serve.apparyllis.com/avatars/owner1/avatar-1'),
    );
    expect(
      archive.archiveJson,
      contains('https://serve.apparyllis.com/avatars/owner1/avatar-2'),
    );
  });

  test('normalizes Simply Plural system color into app accent preference', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-system.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "users": [{"_id": "owner1", "username": "SP System", "color": "3366FF"}],
  "members": []
}
''',
    );

    expect(archive.counts['preferences'], 1);
    expect(archive.archiveJson, contains('"key": "custom_accent_hex"'));
    expect(archive.archiveJson, contains('"value": "#3366ff"'));
  });

  test('normalizes Simply Plural polls into local archive records', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp-polls.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "polls": [
    {
      "_id": "poll1",
      "question": "Dinner?",
      "description": "Pick what works.",
      "multiple": true,
      "options": [
        {"_id": "soup", "text": "Soup", "votes": 2},
        {"_id": "rice", "text": "Rice"}
      ],
      "votes": [
        {"optionId": "rice", "createdAt": 1767225600000}
      ],
      "createdAt": 1767222000000,
      "updatedAt": 1767225600000
    }
  ]
}
''',
    );

    expect(archive.counts['polls'], 1);
    expect(archive.counts['poll_options'], 2);
    expect(archive.counts['poll_votes'], 2);
    expect(archive.counts['raw_payloads'], 0);
    expect(archive.archiveJson, contains('"question": "Dinner?"'));
    expect(archive.archiveJson, contains('"kind": "multiple_choice"'));
    expect(archive.archiveJson, contains('"body": "Soup"'));
    expect(archive.archiveJson, contains('"body": "Rice"'));
    expect(archive.archiveJson, isNot(contains('"collection": "polls"')));
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

  test('normalizes PluralSpace roster and fronts', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.pluralSpace,
      fileName: 'pluralspace.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "pluralspace": true,
  "system": {"name": "River House"},
  "groups": [
    {"id": "g1", "name": "Main"},
    {"id": "g2", "name": "Subsystem", "parentId": "g1"}
  ],
  "members": [
    {"id": "m1", "name": "River", "pronouns": "they/them", "groupId": "g2", "color": "3366ff"}
  ],
  "fronts": [
    {"id": "f1", "member_ids": ["m1"], "started_at": "2026-01-01T00:00:00Z", "ended_at": "2026-01-01T01:00:00Z"}
  ],
  "notes": [
    {"id": "n1", "title": "Welcome", "body": "Imported note", "member_id": "m1"}
  ]
}
''',
    );

    expect(archive.counts['members'], 1);
    expect(archive.counts['groups'], 2);
    expect(archive.counts['group_members'], 1);
    expect(archive.counts['fronts'], 1);
    expect(archive.counts['front_members'], 1);
    expect(archive.counts['notes'], 1);
    expect(archive.archiveJson, contains('"name": "River House"'));
    expect(archive.archiveJson, contains('"display_name": "River"'));
    expect(archive.archiveJson, contains('"parent_group_id"'));
    expect(archive.archiveJson, contains('"source": "pluralspace_file"'));
  });
  test('does not treat another import source UUID as a PluralKit ID', () {
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.pluralSpace,
      fileName: 'pluralspace.json',
      importedAt: DateTime.utc(2026),
      text: '{"members":[{"uuid":"member-uuid","name":"River"}]}',
    );

    final decoded = jsonDecode(archive.archiveJson) as Map<String, Object?>;
    final members = decoded['members']! as List<Object?>;
    final member = members.single! as Map<String, Object?>;
    expect(member['source_member_id'], 'pluralspace_file-member-member-uuid');
    expect(member['pluralkit_id'], isNull);
  });
}
