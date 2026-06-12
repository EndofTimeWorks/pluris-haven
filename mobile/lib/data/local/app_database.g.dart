// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PluralSystemsTable extends PluralSystems
    with TableInfo<$PluralSystemsTable, PluralSystem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PluralSystemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plural_systems';
  @override
  VerificationContext validateIntegrity(
    Insertable<PluralSystem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PluralSystem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PluralSystem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PluralSystemsTable createAlias(String alias) {
    return $PluralSystemsTable(attachedDatabase, alias);
  }
}

class PluralSystem extends DataClass implements Insertable<PluralSystem> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PluralSystem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PluralSystemsCompanion toCompanion(bool nullToAbsent) {
    return PluralSystemsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PluralSystem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PluralSystem(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PluralSystem copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PluralSystem(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PluralSystem copyWithCompanion(PluralSystemsCompanion data) {
    return PluralSystem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PluralSystem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PluralSystem &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PluralSystemsCompanion extends UpdateCompanion<PluralSystem> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PluralSystemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PluralSystemsCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PluralSystem> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PluralSystemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PluralSystemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PluralSystemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SystemGroupsTable extends SystemGroups
    with TableInfo<$SystemGroupsTable, SystemGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SystemGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemIdMeta = const VerificationMeta(
    'systemId',
  );
  @override
  late final GeneratedColumn<String> systemId = GeneratedColumn<String>(
    'system_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plural_systems (id)',
    ),
  );
  static const VerificationMeta _parentGroupIdMeta = const VerificationMeta(
    'parentGroupId',
  );
  @override
  late final GeneratedColumn<String> parentGroupId = GeneratedColumn<String>(
    'parent_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    systemId,
    parentGroupId,
    name,
    colorHex,
    description,
    emoji,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'system_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<SystemGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('system_id')) {
      context.handle(
        _systemIdMeta,
        systemId.isAcceptableOrUnknown(data['system_id']!, _systemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_systemIdMeta);
    }
    if (data.containsKey('parent_group_id')) {
      context.handle(
        _parentGroupIdMeta,
        parentGroupId.isAcceptableOrUnknown(
          data['parent_group_id']!,
          _parentGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SystemGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SystemGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      systemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_id'],
      )!,
      parentGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_group_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SystemGroupsTable createAlias(String alias) {
    return $SystemGroupsTable(attachedDatabase, alias);
  }
}

class SystemGroup extends DataClass implements Insertable<SystemGroup> {
  final String id;
  final String systemId;
  final String? parentGroupId;
  final String name;
  final String? colorHex;
  final String? description;
  final String? emoji;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SystemGroup({
    required this.id,
    required this.systemId,
    this.parentGroupId,
    required this.name,
    this.colorHex,
    this.description,
    this.emoji,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['system_id'] = Variable<String>(systemId);
    if (!nullToAbsent || parentGroupId != null) {
      map['parent_group_id'] = Variable<String>(parentGroupId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SystemGroupsCompanion toCompanion(bool nullToAbsent) {
    return SystemGroupsCompanion(
      id: Value(id),
      systemId: Value(systemId),
      parentGroupId: parentGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentGroupId),
      name: Value(name),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SystemGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SystemGroup(
      id: serializer.fromJson<String>(json['id']),
      systemId: serializer.fromJson<String>(json['systemId']),
      parentGroupId: serializer.fromJson<String?>(json['parentGroupId']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      description: serializer.fromJson<String?>(json['description']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'systemId': serializer.toJson<String>(systemId),
      'parentGroupId': serializer.toJson<String?>(parentGroupId),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String?>(colorHex),
      'description': serializer.toJson<String?>(description),
      'emoji': serializer.toJson<String?>(emoji),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SystemGroup copyWith({
    String? id,
    String? systemId,
    Value<String?> parentGroupId = const Value.absent(),
    String? name,
    Value<String?> colorHex = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> emoji = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SystemGroup(
    id: id ?? this.id,
    systemId: systemId ?? this.systemId,
    parentGroupId: parentGroupId.present
        ? parentGroupId.value
        : this.parentGroupId,
    name: name ?? this.name,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    description: description.present ? description.value : this.description,
    emoji: emoji.present ? emoji.value : this.emoji,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SystemGroup copyWithCompanion(SystemGroupsCompanion data) {
    return SystemGroup(
      id: data.id.present ? data.id.value : this.id,
      systemId: data.systemId.present ? data.systemId.value : this.systemId,
      parentGroupId: data.parentGroupId.present
          ? data.parentGroupId.value
          : this.parentGroupId,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      description: data.description.present
          ? data.description.value
          : this.description,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SystemGroup(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('parentGroupId: $parentGroupId, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('description: $description, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    systemId,
    parentGroupId,
    name,
    colorHex,
    description,
    emoji,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SystemGroup &&
          other.id == this.id &&
          other.systemId == this.systemId &&
          other.parentGroupId == this.parentGroupId &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.description == this.description &&
          other.emoji == this.emoji &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SystemGroupsCompanion extends UpdateCompanion<SystemGroup> {
  final Value<String> id;
  final Value<String> systemId;
  final Value<String?> parentGroupId;
  final Value<String> name;
  final Value<String?> colorHex;
  final Value<String?> description;
  final Value<String?> emoji;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SystemGroupsCompanion({
    this.id = const Value.absent(),
    this.systemId = const Value.absent(),
    this.parentGroupId = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.description = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SystemGroupsCompanion.insert({
    required String id,
    required String systemId,
    this.parentGroupId = const Value.absent(),
    required String name,
    this.colorHex = const Value.absent(),
    this.description = const Value.absent(),
    this.emoji = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       systemId = Value(systemId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SystemGroup> custom({
    Expression<String>? id,
    Expression<String>? systemId,
    Expression<String>? parentGroupId,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? description,
    Expression<String>? emoji,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (systemId != null) 'system_id': systemId,
      if (parentGroupId != null) 'parent_group_id': parentGroupId,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (description != null) 'description': description,
      if (emoji != null) 'emoji': emoji,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SystemGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? systemId,
    Value<String?>? parentGroupId,
    Value<String>? name,
    Value<String?>? colorHex,
    Value<String?>? description,
    Value<String?>? emoji,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SystemGroupsCompanion(
      id: id ?? this.id,
      systemId: systemId ?? this.systemId,
      parentGroupId: parentGroupId ?? this.parentGroupId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (systemId.present) {
      map['system_id'] = Variable<String>(systemId.value);
    }
    if (parentGroupId.present) {
      map['parent_group_id'] = Variable<String>(parentGroupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SystemGroupsCompanion(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('parentGroupId: $parentGroupId, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('description: $description, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, Member> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemIdMeta = const VerificationMeta(
    'systemId',
  );
  @override
  late final GeneratedColumn<String> systemId = GeneratedColumn<String>(
    'system_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plural_systems (id)',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pronounsMeta = const VerificationMeta(
    'pronouns',
  );
  @override
  late final GeneratedColumn<String> pronouns = GeneratedColumn<String>(
    'pronouns',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pluralKitIdMeta = const VerificationMeta(
    'pluralKitId',
  );
  @override
  late final GeneratedColumn<String> pluralKitId = GeneratedColumn<String>(
    'plural_kit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    systemId,
    displayName,
    pronouns,
    colorHex,
    folderId,
    description,
    avatarUrl,
    pluralKitId,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<Member> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('system_id')) {
      context.handle(
        _systemIdMeta,
        systemId.isAcceptableOrUnknown(data['system_id']!, _systemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_systemIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('pronouns')) {
      context.handle(
        _pronounsMeta,
        pronouns.isAcceptableOrUnknown(data['pronouns']!, _pronounsMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('plural_kit_id')) {
      context.handle(
        _pluralKitIdMeta,
        pluralKitId.isAcceptableOrUnknown(
          data['plural_kit_id']!,
          _pluralKitIdMeta,
        ),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Member map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Member(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      systemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      pronouns: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pronouns'],
      ),
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      pluralKitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plural_kit_id'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class Member extends DataClass implements Insertable<Member> {
  final String id;
  final String systemId;
  final String displayName;
  final String? pronouns;
  final String? colorHex;
  final String? folderId;
  final String? description;
  final String? avatarUrl;
  final String? pluralKitId;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Member({
    required this.id,
    required this.systemId,
    required this.displayName,
    this.pronouns,
    this.colorHex,
    this.folderId,
    this.description,
    this.avatarUrl,
    this.pluralKitId,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['system_id'] = Variable<String>(systemId);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || pronouns != null) {
      map['pronouns'] = Variable<String>(pronouns);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || pluralKitId != null) {
      map['plural_kit_id'] = Variable<String>(pluralKitId);
    }
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      systemId: Value(systemId),
      displayName: Value(displayName),
      pronouns: pronouns == null && nullToAbsent
          ? const Value.absent()
          : Value(pronouns),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      pluralKitId: pluralKitId == null && nullToAbsent
          ? const Value.absent()
          : Value(pluralKitId),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Member.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Member(
      id: serializer.fromJson<String>(json['id']),
      systemId: serializer.fromJson<String>(json['systemId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      pronouns: serializer.fromJson<String?>(json['pronouns']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      description: serializer.fromJson<String?>(json['description']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      pluralKitId: serializer.fromJson<String?>(json['pluralKitId']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'systemId': serializer.toJson<String>(systemId),
      'displayName': serializer.toJson<String>(displayName),
      'pronouns': serializer.toJson<String?>(pronouns),
      'colorHex': serializer.toJson<String?>(colorHex),
      'folderId': serializer.toJson<String?>(folderId),
      'description': serializer.toJson<String?>(description),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'pluralKitId': serializer.toJson<String?>(pluralKitId),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Member copyWith({
    String? id,
    String? systemId,
    String? displayName,
    Value<String?> pronouns = const Value.absent(),
    Value<String?> colorHex = const Value.absent(),
    Value<String?> folderId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> pluralKitId = const Value.absent(),
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Member(
    id: id ?? this.id,
    systemId: systemId ?? this.systemId,
    displayName: displayName ?? this.displayName,
    pronouns: pronouns.present ? pronouns.value : this.pronouns,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    folderId: folderId.present ? folderId.value : this.folderId,
    description: description.present ? description.value : this.description,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    pluralKitId: pluralKitId.present ? pluralKitId.value : this.pluralKitId,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Member copyWithCompanion(MembersCompanion data) {
    return Member(
      id: data.id.present ? data.id.value : this.id,
      systemId: data.systemId.present ? data.systemId.value : this.systemId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      pronouns: data.pronouns.present ? data.pronouns.value : this.pronouns,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      description: data.description.present
          ? data.description.value
          : this.description,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      pluralKitId: data.pluralKitId.present
          ? data.pluralKitId.value
          : this.pluralKitId,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Member(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('displayName: $displayName, ')
          ..write('pronouns: $pronouns, ')
          ..write('colorHex: $colorHex, ')
          ..write('folderId: $folderId, ')
          ..write('description: $description, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('pluralKitId: $pluralKitId, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    systemId,
    displayName,
    pronouns,
    colorHex,
    folderId,
    description,
    avatarUrl,
    pluralKitId,
    archived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Member &&
          other.id == this.id &&
          other.systemId == this.systemId &&
          other.displayName == this.displayName &&
          other.pronouns == this.pronouns &&
          other.colorHex == this.colorHex &&
          other.folderId == this.folderId &&
          other.description == this.description &&
          other.avatarUrl == this.avatarUrl &&
          other.pluralKitId == this.pluralKitId &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MembersCompanion extends UpdateCompanion<Member> {
  final Value<String> id;
  final Value<String> systemId;
  final Value<String> displayName;
  final Value<String?> pronouns;
  final Value<String?> colorHex;
  final Value<String?> folderId;
  final Value<String?> description;
  final Value<String?> avatarUrl;
  final Value<String?> pluralKitId;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.systemId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.pronouns = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.folderId = const Value.absent(),
    this.description = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.pluralKitId = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String systemId,
    required String displayName,
    this.pronouns = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.folderId = const Value.absent(),
    this.description = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.pluralKitId = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       systemId = Value(systemId),
       displayName = Value(displayName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Member> custom({
    Expression<String>? id,
    Expression<String>? systemId,
    Expression<String>? displayName,
    Expression<String>? pronouns,
    Expression<String>? colorHex,
    Expression<String>? folderId,
    Expression<String>? description,
    Expression<String>? avatarUrl,
    Expression<String>? pluralKitId,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (systemId != null) 'system_id': systemId,
      if (displayName != null) 'display_name': displayName,
      if (pronouns != null) 'pronouns': pronouns,
      if (colorHex != null) 'color_hex': colorHex,
      if (folderId != null) 'folder_id': folderId,
      if (description != null) 'description': description,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (pluralKitId != null) 'plural_kit_id': pluralKitId,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String>? systemId,
    Value<String>? displayName,
    Value<String?>? pronouns,
    Value<String?>? colorHex,
    Value<String?>? folderId,
    Value<String?>? description,
    Value<String?>? avatarUrl,
    Value<String?>? pluralKitId,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      systemId: systemId ?? this.systemId,
      displayName: displayName ?? this.displayName,
      pronouns: pronouns ?? this.pronouns,
      colorHex: colorHex ?? this.colorHex,
      folderId: folderId ?? this.folderId,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pluralKitId: pluralKitId ?? this.pluralKitId,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (systemId.present) {
      map['system_id'] = Variable<String>(systemId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (pronouns.present) {
      map['pronouns'] = Variable<String>(pronouns.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (pluralKitId.present) {
      map['plural_kit_id'] = Variable<String>(pluralKitId.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('displayName: $displayName, ')
          ..write('pronouns: $pronouns, ')
          ..write('colorHex: $colorHex, ')
          ..write('folderId: $folderId, ')
          ..write('description: $description, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('pluralKitId: $pluralKitId, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemIdMeta = const VerificationMeta(
    'systemId',
  );
  @override
  late final GeneratedColumn<String> systemId = GeneratedColumn<String>(
    'system_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plural_systems (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    systemId,
    memberId,
    title,
    body,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('system_id')) {
      context.handle(
        _systemIdMeta,
        systemId.isAcceptableOrUnknown(data['system_id']!, _systemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_systemIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      systemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String systemId;
  final String? memberId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Note({
    required this.id,
    required this.systemId,
    this.memberId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['system_id'] = Variable<String>(systemId);
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      systemId: Value(systemId),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      title: Value(title),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      systemId: serializer.fromJson<String>(json['systemId']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'systemId': serializer.toJson<String>(systemId),
      'memberId': serializer.toJson<String?>(memberId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Note copyWith({
    String? id,
    String? systemId,
    Value<String?> memberId = const Value.absent(),
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Note(
    id: id ?? this.id,
    systemId: systemId ?? this.systemId,
    memberId: memberId.present ? memberId.value : this.memberId,
    title: title ?? this.title,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      systemId: data.systemId.present ? data.systemId.value : this.systemId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('memberId: $memberId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, systemId, memberId, title, body, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.systemId == this.systemId &&
          other.memberId == this.memberId &&
          other.title == this.title &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String> systemId;
  final Value<String?> memberId;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.systemId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required String systemId,
    this.memberId = const Value.absent(),
    required String title,
    required String body,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       systemId = Value(systemId),
       title = Value(title),
       body = Value(body),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? systemId,
    Expression<String>? memberId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (systemId != null) 'system_id': systemId,
      if (memberId != null) 'member_id': memberId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? systemId,
    Value<String?>? memberId,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      systemId: systemId ?? this.systemId,
      memberId: memberId ?? this.memberId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (systemId.present) {
      map['system_id'] = Variable<String>(systemId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('memberId: $memberId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FrontSessionsTable extends FrontSessions
    with TableInfo<$FrontSessionsTable, FrontSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrontSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemIdMeta = const VerificationMeta(
    'systemId',
  );
  @override
  late final GeneratedColumn<String> systemId = GeneratedColumn<String>(
    'system_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plural_systems (id)',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    systemId,
    label,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'front_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrontSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('system_id')) {
      context.handle(
        _systemIdMeta,
        systemId.isAcceptableOrUnknown(data['system_id']!, _systemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_systemIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FrontSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrontSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      systemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FrontSessionsTable createAlias(String alias) {
    return $FrontSessionsTable(attachedDatabase, alias);
  }
}

class FrontSession extends DataClass implements Insertable<FrontSession> {
  final String id;
  final String systemId;
  final String? label;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FrontSession({
    required this.id,
    required this.systemId,
    this.label,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['system_id'] = Variable<String>(systemId);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FrontSessionsCompanion toCompanion(bool nullToAbsent) {
    return FrontSessionsCompanion(
      id: Value(id),
      systemId: Value(systemId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FrontSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrontSession(
      id: serializer.fromJson<String>(json['id']),
      systemId: serializer.fromJson<String>(json['systemId']),
      label: serializer.fromJson<String?>(json['label']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'systemId': serializer.toJson<String>(systemId),
      'label': serializer.toJson<String?>(label),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FrontSession copyWith({
    String? id,
    String? systemId,
    Value<String?> label = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FrontSession(
    id: id ?? this.id,
    systemId: systemId ?? this.systemId,
    label: label.present ? label.value : this.label,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FrontSession copyWithCompanion(FrontSessionsCompanion data) {
    return FrontSession(
      id: data.id.present ? data.id.value : this.id,
      systemId: data.systemId.present ? data.systemId.value : this.systemId,
      label: data.label.present ? data.label.value : this.label,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrontSession(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('label: $label, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    systemId,
    label,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrontSession &&
          other.id == this.id &&
          other.systemId == this.systemId &&
          other.label == this.label &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FrontSessionsCompanion extends UpdateCompanion<FrontSession> {
  final Value<String> id;
  final Value<String> systemId;
  final Value<String?> label;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FrontSessionsCompanion({
    this.id = const Value.absent(),
    this.systemId = const Value.absent(),
    this.label = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FrontSessionsCompanion.insert({
    required String id,
    required String systemId,
    this.label = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       systemId = Value(systemId),
       startedAt = Value(startedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FrontSession> custom({
    Expression<String>? id,
    Expression<String>? systemId,
    Expression<String>? label,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (systemId != null) 'system_id': systemId,
      if (label != null) 'label': label,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FrontSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? systemId,
    Value<String?>? label,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FrontSessionsCompanion(
      id: id ?? this.id,
      systemId: systemId ?? this.systemId,
      label: label ?? this.label,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (systemId.present) {
      map['system_id'] = Variable<String>(systemId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrontSessionsCompanion(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('label: $label, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FrontSessionMembersTable extends FrontSessionMembers
    with TableInfo<$FrontSessionMembersTable, FrontSessionMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrontSessionMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES front_sessions (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, memberId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'front_session_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrontSessionMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, memberId};
  @override
  FrontSessionMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrontSessionMember(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
    );
  }

  @override
  $FrontSessionMembersTable createAlias(String alias) {
    return $FrontSessionMembersTable(attachedDatabase, alias);
  }
}

class FrontSessionMember extends DataClass
    implements Insertable<FrontSessionMember> {
  final String sessionId;
  final String memberId;
  const FrontSessionMember({required this.sessionId, required this.memberId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['member_id'] = Variable<String>(memberId);
    return map;
  }

  FrontSessionMembersCompanion toCompanion(bool nullToAbsent) {
    return FrontSessionMembersCompanion(
      sessionId: Value(sessionId),
      memberId: Value(memberId),
    );
  }

  factory FrontSessionMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrontSessionMember(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      memberId: serializer.fromJson<String>(json['memberId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'memberId': serializer.toJson<String>(memberId),
    };
  }

  FrontSessionMember copyWith({String? sessionId, String? memberId}) =>
      FrontSessionMember(
        sessionId: sessionId ?? this.sessionId,
        memberId: memberId ?? this.memberId,
      );
  FrontSessionMember copyWithCompanion(FrontSessionMembersCompanion data) {
    return FrontSessionMember(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrontSessionMember(')
          ..write('sessionId: $sessionId, ')
          ..write('memberId: $memberId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, memberId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrontSessionMember &&
          other.sessionId == this.sessionId &&
          other.memberId == this.memberId);
}

class FrontSessionMembersCompanion extends UpdateCompanion<FrontSessionMember> {
  final Value<String> sessionId;
  final Value<String> memberId;
  final Value<int> rowid;
  const FrontSessionMembersCompanion({
    this.sessionId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FrontSessionMembersCompanion.insert({
    required String sessionId,
    required String memberId,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       memberId = Value(memberId);
  static Insertable<FrontSessionMember> custom({
    Expression<String>? sessionId,
    Expression<String>? memberId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (memberId != null) 'member_id': memberId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FrontSessionMembersCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? memberId,
    Value<int>? rowid,
  }) {
    return FrontSessionMembersCompanion(
      sessionId: sessionId ?? this.sessionId,
      memberId: memberId ?? this.memberId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrontSessionMembersCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('memberId: $memberId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportRecordsTable extends ImportRecords
    with TableInfo<$ImportRecordsTable, ImportRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemIdMeta = const VerificationMeta(
    'systemId',
  );
  @override
  late final GeneratedColumn<String> systemId = GeneratedColumn<String>(
    'system_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plural_systems (id)',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryJsonMeta = const VerificationMeta(
    'summaryJson',
  );
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
    'summary_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    systemId,
    source,
    fileName,
    summaryJson,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('system_id')) {
      context.handle(
        _systemIdMeta,
        systemId.isAcceptableOrUnknown(data['system_id']!, _systemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_systemIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('summary_json')) {
      context.handle(
        _summaryJsonMeta,
        summaryJson.isAcceptableOrUnknown(
          data['summary_json']!,
          _summaryJsonMeta,
        ),
      );
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      systemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      summaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_json'],
      ),
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $ImportRecordsTable createAlias(String alias) {
    return $ImportRecordsTable(attachedDatabase, alias);
  }
}

class ImportRecord extends DataClass implements Insertable<ImportRecord> {
  final String id;
  final String systemId;
  final String source;
  final String? fileName;
  final String? summaryJson;
  final DateTime importedAt;
  const ImportRecord({
    required this.id,
    required this.systemId,
    required this.source,
    this.fileName,
    this.summaryJson,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['system_id'] = Variable<String>(systemId);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || summaryJson != null) {
      map['summary_json'] = Variable<String>(summaryJson);
    }
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  ImportRecordsCompanion toCompanion(bool nullToAbsent) {
    return ImportRecordsCompanion(
      id: Value(id),
      systemId: Value(systemId),
      source: Value(source),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      summaryJson: summaryJson == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryJson),
      importedAt: Value(importedAt),
    );
  }

  factory ImportRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportRecord(
      id: serializer.fromJson<String>(json['id']),
      systemId: serializer.fromJson<String>(json['systemId']),
      source: serializer.fromJson<String>(json['source']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      summaryJson: serializer.fromJson<String?>(json['summaryJson']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'systemId': serializer.toJson<String>(systemId),
      'source': serializer.toJson<String>(source),
      'fileName': serializer.toJson<String?>(fileName),
      'summaryJson': serializer.toJson<String?>(summaryJson),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  ImportRecord copyWith({
    String? id,
    String? systemId,
    String? source,
    Value<String?> fileName = const Value.absent(),
    Value<String?> summaryJson = const Value.absent(),
    DateTime? importedAt,
  }) => ImportRecord(
    id: id ?? this.id,
    systemId: systemId ?? this.systemId,
    source: source ?? this.source,
    fileName: fileName.present ? fileName.value : this.fileName,
    summaryJson: summaryJson.present ? summaryJson.value : this.summaryJson,
    importedAt: importedAt ?? this.importedAt,
  );
  ImportRecord copyWithCompanion(ImportRecordsCompanion data) {
    return ImportRecord(
      id: data.id.present ? data.id.value : this.id,
      systemId: data.systemId.present ? data.systemId.value : this.systemId,
      source: data.source.present ? data.source.value : this.source,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      summaryJson: data.summaryJson.present
          ? data.summaryJson.value
          : this.summaryJson,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportRecord(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('source: $source, ')
          ..write('fileName: $fileName, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, systemId, source, fileName, summaryJson, importedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportRecord &&
          other.id == this.id &&
          other.systemId == this.systemId &&
          other.source == this.source &&
          other.fileName == this.fileName &&
          other.summaryJson == this.summaryJson &&
          other.importedAt == this.importedAt);
}

class ImportRecordsCompanion extends UpdateCompanion<ImportRecord> {
  final Value<String> id;
  final Value<String> systemId;
  final Value<String> source;
  final Value<String?> fileName;
  final Value<String?> summaryJson;
  final Value<DateTime> importedAt;
  final Value<int> rowid;
  const ImportRecordsCompanion({
    this.id = const Value.absent(),
    this.systemId = const Value.absent(),
    this.source = const Value.absent(),
    this.fileName = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportRecordsCompanion.insert({
    required String id,
    required String systemId,
    required String source,
    this.fileName = const Value.absent(),
    this.summaryJson = const Value.absent(),
    required DateTime importedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       systemId = Value(systemId),
       source = Value(source),
       importedAt = Value(importedAt);
  static Insertable<ImportRecord> custom({
    Expression<String>? id,
    Expression<String>? systemId,
    Expression<String>? source,
    Expression<String>? fileName,
    Expression<String>? summaryJson,
    Expression<DateTime>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (systemId != null) 'system_id': systemId,
      if (source != null) 'source': source,
      if (fileName != null) 'file_name': fileName,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? systemId,
    Value<String>? source,
    Value<String?>? fileName,
    Value<String?>? summaryJson,
    Value<DateTime>? importedAt,
    Value<int>? rowid,
  }) {
    return ImportRecordsCompanion(
      id: id ?? this.id,
      systemId: systemId ?? this.systemId,
      source: source ?? this.source,
      fileName: fileName ?? this.fileName,
      summaryJson: summaryJson ?? this.summaryJson,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (systemId.present) {
      map['system_id'] = Variable<String>(systemId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportRecordsCompanion(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('source: $source, ')
          ..write('fileName: $fileName, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PluralSystemsTable pluralSystems = $PluralSystemsTable(this);
  late final $SystemGroupsTable systemGroups = $SystemGroupsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $FrontSessionsTable frontSessions = $FrontSessionsTable(this);
  late final $FrontSessionMembersTable frontSessionMembers =
      $FrontSessionMembersTable(this);
  late final $ImportRecordsTable importRecords = $ImportRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pluralSystems,
    systemGroups,
    members,
    notes,
    frontSessions,
    frontSessionMembers,
    importRecords,
  ];
}

typedef $$PluralSystemsTableCreateCompanionBuilder =
    PluralSystemsCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PluralSystemsTableUpdateCompanionBuilder =
    PluralSystemsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PluralSystemsTableReferences
    extends BaseReferences<_$AppDatabase, $PluralSystemsTable, PluralSystem> {
  $$PluralSystemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SystemGroupsTable, List<SystemGroup>>
  _systemGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.systemGroups,
    aliasName: 'plural_systems__id__system_groups__system_id',
  );

  $$SystemGroupsTableProcessedTableManager get systemGroupsRefs {
    final manager = $$SystemGroupsTableTableManager(
      $_db,
      $_db.systemGroups,
    ).filter((f) => f.systemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_systemGroupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MembersTable, List<Member>> _membersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.members,
    aliasName: 'plural_systems__id__members__system_id',
  );

  $$MembersTableProcessedTableManager get membersRefs {
    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.systemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_membersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotesTable, List<Note>> _notesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.notes,
    aliasName: 'plural_systems__id__notes__system_id',
  );

  $$NotesTableProcessedTableManager get notesRefs {
    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.systemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FrontSessionsTable, List<FrontSession>>
  _frontSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.frontSessions,
    aliasName: 'plural_systems__id__front_sessions__system_id',
  );

  $$FrontSessionsTableProcessedTableManager get frontSessionsRefs {
    final manager = $$FrontSessionsTableTableManager(
      $_db,
      $_db.frontSessions,
    ).filter((f) => f.systemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_frontSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ImportRecordsTable, List<ImportRecord>>
  _importRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.importRecords,
    aliasName: 'plural_systems__id__import_records__system_id',
  );

  $$ImportRecordsTableProcessedTableManager get importRecordsRefs {
    final manager = $$ImportRecordsTableTableManager(
      $_db,
      $_db.importRecords,
    ).filter((f) => f.systemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_importRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PluralSystemsTableFilterComposer
    extends Composer<_$AppDatabase, $PluralSystemsTable> {
  $$PluralSystemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> systemGroupsRefs(
    Expression<bool> Function($$SystemGroupsTableFilterComposer f) f,
  ) {
    final $$SystemGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.systemGroups,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemGroupsTableFilterComposer(
            $db: $db,
            $table: $db.systemGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> membersRefs(
    Expression<bool> Function($$MembersTableFilterComposer f) f,
  ) {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notesRefs(
    Expression<bool> Function($$NotesTableFilterComposer f) f,
  ) {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> frontSessionsRefs(
    Expression<bool> Function($$FrontSessionsTableFilterComposer f) f,
  ) {
    final $$FrontSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frontSessions,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrontSessionsTableFilterComposer(
            $db: $db,
            $table: $db.frontSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> importRecordsRefs(
    Expression<bool> Function($$ImportRecordsTableFilterComposer f) f,
  ) {
    final $$ImportRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importRecords,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportRecordsTableFilterComposer(
            $db: $db,
            $table: $db.importRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PluralSystemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PluralSystemsTable> {
  $$PluralSystemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PluralSystemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PluralSystemsTable> {
  $$PluralSystemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> systemGroupsRefs<T extends Object>(
    Expression<T> Function($$SystemGroupsTableAnnotationComposer a) f,
  ) {
    final $$SystemGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.systemGroups,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.systemGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> membersRefs<T extends Object>(
    Expression<T> Function($$MembersTableAnnotationComposer a) f,
  ) {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notesRefs<T extends Object>(
    Expression<T> Function($$NotesTableAnnotationComposer a) f,
  ) {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> frontSessionsRefs<T extends Object>(
    Expression<T> Function($$FrontSessionsTableAnnotationComposer a) f,
  ) {
    final $$FrontSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frontSessions,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrontSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.frontSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> importRecordsRefs<T extends Object>(
    Expression<T> Function($$ImportRecordsTableAnnotationComposer a) f,
  ) {
    final $$ImportRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importRecords,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.importRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PluralSystemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PluralSystemsTable,
          PluralSystem,
          $$PluralSystemsTableFilterComposer,
          $$PluralSystemsTableOrderingComposer,
          $$PluralSystemsTableAnnotationComposer,
          $$PluralSystemsTableCreateCompanionBuilder,
          $$PluralSystemsTableUpdateCompanionBuilder,
          (PluralSystem, $$PluralSystemsTableReferences),
          PluralSystem,
          PrefetchHooks Function({
            bool systemGroupsRefs,
            bool membersRefs,
            bool notesRefs,
            bool frontSessionsRefs,
            bool importRecordsRefs,
          })
        > {
  $$PluralSystemsTableTableManager(_$AppDatabase db, $PluralSystemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PluralSystemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PluralSystemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PluralSystemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PluralSystemsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PluralSystemsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PluralSystemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                systemGroupsRefs = false,
                membersRefs = false,
                notesRefs = false,
                frontSessionsRefs = false,
                importRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (systemGroupsRefs) db.systemGroups,
                    if (membersRefs) db.members,
                    if (notesRefs) db.notes,
                    if (frontSessionsRefs) db.frontSessions,
                    if (importRecordsRefs) db.importRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (systemGroupsRefs)
                        await $_getPrefetchedData<
                          PluralSystem,
                          $PluralSystemsTable,
                          SystemGroup
                        >(
                          currentTable: table,
                          referencedTable: $$PluralSystemsTableReferences
                              ._systemGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PluralSystemsTableReferences(
                                db,
                                table,
                                p0,
                              ).systemGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.systemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (membersRefs)
                        await $_getPrefetchedData<
                          PluralSystem,
                          $PluralSystemsTable,
                          Member
                        >(
                          currentTable: table,
                          referencedTable: $$PluralSystemsTableReferences
                              ._membersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PluralSystemsTableReferences(
                                db,
                                table,
                                p0,
                              ).membersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.systemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notesRefs)
                        await $_getPrefetchedData<
                          PluralSystem,
                          $PluralSystemsTable,
                          Note
                        >(
                          currentTable: table,
                          referencedTable: $$PluralSystemsTableReferences
                              ._notesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PluralSystemsTableReferences(
                                db,
                                table,
                                p0,
                              ).notesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.systemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (frontSessionsRefs)
                        await $_getPrefetchedData<
                          PluralSystem,
                          $PluralSystemsTable,
                          FrontSession
                        >(
                          currentTable: table,
                          referencedTable: $$PluralSystemsTableReferences
                              ._frontSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PluralSystemsTableReferences(
                                db,
                                table,
                                p0,
                              ).frontSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.systemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (importRecordsRefs)
                        await $_getPrefetchedData<
                          PluralSystem,
                          $PluralSystemsTable,
                          ImportRecord
                        >(
                          currentTable: table,
                          referencedTable: $$PluralSystemsTableReferences
                              ._importRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PluralSystemsTableReferences(
                                db,
                                table,
                                p0,
                              ).importRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.systemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PluralSystemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PluralSystemsTable,
      PluralSystem,
      $$PluralSystemsTableFilterComposer,
      $$PluralSystemsTableOrderingComposer,
      $$PluralSystemsTableAnnotationComposer,
      $$PluralSystemsTableCreateCompanionBuilder,
      $$PluralSystemsTableUpdateCompanionBuilder,
      (PluralSystem, $$PluralSystemsTableReferences),
      PluralSystem,
      PrefetchHooks Function({
        bool systemGroupsRefs,
        bool membersRefs,
        bool notesRefs,
        bool frontSessionsRefs,
        bool importRecordsRefs,
      })
    >;
typedef $$SystemGroupsTableCreateCompanionBuilder =
    SystemGroupsCompanion Function({
      required String id,
      required String systemId,
      Value<String?> parentGroupId,
      required String name,
      Value<String?> colorHex,
      Value<String?> description,
      Value<String?> emoji,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SystemGroupsTableUpdateCompanionBuilder =
    SystemGroupsCompanion Function({
      Value<String> id,
      Value<String> systemId,
      Value<String?> parentGroupId,
      Value<String> name,
      Value<String?> colorHex,
      Value<String?> description,
      Value<String?> emoji,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SystemGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $SystemGroupsTable, SystemGroup> {
  $$SystemGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PluralSystemsTable _systemIdTable(_$AppDatabase db) => db
      .pluralSystems
      .createAlias('system_groups__system_id__plural_systems__id');

  $$PluralSystemsTableProcessedTableManager get systemId {
    final $_column = $_itemColumn<String>('system_id')!;

    final manager = $$PluralSystemsTableTableManager(
      $_db,
      $_db.pluralSystems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_systemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SystemGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $SystemGroupsTable> {
  $$SystemGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentGroupId => $composableBuilder(
    column: $table.parentGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PluralSystemsTableFilterComposer get systemId {
    final $$PluralSystemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableFilterComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SystemGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $SystemGroupsTable> {
  $$SystemGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentGroupId => $composableBuilder(
    column: $table.parentGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PluralSystemsTableOrderingComposer get systemId {
    final $$PluralSystemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableOrderingComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SystemGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SystemGroupsTable> {
  $$SystemGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentGroupId => $composableBuilder(
    column: $table.parentGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PluralSystemsTableAnnotationComposer get systemId {
    final $$PluralSystemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableAnnotationComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SystemGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SystemGroupsTable,
          SystemGroup,
          $$SystemGroupsTableFilterComposer,
          $$SystemGroupsTableOrderingComposer,
          $$SystemGroupsTableAnnotationComposer,
          $$SystemGroupsTableCreateCompanionBuilder,
          $$SystemGroupsTableUpdateCompanionBuilder,
          (SystemGroup, $$SystemGroupsTableReferences),
          SystemGroup,
          PrefetchHooks Function({bool systemId})
        > {
  $$SystemGroupsTableTableManager(_$AppDatabase db, $SystemGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SystemGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SystemGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SystemGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> systemId = const Value.absent(),
                Value<String?> parentGroupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SystemGroupsCompanion(
                id: id,
                systemId: systemId,
                parentGroupId: parentGroupId,
                name: name,
                colorHex: colorHex,
                description: description,
                emoji: emoji,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String systemId,
                Value<String?> parentGroupId = const Value.absent(),
                required String name,
                Value<String?> colorHex = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SystemGroupsCompanion.insert(
                id: id,
                systemId: systemId,
                parentGroupId: parentGroupId,
                name: name,
                colorHex: colorHex,
                description: description,
                emoji: emoji,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SystemGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({systemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (systemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.systemId,
                                referencedTable: $$SystemGroupsTableReferences
                                    ._systemIdTable(db),
                                referencedColumn: $$SystemGroupsTableReferences
                                    ._systemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SystemGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SystemGroupsTable,
      SystemGroup,
      $$SystemGroupsTableFilterComposer,
      $$SystemGroupsTableOrderingComposer,
      $$SystemGroupsTableAnnotationComposer,
      $$SystemGroupsTableCreateCompanionBuilder,
      $$SystemGroupsTableUpdateCompanionBuilder,
      (SystemGroup, $$SystemGroupsTableReferences),
      SystemGroup,
      PrefetchHooks Function({bool systemId})
    >;
typedef $$MembersTableCreateCompanionBuilder =
    MembersCompanion Function({
      required String id,
      required String systemId,
      required String displayName,
      Value<String?> pronouns,
      Value<String?> colorHex,
      Value<String?> folderId,
      Value<String?> description,
      Value<String?> avatarUrl,
      Value<String?> pluralKitId,
      Value<bool> archived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MembersTableUpdateCompanionBuilder =
    MembersCompanion Function({
      Value<String> id,
      Value<String> systemId,
      Value<String> displayName,
      Value<String?> pronouns,
      Value<String?> colorHex,
      Value<String?> folderId,
      Value<String?> description,
      Value<String?> avatarUrl,
      Value<String?> pluralKitId,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MembersTableReferences
    extends BaseReferences<_$AppDatabase, $MembersTable, Member> {
  $$MembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PluralSystemsTable _systemIdTable(_$AppDatabase db) =>
      db.pluralSystems.createAlias('members__system_id__plural_systems__id');

  $$PluralSystemsTableProcessedTableManager get systemId {
    final $_column = $_itemColumn<String>('system_id')!;

    final manager = $$PluralSystemsTableTableManager(
      $_db,
      $_db.pluralSystems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_systemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $FrontSessionMembersTable,
    List<FrontSessionMember>
  >
  _frontSessionMembersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.frontSessionMembers,
        aliasName: 'members__id__front_session_members__member_id',
      );

  $$FrontSessionMembersTableProcessedTableManager get frontSessionMembersRefs {
    final manager = $$FrontSessionMembersTableTableManager(
      $_db,
      $_db.frontSessionMembers,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _frontSessionMembersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pronouns => $composableBuilder(
    column: $table.pronouns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluralKitId => $composableBuilder(
    column: $table.pluralKitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PluralSystemsTableFilterComposer get systemId {
    final $$PluralSystemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableFilterComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> frontSessionMembersRefs(
    Expression<bool> Function($$FrontSessionMembersTableFilterComposer f) f,
  ) {
    final $$FrontSessionMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frontSessionMembers,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrontSessionMembersTableFilterComposer(
            $db: $db,
            $table: $db.frontSessionMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pronouns => $composableBuilder(
    column: $table.pronouns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluralKitId => $composableBuilder(
    column: $table.pluralKitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PluralSystemsTableOrderingComposer get systemId {
    final $$PluralSystemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableOrderingComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pronouns =>
      $composableBuilder(column: $table.pronouns, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get pluralKitId => $composableBuilder(
    column: $table.pluralKitId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PluralSystemsTableAnnotationComposer get systemId {
    final $$PluralSystemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableAnnotationComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> frontSessionMembersRefs<T extends Object>(
    Expression<T> Function($$FrontSessionMembersTableAnnotationComposer a) f,
  ) {
    final $$FrontSessionMembersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.frontSessionMembers,
          getReferencedColumn: (t) => t.memberId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FrontSessionMembersTableAnnotationComposer(
                $db: $db,
                $table: $db.frontSessionMembers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          Member,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (Member, $$MembersTableReferences),
          Member,
          PrefetchHooks Function({bool systemId, bool frontSessionMembersRefs})
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> systemId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> pronouns = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> pluralKitId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                id: id,
                systemId: systemId,
                displayName: displayName,
                pronouns: pronouns,
                colorHex: colorHex,
                folderId: folderId,
                description: description,
                avatarUrl: avatarUrl,
                pluralKitId: pluralKitId,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String systemId,
                required String displayName,
                Value<String?> pronouns = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> pluralKitId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                id: id,
                systemId: systemId,
                displayName: displayName,
                pronouns: pronouns,
                colorHex: colorHex,
                folderId: folderId,
                description: description,
                avatarUrl: avatarUrl,
                pluralKitId: pluralKitId,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({systemId = false, frontSessionMembersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (frontSessionMembersRefs) db.frontSessionMembers,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (systemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.systemId,
                                    referencedTable: $$MembersTableReferences
                                        ._systemIdTable(db),
                                    referencedColumn: $$MembersTableReferences
                                        ._systemIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (frontSessionMembersRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          FrontSessionMember
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._frontSessionMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).frontSessionMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      Member,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (Member, $$MembersTableReferences),
      Member,
      PrefetchHooks Function({bool systemId, bool frontSessionMembersRefs})
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String id,
      required String systemId,
      Value<String?> memberId,
      required String title,
      required String body,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String> systemId,
      Value<String?> memberId,
      Value<String> title,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, Note> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PluralSystemsTable _systemIdTable(_$AppDatabase db) =>
      db.pluralSystems.createAlias('notes__system_id__plural_systems__id');

  $$PluralSystemsTableProcessedTableManager get systemId {
    final $_column = $_itemColumn<String>('system_id')!;

    final manager = $$PluralSystemsTableTableManager(
      $_db,
      $_db.pluralSystems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_systemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PluralSystemsTableFilterComposer get systemId {
    final $$PluralSystemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableFilterComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PluralSystemsTableOrderingComposer get systemId {
    final $$PluralSystemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableOrderingComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PluralSystemsTableAnnotationComposer get systemId {
    final $$PluralSystemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableAnnotationComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, $$NotesTableReferences),
          Note,
          PrefetchHooks Function({bool systemId})
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> systemId = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                systemId: systemId,
                memberId: memberId,
                title: title,
                body: body,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String systemId,
                Value<String?> memberId = const Value.absent(),
                required String title,
                required String body,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                systemId: systemId,
                memberId: memberId,
                title: title,
                body: body,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$NotesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({systemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (systemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.systemId,
                                referencedTable: $$NotesTableReferences
                                    ._systemIdTable(db),
                                referencedColumn: $$NotesTableReferences
                                    ._systemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, $$NotesTableReferences),
      Note,
      PrefetchHooks Function({bool systemId})
    >;
typedef $$FrontSessionsTableCreateCompanionBuilder =
    FrontSessionsCompanion Function({
      required String id,
      required String systemId,
      Value<String?> label,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FrontSessionsTableUpdateCompanionBuilder =
    FrontSessionsCompanion Function({
      Value<String> id,
      Value<String> systemId,
      Value<String?> label,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FrontSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $FrontSessionsTable, FrontSession> {
  $$FrontSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PluralSystemsTable _systemIdTable(_$AppDatabase db) => db
      .pluralSystems
      .createAlias('front_sessions__system_id__plural_systems__id');

  $$PluralSystemsTableProcessedTableManager get systemId {
    final $_column = $_itemColumn<String>('system_id')!;

    final manager = $$PluralSystemsTableTableManager(
      $_db,
      $_db.pluralSystems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_systemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $FrontSessionMembersTable,
    List<FrontSessionMember>
  >
  _frontSessionMembersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.frontSessionMembers,
        aliasName: 'front_sessions__id__front_session_members__session_id',
      );

  $$FrontSessionMembersTableProcessedTableManager get frontSessionMembersRefs {
    final manager = $$FrontSessionMembersTableTableManager(
      $_db,
      $_db.frontSessionMembers,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _frontSessionMembersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FrontSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $FrontSessionsTable> {
  $$FrontSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PluralSystemsTableFilterComposer get systemId {
    final $$PluralSystemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableFilterComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> frontSessionMembersRefs(
    Expression<bool> Function($$FrontSessionMembersTableFilterComposer f) f,
  ) {
    final $$FrontSessionMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frontSessionMembers,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrontSessionMembersTableFilterComposer(
            $db: $db,
            $table: $db.frontSessionMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FrontSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FrontSessionsTable> {
  $$FrontSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PluralSystemsTableOrderingComposer get systemId {
    final $$PluralSystemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableOrderingComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrontSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FrontSessionsTable> {
  $$FrontSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PluralSystemsTableAnnotationComposer get systemId {
    final $$PluralSystemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableAnnotationComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> frontSessionMembersRefs<T extends Object>(
    Expression<T> Function($$FrontSessionMembersTableAnnotationComposer a) f,
  ) {
    final $$FrontSessionMembersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.frontSessionMembers,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FrontSessionMembersTableAnnotationComposer(
                $db: $db,
                $table: $db.frontSessionMembers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FrontSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FrontSessionsTable,
          FrontSession,
          $$FrontSessionsTableFilterComposer,
          $$FrontSessionsTableOrderingComposer,
          $$FrontSessionsTableAnnotationComposer,
          $$FrontSessionsTableCreateCompanionBuilder,
          $$FrontSessionsTableUpdateCompanionBuilder,
          (FrontSession, $$FrontSessionsTableReferences),
          FrontSession,
          PrefetchHooks Function({bool systemId, bool frontSessionMembersRefs})
        > {
  $$FrontSessionsTableTableManager(_$AppDatabase db, $FrontSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrontSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrontSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FrontSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> systemId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FrontSessionsCompanion(
                id: id,
                systemId: systemId,
                label: label,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String systemId,
                Value<String?> label = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FrontSessionsCompanion.insert(
                id: id,
                systemId: systemId,
                label: label,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FrontSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({systemId = false, frontSessionMembersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (frontSessionMembersRefs) db.frontSessionMembers,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (systemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.systemId,
                                    referencedTable:
                                        $$FrontSessionsTableReferences
                                            ._systemIdTable(db),
                                    referencedColumn:
                                        $$FrontSessionsTableReferences
                                            ._systemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (frontSessionMembersRefs)
                        await $_getPrefetchedData<
                          FrontSession,
                          $FrontSessionsTable,
                          FrontSessionMember
                        >(
                          currentTable: table,
                          referencedTable: $$FrontSessionsTableReferences
                              ._frontSessionMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FrontSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).frontSessionMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FrontSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FrontSessionsTable,
      FrontSession,
      $$FrontSessionsTableFilterComposer,
      $$FrontSessionsTableOrderingComposer,
      $$FrontSessionsTableAnnotationComposer,
      $$FrontSessionsTableCreateCompanionBuilder,
      $$FrontSessionsTableUpdateCompanionBuilder,
      (FrontSession, $$FrontSessionsTableReferences),
      FrontSession,
      PrefetchHooks Function({bool systemId, bool frontSessionMembersRefs})
    >;
typedef $$FrontSessionMembersTableCreateCompanionBuilder =
    FrontSessionMembersCompanion Function({
      required String sessionId,
      required String memberId,
      Value<int> rowid,
    });
typedef $$FrontSessionMembersTableUpdateCompanionBuilder =
    FrontSessionMembersCompanion Function({
      Value<String> sessionId,
      Value<String> memberId,
      Value<int> rowid,
    });

final class $$FrontSessionMembersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FrontSessionMembersTable,
          FrontSessionMember
        > {
  $$FrontSessionMembersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FrontSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .frontSessions
      .createAlias('front_session_members__session_id__front_sessions__id');

  $$FrontSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$FrontSessionsTableTableManager(
      $_db,
      $_db.frontSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('front_session_members__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FrontSessionMembersTableFilterComposer
    extends Composer<_$AppDatabase, $FrontSessionMembersTable> {
  $$FrontSessionMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$FrontSessionsTableFilterComposer get sessionId {
    final $$FrontSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.frontSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrontSessionsTableFilterComposer(
            $db: $db,
            $table: $db.frontSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrontSessionMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $FrontSessionMembersTable> {
  $$FrontSessionMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$FrontSessionsTableOrderingComposer get sessionId {
    final $$FrontSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.frontSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrontSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.frontSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrontSessionMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FrontSessionMembersTable> {
  $$FrontSessionMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$FrontSessionsTableAnnotationComposer get sessionId {
    final $$FrontSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.frontSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrontSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.frontSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrontSessionMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FrontSessionMembersTable,
          FrontSessionMember,
          $$FrontSessionMembersTableFilterComposer,
          $$FrontSessionMembersTableOrderingComposer,
          $$FrontSessionMembersTableAnnotationComposer,
          $$FrontSessionMembersTableCreateCompanionBuilder,
          $$FrontSessionMembersTableUpdateCompanionBuilder,
          (FrontSessionMember, $$FrontSessionMembersTableReferences),
          FrontSessionMember,
          PrefetchHooks Function({bool sessionId, bool memberId})
        > {
  $$FrontSessionMembersTableTableManager(
    _$AppDatabase db,
    $FrontSessionMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrontSessionMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrontSessionMembersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FrontSessionMembersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FrontSessionMembersCompanion(
                sessionId: sessionId,
                memberId: memberId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String memberId,
                Value<int> rowid = const Value.absent(),
              }) => FrontSessionMembersCompanion.insert(
                sessionId: sessionId,
                memberId: memberId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FrontSessionMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$FrontSessionMembersTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$FrontSessionMembersTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable:
                                    $$FrontSessionMembersTableReferences
                                        ._memberIdTable(db),
                                referencedColumn:
                                    $$FrontSessionMembersTableReferences
                                        ._memberIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FrontSessionMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FrontSessionMembersTable,
      FrontSessionMember,
      $$FrontSessionMembersTableFilterComposer,
      $$FrontSessionMembersTableOrderingComposer,
      $$FrontSessionMembersTableAnnotationComposer,
      $$FrontSessionMembersTableCreateCompanionBuilder,
      $$FrontSessionMembersTableUpdateCompanionBuilder,
      (FrontSessionMember, $$FrontSessionMembersTableReferences),
      FrontSessionMember,
      PrefetchHooks Function({bool sessionId, bool memberId})
    >;
typedef $$ImportRecordsTableCreateCompanionBuilder =
    ImportRecordsCompanion Function({
      required String id,
      required String systemId,
      required String source,
      Value<String?> fileName,
      Value<String?> summaryJson,
      required DateTime importedAt,
      Value<int> rowid,
    });
typedef $$ImportRecordsTableUpdateCompanionBuilder =
    ImportRecordsCompanion Function({
      Value<String> id,
      Value<String> systemId,
      Value<String> source,
      Value<String?> fileName,
      Value<String?> summaryJson,
      Value<DateTime> importedAt,
      Value<int> rowid,
    });

final class $$ImportRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $ImportRecordsTable, ImportRecord> {
  $$ImportRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PluralSystemsTable _systemIdTable(_$AppDatabase db) => db
      .pluralSystems
      .createAlias('import_records__system_id__plural_systems__id');

  $$PluralSystemsTableProcessedTableManager get systemId {
    final $_column = $_itemColumn<String>('system_id')!;

    final manager = $$PluralSystemsTableTableManager(
      $_db,
      $_db.pluralSystems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_systemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImportRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportRecordsTable> {
  $$ImportRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PluralSystemsTableFilterComposer get systemId {
    final $$PluralSystemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableFilterComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportRecordsTable> {
  $$ImportRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PluralSystemsTableOrderingComposer get systemId {
    final $$PluralSystemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableOrderingComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportRecordsTable> {
  $$ImportRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  $$PluralSystemsTableAnnotationComposer get systemId {
    final $$PluralSystemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.pluralSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PluralSystemsTableAnnotationComposer(
            $db: $db,
            $table: $db.pluralSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportRecordsTable,
          ImportRecord,
          $$ImportRecordsTableFilterComposer,
          $$ImportRecordsTableOrderingComposer,
          $$ImportRecordsTableAnnotationComposer,
          $$ImportRecordsTableCreateCompanionBuilder,
          $$ImportRecordsTableUpdateCompanionBuilder,
          (ImportRecord, $$ImportRecordsTableReferences),
          ImportRecord,
          PrefetchHooks Function({bool systemId})
        > {
  $$ImportRecordsTableTableManager(_$AppDatabase db, $ImportRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> systemId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportRecordsCompanion(
                id: id,
                systemId: systemId,
                source: source,
                fileName: fileName,
                summaryJson: summaryJson,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String systemId,
                required String source,
                Value<String?> fileName = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                required DateTime importedAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportRecordsCompanion.insert(
                id: id,
                systemId: systemId,
                source: source,
                fileName: fileName,
                summaryJson: summaryJson,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImportRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({systemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (systemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.systemId,
                                referencedTable: $$ImportRecordsTableReferences
                                    ._systemIdTable(db),
                                referencedColumn: $$ImportRecordsTableReferences
                                    ._systemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImportRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportRecordsTable,
      ImportRecord,
      $$ImportRecordsTableFilterComposer,
      $$ImportRecordsTableOrderingComposer,
      $$ImportRecordsTableAnnotationComposer,
      $$ImportRecordsTableCreateCompanionBuilder,
      $$ImportRecordsTableUpdateCompanionBuilder,
      (ImportRecord, $$ImportRecordsTableReferences),
      ImportRecord,
      PrefetchHooks Function({bool systemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PluralSystemsTableTableManager get pluralSystems =>
      $$PluralSystemsTableTableManager(_db, _db.pluralSystems);
  $$SystemGroupsTableTableManager get systemGroups =>
      $$SystemGroupsTableTableManager(_db, _db.systemGroups);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$FrontSessionsTableTableManager get frontSessions =>
      $$FrontSessionsTableTableManager(_db, _db.frontSessions);
  $$FrontSessionMembersTableTableManager get frontSessionMembers =>
      $$FrontSessionMembersTableTableManager(_db, _db.frontSessionMembers);
  $$ImportRecordsTableTableManager get importRecords =>
      $$ImportRecordsTableTableManager(_db, _db.importRecords);
}
