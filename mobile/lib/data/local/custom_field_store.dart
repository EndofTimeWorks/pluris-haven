import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_text_codec.dart';

class CustomFieldSummary {
  const CustomFieldSummary({
    required this.id,
    required this.name,
    required this.fieldType,
    this.privacy,
    required this.position,
    required this.valueCount,
  });

  final String id;
  final String name;
  final String fieldType;
  final String? privacy;
  final int position;
  final int valueCount;
}

class CustomFieldDraft {
  const CustomFieldDraft({
    required this.name,
    this.fieldType = 'text',
    this.privacy,
  });

  final String name;
  final String fieldType;
  final String? privacy;
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
  final String value;
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
  f.position,
  COUNT(v.id) AS value_count
FROM custom_field_definitions f
LEFT JOIN custom_field_values v ON v.field_id = f.id
WHERE f.system_id = ?
GROUP BY f.id, f.name, f.field_type, f.privacy, f.position
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
                position: row.read<int>('position'),
                valueCount: row.read<int>('value_count'),
              ),
          ],
        );
  }

  Stream<List<CustomFieldValueSummary>> watchValues() {
    return database
        .customSelect(
          '''
SELECT v.id, v.field_id, v.member_id, v.value
FROM custom_field_values v
INNER JOIN custom_field_definitions f ON f.id = v.field_id
WHERE f.system_id = ?
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
              CustomFieldValueSummary(
                id: row.read<String>('id'),
                fieldId: row.read<String>('field_id'),
                memberId: row.readNullable<String>('member_id'),
                value:
                    (await decryptText(
                      row.read<String>('value'),
                      'custom_field_values',
                      row.read<String>('id'),
                      'value',
                    )) ??
                    '',
              ),
          ],
        );
  }

  Future<void> save(CustomFieldDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;

    final fieldType = _allowedTypes.contains(draft.fieldType)
        ? draft.fieldType
        : 'text';
    final now = DateTime.now().toUtc();
    final fieldId = 'custom-field-${now.microsecondsSinceEpoch}';
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
            position: Value((maxPosition ?? -1) + 1),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> update(String fieldId, CustomFieldDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;

    final fieldType = _allowedTypes.contains(draft.fieldType)
        ? draft.fieldType
        : 'text';
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
            updatedAt: Value(DateTime.now().toUtc()),
          ),
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
    required String value,
  }) async {
    final field =
        await (database.select(database.customFieldDefinitions)..where(
              (field) =>
                  field.id.equals(fieldId) &
                  field.systemId.equals(localSystemId),
            ))
            .getSingleOrNull();
    if (field == null) return;

    final trimmed = value.trim();
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

    if (trimmed.isEmpty) {
      if (existing != null) {
        await (database.delete(
          database.customFieldValues,
        )..where((row) => row.id.equals(existing.id))).go();
      }
      return;
    }

    final now = DateTime.now().toUtc();
    if (existing == null) {
      final valueId = 'custom-field-value-${now.microsecondsSinceEpoch}';
      await database
          .into(database.customFieldValues)
          .insert(
            CustomFieldValuesCompanion.insert(
              id: valueId,
              fieldId: fieldId,
              memberId: Value(ownerId),
              value: await encryptText(
                trimmed,
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
            trimmed,
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

const _allowedTypes = {'text', 'number', 'date', 'boolean', 'select'};
