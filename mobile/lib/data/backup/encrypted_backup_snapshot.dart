import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../security/haven_crypto.dart';

const encryptedBackupFormat = 'pluris_haven.encrypted_backup_snapshot';
const encryptedBackupVersion = 2;
const encryptedBackupCiphertextPrefix = 'ph2:';
const _legacyEncryptedBackupCiphertextPrefix = 'ph1:';
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
/// plaintext. Version 2 binds each authenticated chunk to its manifest and
/// position. The unkeyed chunk hash is only an early corruption check.
class EncryptedBackupSnapshot {
  EncryptedBackupSnapshot({
    this.version = encryptedBackupVersion,
    required this.snapshotId,
    required this.createdAt,
    required this.chunkSize,
    required this.chunks,
  });

  final int version;
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
    final snapshotCreatedAt = (createdAt ?? DateTime.now()).toUtc();
    final chunkCount = (plainBytes.length + chunkSize - 1) ~/ chunkSize;
    if (chunkCount > maxEncryptedBackupChunkCount) {
      throw ArgumentError.value(
        chunkCount,
        'archiveJson',
        'requires too many encrypted backup chunks',
      );
    }
    final chunks = <EncryptedBackupChunk>[];
    for (var offset = 0; offset < plainBytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, plainBytes.length);
      final plainChunk = plainBytes.sublist(offset, end);
      final index = chunks.length;
      final ciphertext = await crypto.encryptBytes(
        plainChunk,
        aad: _backupChunkAad(
          version: encryptedBackupVersion,
          snapshotId: snapshotId,
          createdAt: snapshotCreatedAt,
          chunkSize: chunkSize,
          chunkCount: chunkCount,
          index: index,
        ),
      );
      final storedCiphertext = '$encryptedBackupCiphertextPrefix$ciphertext';
      chunks.add(
        EncryptedBackupChunk(
          index: index,
          ciphertext: storedCiphertext,
          sha256: await _sha256(utf8.encode(storedCiphertext)),
        ),
      );
    }

    return EncryptedBackupSnapshot(
      version: encryptedBackupVersion,
      snapshotId: snapshotId,
      createdAt: snapshotCreatedAt,
      chunkSize: chunkSize,
      chunks: List.unmodifiable(chunks),
    );
  }

  factory EncryptedBackupSnapshot.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (json['format'] != encryptedBackupFormat ||
        (version != 1 && version != encryptedBackupVersion)) {
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
      version: version as int,
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
    'version': version,
    'snapshot_id': snapshotId,
    'created_at': createdAt.toIso8601String(),
    'chunk_size': chunkSize,
    'chunk_count': chunks.length,
    'chunks': [for (final chunk in chunks) chunk.toJson()],
  };

  /// Verifies chunk hashes, decrypts in index order, and returns the archive.
  ///
  /// Version 1 did not authenticate manifest identity or chunk position. It is
  /// rejected by default, but can still be opened explicitly for offline data
  /// recovery when the caller trusts the source of the legacy snapshot.
  Future<String> restoreArchiveJson(
    HavenCrypto crypto, {
    bool allowUnauthenticatedLegacyV1 = false,
  }) async {
    if (version != 1 && version != encryptedBackupVersion) {
      throw const FormatException('Unsupported encrypted backup snapshot.');
    }
    if (version == 1 && !allowUnauthenticatedLegacyV1) {
      throw const FormatException(
        'Legacy encrypted backups require explicit trusted-source recovery.',
      );
    }
    if (chunkSize < minEncryptedBackupChunkSize ||
        chunkSize > maxEncryptedBackupChunkSize ||
        chunks.length > maxEncryptedBackupChunkCount) {
      throw const FormatException('Encrypted backup snapshot exceeds limits.');
    }
    final ordered = [...chunks]..sort((a, b) => a.index.compareTo(b.index));
    if (ordered.isEmpty) {
      throw const FormatException('Encrypted backup snapshot has no chunks.');
    }
    final plainBytes = BytesBuilder(copy: false);
    var plainByteCount = 0;
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
      late final List<int> plainChunk;
      try {
        if (version == 1) {
          if (!chunk.ciphertext.startsWith(
            _legacyEncryptedBackupCiphertextPrefix,
          )) {
            throw const FormatException('Unsupported encrypted backup chunk.');
          }
          final encodedPlainChunk = await crypto.decrypt(
            chunk.ciphertext.substring(
              _legacyEncryptedBackupCiphertextPrefix.length,
            ),
          );
          if (encodedPlainChunk == null) {
            throw const FormatException(
              'Encrypted backup chunk has no content.',
            );
          }
          plainChunk = base64Url.decode(encodedPlainChunk);
        } else {
          if (!chunk.ciphertext.startsWith(encryptedBackupCiphertextPrefix)) {
            throw const FormatException('Unsupported encrypted backup chunk.');
          }
          plainChunk = await crypto.decryptBytes(
            chunk.ciphertext.substring(encryptedBackupCiphertextPrefix.length),
            aad: _backupChunkAad(
              version: version,
              snapshotId: snapshotId,
              createdAt: createdAt,
              chunkSize: chunkSize,
              chunkCount: chunks.length,
              index: chunk.index,
            ),
          );
        }
      } on Object {
        throw const FormatException(
          'Encrypted backup chunk could not be authenticated.',
        );
      }
      if (plainChunk.isEmpty || plainChunk.length > chunkSize) {
        throw const FormatException(
          'Encrypted backup chunk exceeds its declared size.',
        );
      }
      if (plainByteCount > maxEncryptedBackupPlainBytes - plainChunk.length) {
        throw const FormatException(
          'Encrypted backup snapshot exceeds its size limit.',
        );
      }
      plainBytes.add(plainChunk);
      plainByteCount += plainChunk.length;
    }
    return utf8.decode(plainBytes.takeBytes());
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
      (!chunk.ciphertext.startsWith(encryptedBackupCiphertextPrefix) &&
          !chunk.ciphertext.startsWith(
            _legacyEncryptedBackupCiphertextPrefix,
          ))) {
    throw const FormatException(
      'Encrypted backup chunk ciphertext is invalid.',
    );
  }
  if (!_sha256Pattern.hasMatch(chunk.sha256)) {
    throw const FormatException('Encrypted backup chunk hash is invalid.');
  }
}

List<int> _backupChunkAad({
  required int version,
  required String snapshotId,
  required DateTime createdAt,
  required int chunkSize,
  required int chunkCount,
  required int index,
}) => utf8.encode(
  jsonEncode({
    'format': encryptedBackupFormat,
    'version': version,
    'snapshot_id': snapshotId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'chunk_size': chunkSize,
    'chunk_count': chunkCount,
    'index': index,
  }),
);
