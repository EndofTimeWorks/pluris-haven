import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class DecodedImportFile {
  const DecodedImportFile({
    required this.displayName,
    required this.text,
    this.avatarAssets = const [],
  });

  final String displayName;
  final String text;
  final List<ImportAvatarAsset> avatarAssets;
}

enum ImportFileDecodeFailure {
  empty,
  tooLarge,
  invalidUtf8,
  invalidZip,
  tooManyZipEntries,
  zipExpansionTooLarge,
  unsupportedZip,
}

class ImportFileDecodeException implements Exception {
  const ImportFileDecodeException(this.failure);

  final ImportFileDecodeFailure failure;
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

const _maxImportBytes = 32 * 1024 * 1024;
const _maxZipEntries = 10_000;
const _maxZipEntryBytes = 20 * 1024 * 1024;
const _maxZipExpandedBytes = 50 * 1024 * 1024;

Future<DecodedImportFile> decodeImportFileBytes({
  required String fileName,
  required Uint8List? bytes,
  int maximumBytes = _maxImportBytes,
}) async {
  if (bytes == null || bytes.isEmpty) {
    throw const ImportFileDecodeException(ImportFileDecodeFailure.empty);
  }
  if (bytes.length > maximumBytes) {
    throw const ImportFileDecodeException(ImportFileDecodeFailure.tooLarge);
  }
  final transferable = TransferableTypedData.fromList([bytes]);
  try {
    return await Isolate.run(
      () => _decodeImportFileBytes(
        fileName: fileName,
        bytes: transferable.materialize().asUint8List(),
      ),
    );
  } on ImportFileDecodeException {
    rethrow;
  } on ArchiveException {
    throw const ImportFileDecodeException(ImportFileDecodeFailure.invalidZip);
  } on FormatException {
    throw const ImportFileDecodeException(ImportFileDecodeFailure.invalidUtf8);
  }
}

DecodedImportFile _decodeImportFileBytes({
  required String fileName,
  required Uint8List bytes,
}) {
  if (_looksLikeZip(fileName, bytes)) {
    return _decodeZipImport(fileName: fileName, bytes: bytes);
  }

  return DecodedImportFile(
    displayName: fileName,
    text: utf8.decode(bytes, allowMalformed: false),
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

DecodedImportFile _decodeZipImport({
  required String fileName,
  required Uint8List bytes,
}) {
  var declaredEntryCount = 0;
  var declaredExpandedBytes = 0;
  final archive = ZipDecoder().decodeBytes(
    bytes,
    verify: true,
    callback: (entry) {
      declaredEntryCount += 1;
      if (declaredEntryCount > _maxZipEntries) {
        throw const ImportFileDecodeException(
          ImportFileDecodeFailure.tooManyZipEntries,
        );
      }
      if (!entry.isFile) return;
      if (entry.size < 0 ||
          entry.size > _maxZipEntryBytes ||
          declaredExpandedBytes > _maxZipExpandedBytes - entry.size) {
        throw const ImportFileDecodeException(
          ImportFileDecodeFailure.zipExpansionTooLarge,
        );
      }
      declaredExpandedBytes += entry.size;
    },
  );
  _ZipJsonCandidate? best;
  final avatarAssets = <ImportAvatarAsset>[];
  var expandedBytes = 0;

  for (var entryIndex = 0; entryIndex < archive.length; entryIndex++) {
    if (entryIndex >= _maxZipEntries) {
      throw const ImportFileDecodeException(
        ImportFileDecodeFailure.tooManyZipEntries,
      );
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
      throw const ImportFileDecodeException(
        ImportFileDecodeFailure.zipExpansionTooLarge,
      );
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

    final text = utf8.decode(fileBytes, allowMalformed: false);
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
      throw const ImportFileDecodeException(
        ImportFileDecodeFailure.unsupportedZip,
      );
    }
    return DecodedImportFile(
      displayName: fileName,
      text: '{}',
      avatarAssets: avatarAssets,
    );
  }

  return DecodedImportFile(
    displayName: '$fileName / ${selected.name}',
    text: selected.text,
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
