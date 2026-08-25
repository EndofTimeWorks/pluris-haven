import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../security/master_key_store.dart';

const localAvatarReferencePrefix = 'local-avatar:';
const _maximumCachedAvatarBytes = 16 * 1024 * 1024;

final class LocalAvatarStore {
  LocalAvatarStore({HavenMasterKeyStore? keyStore, this._rootDirectory})
    : _keyStore = keyStore ?? HavenMasterKeyStore();

  final HavenMasterKeyStore _keyStore;
  final Future<Directory> Function()? _rootDirectory;
  final Map<String, Uint8List> _readCache = {};
  var _cachedBytes = 0;

  Future<Uint8List?> read(String reference) async {
    final cached = _readCache.remove(reference);
    if (cached != null) {
      _readCache[reference] = cached;
      return cached;
    }
    final file = await _fileForReference(reference);
    if (file == null || !await file.exists()) return null;
    final stored = await file.readAsBytes();
    final bytes = _isEncrypted(stored)
        ? Uint8List.fromList(
            await (await _keyStore.loadOrCreateCrypto()).decryptBytes(
              utf8.decode(stored),
              aad: utf8.encode('avatar:${file.uri.pathSegments.last}'),
            ),
          )
        : stored;
    _cache(reference, bytes);
    return bytes;
  }

  Future<void> write(String fileName, Uint8List bytes) async {
    if (!_validFileName(fileName)) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'Invalid avatar filename.',
      );
    }
    final file = await _fileForName(fileName);
    final encrypted = await (await _keyStore.loadOrCreateCrypto()).encryptBytes(
      bytes,
      aad: utf8.encode('avatar:$fileName'),
    );
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsBytes(utf8.encode(encrypted), flush: true);
    await temporary.rename(file.path);
    _evict('local-avatar:$fileName');
  }

  Future<void> migrateLegacyFiles() async {
    final root = await _root();
    if (!await root.exists()) return;
    final files = (await root.list().toList()).whereType<File>().toList();
    for (final file in files) {
      final stored = await file.readAsBytes();
      if (_isEncrypted(stored)) continue;
      await write(file.uri.pathSegments.last, stored);
    }
  }

  Future<File?> _fileForReference(String reference) async {
    if (!reference.startsWith(localAvatarReferencePrefix)) return null;
    final name = reference.substring(localAvatarReferencePrefix.length).trim();
    if (!_validFileName(name)) return null;
    return _fileForName(name);
  }

  Future<File> _fileForName(String name) async =>
      File('${(await _root()).path}/$name');

  Future<Directory> _root() async {
    final configured = _rootDirectory;
    if (configured != null) {
      final root = await configured();
      if (!await root.exists()) await root.create(recursive: true);
      return root;
    }
    Directory base;
    try {
      base = await getApplicationDocumentsDirectory();
    } on Object {
      base = Directory('${Directory.systemTemp.path}/pluris-haven-test');
    }
    final root = Directory('${base.path}/avatars');
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  bool _isEncrypted(Uint8List bytes) =>
      bytes.length >= 3 && bytes[0] == 118 && bytes[1] == 50 && bytes[2] == 58;

  bool _validFileName(String name) =>
      name.isNotEmpty && !name.contains('/') && !name.contains('\\');

  void _cache(String reference, Uint8List bytes) {
    if (bytes.length > _maximumCachedAvatarBytes) return;
    while (_cachedBytes + bytes.length > _maximumCachedAvatarBytes &&
        _readCache.isNotEmpty) {
      _evict(_readCache.keys.first);
    }
    _readCache[reference] = bytes;
    _cachedBytes += bytes.length;
  }

  void _evict(String reference) {
    final existing = _readCache.remove(reference);
    if (existing != null) _cachedBytes -= existing.length;
  }
}
