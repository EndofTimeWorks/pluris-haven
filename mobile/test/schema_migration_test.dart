// Tests that AppDatabase.migration.onUpgrade correctly brings a real,
// historical-shaped SQLite file up to the current schema (schemaVersion 20).
//
// There are no captured drift schema snapshots for old versions of this app,
// so there is no version-by-version JSON to diff against. Instead, the
// historical shape of each schema version is reconstructed mechanically from
// onUpgrade itself: `migrator.createTable(x)` and `migrator.addColumn(t, c)`
// always operate against the CURRENT (v20) Dart column/table definition, so
// "what did version N look like" is exactly "the current table/column set,
// minus everything added by an `if (from < M)` block for M > N". That
// subtraction is done by hand below (see the comments next to each raw
// CREATE TABLE), and cross-checked against lib/data/local/app_database.dart.
//
// Each test builds a raw SQLite file with only the tables/columns that
// existed at some historical version, stamps `PRAGMA user_version` to that
// version, closes it, then reopens the SAME file with the real,
// unmodified `AppDatabase` class. Opening triggers the real
// `onUpgrade(migrator, from, 19)` path end-to-end.
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Creates a raw SQLite file at [path], executes [statements] to build a
/// historical schema shape, and stamps `PRAGMA user_version` to [version].
void _seedLegacyDatabase({
  required String path,
  required int version,
  required List<String> statements,
}) {
  final raw = sqlite3.sqlite3.open(path);
  try {
    for (final statement in statements) {
      raw.execute(statement);
    }
    raw.userVersion = version;
  } finally {
    raw.close();
  }
}

Future<Object?> _value(
  AppDatabase database,
  String query,
  String column,
) async {
  final row = await database.customSelect(query).getSingle();
  return row.data[column];
}

const _performanceIndexNames = [
  'members_list_order',
  'group_members_member_id',
  'front_sessions_history_order',
  'front_sessions_current',
  'named_fronts_system_order',
];

Future<Iterable<String>> _indexNames(AppDatabase database) async {
  final rows = await database
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
      .get();
  return rows.map((row) => row.read<String>('name'));
}

