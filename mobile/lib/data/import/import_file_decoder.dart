import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class DecodedImportFile {
  const DecodedImportFile({
    required this.displayName,
    required this.text,
    required this.detail,
    this.avatarAssets = const [],
  });

  final String displayName;
  final String text;
  final String detail;
  final List<ImportAvatarAsset> avatarAssets;
}

class ImportAvatarAsset {
  const ImportAvatarAsset({
    required this.id,
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  final String id;
  final String name;
  final Uint8List bytes;
  final String? mimeType;
}

const _maxImportBytes = 100 * 1024 * 1024;
const _maxZipEntries = 10_000;
const _maxZipEntryBytes = 50 * 1024 * 1024;
const _maxZipExpandedBytes = 100 * 1024 * 1024;

DecodedImportFile? decodeImportFileBytes({
  required String fileName,
  required Uint8List? bytes,
}) {
  if (bytes == null || bytes.isEmpty) {
    return null;
  }

  if (bytes.length > _maxImportBytes) {
    return null;
  }

  if (_looksLikeZip(fileName, bytes)) {
    try {
      return _decodeZipImport(fileName: fileName, bytes: bytes);
    } on Object {
      return null;
    }
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
  final avatarAssets = <ImportAvatarAsset>[];
  var expandedBytes = 0;

  for (var entryIndex = 0; entryIndex < archive.length; entryIndex++) {
    if (entryIndex >= _maxZipEntries) {
      return null;
    }
    final entry = archive[entryIndex];
    final name = entry.name;
    final lowerName = name.toLowerCase();
    if (!entry.isFile) {
      continue;
    }

    final isAvatar = _looksLikeAvatarAsset(lowerName, zipFileName: fileName);
    final isJson = lowerName.endsWith('.json');
    if (!isAvatar && !isJson) {
      continue;
    }
    if (entry.size > _maxZipEntryBytes ||
        expandedBytes > _maxZipExpandedBytes - entry.size) {
      return null;
    }
    expandedBytes += entry.size;

    final fileBytes = entry.readBytes();
    if (fileBytes == null || fileBytes.isEmpty) {
      continue;
    }

    if (isAvatar) {
      avatarAssets.add(
        ImportAvatarAsset(
          id: _avatarAssetId(name),
          name: name,
          bytes: Uint8List.fromList(fileBytes),
          mimeType: _mimeTypeForName(lowerName),
        ),
      );
      continue;
    }

    if (!lowerName.endsWith('.json')) {
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
    if (avatarAssets.isEmpty) {
      return null;
    }
    return DecodedImportFile(
      displayName: fileName,
      text: '{}',
      detail: 'Read ${avatarAssets.length} avatars from $fileName.',
      avatarAssets: avatarAssets,
    );
  }

  return DecodedImportFile(
    displayName: '$fileName / ${selected.name}',
    text: selected.text,
    detail: avatarAssets.isEmpty
        ? 'Read ${selected.name} from $fileName.'
        : 'Read ${selected.name} and ${avatarAssets.length} avatars from $fileName.',
    avatarAssets: avatarAssets,
  );
}

bool _looksLikeAvatarAsset(String lowerName, {required String zipFileName}) {
  final lowerZipName = zipFileName.toLowerCase();
  if (!lowerName.contains('avatar') && !lowerZipName.contains('avatar')) {
    return false;
  }
  return lowerName.endsWith('.png') ||
      lowerName.endsWith('.jpg') ||
      lowerName.endsWith('.jpeg') ||
      lowerName.endsWith('.webp') ||
      lowerName.endsWith('.gif');
}

String _avatarAssetId(String name) {
  final fileName = name.split('/').last;
  final dot = fileName.lastIndexOf('.');
  return dot <= 0 ? fileName : fileName.substring(0, dot);
}

String? _mimeTypeForName(String lowerName) {
  if (lowerName.endsWith('.png')) {
    return 'image/png';
  }
  if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lowerName.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lowerName.endsWith('.gif')) {
    return 'image/gif';
  }
  return null;
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
