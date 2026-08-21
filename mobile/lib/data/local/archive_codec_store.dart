part of 'haven_repository.dart';

extension LocalHavenRepositoryArchiveCodec on LocalHavenRepository {
  List<Map<String, Object?>> _jsonObjectList(Object? value) {
    if (value == null) return <Map<String, Object?>>[];
    if (value is! List) {
      throw const FormatException('Expected an archive list.');
    }

    return [
      for (final item in value)
        if (item is Map<String, Object?>) item else _throwArchiveObjectError(),
    ];
  }

  Map<String, Object?> _throwArchiveObjectError() {
    throw const FormatException('Expected an archive object in list.');
  }

  String _requiredString(Map<String, Object?> object, String key) {
    final value = _stringValue(object[key]);
    if (value == null || value.trim().isEmpty) {
      throw FormatException('Missing required archive field: $key.');
    }
    return value;
  }

  String? _stringValue(Object? value) => value is String ? value : null;

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = _stringValue(value);
    return text == null ? null : int.tryParse(text);
  }

  DateTime? _dateValue(Object? value) {
    final text = _stringValue(value);
    if (text == null || text.trim().isEmpty) return null;
    return DateTime.tryParse(text)?.toUtc();
  }
}

class _ImportAvatarBytes {
  const _ImportAvatarBytes({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String id;
  final String name;
  final String? mimeType;
  final Uint8List bytes;
}

String _avatarExtension(String sourceName, String? mimeType) {
  final mimeExtension = switch (mimeType) {
    'image/png' => '.png',
    'image/jpeg' => '.jpg',
    'image/webp' => '.webp',
    'image/gif' => '.gif',
    'image/svg+xml' => '.svg',
    _ => null,
  };
  if (mimeExtension != null) return mimeExtension;

  final lowerName = sourceName.toLowerCase();
  if (lowerName.endsWith('.png')) return '.png';
  if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) return '.jpg';
  if (lowerName.endsWith('.webp')) return '.webp';
  if (lowerName.endsWith('.gif')) return '.gif';
  if (lowerName.endsWith('.svg')) return '.svg';
  return '.bin';
}

String _safeFilePart(String value) {
  final cleaned = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
  return cleaned.isEmpty ? 'avatar' : cleaned;
}
