import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class DecodedImportFile {
  const DecodedImportFile({
    required this.displayName,
    required this.text,
    required this.detail,
  });

  final String displayName;
  final String text;
  final String detail;
}

DecodedImportFile? decodeImportFileBytes({
  required String fileName,
  required Uint8List? bytes,
}) {
  if (bytes == null || bytes.isEmpty) {
    return null;
  }

  if (_looksLikeZip(fileName, bytes)) {
    return _decodeZipImport(fileName: fileName, bytes: bytes);
  }

  return DecodedImportFile(
    displayName: fileName,
    text: utf8.decode(bytes, allowMalformed: true),
    detail: 'Read $fileName.',
  );
}

bool _looksLikeZip(String fileName, Uint8List bytes) {
  final lowerName = fileName.toLowerCase();
  return lowerName.endsWith('.zip') ||
      (bytes.length >= 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4b &&
          bytes[2] == 0x03 &&
          bytes[3] == 0x04);
}

DecodedImportFile? _decodeZipImport({
  required String fileName,
  required Uint8List bytes,
}) {
  final archive = ZipDecoder().decodeBytes(bytes, verify: true);
  _ZipJsonCandidate? best;

  for (final entry in archive) {
    final name = entry.name;
    final lowerName = name.toLowerCase();
    if (!entry.isFile || !lowerName.endsWith('.json')) {
      continue;
    }

    final fileBytes = entry.readBytes();
    if (fileBytes == null || fileBytes.isEmpty) {
      continue;
    }

    final text = utf8.decode(fileBytes, allowMalformed: true);
    final candidate = _ZipJsonCandidate(
      name: name,
      text: text,
      score: _jsonCandidateScore(name, text, fileBytes.length),
    );

    if (best == null || candidate.score > best.score) {
      best = candidate;
    }
  }

  final selected = best;
  if (selected == null) {
    return null;
  }

  return DecodedImportFile(
    displayName: '$fileName / ${selected.name}',
    text: selected.text,
    detail: 'Read ${selected.name} from $fileName.',
  );
}

int _jsonCandidateScore(String name, String text, int length) {
  final lowerName = name.toLowerCase();
  final compactText = text.toLowerCase();
  var score = 0;

  if (lowerName.contains('export')) {
    score += 30;
  }
  if (lowerName.contains('simply') || lowerName.contains('plural')) {
    score += 20;
  }
  if (compactText.contains('pluris_haven.local_archive')) {
    score += 80;
  }
  if (compactText.contains('"members"') ||
      compactText.contains('"memberslist"') ||
      compactText.contains('"fronthistory"') ||
      compactText.contains('"fronters"')) {
    score += 60;
  }
  if (compactText.contains('"groups"') || compactText.contains('"folders"')) {
    score += 20;
  }

  return score + length.clamp(0, 1000000) ~/ 1000;
}

class _ZipJsonCandidate {
  const _ZipJsonCandidate({
    required this.name,
    required this.text,
    required this.score,
  });

  final String name;
  final String text;
  final int score;
}
