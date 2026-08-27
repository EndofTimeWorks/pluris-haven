import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pluris_haven/data/import/import_archive_mapper.dart';
import 'package:pluris_haven/data/import/import_file_decoder.dart';
import 'package:pluris_haven/data/import/import_sources.dart';

const _avatarPng = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xd7,
  0x63,
  0xf8,
  0xcf,
  0xc0,
  0xf0,
  0x1f,
  0x00,
  0x05,
  0x00,
  0x01,
  0xff,
  0x89,
  0x99,
  0x3d,
  0x1d,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];

class StressImportFixture {
  const StressImportFixture({
    required this.exportJson,
    required this.avatarZip,
  });

  final String exportJson;
  final Uint8List avatarZip;
}

StressImportFixture buildStressImportFixture(int memberCount) {
  if (memberCount < 2) {
    throw ArgumentError.value(memberCount, 'memberCount', 'must be at least 2');
  }

  const colors = ['7c3aed', '10b981', 'f59e0b', 'ef4444', '3b82f6'];
  final groupCount = max(1, memberCount ~/ 20);
  final avatarCount = (memberCount / 4).ceil();
  final members = <Map<String, Object?>>[];
  final groups = <Map<String, Object?>>[];
  final frontHistory = <Map<String, Object?>>[];
  final notes = <Map<String, Object?>>[];
  final journals = <Map<String, Object?>>[];
  final messages = <Map<String, Object?>>[];

  for (var index = 0; index < groupCount; index++) {
    groups.add({
      '_id': 'group-$index',
      'name': 'Group ${index + 1}',
      'color': colors[index % colors.length],
      'members': <String>[],
    });
  }

  for (var index = 0; index < memberCount; index++) {
    final memberId = 'member-$index';
    final group = groups[index % groupCount]['members'] as List<String>;
    group.add(memberId);
    members.add({
      '_id': memberId,
      'name': 'Fixture member ${index + 1}',
      'pronouns': index.isEven ? 'they/them' : 'she/they',
      'desc':
          'Synthetic member $index. This fixture only contains generated data.',
      'folderId': 'group-${index % groupCount}',
      'color': colors[index % colors.length],
      'archived': index != 0 && index % 41 == 0,
      'buckets': ['bucket-${index % 3}'],
      'avatarUuid': index % 4 == 0 ? 'avatar-$index' : null,
      'info': {
        'role': ['host', 'protector', 'caretaker'][index % 3],
        'age': '${18 + index % 40}',
        'food': ['ramen', 'tea', 'toast'][index % 3],
        'comfort': ['high', 'medium', 'low'][index % 3],
        'out': index.isEven,
        'colour': colors[index % colors.length],
        'known': 1767225600000 + index * 1000,
        'note': 'Generated field value $index',
      },
    });

    if (index % 4 == 0) {
      notes.add({
        '_id': 'note-$index',
        'member': memberId,
        'title': 'Fixture note $index',
        'note': 'Generated note for import and encrypted local storage.',
        'date': 1767225600000 + index * 1000,
      });
    }
    if (index % 5 == 0) {
      journals.add({
        '_id': 'journal-$index',
        'member': memberId,
        'title': 'Fixture journal $index',
        'body': 'Generated journal entry for list and detail rendering.',
        'visibility': 'private',
        'createdAt': 1767225600000 + index * 1000,
      });
    }
    if (index % 3 == 0) {
      messages.add({
        '_id': 'message-$index',
        'writer': memberId,
        'body': 'Generated message $index for imported message storage.',
        'writtenAt': 1767225600000 + index * 1000,
      });
    }
  }

  for (var index = 0; index < memberCount * 3; index++) {
    final start = 1767225600000 + index * 600000;
    frontHistory.add({
      '_id': 'front-$index',
      'memberIds': [
        'member-${index % memberCount}',
        if (index % 3 == 0) 'member-${(index + 1) % memberCount}',
      ],
      'startTime': start,
      'endTime': start + 480000,
      'customStatus': 'Generated front $index',
    });
  }

  final archive = Archive();
  for (var index = 0; index < avatarCount; index++) {
    final memberIndex = index * 4;
    archive.addFile(
      ArchiveFile(
        'avatars/avatar-$memberIndex.png',
        _avatarPng.length,
        _avatarPng,
      ),
    );
  }

  return StressImportFixture(
    exportJson: const JsonEncoder.withIndent('  ').convert({
      'system': {'name': 'Pluris stress fixture'},
      'members': members,
      'groups': groups,
      'customFields': [
        {'_id': 'role', 'name': 'Role', 'type': 'text'},
        {'_id': 'age', 'name': 'Age', 'type': 'text'},
        {'_id': 'food', 'name': 'Favourite food', 'type': 'text'},
        {'_id': 'comfort', 'name': 'Comfort level', 'type': 'text'},
        {'_id': 'out', 'name': 'Out to family', 'type': 'text'},
        {'_id': 'colour', 'name': 'Colour', 'type': 'color'},
        {'_id': 'known', 'name': 'Known since', 'type': 'date'},
        {'_id': 'note', 'name': 'Fixture note', 'type': 'text'},
      ],
      'privacyBuckets': [
        {'_id': 'bucket-0', 'name': 'Private', 'color': '7c3aed'},
        {'_id': 'bucket-1', 'name': 'Friends', 'color': '10b981'},
        {'_id': 'bucket-2', 'name': 'Public', 'color': '3b82f6'},
      ],
      'frontHistory': frontHistory,
      'customFronts': [
        for (var index = 0; index < max(1, memberCount ~/ 40); index++)
          {
            '_id': 'custom-front-$index',
            'name': 'Custom front ${index + 1}',
            'color': colors[index % colors.length],
            'memberIds': ['member-${index % memberCount}'],
          },
      ],
      'notes': notes,
      'journals': journals,
      'messages': messages,
      'reminders': [
        {
          '_id': 'reminder-1',
          'name': 'Fixture reminder',
          'schedule': 'daily 20:00',
          'body': 'Generated reminder.',
        },
      ],
      'polls': [
        {
          '_id': 'poll-1',
          'question': 'Generated fixture poll',
          'options': [
            {'_id': 'poll-option-1', 'name': 'First', 'votes': 1},
            {'_id': 'poll-option-2', 'name': 'Second'},
          ],
        },
      ],
    }),
    avatarZip: ZipEncoder().encodeBytes(archive),
  );
}

