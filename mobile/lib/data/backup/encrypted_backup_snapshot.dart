import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../security/haven_crypto.dart';

const encryptedBackupFormat = 'pluris_haven.encrypted_backup_snapshot';
const encryptedBackupVersion = 1;
const encryptedBackupCiphertextPrefix = 'ph1:';
const defaultEncryptedBackupChunkSize = 256 * 1024;
const minEncryptedBackupChunkSize = 1024;
const maxEncryptedBackupChunkSize = 4 * 1024 * 1024;
const maxEncryptedBackupChunkCount = 1024;
const maxEncryptedBackupPlainBytes = 100 * 1024 * 1024;
const maxEncryptedBackupCiphertextLength = 8 * 1024 * 1024;

final _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');

/// A client-encrypted, immutable snapshot suitable for uploading as opaque
/// chunks to a backup object store.
///
/// The server must not need this class, the device master key, or the archive
/// plaintext. Each chunk is independently authenticated so interrupted or
/// resumable uploads can be checked without trusting server metadata.
class EncryptedBackupSnapshot {
  EncryptedBackupSnapshot({
    required this.snapshotId,
    required this.createdAt,
    required this.chunkSize,
    required this.chunks,
  });

  final String snapshotId;
  final DateTime createdAt;
  final int chunkSize;
  final List<EncryptedBackupChunk> chunks;

  static Future<EncryptedBackupSnapshot> create({
    required String snapshotId,
    required String archiveJson,
    required HavenCrypto crypto,
    DateTime? createdAt,
    int chunkSize = defaultEncryptedBackupChunkSize,
  }) async {
    _validateSnapshotId(snapshotId);
    if (chunkSize < minEncryptedBackupChunkSize ||
        chunkSize > maxEncryptedBackupChunkSize) {
      throw ArgumentError.value(
        chunkSize,
        'chunkSize',
        'must be between $minEncryptedBackupChunkSize and '
            '$maxEncryptedBackupChunkSize bytes',
      );
    }

    final plainBytes = utf8.encode(archiveJson);
    if (plainBytes.isEmpty) {
      throw ArgumentError.value(
        archiveJson,
        'archiveJson',
        'must contain an archive payload',
      );
    }
    if (plainBytes.length > maxEncryptedBackupPlainBytes) {
      throw ArgumentError.value(
        archiveJson,
        'archiveJson',
        'must not exceed $maxEncryptedBackupPlainBytes bytes',
      );
    }
    final chunks = <EncryptedBackupChunk>[];
    for (var offset = 0; offset < plainBytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, plainBytes.length);
      final plainChunk = plainBytes.sublist(offset, end);
      final encodedPlainChunk = base64Url.encode(plainChunk);
      final ciphertext = await crypto.encrypt(encodedPlainChunk);
      if (ciphertext == null) {
        throw StateError('Backup chunk encryption returned no ciphertext.');
      }
      final storedCiphertext = '$encryptedBackupCiphertextPrefix$ciphertext';
      chunks.add(
        EncryptedBackupChunk(
          index: chunks.length,
          ciphertext: storedCiphertext,
          sha256: await _sha256(utf8.encode(storedCiphertext)),
        ),
      );
    }

