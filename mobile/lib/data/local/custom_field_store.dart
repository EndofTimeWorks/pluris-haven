import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_id.dart';
import 'local_text_codec.dart';

class CustomFieldSummary {
  const CustomFieldSummary({
    required this.id,
    required this.name,
    required this.fieldType,
    this.privacy,
    this.configuration = const {},
    required this.position,
    required this.valueCount,
  });

  final String id;
  final String name;
  final String fieldType;
  final String? privacy;
  final Map<String, Object?> configuration;
  final int position;
  final int valueCount;
}

class CustomFieldDraft {
  const CustomFieldDraft({
    required this.name,
    this.fieldType = 'text',
    this.privacy,
    this.configuration = const {},
  });

  final String name;
  final String fieldType;
  final String? privacy;
  final Map<String, Object?> configuration;
}

class CustomFieldValueSummary {
  const CustomFieldValueSummary({
    required this.id,
    required this.fieldId,
    this.memberId,
    required this.value,
  });

  final String id;
  final String fieldId;
  final String? memberId;
  final Object? value;

  String get displayValue => displayCustomFieldValue(value);
}

/// A non-destructive type-change preflight. Unresolved values require an
/// explicit per-value resolution flow; callers must not apply the change.
class CustomFieldTypeMigrationPreview {
  const CustomFieldTypeMigrationPreview({
    required this.fieldId,
    required this.fromType,
    required this.toType,
    required this.losslessValueIds,
    required this.unresolvedValueIds,
  });

  final String fieldId;
  final String fromType;
  final String toType;
  final List<String> losslessValueIds;
  final List<String> unresolvedValueIds;

  bool get canApply => unresolvedValueIds.isEmpty;
}

