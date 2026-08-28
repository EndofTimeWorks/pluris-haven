import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_archive_mapper.dart';
import 'package:pluris_haven/data/import/import_file_decoder.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/data/security/haven_crypto.dart';

import 'test_repository.dart';

void main() {
  test('preserves extensible custom fields and typed values', () async {
    final sourceDatabase = AppDatabase(NativeDatabase.memory());
    final source = testRepository(sourceDatabase);
    await source.ensureLocalSystem();
    await source.saveCustomField(
      const CustomFieldDraft(
        name: 'Energy profile',
        fieldType: 'prism.slider',
        privacy: 'trusted',
        configuration: {'minimum': 0, 'maximum': 10, 'icon': 'battery'},
      ),
    );

    final field = (await source.watchCustomFields().first).single;
    expect(field.fieldType, 'prism.slider');
    expect(field.configuration['maximum'], 10);
    await source.setCustomFieldValue(
      fieldId: field.id,
      memberId: null,
      value: const {'value': 7, 'unit': 'levels'},
    );

    final stored = (await source.watchCustomFieldValues().first).single;
    expect(stored.value, const {'value': 7, 'unit': 'levels'});
    final rawField = await sourceDatabase
        .select(sourceDatabase.customFieldDefinitions)
        .getSingle();
    final rawValue = await sourceDatabase
        .select(sourceDatabase.customFieldValues)
        .getSingle();
    expect(rawField.configuration, isNot(contains('battery')));
    expect(rawValue.value, isNot(contains('levels')));

    final archive = await source.buildLocalArchiveJson();
    await sourceDatabase.close();
    final decoded = jsonDecode(archive) as Map<String, dynamic>;
    expect(
      (decoded['custom_fields'] as List).single['configuration'],
      containsPair('icon', 'battery'),
    );
    expect((decoded['custom_field_values'] as List).single['value'], const {
      'value': 7,
      'unit': 'levels',
    });

    final targetDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(targetDatabase.close);
    final target = testRepository(targetDatabase);
    await target.ensureLocalSystem();
    await target.importLocalArchiveJson(
      archive,
      fileName: 'custom-fields.json',
    );

    final restoredField = (await target.watchCustomFields().first).single;
    final restoredValue = (await target.watchCustomFieldValues().first).single;
    expect(restoredField.fieldType, 'prism.slider');
    expect(restoredField.configuration, field.configuration);
    expect(restoredValue.value, stored.value);
  });

  test('decrypts only scoped custom field values', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final crypto = _CountingHavenCrypto();
    final repository = LocalHavenRepository(database, crypto: crypto);
    await repository.ensureLocalSystem();

    await repository.saveMember(const MemberDraft(displayName: 'River'));
    await repository.saveMember(const MemberDraft(displayName: 'Juniper'));
    final members = await repository.watchMembers().first;
    final river = members.singleWhere(
      (member) => member.displayName == 'River',
    );
    final juniper = members.singleWhere(
      (member) => member.displayName == 'Juniper',
    );

    await repository.saveCustomField(const CustomFieldDraft(name: 'Mood'));
    await repository.saveCustomField(const CustomFieldDraft(name: 'Energy'));
    final fields = await repository.watchCustomFields().first;
    final mood = fields.singleWhere((field) => field.name == 'Mood');
    final energy = fields.singleWhere((field) => field.name == 'Energy');

    await repository.setCustomFieldValue(
      fieldId: mood.id,
      memberId: river.id,
      value: 'calm',
    );
    await repository.setCustomFieldValue(
      fieldId: mood.id,
      memberId: juniper.id,
      value: 'focused',
    );
    await repository.setCustomFieldValue(
      fieldId: energy.id,
      memberId: river.id,
      value: 7,
    );

    crypto.decryptCalls = 0;
    expect(
      await repository.watchCustomFieldValues(fieldId: mood.id).first,
      hasLength(2),
    );
    expect(crypto.decryptCalls, 2);

    expect(
      await repository.watchCustomFieldValues(memberId: river.id).first,
      hasLength(2),
    );

    expect(
      await repository
          .watchCustomFieldValues(fieldId: mood.id, memberId: river.id)
          .first,
      hasLength(1),
    );
  });

  test('assigns distinct ordering ranks to new members', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LocalHavenRepository(
      database,
      crypto: HavenCrypto(await generateMasterKey()),
    );
    await repository.ensureLocalSystem();

    await repository.saveMember(const MemberDraft(displayName: 'River'));
    await repository.saveMember(const MemberDraft(displayName: 'Juniper'));

    final members = await repository.watchMembers().first;
    expect(members.map((member) => member.lexoRank).toSet(), hasLength(2));
    expect(
      members.map((member) => member.displayName),
      orderedEquals(['River', 'Juniper']),
    );
  });

  test('reuses member decryptions when only metadata changes', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final crypto = _CountingHavenCrypto();
    final repository = LocalHavenRepository(database, crypto: crypto);
    await repository.ensureLocalSystem();
    await repository.saveMember(
      const MemberDraft(
        displayName: 'River',
        pronouns: 'they/them',
        colorHex: '#123456',
        birthday: '02-03',
        emoji: 'R',
        privacy: 'trusted',
        description: 'Profile',
        avatarUrl: 'local-avatar:river.png',
        pluralKitId: 'pk-river',
      ),
    );

    final members = StreamIterator(
      repository.watchMembers(includeArchived: true),
    );
    addTearDown(members.cancel);
    expect(await members.moveNext(), isTrue);
    final memberId = members.current.single.id;
    expect(crypto.decryptCalls, 9);

    await repository.archiveMember(memberId);
    expect(await members.moveNext(), isTrue);
    expect(members.current.single.archived, isTrue);
    expect(crypto.decryptCalls, 9);

    await repository.updateMember(
      memberId,
      const MemberDraft(
        displayName: 'Brook',
        pronouns: 'they/them',
        colorHex: '#654321',
        birthday: '02-03',
        emoji: 'B',
        privacy: 'trusted',
        description: 'Updated profile',
        avatarUrl: 'local-avatar:brook.png',
        pluralKitId: 'pk-brook',
      ),
    );
    expect(await members.moveNext(), isTrue);
    expect(members.current.single.displayName, 'Brook');
    expect(crypto.decryptCalls, 18);
  });

  test('filters archived members and custom fronts independently', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LocalHavenRepository(
      database,
      crypto: HavenCrypto(SecretKey(List<int>.generate(32, (index) => index))),
    );
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'River'));
    await repository.saveMember(const MemberDraft(displayName: 'Co-fronting'));

    final savedMembers = await repository.watchMembers().first;
    final normalMember = savedMembers.singleWhere(
      (member) => member.displayName == 'River',
    );
    final customFront = savedMembers.singleWhere(
      (member) => member.displayName == 'Co-fronting',
    );
    await (database.update(database.members)
          ..where((member) => member.id.equals(customFront.id)))
        .write(const MembersCompanion(isCustomFront: Value(true)));
    await repository.archiveMember(normalMember.id);

    expect(await repository.watchMembers().first, isEmpty);
    expect(
      await repository.watchMembers(includeArchived: true).first,
      hasLength(1),
    );
    expect(
      await repository.watchMembers(includeCustomFronts: true).first,
      hasLength(1),
    );
    expect(
      await repository
          .watchMembers(includeArchived: true, includeCustomFronts: true)
          .first,
      hasLength(2),
    );
  });

  test('stores and clears current front in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    var snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.systemName, 'Local system');
    expect(snapshot.currentFrontText, 'None');
    expect(snapshot.frontHistoryCount, 0);

    await repository.setCustomFront('blurry co-con');
    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.currentFrontText, 'blurry co-con');
    expect(snapshot.currentFrontStatus, 'fronting');
    expect(snapshot.frontHistoryCount, 1);

    var history = await repository.watchFrontHistory().first;
    expect(history, hasLength(1));
    expect(history.single.label, 'blurry co-con');
    expect(history.single.isActive, isTrue);

    await repository.clearCurrentFront();
    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.currentFrontText, 'None');
    expect(snapshot.currentFrontStatus, 'none');
    expect(snapshot.frontHistoryCount, 1);

    history = await repository.watchFrontHistory().first;
    expect(history.single.isActive, isFalse);
  });

  test('creates and edits historical front intervals', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'River'));
    final member = (await repository.watchMembers().first).single;
    final started = DateTime.utc(2026, 1, 1, 10);
    final ended = DateTime.utc(2026, 1, 1, 11);

    await repository.saveFrontHistoryEntry(
      FrontHistoryDraft(
        startedAt: started,
        endedAt: ended,
        memberIds: [member.id],
        statusNote: 'Morning',
      ),
    );
    var history = await repository.watchFrontHistory().first;
    expect(history.single.label, 'River');
    expect(history.single.memberIds, [member.id]);
    expect(history.single.endedAt?.toUtc(), ended);

    await repository.updateFrontHistoryEntry(
      history.single.id,
      FrontHistoryDraft(
        startedAt: started,
        endedAt: ended.add(const Duration(hours: 1)),
        label: 'Blurry',
      ),
    );
    history = await repository.watchFrontHistory().first;
    expect(history.single.label, 'Blurry');
    expect(history.single.memberIds, isEmpty);
    expect(history.single.endedAt?.toUtc(), DateTime.utc(2026, 1, 1, 12));
  });

  test('stores app customization in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    var customization = await repository.loadCustomization();
    expect(customization.themeMode, HavenThemeMode.dark);
    expect(customization.accentColor, HavenAccentColor.purple);
    expect(customization.compactDashboard, isFalse);
    expect(customization.showDashboardSubtitles, isTrue);
    expect(customization.dashboardShortcutIds, defaultDashboardShortcutIds);
    expect(customization.languageCode, 'system');

    await repository.setThemeMode(HavenThemeMode.system);
    await repository.setAccentColor(HavenAccentColor.teal);
    await repository.setCompactDashboard(true);
    await repository.setShowDashboardSubtitles(false);
    await repository.setDashboardShortcutVisible('analytics', true);
    await repository.moveDashboardShortcut('analytics', -10);
    await repository.setDashboardShortcutVisible('notes', false);
    await repository.setLanguageCode('pt-BR');

    customization = await repository.loadCustomization();
    expect(customization.themeMode, HavenThemeMode.system);
    expect(customization.accentColor, HavenAccentColor.teal);
    expect(customization.compactDashboard, isTrue);
    expect(customization.showDashboardSubtitles, isFalse);
    expect(customization.dashboardShortcutIds.first, 'analytics');
    expect(customization.dashboardShortcutIds, isNot(contains('notes')));
    expect(customization.languageCode, 'pt-BR');
    expect(customization.language.label, 'português brasileiro');

    await repository.resetDashboardShortcuts();
    customization = await repository.loadCustomization();
    expect(customization.dashboardShortcutIds, defaultDashboardShortcutIds);

    await repository.setDashboardShortcutIds(const []);
    customization = await repository.loadCustomization();
    expect(customization.dashboardShortcutIds, isEmpty);
  });

  test('migrates plaintext member names to encrypted storage', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final crypto = HavenCrypto(await generateMasterKey());
    final encryptedRepository = LocalHavenRepository(database, crypto: crypto);
    await encryptedRepository.ensureLocalSystem();
    final now = DateTime.now().toUtc();
    await database
        .into(database.members)
        .insert(
          MembersCompanion.insert(
            id: 'legacy-member',
            systemId: localSystemId,
            displayName: 'River',
            pronouns: const Value('they/them'),
            colorHex: const Value('#123456'),
            birthday: const Value('02-03'),
            emoji: const Value('🌊'),
            privacy: const Value('trusted'),
            description: const Value('Legacy private profile'),
            avatarUrl: const Value('local-avatar:river.png'),
            pluralKitId: const Value('pk-river'),
            lexoRank: '0|zzzzzz',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await encryptedRepository.migrateMemberNamesToEncryption();
    final changesAfterMigration = await database
        .customSelect('SELECT total_changes() AS count')
        .getSingle();
    await encryptedRepository.migrateMemberNamesToEncryption();
    final changesAfterNoOp = await database
        .customSelect('SELECT total_changes() AS count')
        .getSingle();

    final stored = (await database.select(database.members).get()).single;
    expect(stored.displayName, isNot('River'));
    expect(stored.pronouns, isNot('they/them'));
    expect(stored.description, isNot('Legacy private profile'));
    expect(stored.profileEncryptionVersion, 2);
    expect(stored.displayNameHash, isNotEmpty);
    expect(
      changesAfterNoOp.read<int>('count'),
      changesAfterMigration.read<int>('count'),
    );
    expect(
      await (database.select(database.appPreferences)..where(
            (row) => row.key.equals('internal.member_encryption_sweep_version'),
          ))
          .getSingle()
          .then((row) => row.value),
      '2',
    );
    final member = (await encryptedRepository.watchMembers().first).single;
    expect(member.displayName, 'River');
    expect(member.pronouns, 'they/them');
    expect(member.description, 'Legacy private profile');
  });

  test('migrates unauthenticated empty protected text', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final crypto = HavenCrypto(await generateMasterKey());
    final repository = LocalHavenRepository(database, crypto: crypto);
    await repository.ensureLocalSystem();
    final now = DateTime.now().toUtc();
    await (database.update(database.pluralSystems)
          ..where((row) => row.id.equals(localSystemId)))
        .write(const PluralSystemsCompanion(name: Value('ph2:')));
    await database
        .into(database.members)
        .insert(
          MembersCompanion.insert(
            id: 'member-empty',
            systemId: localSystemId,
            displayName: (await crypto.encrypt(
              'River',
              aad: 'members:member-empty:display_name',
            ))!,
            displayNameHash: Value(await crypto.blindIndex('River')),
            profileEncryptionVersion: const Value(2),
            pronouns: const Value(''),
            lexoRank: '0|zzzzzz',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.members)
        .insert(
          MembersCompanion.insert(
            id: 'member-partial-migration',
            systemId: localSystemId,
            displayName: (await crypto.encrypt(
              'Mica',
              aad: 'members:member-partial-migration:display_name',
            ))!,
            displayNameHash: Value(await crypto.blindIndex('Mica')),
            profileEncryptionVersion: const Value(1),
            pronouns: const Value(''),
            lexoRank: '0|zzzzzz1',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await repository.migrateUnauthenticatedEmptyCiphertexts();
    await repository.migrateMemberNamesToEncryption();

    final system = await database.select(database.pluralSystems).getSingle();
    final members = await database.select(database.members).get();
    final member = members.singleWhere((row) => row.id == 'member-empty');
    final partiallyMigrated = members.singleWhere(
      (row) => row.id == 'member-partial-migration',
    );
    expect(system.name, startsWith('ph2:v2:'));
    expect(member.pronouns, startsWith('v2:'));
    expect(partiallyMigrated.pronouns, startsWith('v2:'));
    expect(partiallyMigrated.profileEncryptionVersion, 2);
    expect((await repository.loadHomeSnapshot()).systemName, '');
    final summaries = await repository.watchMembers().first;
    expect(
      summaries.singleWhere((row) => row.id == 'member-empty').pronouns,
      '',
    );
    expect(
      summaries
          .singleWhere((row) => row.id == 'member-partial-migration')
          .displayName,
      'Mica',
    );
    expect(
      await (database.select(database.appPreferences)..where(
            (row) => row.key.equals('internal.empty_ciphertext_sweep_version'),
          ))
          .getSingle()
          .then((row) => row.value),
      '1',
    );
  });

  test('reindexes existing member names with Unicode normalization', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final crypto = HavenCrypto(await generateMasterKey());
    final repository = LocalHavenRepository(database, crypto: crypto);
    await repository.ensureLocalSystem();
    final now = DateTime.now().toUtc();
    await database
        .into(database.members)
        .insert(
          MembersCompanion.insert(
            id: 'member-unicode',
            systemId: localSystemId,
            displayName: (await crypto.encrypt(
              'Cafe\u0301',
              aad: 'members:member-unicode:display_name',
            ))!,
            displayNameHash: const Value('legacy-normalization-hash'),
            profileEncryptionVersion: const Value(2),
            lexoRank: '0|zzzzzz',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await repository.migrateBlindIndexesToUnicodeNormalization();
    final migrated = (await database.select(database.members).get()).single;
    expect(migrated.displayNameHash, await crypto.blindIndex('Caf\u00e9'));

    final changesAfterMigration = await database
        .customSelect('SELECT total_changes() AS count')
        .getSingle();
    await repository.migrateBlindIndexesToUnicodeNormalization();
    final changesAfterNoOp = await database
        .customSelect('SELECT total_changes() AS count')
        .getSingle();
    expect(
      changesAfterNoOp.read<int>('count'),
      changesAfterMigration.read<int>('count'),
    );
  });

  test('stores members and links them to front sessions', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveMember(
      const MemberDraft(
        displayName: 'Iris',
        pronouns: 'she/they',
        birthday: '02-03',
        emoji: 'I',
        privacy: 'trusted',
      ),
    );

    var members = await repository.watchMembers().first;
    expect(members, hasLength(1));
    expect(members.single.displayName, 'Iris');
    expect(members.single.pronouns, 'she/they');
    expect(members.single.birthday, '02-03');
    expect(members.single.emoji, 'I');
    expect(members.single.privacy, 'trusted');

    var snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.memberCount, 1);

    await repository.setFrontMembers([members.single.id]);
    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.currentFrontText, 'Iris');
    expect(snapshot.frontHistoryCount, 1);

    final history = await repository.watchFrontHistory().first;
    expect(history.single.label, 'Iris');

    final frontLinks = await database
        .select(database.frontSessionMembers)
        .get();
    expect(frontLinks, hasLength(1));
    expect(frontLinks.single.memberId, members.single.id);

    await repository.archiveMember(members.single.id);
    members = await repository.watchMembers().first;
    expect(members, isEmpty);

    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.memberCount, 0);
  });

  test('fails closed when a protected member name is corrupted', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'River'));

    final stored = (await database.select(database.members).get()).single;
    await (database.update(
      database.members,
    )..where((member) => member.id.equals(stored.id))).write(
      MembersCompanion(
        displayName: const Value('corrupted ciphertext'),
        displayNameHash: Value(stored.displayNameHash),
      ),
    );

    expect(repository.watchMembers().first, throwsA(anything));
  });

  test('rejects local ciphertext moved between rows or columns', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveNote(const NoteDraft(title: 'One', body: 'First'));
    await repository.saveNote(const NoteDraft(title: 'Two', body: 'Second'));

    final stored = await database.select(database.notes).get();
    expect(stored, hasLength(2));
    await (database.update(database.notes)
          ..where((row) => row.id.equals(stored.first.id)))
        .write(NotesCompanion(title: Value(stored.last.title)));
    expect(repository.buildLocalArchiveJson(), throwsA(anything));

    await (database.update(database.notes)
          ..where((row) => row.id.equals(stored.first.id)))
        .write(NotesCompanion(title: Value(stored.first.body)));
    expect(repository.buildLocalArchiveJson(), throwsA(anything));
  });

  test('restores revision plaintext under the target record context', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveNote(
      const NoteDraft(title: 'Current title', body: 'Current body'),
    );
    final note = (await repository.watchNotes().first).single;
    final now = DateTime.now().toUtc();
    await database
        .into(database.contentRevisions)
        .insert(
          ContentRevisionsCompanion.insert(
            id: 'revision-restore-test',
            targetType: 'note',
            targetId: note.id,
            title: Value(
              await _encryptedLocalText(
                testCrypto(),
                'Earlier title',
                'content_revisions',
                'revision-restore-test',
                'title',
              ),
            ),
            body: await _encryptedLocalText(
              testCrypto(),
              'Earlier body',
              'content_revisions',
              'revision-restore-test',
              'body',
            ),
            createdAt: now,
          ),
        );

    await repository.restoreRevision('revision-restore-test', 'note', note.id);

    final restored = (await repository.watchNotes().first).single;
    expect(restored.title, 'Earlier title');
    expect(restored.body, 'Earlier body');
    final raw = (await database.select(database.notes).get()).single;
    expect(raw.title, startsWith('ph2:'));
    expect(raw.body, startsWith('ph2:'));
  });

  test('stores edits assigns and deletes privacy buckets', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'Iris'));
    final member = (await repository.watchMembers().first).single;

    await repository.savePrivacyBucket(
      PrivacyBucketDraft(
        name: 'Trusted',
        description: 'People we trust',
        colorHex: '#12AB34',
        memberIds: [member.id],
      ),
    );
    var buckets = await repository.watchPrivacyBuckets().first;
    expect(buckets, hasLength(1));
    expect(buckets.single.memberIds, [member.id]);

    await repository.updatePrivacyBucket(
      buckets.single.id,
      const PrivacyBucketDraft(name: 'Close friends', colorHex: '#ABCDEF'),
    );
    buckets = await repository.watchPrivacyBuckets().first;
    expect(buckets.single.name, 'Close friends');
    expect(buckets.single.memberIds, isEmpty);

    final archive =
        jsonDecode(await repository.buildLocalArchiveJson())
            as Map<String, Object?>;
    expect(archive['privacy_buckets'], isA<List<Object?>>());

    await repository.deletePrivacyBucket(buckets.single.id);
    expect(await repository.watchPrivacyBuckets().first, isEmpty);
  });

  test('stores groups in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveGroup(
      const GroupDraft(
        name: 'Caretakers',
        emoji: '*',
        description: 'Internal support crew',
      ),
    );
    await repository.saveGroup(const GroupDraft(name: 'Archivists'));

    final groups = await repository.watchGroups().first;
    expect(groups.map((group) => group.name), ['Archivists', 'Caretakers']);
    expect(groups.last.emoji, '*');
    expect(groups.last.description, 'Internal support crew');

    final snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.groupCount, 2);
  });

  test('stores members in multiple groups', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveGroup(const GroupDraft(name: 'Caretakers'));
    await repository.saveGroup(const GroupDraft(name: 'Subsystem A'));
    final groups = await repository.watchGroups().first;

    await repository.saveMember(
      MemberDraft(
        displayName: 'Iris',
        folderId: groups.first.id,
        groupIds: [for (final group in groups) group.id],
      ),
    );

    final members = await repository.watchMembers().first;
    expect(members.single.groupIds.toSet(), {
      for (final group in groups) group.id,
    });

    final groupsWithCounts = await repository.watchGroups().first;
    expect([for (final group in groupsWithCounts) group.memberCount], [1, 1]);

    await repository.updateMember(
      members.single.id,
      const MemberDraft(displayName: 'Iris', groupIds: []),
    );

    expect((await repository.watchMembers().first).single.groupIds, isEmpty);
    expect(
      [
        for (final group in await repository.watchGroups().first)
          group.memberCount,
      ],
      [0, 0],
    );
  });

  test('stores notes in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveNote(
      const NoteDraft(title: 'Grounding', body: 'Drink water and check meds.'),
    );

    final notes = await repository.watchNotes().first;
    expect(notes, hasLength(1));
    expect(notes.single.title, 'Grounding');
    expect(notes.single.body, 'Drink water and check meds.');
    await repository.updateNote(
      notes.single.id,
      const NoteDraft(
        title: 'Grounding edited',
        body: 'Drink water and check meds before bed.',
      ),
    );
    final updatedNotes = await repository.watchNotes().first;
    expect(updatedNotes.single.title, 'Grounding edited');
    expect(updatedNotes.single.body, 'Drink water and check meds before bed.');

    final snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.noteCount, 1);
  });

  test('stores messages, reminders, and notification events locally', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveMember(const MemberDraft(displayName: 'Iris'));
    final member = (await repository.watchMembers().first).single;

    await repository.saveMessage(
      MessageDraft(
        body: 'Remember to check in.',
        boardKind: 'member',
        boardMemberId: member.id,
      ),
    );
    await repository.saveReminder(
      const ReminderDraft(
        title: 'Medication',
        body: 'With water',
        scheduleText: 'Daily',
      ),
    );
    await repository.recordNotificationEvent(
      const NotificationEventDraft(
        kind: 'front',
        title: 'Front changed',
        body: 'Iris is fronting',
      ),
    );

    final messages = await repository.watchMessages().first;
    final reminders = await repository.watchReminders().first;
    final events = await repository.watchNotificationEvents().first;

    expect(messages.single.body, 'Remember to check in.');
    expect(messages.single.boardKind, 'member');
    expect(messages.single.boardMemberId, member.id);
    await repository.updateMessage(
      messages.single.id,
      const MessageDraft(body: 'Remember to check in after dinner.'),
    );
    final updatedMessages = await repository.watchMessages().first;
    expect(updatedMessages.single.body, 'Remember to check in after dinner.');
    await repository.deleteMessage(updatedMessages.single.id);
    expect(await repository.watchMessages().first, isEmpty);

    expect(reminders.single.title, 'Medication');
    expect(reminders.single.scheduleText, 'Daily');
    expect(reminders.single.enabled, isTrue);
    await repository.setReminderEnabled(reminders.single.id, false);
    final disabledReminders = await repository.watchReminders().first;
    expect(disabledReminders.single.enabled, isFalse);
    expect(events.single.kind, 'front');
    expect(events.single.title, 'Front changed');
  });

  test(
    'after-front reminders fire only for newly started matching fronts',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      await repository.saveMember(const MemberDraft(displayName: 'Iris'));
      await repository.saveMember(const MemberDraft(displayName: 'Juniper'));
      final members = await repository.watchMembers().first;
      final iris = members.singleWhere(
        (member) => member.displayName == 'Iris',
      );
      final juniper = members.singleWhere(
        (member) => member.displayName == 'Juniper',
      );

      Future<void> saveAfterFront({
        required String title,
        String? memberId,
        bool enabled = true,
      }) async {
        await repository.saveReminder(
          ReminderDraft(
            title: title,
            scheduleText: 'After a selected front starts',
            scheduleKind: 'after_front',
            triggerType: 'event',
            triggerMemberId: memberId,
            triggerEvent: 'front_started',
            delaySeconds: 30,
            enabled: enabled,
          ),
        );
      }

      await saveAfterFront(title: 'Any front');
      await saveAfterFront(title: 'Iris only', memberId: iris.id);
      await saveAfterFront(title: 'Juniper only', memberId: juniper.id);
      await saveAfterFront(title: 'Disabled', enabled: false);
      await repository.saveReminder(
        const ReminderDraft(
          title: 'Daily reminder',
          scheduleText: 'Daily',
          scheduleKind: 'daily',
        ),
      );

      final first = await repository.setFrontMembers([iris.id]);
      expect(first.map((reminder) => reminder.title).toSet(), {
        'Any front',
        'Iris only',
      });
      expect(first.every((reminder) => reminder.lastFiredAt != null), isTrue);
      expect(first.every((reminder) => reminder.delaySeconds == 30), isTrue);

      expect(await repository.setFrontMembers([iris.id]), isEmpty);

      final second = await repository.setFrontMembers([juniper.id]);
      expect(second.map((reminder) => reminder.title).toSet(), {
        'Any front',
        'Juniper only',
      });
    },
  );

  test('stores and updates local polls', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    await repository.savePoll(
      const PollDraft(
        question: 'Dinner?',
        description: 'Pick what works tonight.',
        kind: PollKind.singleChoice,
        options: ['Soup', 'Rice', 'Soup'],
      ),
    );

    var polls = await repository.watchPolls().first;
    expect(polls, hasLength(1));
    expect(polls.single.question, 'Dinner?');
    expect(polls.single.description, 'Pick what works tonight.');
    expect(polls.single.options.map((option) => option.body), ['Soup', 'Rice']);

    await repository.togglePollOption(
      polls.single.id,
      polls.single.options.first.id,
    );
    polls = await repository.watchPolls().first;
    expect(polls.single.selectedCount, 1);
    expect(polls.single.options.first.selected, isTrue);

    await repository.closePoll(polls.single.id);
    polls = await repository.watchPolls().first;
    expect(polls.single.closed, isTrue);

    await repository.deletePoll(polls.single.id);
    polls = await repository.watchPolls().first;
    expect(polls, isEmpty);
  });

  test('exports a versioned local archive', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(
      const MemberDraft(displayName: 'Iris', pronouns: 'she/they'),
    );
    await repository.saveGroup(const GroupDraft(name: 'Caretakers'));
    await repository.saveNote(
      const NoteDraft(title: 'Grounding', body: 'Drink water.'),
    );
    await repository.saveMessage(const MessageDraft(body: 'System check-in.'));
    await repository.saveReminder(
      const ReminderDraft(title: 'Meds', scheduleText: 'Daily'),
    );
    await repository.savePoll(
      const PollDraft(
        question: 'Dinner?',
        kind: PollKind.multipleChoice,
        options: ['Soup', 'Rice'],
      ),
    );
    await repository.recordNotificationEvent(
      const NotificationEventDraft(
        kind: 'front',
        title: 'Front changed',
        body: 'Iris is fronting',
      ),
    );
    final member = (await repository.watchMembers().first).single;
    final note = (await repository.watchNotes().first).single;
    final now = DateTime.utc(2026, 1, 2, 3, 4, 5);
    await repository.saveTag(
      Tag(
        id: 'tag-grounded',
        systemId: localSystemId,
        name: 'Grounded',
        colorHex: '#80FFAA',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.setMemberTags(member.id, ['tag-grounded']);
    await repository.saveJournal(
      JournalEntry(
        id: 'journal-1',
        systemId: localSystemId,
        memberId: member.id,
        title: 'Switch notes',
        body: 'Felt close to front.',
        visibility: 'system',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database
        .into(database.contentRevisions)
        .insert(
          ContentRevisionsCompanion.insert(
            id: 'revision-note-1',
            targetType: 'note',
            targetId: note.id,
            title: Value(
              await _encryptedLocalText(
                testCrypto(),
                'Grounding',
                'content_revisions',
                'revision-note-1',
                'title',
              ),
            ),
            body: await _encryptedLocalText(
              testCrypto(),
              'Drink water and breathe.',
              'content_revisions',
              'revision-note-1',
              'body',
            ),
            pinnedAt: Value(now),
            createdAt: now,
          ),
        );
    await repository.setFrontMembers([member.id]);
    final front = (await repository.watchFrontHistory().first).single;
    await database
        .into(database.frontAuditEvents)
        .insert(
          FrontAuditEventsCompanion.insert(
            id: 'front-audit-1',
            frontId: front.id,
            beforeSnapshot: const Value(null),
            afterSnapshot: Value(
              await _encryptedLocalText(
                testCrypto(),
                '{"members":["Iris"]}',
                'front_audit_events',
                'front-audit-1',
                'after_snapshot',
              ),
            ),
            createdAt: now,
          ),
        );
    final poll = (await repository.watchPolls().first).single;
    await database
        .into(database.pollVoteEvents)
        .insert(
          PollVoteEventsCompanion.insert(
            id: 'poll-event-1',
            pollId: poll.id,
            optionId: poll.options.first.id,
            action: 'select',
            createdAt: now,
          ),
        );

    final archive =
        jsonDecode(await repository.buildLocalArchiveJson())
            as Map<String, dynamic>;

    expect(archive['format'], 'pluris_haven.local_archive');
    expect(archive['version'], 1);
    expect((archive['members'] as List), hasLength(1));
    expect((archive['groups'] as List), hasLength(1));
    expect((archive['notes'] as List), hasLength(1));
    expect((archive['messages'] as List), hasLength(1));
    expect((archive['reminders'] as List), hasLength(1));
    expect((archive['tags'] as List), hasLength(1));
    expect((archive['member_tags'] as List), hasLength(1));
    expect((archive['journals'] as List), hasLength(1));
    expect((archive['content_revisions'] as List), hasLength(1));
    expect((archive['polls'] as List), hasLength(1));
    expect((archive['poll_options'] as List), hasLength(2));
    expect((archive['poll_votes'] as List), isA<List>());
    expect((archive['poll_vote_events'] as List), hasLength(1));
    expect((archive['fronts'] as List), hasLength(1));
    expect((archive['front_members'] as List), hasLength(1));
    expect((archive['front_audit_events'] as List), hasLength(1));
    expect((archive['notification_events'] as List), hasLength(1));
    expect((archive['preferences'] as List), isA<List>());
  });

  test('documents local archive table coverage', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    const archivedTables = {
      'plural_systems': 'system',
      'system_groups': 'groups',
      'members': 'members',
      'group_members': 'group_members',
      'notes': 'notes',
      'chat_categories': 'chat_categories',
      'chat_channels': 'chat_channels',
      'messages': 'messages',
      'reminders': 'reminders',
      'custom_field_definitions': 'custom_fields',
      'custom_field_values': 'custom_field_values',
      'polls': 'polls',
      'poll_options': 'poll_options',
      'poll_votes': 'poll_votes',
      'front_sessions': 'fronts',
      'front_session_members': 'front_members',
      'import_records': 'import_records',
      'import_payloads': 'raw_payloads',
      'notification_events': 'notification_events',
      'app_preferences': 'preferences',
      'tags': 'tags',
      'member_tags': 'member_tags',
      'journal_entries': 'journals',
      'content_revisions': 'content_revisions',
      'front_audit_events': 'front_audit_events',
      'poll_vote_events': 'poll_vote_events',
      'named_fronts': 'named_fronts',
      'named_front_members': 'named_front_members',
      'privacy_buckets': 'privacy_buckets',
      'privacy_bucket_members': 'privacy_bucket_members',
    };
    const intentionallyLocalOnlyTables = {'background_jobs', 'pending_actions'};

    final actualTableNames = database.allTables
        .map((table) => table.actualTableName)
        .toSet();
    expect({
      ...archivedTables.keys,
      ...intentionallyLocalOnlyTables,
    }, actualTableNames);

    final archive =
        jsonDecode(await repository.buildLocalArchiveJson())
            as Map<String, dynamic>;
    expect(archive.keys, containsAll(archivedTables.values));
  });

  test('imports a local archive into an empty database', () async {
    final sourceDatabase = AppDatabase(NativeDatabase.memory());
    final source = testRepository(sourceDatabase);
    await source.ensureLocalSystem();

    await source.saveMember(
      const MemberDraft(displayName: 'Iris', pronouns: 'she/they'),
    );
    await source.saveGroup(const GroupDraft(name: 'Caretakers'));
    await source.saveNote(
      const NoteDraft(title: 'Grounding', body: 'Drink water.'),
    );
    await source.saveMessage(const MessageDraft(body: 'System check-in.'));
    await source.saveReminder(
      const ReminderDraft(title: 'Meds', scheduleText: 'Daily'),
    );
    await source.savePoll(
      const PollDraft(
        question: 'Dinner?',
        kind: PollKind.multipleChoice,
        options: ['Soup', 'Rice'],
      ),
    );
    await source.recordNotificationEvent(
      const NotificationEventDraft(
        kind: 'front',
        title: 'Front changed',
        body: 'Iris is fronting',
      ),
    );
    final member = (await source.watchMembers().first).single;
    await source.saveReminder(
      ReminderDraft(
        title: 'Check in after fronting',
        scheduleText: 'After Iris fronts',
        scheduleKind: 'after_front',
        triggerType: 'event',
        triggerMemberId: member.id,
        triggerEvent: 'front_started',
        delaySeconds: 45,
      ),
    );
    final group = (await source.watchGroups().first).single;
    final note = (await source.watchNotes().first).single;
    final now = DateTime.utc(2026, 1, 2, 3, 4, 5);
    await source.updateMember(
      member.id,
      MemberDraft(
        displayName: member.displayName,
        pronouns: member.pronouns,
        folderId: group.id,
      ),
    );
    await source.saveTag(
      Tag(
        id: 'tag-grounded',
        systemId: localSystemId,
        name: 'Grounded',
        colorHex: '#80FFAA',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await source.setMemberTags(member.id, ['tag-grounded']);
    await source.saveJournal(
      JournalEntry(
        id: 'journal-1',
        systemId: localSystemId,
        memberId: member.id,
        title: 'Switch notes',
        body: 'Felt close to front.',
        visibility: 'system',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await sourceDatabase
        .into(sourceDatabase.contentRevisions)
        .insert(
          ContentRevisionsCompanion.insert(
            id: 'revision-note-1',
            targetType: 'note',
            targetId: note.id,
            title: Value(
              await _encryptedLocalText(
                testCrypto(),
                'Grounding',
                'content_revisions',
                'revision-note-1',
                'title',
              ),
            ),
            body: await _encryptedLocalText(
              testCrypto(),
              'Drink water and breathe.',
              'content_revisions',
              'revision-note-1',
              'body',
            ),
            pinnedAt: Value(now),
            createdAt: now,
          ),
        );
    await source.setFrontMembers([member.id]);
    final front = (await source.watchFrontHistory().first).single;
    await sourceDatabase
        .into(sourceDatabase.frontAuditEvents)
        .insert(
          FrontAuditEventsCompanion.insert(
            id: 'front-audit-1',
            frontId: front.id,
            beforeSnapshot: const Value(null),
            afterSnapshot: Value(
              await _encryptedLocalText(
                testCrypto(),
                '{"members":["Iris"]}',
                'front_audit_events',
                'front-audit-1',
                'after_snapshot',
              ),
            ),
            createdAt: now,
          ),
        );
    final poll = (await source.watchPolls().first).single;
    await sourceDatabase
        .into(sourceDatabase.pollVoteEvents)
        .insert(
          PollVoteEventsCompanion.insert(
            id: 'poll-event-1',
            pollId: poll.id,
            optionId: poll.options.first.id,
            action: 'select',
            createdAt: now,
          ),
        );

    final archive = await source.buildLocalArchiveJson();
    final sourceArchive = jsonDecode(archive) as Map<String, dynamic>;
    expect(sourceArchive['group_members'], hasLength(1));
    expect(sourceArchive['member_tags'], hasLength(1));
    expect(sourceArchive['journals'], hasLength(1));
    expect(sourceArchive['content_revisions'], hasLength(1));
    expect(sourceArchive['front_audit_events'], hasLength(1));
    expect(sourceArchive['poll_vote_events'], hasLength(1));
    await sourceDatabase.close();

    final targetDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(targetDatabase.close);
    final target = testRepository(targetDatabase);
    await target.ensureLocalSystem();

    await target.importLocalArchiveJson(
      archive,
      strategy: ImportConflictStrategy.update,
      fileName: 'backup.json',
    );

    expect(await target.watchMembers().first, hasLength(1));
    final importedGroups = await target.watchGroups().first;
    expect(importedGroups, hasLength(1));
    expect(importedGroups.single.memberCount, 1);
    expect(await target.watchNotes().first, hasLength(1));
    expect(await target.watchMessages().first, hasLength(1));
    final importedReminders = await target.watchReminders().first;
    expect(importedReminders, hasLength(2));
    final afterFrontReminder = importedReminders.singleWhere(
      (reminder) => reminder.scheduleKind == 'after_front',
    );
    expect(afterFrontReminder.triggerType, 'event');
    expect(afterFrontReminder.triggerMemberId, member.id);
    expect(afterFrontReminder.triggerEvent, 'front_started');
    expect(afterFrontReminder.delaySeconds, 45);
    final importedMembers = await target.watchMembers().first;
    final importedMember = importedMembers.single;
    expect(await target.watchTags().first, hasLength(1));
    expect(
      (await target.watchTagsForMember(importedMember.id).first).single.name,
      'Grounded',
    );
    expect(
      await target.watchJournals(memberId: importedMember.id).first,
      hasLength(1),
    );
    expect(await target.watchRevisions('note', note.id).first, hasLength(1));
    final polls = await target.watchPolls().first;
    expect(polls, hasLength(1));
    expect(polls.single.options, hasLength(2));
    expect(
      await target.watchPollVoteEvents(polls.single.id).first,
      hasLength(1),
    );
    expect(await target.watchNotificationEvents().first, hasLength(1));
    final importedFronts = await target.watchFrontHistory().first;
    expect(importedFronts, hasLength(1));
    expect(
      await target.watchFrontAuditEvents(importedFronts.single.id).first,
      hasLength(1),
    );
    final targetArchive =
        jsonDecode(await target.buildLocalArchiveJson())
            as Map<String, dynamic>;
    expect(targetArchive['group_members'], hasLength(1));
    expect(targetArchive['member_tags'], hasLength(1));
    expect(targetArchive['journals'], hasLength(1));
    expect(targetArchive['content_revisions'], hasLength(1));
    expect(targetArchive['front_audit_events'], hasLength(1));
    expect(targetArchive['poll_vote_events'], hasLength(1));
    expect(
      (targetArchive['import_records'] as List).single['file_name'],
      'backup.json',
    );

    final snapshot = await target.loadHomeSnapshot();
    expect(snapshot.memberCount, 1);
    expect(snapshot.groupCount, 1);
    expect(snapshot.noteCount, 1);
    expect(snapshot.frontHistoryCount, 1);

    final importRecords = await targetDatabase
        .select(targetDatabase.importRecords)
        .get();
    expect(importRecords, hasLength(1));
    expect(importRecords.single.source, 'plurishaven_archive');
    expect(importRecords.single.fileName, isNot('backup.json'));
  });

  test('rehearses a restore without changing the current database', () async {
    final sourceDatabase = AppDatabase(NativeDatabase.memory());
    final source = testRepository(sourceDatabase);
    await source.ensureLocalSystem();
    await source.saveMember(
      const MemberDraft(displayName: 'Iris', pronouns: 'she/they'),
    );
    await source.saveGroup(const GroupDraft(name: 'Caretakers'));
    await source.saveNote(
      const NoteDraft(title: 'Grounding', body: 'Drink water.'),
    );
    final member = (await source.watchMembers().first).single;
    final now = DateTime.utc(2026, 1, 2, 3, 4, 5);
    await source.saveTag(
      Tag(
        id: 'tag-grounded',
        systemId: localSystemId,
        name: 'Grounded',
        colorHex: '#80FFAA',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await source.setMemberTags(member.id, ['tag-grounded']);
    await source.saveJournal(
      JournalEntry(
        id: 'journal-1',
        systemId: localSystemId,
        memberId: member.id,
        title: 'Switch notes',
        body: 'Felt close to front.',
        visibility: 'system',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final archive = await source.buildLocalArchiveJson();
    await sourceDatabase.close();

    final targetDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(targetDatabase.close);
    final target = testRepository(targetDatabase);
    await target.ensureLocalSystem();

    final rehearsal = await target.rehearseLocalArchiveRestore(
      archive,
      strategy: ImportConflictStrategy.update,
      fileName: 'backup.json',
    );

    expect(rehearsal.canRestore, isTrue);
    expect(rehearsal.error, isNull);
    expect(rehearsal.counts['members'], 1);
    expect(rehearsal.counts['groups'], 1);
    expect(rehearsal.counts['notes'], 1);
    expect(rehearsal.counts['tags'], 1);
    expect(rehearsal.counts['member_tags'], 1);
    expect(rehearsal.counts['journals'], 1);
    expect(rehearsal.counts['import_records'], 1);
    expect(await target.watchMembers().first, isEmpty);
    expect(await target.watchGroups().first, isEmpty);
    expect(await target.watchNotes().first, isEmpty);
    expect(await target.watchTags().first, isEmpty);
    expect(await target.watchJournals().first, isEmpty);
  });

  test('reports restore rehearsal failures without throwing', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    final rehearsal = await repository.rehearseLocalArchiveRestore(
      '{"format":"wrong"}',
      fileName: 'broken.json',
    );

    expect(rehearsal.canRestore, isFalse);
    expect(rehearsal.error, contains('Unsupported archive format'));
    expect(await repository.watchMembers().first, isEmpty);
  });

  test('imports normalized external archives', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    final normalized = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'simply-plural.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "system": {"name": "Imported system"},
  "members": [{"id": "m1", "name": "Iris", "pronouns": "she/they"}],
  "frontHistory": [
    {"id": "f1", "startedAt": "2026-01-01T12:00:00Z", "members": ["m1"]}
  ],
  "messages": [{"id": "msg1", "body": "hello"}]
}
''',
    );

    await repository.importLocalArchiveJson(
      normalized.archiveJson,
      source: ImportSource.simplyPlural,
      fileName: 'simply-plural.json',
    );

    final members = await repository.watchMembers().first;
    final fronts = await repository.watchFrontHistory().first;
    final messages = await repository.watchMessages().first;

    expect(members.single.displayName, 'Iris');
    expect(members.single.pronouns, 'she/they');
    expect(fronts.single.label, 'Iris');
    expect(messages.single.body, 'hello');

    final importRecords = await database.select(database.importRecords).get();
    expect(importRecords.single.source, 'simplyplural_file');

    final payloads = await database.select(database.importPayloads).get();
    expect(payloads, isEmpty);

    final reExported = await repository.buildLocalArchiveJson();
    expect(reExported, contains('"raw_payloads"'));
    expect(reExported, isNot(contains('"collection": "members"')));
  });

  test(
    're-imports Simply Plural front history without foreign key failures',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final repository = testRepository(database);
      await repository.ensureLocalSystem();

      final normalized = normalizeImportTextToLocalArchive(
        source: ImportSource.simplyPlural,
        fileName: 'simply-plural.json',
        importedAt: DateTime.utc(2026),
        text: '''
{
  "users": [{"_id": "owner1", "username": "Imported system"}],
  "members": [{"_id": "m1", "name": "Iris"}],
  "frontStatuses": [{"_id": "cf1", "name": "Asleep"}],
  "frontHistory": [
    {
      "_id": "f1",
      "member": "m1",
      "custom": false,
      "customStatus": "blurry",
      "startTime": 1767225600000,
      "endTime": 1767229200000
    },
    {
      "_id": "f2",
      "member": "cf1",
      "custom": true,
      "customStatus": "Asleep",
      "startTime": 1767232800000,
      "endTime": 1767236400000
    }
  ],
  "securityLogs": [{"_id": "log1", "kind": "login"}]
}
''',
      );

      await repository.importLocalArchiveJson(
        normalized.archiveJson,
        source: ImportSource.simplyPlural,
        fileName: 'simply-plural.json',
      );
      await repository.importLocalArchiveJson(
        normalized.archiveJson,
        source: ImportSource.simplyPlural,
        fileName: 'simply-plural.json',
      );

      final members = await repository
          .watchMembers(includeArchived: true)
          .first;
      final fronts = await repository.watchFrontHistory().first;
      final namedFronts = await repository.watchNamedFronts().first;
      final payloads = await database.select(database.importPayloads).get();

      expect(members.map((member) => member.displayName), contains('Iris'));
      expect(
        members.map((member) => member.displayName),
        isNot(contains('Asleep')),
      );
      expect(namedFronts.map((front) => front.customLabel), contains('Asleep'));
      expect(fronts, hasLength(2));
      expect(fronts.map((front) => front.label), contains('Asleep'));
      expect(
        fronts.singleWhere((front) => front.label == 'Iris').statusNote,
        'blurry',
      );
      await repository.applyNamedFront(namedFronts.single.id);
      final home = await repository.watchHomeSnapshot().first;
      expect(home.currentFrontLabel, 'Asleep');
      final exported =
          jsonDecode(await repository.buildLocalArchiveJson())
              as Map<String, dynamic>;
      final exportedFronts = (exported['fronts'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        exportedFronts.any((front) => front['status_note'] == 'blurry'),
        isTrue,
      );
      expect(
        payloads.map((payload) => payload.collection),
        contains('securityLogs'),
      );
      final retained = await repository.watchRetainedImportPayloads().first;
      expect(retained, hasLength(1));
      expect(retained.single.collections, contains('securityLogs'));
      await repository.deleteRetainedImportPayloads(
        retained.single.importRecordId,
      );
      expect(await database.select(database.importPayloads).get(), isEmpty);
    },
  );

  test('runs queued import jobs from the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    final normalized = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'simply-plural.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [{"id": "m1", "name": "Iris", "pronouns": "she/they"}]
}
''',
    );

    final jobId = await repository.enqueueImportArchiveJob(
      normalized.archiveJson,
      strategy: ImportConflictStrategy.skip,
      source: ImportSource.simplyPlural,
      fileName: 'simply-plural.json',
    );

    var jobs = await repository.watchBackgroundJobs().first;
    expect(jobs.single.id, jobId);
    expect(jobs.single.status, 'queued');

    expect(await repository.runQueuedImportJobs(), isTrue);

    jobs = await repository.watchBackgroundJobs().first;
    expect(jobs.single.status, 'done');

    final members = await repository.watchMembers().first;
    expect(members.single.displayName, 'Iris');
  });

  test('stores imported avatar assets locally', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();

    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [{"_id": "m1", "name": "Iris", "avatarUuid": "avatar-1"}]
}
''',
      avatarAssets: [
        ImportAvatarAsset(
          id: 'avatar-1',
          name: 'avatars/avatar-1.png',
          mimeType: 'image/png',
          bytes: Uint8List.fromList([
            0x89,
            0x50,
            0x4e,
            0x47,
            0x0d,
            0x0a,
            0x1a,
            0x0a,
          ]),
        ),
      ],
    );

    await repository.importLocalArchiveJson(
      archive.archiveJson,
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
    );

    final member = (await repository.watchMembers().first).single;
    expect(member.avatarUrl, startsWith('local-avatar:'));
    expect(member.avatarUrl, endsWith('.png'));
  });

  test('uses avatar bytes instead of a misleading source extension', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [{"_id": "m1", "name": "Iris", "avatarUuid": "avatar-1"}]
}
''',
      avatarAssets: [
        ImportAvatarAsset(
          id: 'avatar-1',
          name: 'avatars/avatar-1.png',
          mimeType: 'image/png',
          bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]),
        ),
      ],
    );

    await repository.importLocalArchiveJson(
      archive.archiveJson,
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
    );

    final member = (await repository.watchMembers().first).single;
    expect(member.avatarUrl, endsWith('.jpg'));
    final exported =
        jsonDecode(await repository.buildLocalArchiveJson())
            as Map<String, dynamic>;
    final assets = (exported['avatar_assets'] as List)
        .cast<Map<String, dynamic>>();
    expect(assets.single['mime_type'], 'image/jpeg');
  });

  test('does not retain an unavailable remote avatar as local data', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.importLocalArchiveJson('''
{
  "format": "pluris_haven.local_archive",
  "version": 1,
  "system": null,
  "members": [
    {
      "id": "m1",
      "display_name": "Iris",
      "avatar_url": "http://127.0.0.1:1/unavailable.png"
    }
  ]
}
''');

    final member = (await repository.watchMembers().first).single;
    expect(member.avatarUrl, isNull);
    final exported = await repository.buildLocalArchiveJson();
    expect(exported, isNot(contains('127.0.0.1')));
  });

  test('does not export device-local avatar paths or URIs', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(
      const MemberDraft(
        displayName: 'File URI',
        avatarUrl: 'file:///data/user/0/works.endoftime.plurishaven/avatar.png',
      ),
    );
    await repository.saveMember(
      const MemberDraft(
        displayName: 'Document URI',
        avatarUrl: 'content://com.android.providers.media/avatar/42',
      ),
    );
    await repository.saveMember(
      const MemberDraft(
        displayName: 'Absolute path',
        avatarUrl: '/data/user/0/works.endoftime.plurishaven/avatar.png',
      ),
    );

    final archive = await repository.buildLocalArchiveJson();
    final decoded = jsonDecode(archive) as Map<String, dynamic>;
    final members = (decoded['members'] as List).cast<Map<String, dynamic>>();

    expect(members.map((member) => member['avatar_url']), everyElement(isNull));
    expect(archive, isNot(contains('file://')));
    expect(archive, isNot(contains('content://')));
    expect(archive, isNot(contains('/data/user/0/')));
  });
}

Future<String> _encryptedLocalText(
  HavenCrypto crypto,
  String value,
  String table,
  String rowId,
  String column,
) async {
  final ciphertext = await crypto.encrypt(
    value,
    aad: 'pluris-haven:local-text:v2\u0000$table\u0000$rowId\u0000$column',
  );
  return 'ph2:$ciphertext';
}

class _CountingHavenCrypto extends HavenCrypto {
  _CountingHavenCrypto()
    : super(SecretKey(List<int>.filled(32, 0x42, growable: false)));

  int decryptCalls = 0;

  @override
  Future<String?> decrypt(String? ciphertext, {String aad = ''}) {
    decryptCalls++;
    return super.decrypt(ciphertext, aad: aad);
  }
}