/// Version-1 schema: the tables that were never touched by any
/// `migrator.createTable` call in onUpgrade (so they must predate it), each
/// stripped of every column added later by `migrator.addColumn`.
List<String> _v1Statements() => [
  '''
  CREATE TABLE plural_systems (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // color_hex/avatar_url/description added at v14
  '''
  CREATE TABLE system_groups (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    parent_group_id TEXT,
    name TEXT NOT NULL,
    color_hex TEXT,
    description TEXT,
    emoji TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // is_subsystem added at v13
  '''
  CREATE TABLE members (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    display_name TEXT NOT NULL,
    pronouns TEXT,
    color_hex TEXT,
    folder_id TEXT,
    description TEXT,
    avatar_url TEXT,
    plural_kit_id TEXT,
    archived INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // is_custom_front(v7), display_name_hash/frame_shape/lexo_rank(v8),
  // birthday/emoji/privacy(v11), profile_encryption_version(v17) added later
  '''
  CREATE TABLE notes (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    member_id TEXT,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // never touched by onUpgrade
  '''
  CREATE TABLE front_sessions (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    label TEXT,
    started_at INTEGER NOT NULL,
    ended_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // status_note added at v10
  '''
  CREATE TABLE front_session_members (
    session_id TEXT NOT NULL,
    member_id TEXT NOT NULL,
    PRIMARY KEY (session_id, member_id)
  )
  ''', // never touched by onUpgrade
  '''
  CREATE TABLE import_records (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    source TEXT NOT NULL,
    file_name TEXT,
    summary_json TEXT,
    imported_at INTEGER NOT NULL
  )
  ''', // never touched by onUpgrade
];

/// Version-8 schema: everything present right after the largest single
/// migration step (`if (from < 8)`), which adds ~9 new tables and many
/// columns across several existing tables. Built the same way: current
/// column set minus everything added by a `from < M` block where M > 8.
List<String> _v8Statements() => [
  '''
  CREATE TABLE plural_systems (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // color_hex/avatar_url/description still not added until v14
  '''
  CREATE TABLE system_groups (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    parent_group_id TEXT,
    name TEXT NOT NULL,
    color_hex TEXT,
    description TEXT,
    emoji TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // is_subsystem still not added until v13
  '''
  CREATE TABLE members (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    display_name TEXT NOT NULL,
    display_name_hash TEXT,
    pronouns TEXT,
    color_hex TEXT,
    folder_id TEXT,
    description TEXT,
    avatar_url TEXT,
    plural_kit_id TEXT,
    frame_shape TEXT NOT NULL DEFAULT 'circle',
    lexo_rank TEXT NOT NULL DEFAULT '0|zzzzzz',
    is_custom_front INTEGER NOT NULL DEFAULT 0,
    archived INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // birthday/emoji/privacy(v11), profile_encryption_version(v17) not yet
  '''
  CREATE TABLE notes (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    member_id TEXT,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE front_sessions (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    label TEXT,
    started_at INTEGER NOT NULL,
    ended_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // status_note still not added until v10
  '''
  CREATE TABLE front_session_members (
    session_id TEXT NOT NULL,
    member_id TEXT NOT NULL,
    PRIMARY KEY (session_id, member_id)
  )
  ''',
  '''
  CREATE TABLE import_records (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    source TEXT NOT NULL,
    file_name TEXT,
    summary_json TEXT,
    imported_at INTEGER NOT NULL
  )
  ''',
  // -- created at v2 --
  '''
  CREATE TABLE app_preferences (
    "key" TEXT NOT NULL PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  // -- created at v3 --
  '''
  CREATE TABLE messages (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    member_id TEXT,
    body TEXT NOT NULL,
    board_kind TEXT NOT NULL DEFAULT 'system',
    board_member_id TEXT,
    parent_message_id TEXT,
    deleted_at INTEGER,
    archived INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // channel_id added at v16, not yet present
  '''
  CREATE TABLE reminders (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    schedule_text TEXT NOT NULL,
    trigger_type TEXT NOT NULL DEFAULT 'repeated',
    trigger_member_id TEXT,
    trigger_event TEXT,
    delay_seconds INTEGER,
    schedule_kind TEXT,
    schedule_time TEXT,
    schedule_dow_mask INTEGER,
    schedule_dom INTEGER,
    enabled INTEGER NOT NULL DEFAULT 1,
    last_fired_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE notification_events (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    kind TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    read_at INTEGER,
    created_at INTEGER NOT NULL
  )
  ''',
  // -- created at v4 --
  '''
  CREATE TABLE import_payloads (
    id TEXT NOT NULL PRIMARY KEY,
    import_record_id TEXT NOT NULL,
    system_id TEXT NOT NULL,
    source TEXT NOT NULL,
    collection TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    imported_at INTEGER NOT NULL
  )
  ''',
  // -- created at v5 --
  '''
  CREATE TABLE background_jobs (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    type TEXT NOT NULL,
    status TEXT NOT NULL,
    source TEXT,
    file_name TEXT,
    payload_json TEXT NOT NULL,
    error TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    started_at INTEGER,
    finished_at INTEGER
  )
  ''',
  // -- created at v6 --
  '''
  CREATE TABLE polls (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    question TEXT NOT NULL,
    description TEXT,
    kind TEXT NOT NULL DEFAULT 'single_choice',
    restrict_voting_to_fronters INTEGER NOT NULL DEFAULT 0,
    closes_at INTEGER,
    retention_days INTEGER,
    closed INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE poll_options (
    id TEXT NOT NULL PRIMARY KEY,
    poll_id TEXT NOT NULL,
    body TEXT NOT NULL,
    "position" INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE poll_votes (
    poll_id TEXT NOT NULL,
    option_id TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (poll_id, option_id)
  )
  ''',
  // -- created at v7 --
  '''
  CREATE TABLE custom_field_definitions (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    name TEXT NOT NULL,
    field_type TEXT NOT NULL DEFAULT 'text',
    privacy TEXT,
    "position" INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE custom_field_values (
    id TEXT NOT NULL PRIMARY KEY,
    field_id TEXT NOT NULL,
    member_id TEXT,
    value TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  // -- created at v8 --
  '''
  CREATE TABLE tags (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    name TEXT NOT NULL,
    color_hex TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE member_tags (
    tag_id TEXT NOT NULL,
    member_id TEXT NOT NULL,
    PRIMARY KEY (tag_id, member_id)
  )
  ''',
  '''
  CREATE TABLE journal_entries (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    member_id TEXT,
    title TEXT,
    body TEXT NOT NULL,
    visibility TEXT NOT NULL DEFAULT 'system',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE content_revisions (
    id TEXT NOT NULL PRIMARY KEY,
    target_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    title TEXT,
    body TEXT NOT NULL,
    pinned_at INTEGER,
    created_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE front_audit_events (
    id TEXT NOT NULL PRIMARY KEY,
    front_id TEXT NOT NULL,
    before_snapshot TEXT,
    after_snapshot TEXT,
    created_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE poll_vote_events (
    id TEXT NOT NULL PRIMARY KEY,
    poll_id TEXT NOT NULL,
    option_id TEXT NOT NULL,
    action TEXT NOT NULL,
    created_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE pending_actions (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    action_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    target_label TEXT,
    finalize_after INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    cancelled_at INTEGER,
    completed_at INTEGER,
    created_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE named_fronts (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    name TEXT NOT NULL,
    custom_label TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''', // color_hex/avatar_url/description added at v9, not yet present
  '''
  CREATE TABLE named_front_members (
    named_front_id TEXT NOT NULL,
    member_id TEXT NOT NULL,
    PRIMARY KEY (named_front_id, member_id)
  )
  ''',
];

/// Version 3 is the first schema with messages, reminders, and notification
/// events. These tables had not yet received their structured v8 columns.
List<String> _v3Statements() => [
  ..._v1Statements(),
  '''
  CREATE TABLE app_preferences (
    "key" TEXT NOT NULL PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE messages (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    member_id TEXT,
    body TEXT NOT NULL,
    archived INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE reminders (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    schedule_text TEXT NOT NULL,
    enabled INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE notification_events (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    kind TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    read_at INTEGER,
    created_at INTEGER NOT NULL
  )
  ''',
];

/// Version 12 follows the member/profile and front-status shape changes and
/// introduces the many-to-many group membership table.
List<String> _v12Statements() => [
  ..._v8Statements(),
  'ALTER TABLE named_fronts ADD COLUMN color_hex TEXT',
  'ALTER TABLE named_fronts ADD COLUMN avatar_url TEXT',
  'ALTER TABLE named_fronts ADD COLUMN description TEXT',
  'ALTER TABLE front_sessions ADD COLUMN status_note TEXT',
  'ALTER TABLE members ADD COLUMN birthday TEXT',
  'ALTER TABLE members ADD COLUMN emoji TEXT',
  'ALTER TABLE members ADD COLUMN privacy TEXT',
  '''
  CREATE TABLE group_members (
    group_id TEXT NOT NULL,
    member_id TEXT NOT NULL,
    PRIMARY KEY (group_id, member_id)
  )
  ''',
];

/// Version 16 is the final pre-v17 shape. The remaining migrations should
/// add members.profile_encryption_version without disturbing chat or privacy
/// relationships.
List<String> _v16Statements() => [
  ..._v12Statements(),
  'ALTER TABLE system_groups ADD COLUMN is_subsystem INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE plural_systems ADD COLUMN color_hex TEXT',
  'ALTER TABLE plural_systems ADD COLUMN avatar_url TEXT',
  'ALTER TABLE plural_systems ADD COLUMN description TEXT',
  '''
  CREATE TABLE privacy_buckets (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    color_hex TEXT,
    "position" INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE privacy_bucket_members (
    bucket_id TEXT NOT NULL,
    member_id TEXT NOT NULL,
    PRIMARY KEY (bucket_id, member_id)
  )
  ''',
  '''
  CREATE TABLE chat_categories (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    color_hex TEXT,
    "position" INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE chat_channels (
    id TEXT NOT NULL PRIMARY KEY,
    system_id TEXT NOT NULL,
    category_id TEXT,
    name TEXT NOT NULL,
    description TEXT,
    color_hex TEXT,
    "position" INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  'ALTER TABLE messages ADD COLUMN channel_id TEXT',
];

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('schema_migration_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('creates performance indexes on a fresh database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.customSelect('SELECT 1').getSingle();

    expect(await _indexNames(database), containsAll(_performanceIndexNames));
  });

  test('migrates a version-1 database up to the current schema (v20)', () async {
    final dbPath = '${tempDir.path}/legacy_v1.sqlite';
    _seedLegacyDatabase(path: dbPath, version: 1, statements: _v1Statements());

    final database = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(database.close);

    // Merely opening the database runs onUpgrade(1, 20); this must not throw.
    await database.customSelect('SELECT 1').getSingle();

    // v8: displayNameHash / frameShape / lexoRank on members.
    await database
        .customSelect(
          'SELECT display_name_hash, frame_shape, lexo_rank FROM members LIMIT 0',
        )
        .get();

    // v7: custom_field_definitions table.
    await database
        .customSelect(
          'SELECT id, name, field_type, configuration '
          'FROM custom_field_definitions LIMIT 0',
        )
        .get();

    // v6: polls / poll_options / poll_votes tables.
    await database.customSelect('SELECT id, question FROM polls LIMIT 0').get();
    await database
        .customSelect('SELECT id, poll_id, body FROM poll_options LIMIT 0')
        .get();
    await database
        .customSelect('SELECT poll_id, option_id FROM poll_votes LIMIT 0')
        .get();

    // v17: profile_encryption_version on members.
    await database
        .customSelect('SELECT profile_encryption_version FROM members LIMIT 0')
        .get();

    expect(await _indexNames(database), containsAll(_performanceIndexNames));

    // v16: chat_categories / chat_channels tables + messages.channel_id.
    await database
        .customSelect('SELECT id, name FROM chat_categories LIMIT 0')
        .get();
    await database
        .customSelect('SELECT id, category_id, name FROM chat_channels LIMIT 0')
        .get();
    await database
        .customSelect('SELECT channel_id FROM messages LIMIT 0')
        .get();

    // v15: privacy_buckets / privacy_bucket_members tables.
    await database
        .customSelect('SELECT id, name FROM privacy_buckets LIMIT 0')
        .get();
    await database
        .customSelect(
          'SELECT bucket_id, member_id FROM privacy_bucket_members LIMIT 0',
        )
        .get();

    // v14: color_hex / avatar_url / description on plural_systems.
    await database
        .customSelect(
          'SELECT color_hex, avatar_url, description FROM plural_systems LIMIT 0',
        )
        .get();

    // v13: is_subsystem on system_groups.
    await database
        .customSelect('SELECT is_subsystem FROM system_groups LIMIT 0')
        .get();

    // v12: group_members table.
    await database
        .customSelect('SELECT group_id, member_id FROM group_members LIMIT 0')
        .get();

    // v11: birthday / emoji / privacy on members.
    await database
        .customSelect('SELECT birthday, emoji, privacy FROM members LIMIT 0')
        .get();

    // v10: status_note on front_sessions.
    await database
        .customSelect('SELECT status_note FROM front_sessions LIMIT 0')
        .get();

    // v9: color_hex / avatar_url / description on named_fronts.
    await database
        .customSelect(
          'SELECT color_hex, avatar_url, description FROM named_fronts LIMIT 0',
        )
        .get();

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], 20);
  });

  test('migrates a version-8 database (right after the largest migration '
      'step) up to the current schema (v20)', () async {
    final dbPath = '${tempDir.path}/legacy_v8.sqlite';
    _seedLegacyDatabase(path: dbPath, version: 8, statements: _v8Statements());

    final database = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(database.close);

    await database.customSelect('SELECT 1').getSingle();

    // v9-v20 columns/tables should all be present.
    await database
        .customSelect(
          'SELECT color_hex, avatar_url, description FROM named_fronts LIMIT 0',
        )
        .get();
    await database
        .customSelect('SELECT status_note FROM front_sessions LIMIT 0')
        .get();
    await database
        .customSelect('SELECT birthday, emoji, privacy FROM members LIMIT 0')
        .get();
    await database
        .customSelect('SELECT group_id, member_id FROM group_members LIMIT 0')
        .get();
    await database
        .customSelect('SELECT is_subsystem FROM system_groups LIMIT 0')
        .get();
    await database
        .customSelect(
          'SELECT color_hex, avatar_url, description FROM plural_systems LIMIT 0',
        )
        .get();
    await database
        .customSelect('SELECT id, name FROM privacy_buckets LIMIT 0')
        .get();
    await database
        .customSelect(
          'SELECT bucket_id, member_id FROM privacy_bucket_members LIMIT 0',
        )
        .get();
    await database
        .customSelect('SELECT id, name FROM chat_categories LIMIT 0')
        .get();
    await database
        .customSelect('SELECT id, category_id, name FROM chat_channels LIMIT 0')
        .get();
    await database
        .customSelect('SELECT channel_id FROM messages LIMIT 0')
        .get();
    await database
        .customSelect('SELECT profile_encryption_version FROM members LIMIT 0')
        .get();

    // v8 columns should still be intact (untouched by the remaining steps).
    await database
        .customSelect(
          'SELECT display_name_hash, frame_shape, lexo_rank FROM members LIMIT 0',
        )
        .get();
    await database
        .customSelect(
          'SELECT id, name, field_type, configuration '
          'FROM custom_field_definitions LIMIT 0',
        )
        .get();

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], 20);
  });

  test('a real row written before migration survives the v1 -> v20 upgrade '
      'and new columns read back with their schema defaults', () async {
    final dbPath = '${tempDir.path}/legacy_v1_data.sqlite';
    _seedLegacyDatabase(path: dbPath, version: 1, statements: _v1Statements());

    final seedRaw = sqlite3.sqlite3.open(dbPath);
    final nowMs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    seedRaw.execute(
      'INSERT INTO plural_systems (id, name, created_at, updated_at) '
      'VALUES (?, ?, ?, ?)',
      ['sys-1', 'Legacy System', nowMs, nowMs],
    );
    seedRaw.execute(
      'INSERT INTO members (id, system_id, display_name, created_at, '
      'updated_at) VALUES (?, ?, ?, ?, ?)',
      ['mem-1', 'sys-1', 'River', nowMs, nowMs],
    );
    seedRaw.close();

    final database = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(database.close);

    final member = await database
        .customSelect(
          'SELECT display_name, frame_shape, lexo_rank, is_custom_front, '
          'profile_encryption_version FROM members WHERE id = ?',
          variables: [Variable('mem-1')],
        )
        .getSingle();

    expect(member.data['display_name'], 'River');
    // frame_shape / lexo_rank were added via addColumn with withDefault(...),
    // so a pre-existing row must backfill to that default, not null.
    expect(member.data['frame_shape'], 'circle');
    expect(member.data['lexo_rank'], '0|zzzzzz');
    expect(member.data['is_custom_front'], 0);
    expect(member.data['profile_encryption_version'], 0);

    final memberColumns = await database
        .customSelect('PRAGMA table_info(members)')
        .get();
    final rankColumn = memberColumns.singleWhere(
      (column) => column.data['name'] == 'lexo_rank',
    );
    expect(rankColumn.data['dflt_value'], isNull);
  });

  test('v3 message and reminder rows survive their v8 shape expansion', () async {
    final dbPath = '${tempDir.path}/legacy_v3_data.sqlite';
    _seedLegacyDatabase(path: dbPath, version: 3, statements: _v3Statements());

    final raw = sqlite3.sqlite3.open(dbPath);
    const timestamp = 1723300000;
    try {
      raw.execute(
        'INSERT INTO plural_systems (id, name, created_at, updated_at) '
        'VALUES (?, ?, ?, ?)',
        ['sys-1', 'Legacy System', timestamp, timestamp],
      );
      raw.execute(
        'INSERT INTO members (id, system_id, display_name, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?)',
        ['mem-1', 'sys-1', 'River', timestamp, timestamp],
      );
      raw.execute(
        'INSERT INTO messages (id, system_id, member_id, body, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?, ?)',
        ['message-1', 'sys-1', 'mem-1', 'legacy message', timestamp, timestamp],
      );
      raw.execute(
        'INSERT INTO reminders (id, system_id, title, body, schedule_text, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'reminder-1',
          'sys-1',
          'Check in',
          'legacy reminder',
          'Daily',
          timestamp,
          timestamp,
        ],
      );
    } finally {
      raw.close();
    }

    final database = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(database.close);

    final message = await database
        .customSelect(
          "SELECT body, board_kind, channel_id FROM messages WHERE id = 'message-1'",
        )
        .getSingle();
    final reminder = await database
        .customSelect(
          "SELECT body, trigger_type, schedule_kind FROM reminders WHERE id = 'reminder-1'",
        )
        .getSingle();

    expect(message.data['body'], 'legacy message');
    expect(message.data['board_kind'], 'system');
    expect(message.data['channel_id'], isNull);
    expect(reminder.data['body'], 'legacy reminder');
    expect(reminder.data['trigger_type'], 'repeated');
    expect(reminder.data['schedule_kind'], isNull);
    expect(await _value(database, 'PRAGMA user_version', 'user_version'), 20);
  });

  test('v12 member, front, and group relationships survive to v20', () async {
    final dbPath = '${tempDir.path}/legacy_v12_data.sqlite';
    _seedLegacyDatabase(
      path: dbPath,
      version: 12,
      statements: _v12Statements(),
    );

    final raw = sqlite3.sqlite3.open(dbPath);
    const timestamp = 1723300000;
    try {
      raw.execute(
        'INSERT INTO plural_systems (id, name, created_at, updated_at) '
        'VALUES (?, ?, ?, ?)',
        ['sys-1', 'Legacy System', timestamp, timestamp],
      );
      raw.execute(
        'INSERT INTO system_groups (id, system_id, name, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
        ['group-1', 'sys-1', 'Caretakers', timestamp, timestamp],
      );
      raw.execute(
        'INSERT INTO members (id, system_id, display_name, birthday, emoji, '
        'privacy, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'mem-1',
          'sys-1',
          'River',
          '02-03',
          '🌊',
          'private',
          timestamp,
          timestamp,
        ],
      );
      raw.execute(
        'INSERT INTO group_members (group_id, member_id) VALUES (?, ?)',
        ['group-1', 'mem-1'],
      );
      raw.execute(
        'INSERT INTO front_sessions (id, system_id, label, status_note, '
        'started_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'front-1',
          'sys-1',
          'River front',
          'Grounded',
          timestamp,
          timestamp,
          timestamp,
        ],
      );
    } finally {
      raw.close();
    }

    final database = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(database.close);

    final member = await database
        .customSelect(
          "SELECT birthday, emoji, privacy, profile_encryption_version FROM members WHERE id = 'mem-1'",
        )
        .getSingle();
    expect(member.data['birthday'], '02-03');
    expect(member.data['emoji'], '🌊');
    expect(member.data['privacy'], 'private');
    expect(member.data['profile_encryption_version'], 0);
    expect(
      await _value(
        database,
        "SELECT COUNT(*) AS count FROM group_members WHERE group_id = 'group-1' AND member_id = 'mem-1'",
        'count',
      ),
      1,
    );
    expect(
      await _value(
        database,
        "SELECT status_note FROM front_sessions WHERE id = 'front-1'",
        'status_note',
      ),
      'Grounded',
    );
    expect(await _value(database, 'PRAGMA user_version', 'user_version'), 20);
  });

  test('v16 chat and privacy relationships survive the final migration', () async {
    final dbPath = '${tempDir.path}/legacy_v16_data.sqlite';
    _seedLegacyDatabase(
      path: dbPath,
      version: 16,
      statements: _v16Statements(),
    );

    final raw = sqlite3.sqlite3.open(dbPath);
    const timestamp = 1723300000;
    try {
      raw.execute(
        'INSERT INTO plural_systems (id, name, created_at, updated_at) '
        'VALUES (?, ?, ?, ?)',
        ['sys-1', 'Legacy System', timestamp, timestamp],
      );
      raw.execute(
        'INSERT INTO members (id, system_id, display_name, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?)',
        ['mem-1', 'sys-1', 'River', timestamp, timestamp],
      );
      raw.execute(
        'INSERT INTO privacy_buckets (id, system_id, name, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?)',
        ['bucket-1', 'sys-1', 'Trusted', timestamp, timestamp],
      );
      raw.execute(
        'INSERT INTO privacy_bucket_members (bucket_id, member_id) VALUES (?, ?)',
        ['bucket-1', 'mem-1'],
      );
      raw.execute(
        'INSERT INTO chat_categories (id, system_id, name, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?)',
        ['category-1', 'sys-1', 'Internal', timestamp, timestamp],
      );
      raw.execute(
        'INSERT INTO chat_channels (id, system_id, category_id, name, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
        ['channel-1', 'sys-1', 'category-1', 'Check-ins', timestamp, timestamp],
      );
      raw.execute(
        'INSERT INTO messages (id, system_id, body, channel_id, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?, ?)',
        [
          'message-1',
          'sys-1',
          'legacy channel message',
          'channel-1',
          timestamp,
          timestamp,
        ],
      );
    } finally {
      raw.close();
    }

    final database = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(database.close);

    expect(
      await _value(
        database,
        "SELECT channel_id FROM messages WHERE id = 'message-1'",
        'channel_id',
      ),
      'channel-1',
    );
    expect(
      await _value(
        database,
        "SELECT category_id FROM chat_channels WHERE id = 'channel-1'",
        'category_id',
      ),
      'category-1',
    );
    expect(
      await _value(
        database,
        "SELECT COUNT(*) AS count FROM privacy_bucket_members WHERE bucket_id = 'bucket-1' AND member_id = 'mem-1'",
        'count',
      ),
      1,
    );
    expect(
      await _value(
        database,
        "SELECT profile_encryption_version FROM members WHERE id = 'mem-1'",
        'profile_encryption_version',
      ),
      0,
    );
    expect(await _value(database, 'PRAGMA user_version', 'user_version'), 20);
  });

  test('private content survives the v8 -> v20 upgrade', () async {
    final dbPath = '${tempDir.path}/legacy_v8_private_data.sqlite';
    _seedLegacyDatabase(path: dbPath, version: 8, statements: _v8Statements());

    final seedRaw = sqlite3.sqlite3.open(dbPath);
    const timestamp = 1723300000;
    try {
      seedRaw.execute(
        'INSERT INTO plural_systems (id, name, created_at, updated_at) '
        'VALUES (?, ?, ?, ?)',
        ['sys-1', 'Legacy System', timestamp, timestamp],
      );
      seedRaw.execute(
        'INSERT INTO members (id, system_id, display_name, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?)',
        ['mem-1', 'sys-1', 'River', timestamp, timestamp],
      );
      seedRaw.execute(
        'INSERT INTO notes (id, system_id, member_id, title, body, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'note-1',
          'sys-1',
          'mem-1',
          'Legacy note',
          'note body',
          timestamp,
          timestamp,
        ],
      );
      seedRaw.execute(
        'INSERT INTO front_sessions (id, system_id, label, started_at, '
        'ended_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'front-1',
          'sys-1',
          'River front',
          timestamp,
          timestamp + 60,
          timestamp,
          timestamp,
        ],
      );
      seedRaw.execute(
        'INSERT INTO messages (id, system_id, member_id, body, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?, ?)',
        ['message-1', 'sys-1', 'mem-1', 'message body', timestamp, timestamp],
      );
      seedRaw.execute(
        'INSERT INTO reminders (id, system_id, title, body, schedule_text, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'reminder-1',
          'sys-1',
          'Check in',
          'reminder body',
          'daily',
          timestamp,
          timestamp,
        ],
      );
      seedRaw.execute(
        'INSERT INTO polls (id, system_id, question, description, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?, ?)',
        [
          'poll-1',
          'sys-1',
          'Legacy question?',
          'poll detail',
          timestamp,
          timestamp,
        ],
      );
      seedRaw.execute(
        'INSERT INTO poll_options (id, poll_id, body, "position") '
        'VALUES (?, ?, ?, ?)',
        ['option-1', 'poll-1', 'Yes', 0],
      );
      seedRaw.execute(
        'INSERT INTO poll_votes (poll_id, option_id, created_at) '
        'VALUES (?, ?, ?)',
        ['poll-1', 'option-1', timestamp],
      );
      seedRaw.execute(
        'INSERT INTO custom_field_definitions (id, system_id, name, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
        ['field-1', 'sys-1', 'Role', timestamp, timestamp],
      );
      seedRaw.execute(
        'INSERT INTO custom_field_values (id, field_id, member_id, value, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
        ['value-1', 'field-1', 'mem-1', 'Archivist', timestamp, timestamp],
      );
      seedRaw.execute(
        'INSERT INTO journal_entries (id, system_id, member_id, title, body, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'journal-1',
          'sys-1',
          'mem-1',
          'Legacy journal',
          'journal body',
          timestamp,
          timestamp,
        ],
      );
      seedRaw.execute(
        'INSERT INTO content_revisions (id, target_type, target_id, title, '
        'body, created_at) VALUES (?, ?, ?, ?, ?, ?)',
        [
          'revision-1',
          'note',
          'note-1',
          'Old note',
          'old note body',
          timestamp,
        ],
      );
      seedRaw.execute(
        'INSERT INTO front_audit_events (id, front_id, before_snapshot, '
        'after_snapshot, created_at) VALUES (?, ?, ?, ?, ?)',
        ['audit-1', 'front-1', '{"before":true}', '{"after":true}', timestamp],
      );
    } finally {
      seedRaw.close();
    }

    final database = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(database.close);

    Future<Object?> value(String query, String column) async {
      final row = await database.customSelect(query).getSingle();
      return row.data[column];
    }

    expect(
      await value("SELECT body FROM notes WHERE id = 'note-1'", 'body'),
      'note body',
    );
    expect(
      await value(
        "SELECT label FROM front_sessions WHERE id = 'front-1'",
        'label',
      ),
      'River front',
    );
    expect(
      await value("SELECT body FROM messages WHERE id = 'message-1'", 'body'),
      'message body',
    );
    expect(
      await value("SELECT body FROM reminders WHERE id = 'reminder-1'", 'body'),
      'reminder body',
    );
    expect(
      await value("SELECT question FROM polls WHERE id = 'poll-1'", 'question'),
      'Legacy question?',
    );
    expect(
      await value(
        "SELECT body FROM poll_options WHERE id = 'option-1'",
        'body',
      ),
      'Yes',
    );
    expect(
      await value(
        "SELECT COUNT(*) AS count FROM poll_votes WHERE poll_id = 'poll-1'",
        'count',
      ),
      1,
    );
    expect(
      await value(
        "SELECT value FROM custom_field_values WHERE id = 'value-1'",
        'value',
      ),
      'Archivist',
    );
    expect(
      await value(
        "SELECT body FROM journal_entries WHERE id = 'journal-1'",
        'body',
      ),
      'journal body',
    );
    expect(
      await value(
        "SELECT body FROM content_revisions WHERE id = 'revision-1'",
        'body',
      ),
      'old note body',
    );
    expect(
      await value(
        "SELECT after_snapshot FROM front_audit_events WHERE id = 'audit-1'",
        'after_snapshot',
      ),
      '{"after":true}',
    );
    expect(await value('PRAGMA user_version', 'user_version'), 20);
  });
}
