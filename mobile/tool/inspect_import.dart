import 'dart:io';

import 'package:pluris_haven/data/import/import_file_decoder.dart';
import 'package:pluris_haven/data/import/import_plan.dart';
import 'package:pluris_haven/data/import/import_preview.dart';
import 'package:pluris_haven/data/import/import_sources.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    stderr.writeln(
      'Usage: dart run tool/inspect_import.dart <export.json|backup.zip>',
    );
    stderr.writeln(
      'Prints detected import source, record counts, and warning count only.',
    );
    exit(args.isEmpty ? 64 : 0);
  }

  final file = File(args.first);
  if (!await file.exists()) {
    stderr.writeln('Import file not found: ${args.first}');
    exit(66);
  }

  final bytes = await file.readAsBytes();
  late final DecodedImportFile decoded;
  try {
    decoded = await decodeImportFileBytes(
      fileName: file.uri.pathSegments.last,
      bytes: bytes,
    );
  } on FormatException catch (error) {
    stderr.writeln('Could not read import JSON from ${args.first}');
    stderr.writeln(error.message);
    exit(65);
  }

  final guess = guessImportSourceFromFile(
    fileName: decoded.displayName,
    textPreview: decoded.text,
  );
  final source = guess.source ?? ImportSource.simplyPlural;
  final preview = previewImportText(
    fileName: decoded.displayName,
    text: decoded.text,
    selectedSource: source,
    avatarAssets: decoded.avatarAssets,
  );

  stdout.writeln('file: ${decoded.displayName}');
  stdout.writeln('source: ${source.label}');
  stdout.writeln('detected: ${guess.reason}');
  stdout.writeln('can_apply: ${preview.canApply}');
  stdout.writeln('warnings: ${preview.warningsAndErrors.length}');
  stdout.writeln('counts:');
  for (final entry in preview.counts.entries) {
    if (entry.value > 0) {
      stdout.writeln('  ${entry.key}: ${entry.value}');
    }
  }
}