class LocalCustomFieldStore {
  LocalCustomFieldStore(
    this.database, {
    required this.encryptText,
    required this.encryptNullableText,
    required this.decryptText,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final EncryptNullableLocalText encryptNullableText;
  final DecryptLocalText decryptText;

  Stream<List<CustomFieldSummary>> watchFields() {
    return database
        .customSelect(
          '''
SELECT
  f.id,
  f.name,
  f.field_type,
  f.privacy,
  f.configuration,
  f.position,
  COUNT(v.id) AS value_count
FROM custom_field_definitions f
LEFT JOIN custom_field_values v ON v.field_id = f.id
WHERE f.system_id = ?
GROUP BY f.id, f.name, f.field_type, f.privacy, f.configuration, f.position
ORDER BY f.position ASC
''',
          variables: [Variable<String>(localSystemId)],
          readsFrom: {
            database.customFieldDefinitions,
            database.customFieldValues,
          },
        )
        .watch()
        .asyncMap(
          (rows) async => [
            for (final row in rows)
              CustomFieldSummary(
                id: row.read<String>('id'),
                name:
                    (await decryptText(
                      row.read<String>('name'),
                      'custom_field_definitions',
                      row.read<String>('id'),
                      'name',
                    )) ??
                    '',
                fieldType: row.read<String>('field_type'),
                privacy: await decryptText(
                  row.readNullable<String>('privacy'),
                  'custom_field_definitions',
                  row.read<String>('id'),
                  'privacy',
                ),
                configuration: decodeCustomFieldConfiguration(
                  await decryptText(
                    row.readNullable<String>('configuration'),
                    'custom_field_definitions',
                    row.read<String>('id'),
                    'configuration',
                  ),
                ),
                position: row.read<int>('position'),
                valueCount: row.read<int>('value_count'),
              ),
          ],
        );
  }

  Stream<List<CustomFieldValueSummary>> watchValues({
    String? fieldId,
    String? memberId,
  }) {
    final filters = <String>['f.system_id = ?'];
    final variables = <Variable<Object>>[Variable<String>(localSystemId)];
    if (fieldId != null) {
      filters.add('v.field_id = ?');
      variables.add(Variable<String>(fieldId));
    }
    if (memberId != null) {
      filters.add('v.member_id = ?');
      variables.add(Variable<String>(memberId));
    }
    return database
        .customSelect(
          '''
SELECT v.id, v.field_id, v.member_id, v.value
FROM custom_field_values v
INNER JOIN custom_field_definitions f ON f.id = v.field_id
WHERE ${filters.join(' AND ')}
''',
          variables: variables,
          readsFrom: {
            database.customFieldDefinitions,
            database.customFieldValues,
          },
        )
        .watch()
        .asyncMap(
          (rows) async => [
            for (final row in rows)
              CustomFieldValueSummary(
                id: row.read<String>('id'),
                fieldId: row.read<String>('field_id'),
                memberId: row.readNullable<String>('member_id'),
                value: decodeCustomFieldValue(
                  (await decryptText(
                        row.read<String>('value'),
                        'custom_field_values',
                        row.read<String>('id'),
                        'value',
                      )) ??
                      '',
                ),
              ),
          ],
        );
  }

  Future<void> save(CustomFieldDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;

    final fieldType = normalizeCustomFieldType(draft.fieldType);
    final now = DateTime.now().toUtc();
    final fieldId = newLocalId('custom-field');
    final positionExpression = database.customFieldDefinitions.position.max();
    final maxPosition =
        await (database.selectOnly(database.customFieldDefinitions)
              ..addColumns([positionExpression])
              ..where(
                database.customFieldDefinitions.systemId.equals(localSystemId),
              ))
            .map((row) => row.read(positionExpression))
            .getSingle();

    await database
        .into(database.customFieldDefinitions)
        .insert(
          CustomFieldDefinitionsCompanion.insert(
            id: fieldId,
            systemId: localSystemId,
            name: await encryptText(
              name,
              'custom_field_definitions',
              fieldId,
              'name',
            ),
            fieldType: Value(fieldType),
            privacy: Value(
              await encryptNullableText(
                _nullIfBlank(draft.privacy),
                'custom_field_definitions',
                fieldId,
                'privacy',
              ),
            ),
            configuration: Value(
              await encryptNullableText(
                encodeCustomFieldConfiguration(draft.configuration),
                'custom_field_definitions',
                fieldId,
                'configuration',
              ),
            ),
            position: Value((maxPosition ?? -1) + 1),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> update(String fieldId, CustomFieldDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;

    final fieldType = normalizeCustomFieldType(draft.fieldType);
    final existing =
        await (database.select(database.customFieldDefinitions)..where(
              (field) =>
                  field.id.equals(fieldId) &
                  field.systemId.equals(localSystemId),
            ))
            .getSingleOrNull();
    if (existing == null) return;
    if (existing.fieldType != fieldType) {
      final preview = await previewTypeChange(fieldId, fieldType);
      if (!preview.canApply) {
        throw StateError(
          'Custom field type change has values requiring explicit resolution.',
        );
      }
    }
    await (database.update(database.customFieldDefinitions)..where(
          (field) =>
              field.id.equals(fieldId) & field.systemId.equals(localSystemId),
        ))
        .write(
          CustomFieldDefinitionsCompanion(
            name: Value(
              await encryptText(
                name,
                'custom_field_definitions',
                fieldId,
                'name',
              ),
            ),
            fieldType: Value(fieldType),
            privacy: Value(
              await encryptNullableText(
                _nullIfBlank(draft.privacy),
                'custom_field_definitions',
                fieldId,
                'privacy',
              ),
            ),
            configuration: Value(
              await encryptNullableText(
                encodeCustomFieldConfiguration(draft.configuration),
                'custom_field_definitions',
                fieldId,
                'configuration',
              ),
            ),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<CustomFieldTypeMigrationPreview> previewTypeChange(
    String fieldId,
    String requestedType,
  ) async {
    final field =
        await (database.select(database.customFieldDefinitions)..where(
              (row) =>
                  row.id.equals(fieldId) & row.systemId.equals(localSystemId),
            ))
            .getSingleOrNull();
    if (field == null) throw StateError('Custom field does not exist.');
    final targetType = normalizeCustomFieldType(requestedType);
    final values = await (database.select(
      database.customFieldValues,
    )..where((row) => row.fieldId.equals(fieldId))).get();
    final lossless = <String>[];
    final unresolved = <String>[];
    for (final row in values) {
      final value = decodeCustomFieldValue(
        (await decryptText(
              row.value,
              'custom_field_values',
              row.id,
              'value',
            )) ??
            '',
      );
      if (_isLosslessTypeChange(field.fieldType, targetType, value)) {
        lossless.add(row.id);
      } else {
        unresolved.add(row.id);
      }
    }
    return CustomFieldTypeMigrationPreview(
      fieldId: fieldId,
      fromType: field.fieldType,
      toType: targetType,
      losslessValueIds: List.unmodifiable(lossless),
      unresolvedValueIds: List.unmodifiable(unresolved),
    );
  }

  Future<void> delete(String fieldId) async {
    await database.transaction(() async {
      await (database.delete(
        database.customFieldValues,
      )..where((value) => value.fieldId.equals(fieldId))).go();
      await (database.delete(database.customFieldDefinitions)..where(
            (field) =>
                field.id.equals(fieldId) & field.systemId.equals(localSystemId),
          ))
          .go();
    });
  }

  Future<void> setValue({
    required String fieldId,
    required String? memberId,
    required Object? value,
  }) async {
    final field =
        await (database.select(database.customFieldDefinitions)..where(
              (field) =>
                  field.id.equals(fieldId) &
                  field.systemId.equals(localSystemId),
            ))
            .getSingleOrNull();
    if (field == null) return;

    final ownerId = _nullIfBlank(memberId);
    final existing =
        await (database.select(database.customFieldValues)..where(
              (row) =>
                  row.fieldId.equals(fieldId) &
                  (ownerId == null
                      ? row.memberId.isNull()
                      : row.memberId.equals(ownerId)),
            ))
            .getSingleOrNull();

    if (isEmptyCustomFieldValue(value)) {
      if (existing != null) {
        await (database.delete(
          database.customFieldValues,
        )..where((row) => row.id.equals(existing.id))).go();
      }
      return;
    }

    final now = DateTime.now().toUtc();
    final storedValue = encodeCustomFieldValue(value);
    if (existing == null) {
      final valueId = newLocalId('custom-field-value');
      await database
          .into(database.customFieldValues)
          .insert(
            CustomFieldValuesCompanion.insert(
              id: valueId,
              fieldId: fieldId,
              memberId: Value(ownerId),
              value: await encryptText(
                storedValue,
                'custom_field_values',
                valueId,
                'value',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return;
    }

    await (database.update(
      database.customFieldValues,
    )..where((row) => row.id.equals(existing.id))).write(
      CustomFieldValuesCompanion(
        value: Value(
          await encryptText(
            storedValue,
            'custom_field_values',
            existing.id,
            'value',
          ),
        ),
        updatedAt: Value(now),
      ),
    );
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

bool _isLosslessTypeChange(String fromType, String toType, Object? value) {
  if (fromType == toType) return true;
  const textLike = {'text', 'long_text', 'markdown'};
  return textLike.contains(fromType) &&
      textLike.contains(toType) &&
      value is String;
}

const customFieldTypes = <String>{
  'text',
  'long_text',
  'markdown',
  'number',
  'date',
  'datetime',
  'boolean',
  'url',
  'color',
  'select',
  'multiselect',
  'json',
};

const _customFieldValuePrefix = 'phcf1:';
const maximumCustomFieldConfigurationCharacters = 5000;

String normalizeCustomFieldType(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_.:]'), '');
  return normalized.isEmpty ? 'text' : normalized;
}

String? encodeCustomFieldConfiguration(Map<String, Object?> configuration) {
  if (configuration.isEmpty) return null;
  final encoded = jsonEncode(configuration);
  return encoded.length <= maximumCustomFieldConfigurationCharacters
      ? encoded
      : null;
}

Map<String, Object?> decodeCustomFieldConfiguration(String? stored) {
  if (stored == null || stored.isEmpty) return const {};
  try {
    final decoded = jsonDecode(stored);
    if (decoded is Map) {
      return Map.unmodifiable(decoded.cast<String, Object?>());
    }
  } on FormatException {
    // Keep malformed imported configuration from breaking the field list.
  }
  return const {};
}

String encodeCustomFieldValue(Object? value) =>
    '$_customFieldValuePrefix${jsonEncode(value)}';

Object? decodeCustomFieldValue(String stored) {
  if (!stored.startsWith(_customFieldValuePrefix)) return stored;
  try {
    return jsonDecode(stored.substring(_customFieldValuePrefix.length));
  } on FormatException {
    return stored;
  }
}

bool isEmptyCustomFieldValue(Object? value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is List) return value.isEmpty;
  return false;
}

String displayCustomFieldValue(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is List) return value.map(displayCustomFieldValue).join(', ');
  if (value is num) return value.toString();
  return const JsonEncoder.withIndent('  ').convert(value);
}