    return EncryptedBackupSnapshot(
      snapshotId: snapshotId,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
      chunkSize: chunkSize,
      chunks: List.unmodifiable(chunks),
    );
  }

  factory EncryptedBackupSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['format'] != encryptedBackupFormat ||
        json['version'] != encryptedBackupVersion) {
      throw const FormatException('Unsupported encrypted backup snapshot.');
    }
    final snapshotId = json['snapshot_id'];
    final createdAt = json['created_at'];
    final chunkSize = json['chunk_size'];
    final chunkCount = json['chunk_count'];
    final rawChunks = json['chunks'];
    if (snapshotId is! String ||
        createdAt is! String ||
        chunkSize is! int ||
        chunkCount is! int ||
        rawChunks is! List) {
      throw const FormatException('Encrypted backup manifest is malformed.');
    }
    if (chunkSize < minEncryptedBackupChunkSize ||
        chunkSize > maxEncryptedBackupChunkSize) {
      throw const FormatException(
        'Encrypted backup manifest has an invalid chunk size.',
      );
    }
    if (chunkCount < 1 ||
        chunkCount > maxEncryptedBackupChunkCount ||
        chunkCount != rawChunks.length) {
      throw const FormatException(
        'Encrypted backup manifest has missing chunks.',
      );
    }
    _validateSnapshotId(snapshotId);
    return EncryptedBackupSnapshot(
      snapshotId: snapshotId,
      createdAt: DateTime.parse(createdAt).toUtc(),
      chunkSize: chunkSize,
      chunks: List.unmodifiable(
        rawChunks.map((chunk) {
          if (chunk is! Map<String, dynamic>) {
            throw const FormatException('Encrypted backup chunk is malformed.');
          }
          return EncryptedBackupChunk.fromJson(chunk);
        }),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'format': encryptedBackupFormat,
    'version': encryptedBackupVersion,
    'snapshot_id': snapshotId,
    'created_at': createdAt.toIso8601String(),
    'chunk_size': chunkSize,
    'chunk_count': chunks.length,
    'chunks': [for (final chunk in chunks) chunk.toJson()],
  };

  /// Verifies chunk hashes, decrypts in index order, and returns the archive.
  Future<String> restoreArchiveJson(HavenCrypto crypto) async {
    if (chunkSize < minEncryptedBackupChunkSize ||
        chunkSize > maxEncryptedBackupChunkSize ||
        chunks.length > maxEncryptedBackupChunkCount) {
      throw const FormatException('Encrypted backup snapshot exceeds limits.');
    }
    final ordered = [...chunks]..sort((a, b) => a.index.compareTo(b.index));
    if (ordered.isEmpty) {
      throw const FormatException('Encrypted backup snapshot has no chunks.');
    }
    final plainBytes = <int>[];
    for (var position = 0; position < ordered.length; position++) {
      final chunk = ordered[position];
      if (chunk.index != position) {
        throw const FormatException('Encrypted backup chunks are incomplete.');
      }
      _validateEncryptedBackupChunk(chunk);
      final actualHash = await _sha256(utf8.encode(chunk.ciphertext));
      if (actualHash != chunk.sha256) {
        throw const FormatException(
          'Encrypted backup chunk failed integrity check.',
        );
      }
      if (!chunk.ciphertext.startsWith(encryptedBackupCiphertextPrefix)) {
        throw const FormatException('Unsupported encrypted backup chunk.');
      }
      String? encodedPlainChunk;
      try {
        encodedPlainChunk = await crypto.decrypt(
          chunk.ciphertext.substring(encryptedBackupCiphertextPrefix.length),
        );
      } on Object {
        throw const FormatException(
          'Encrypted backup chunk could not be authenticated.',
        );
      }
      if (encodedPlainChunk == null) {
        throw const FormatException('Encrypted backup chunk has no content.');
      }
      late final List<int> plainChunk;
      try {
        plainChunk = base64Url.decode(encodedPlainChunk);
      } on FormatException {
        throw const FormatException('Encrypted backup chunk is not valid.');
      }
      if (plainChunk.isEmpty || plainChunk.length > chunkSize) {
        throw const FormatException(
          'Encrypted backup chunk exceeds its declared size.',
        );
      }
      if (plainBytes.length >
          maxEncryptedBackupPlainBytes - plainChunk.length) {
        throw const FormatException(
          'Encrypted backup snapshot exceeds its size limit.',
        );
      }
      plainBytes.addAll(plainChunk);
    }
    return utf8.decode(plainBytes);
  }
}

class EncryptedBackupChunk {
  const EncryptedBackupChunk({
    required this.index,
    required this.ciphertext,
    required this.sha256,
  });

  final int index;
  final String ciphertext;
  final String sha256;

  factory EncryptedBackupChunk.fromJson(Map<String, dynamic> json) {
    final index = json['index'];
    final ciphertext = json['ciphertext'];
    final sha256 = json['sha256'];
    if (index is! int || ciphertext is! String || sha256 is! String) {
      throw const FormatException('Encrypted backup chunk is malformed.');
    }
    final chunk = EncryptedBackupChunk(
      index: index,
      ciphertext: ciphertext,
      sha256: sha256,
    );
    _validateEncryptedBackupChunk(chunk);
    return chunk;
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'ciphertext': ciphertext,
    'sha256': sha256,
  };
}

Future<String> _sha256(List<int> bytes) async {
  final digest = await Sha256().hash(bytes);
  return digest.bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

void _validateSnapshotId(String snapshotId) {
  if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(snapshotId)) {
    throw ArgumentError.value(
      snapshotId,
      'snapshotId',
      'must contain only letters, numbers, underscore, or hyphen',
    );
  }
}

void _validateEncryptedBackupChunk(EncryptedBackupChunk chunk) {
  if (chunk.index < 0 || chunk.index >= maxEncryptedBackupChunkCount) {
    throw const FormatException('Encrypted backup chunk index is invalid.');
  }
  if (chunk.ciphertext.length > maxEncryptedBackupCiphertextLength ||
      !chunk.ciphertext.startsWith(encryptedBackupCiphertextPrefix)) {
    throw const FormatException(
      'Encrypted backup chunk ciphertext is invalid.',
    );
  }
  if (!_sha256Pattern.hasMatch(chunk.sha256)) {
    throw const FormatException('Encrypted backup chunk hash is invalid.');
  }
}
