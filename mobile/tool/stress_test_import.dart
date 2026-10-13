import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:pluris_haven/data/import/import_archive_mapper.dart';
import 'package:pluris_haven/data/import/import_sources.dart';

String _randText(Random random, int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ';
  return List.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}

String _generatePayload(int memberCount, Random random) {
  final frontCount = memberCount * 3;
  final messageCount = memberCount * 2;

  final members = List.generate(memberCount, (i) {
    return {
      'id': 'm-$i',
      'name': 'Member $i ${_randText(random, 20)}',
      'pronouns': 'they/them',
      'desc': _randText(random, 300),
      'info': {'field1': _randText(random, 50)},
    };
  });

  final groups = List.generate(max(1, memberCount ~/ 50), (i) {
    return {'id': 'g-$i', 'name': 'Group $i'};
  });

  final frontHistory = List.generate(frontCount, (i) {
    final start = 1700000000000 + i * 60000;
    return {
      'id': 'f-$i',
      'member': 'm-${i % memberCount}',
      'startTime': start,
      'endTime': start + 3000000,
    };
  });

  final messages = List.generate(messageCount, (i) {
    return {
      'id': 'msg-$i',
      'message': _randText(random, 400),
      'writer': 'm-${i % memberCount}',
      'writtenAt': 1700000000000 + i * 1000,
    };
  });

  final payload = {
    'system': {'name': 'Stress Test System ${_randText(random, 30)}'},
    'members': members,
    'groups': groups,
    'frontHistory': frontHistory,
    'messages': messages,
    'customFields': [
      {'id': 'field1', 'name': 'Bio', 'type': 'text'},
    ],
  };
  return jsonEncode(payload);
}

void main(List<String> args) {
  final sizes = args.isEmpty
      ? [1000, 5000, 20000, 50000, 100000]
      : args.map(int.parse).toList();
  final random = Random(42);

  for (final size in sizes) {
    stdout.write('members=$size: generating... ');
    final generateStart = DateTime.now();
    final text = _generatePayload(size, random);
    final generateMs = DateTime.now().difference(generateStart).inMilliseconds;
    stdout.write(
      '${(text.length / 1024 / 1024).toStringAsFixed(1)}MB in ${generateMs}ms; normalizing... ',
    );

    final normalizeStart = DateTime.now();
    NormalizedImportArchive normalized;
    try {
      normalized = normalizeImportTextToLocalArchive(
        source: ImportSource.simplyPlural,
        fileName: 'stress-$size.json',
        text: text,
        importedAt: DateTime.utc(2026),
      );
    } catch (error, stack) {
      final normalizeMs = DateTime.now()
          .difference(normalizeStart)
          .inMilliseconds;
      stdout.writeln('FAILED after ${normalizeMs}ms: $error');
      stdout.writeln(stack);
      continue;
    }
    final normalizeMs = DateTime.now()
        .difference(normalizeStart)
        .inMilliseconds;
    final rssMb = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(0);
    stdout.writeln(
      'done in ${normalizeMs}ms; members=${normalized.counts['members']} '
      'fronts=${normalized.counts['fronts']} messages=${normalized.counts['messages']} '
      'archiveJsonMB=${(normalized.archiveJson.length / 1024 / 1024).toStringAsFixed(1)} '
      'processRssMB=$rssMb',
    );
  }
}