Future<void> main(List<String> arguments) async {
  final options = _parseOptions(arguments);
  final outputPath = options['out'];
  final avatarPath = options['avatars'];
  if (outputPath == null || avatarPath == null) {
    stderr.writeln(
      'Usage: dart run tool/generate_stress_import_fixture.dart '
      '--out /tmp/stress.json --avatars /tmp/stress-avatars.zip '
      '[--members 250]',
    );
    exitCode = 64;
    return;
  }
  final memberCount = int.tryParse(options['members'] ?? '250');
  if (memberCount == null || memberCount < 2) {
    throw ArgumentError.value(
      options['members'],
      '--members',
      'must be at least 2',
    );
  }

  final fixture = buildStressImportFixture(memberCount);
  await File(outputPath).writeAsString(fixture.exportJson);
  await File(avatarPath).writeAsBytes(fixture.avatarZip, flush: true);

  final decodedAvatars = await decodeImportFileBytes(
    fileName: File(avatarPath).uri.pathSegments.last,
    bytes: fixture.avatarZip,
  );
  final normalized = normalizeImportTextToLocalArchive(
    source: ImportSource.simplyPlural,
    fileName: File(outputPath).uri.pathSegments.last,
    text: fixture.exportJson,
    avatarAssets: decodedAvatars.avatarAssets,
    importedAt: DateTime.utc(2026),
  );
  stdout.writeln('Wrote $memberCount generated members to $outputPath');
  stdout.writeln(
    'Wrote ${decodedAvatars.avatarAssets.length} valid avatars to $avatarPath',
  );
  stdout.writeln('Normalized counts: ${normalized.counts}');
  stdout.writeln('Warnings: ${normalized.warnings.length}');
}

Map<String, String> _parseOptions(List<String> arguments) {
  final options = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    if (!arguments[index].startsWith('--') || index + 1 == arguments.length) {
      throw ArgumentError('Expected --name value pairs.');
    }
    options[arguments[index].substring(2)] = arguments[index + 1];
  }
  return options;
}
