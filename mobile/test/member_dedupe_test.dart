import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/import/member_dedupe.dart';

void main() {
  test('matches members by PluralKit ID before name', () {
    final index = MemberDedupeIndex([
      const ExistingMemberIdentity(
        localId: 'local-a',
        displayName: 'Old display',
        pluralKitId: 'abcde',
      ),
    ]);

    final resolution = index.resolve(
      const ImportMemberCandidate(
        source: ImportSource.pluralKitFile,
        displayName: 'New display',
        pluralKitId: 'abcde',
      ),
      strategy: ImportConflictStrategy.skip,
    );

    expect(resolution.disposition, ImportDedupeDisposition.skipped);
    expect(resolution.match?.localId, 'local-a');
  });

  test('matches source IDs within the same source', () {
    final index = MemberDedupeIndex([
      const ExistingMemberIdentity(
        localId: 'local-sp',
        displayName: 'Iris',
        source: ImportSource.simplyPlural,
        sourceMemberId: 'sp-1',
      ),
    ]);

    final resolution = index.resolve(
      const ImportMemberCandidate(
        source: ImportSource.simplyPlural,
        displayName: 'Iris renamed',
        sourceMemberId: 'sp-1',
      ),
      strategy: ImportConflictStrategy.update,
    );

    expect(resolution.disposition, ImportDedupeDisposition.updated);
    expect(resolution.match?.localId, 'local-sp');
  });

  test('scopes fallback name matches by custom front flag', () {
    final index = MemberDedupeIndex([
      const ExistingMemberIdentity(localId: 'member', displayName: 'Asleep'),
      const ExistingMemberIdentity(
        localId: 'custom-front',
        displayName: 'Asleep',
        isCustomFront: true,
      ),
    ]);

    final memberResolution = index.resolve(
      const ImportMemberCandidate(
        source: ImportSource.simplyPlural,
        displayName: ' asleep ',
      ),
      strategy: ImportConflictStrategy.skip,
    );
    final frontResolution = index.resolve(
      const ImportMemberCandidate(
        source: ImportSource.simplyPlural,
        displayName: 'ASLEEP',
        isCustomFront: true,
      ),
      strategy: ImportConflictStrategy.skip,
    );

    expect(memberResolution.match?.localId, 'member');
    expect(frontResolution.match?.localId, 'custom-front');
  });

  test('registers created candidates so import batches dedupe themselves', () {
    final index = MemberDedupeIndex([]);

    final first = index.resolve(
      const ImportMemberCandidate(
        source: ImportSource.tupperbox,
        displayName: 'River',
      ),
      strategy: ImportConflictStrategy.skip,
    );
    final second = index.resolve(
      const ImportMemberCandidate(
        source: ImportSource.tupperbox,
        displayName: '  river  ',
      ),
      strategy: ImportConflictStrategy.skip,
    );

    expect(first.disposition, ImportDedupeDisposition.created);
    expect(second.disposition, ImportDedupeDisposition.skipped);
    expect(second.match?.displayName, 'River');
  });

  test('create strategy bypasses dedupe', () {
    final index = MemberDedupeIndex([
      const ExistingMemberIdentity(localId: 'local-a', displayName: 'Aster'),
    ]);

    final resolution = index.resolve(
      const ImportMemberCandidate(
        source: ImportSource.pluralSpace,
        displayName: 'Aster',
      ),
      strategy: ImportConflictStrategy.create,
    );

    expect(resolution.disposition, ImportDedupeDisposition.created);
    expect(resolution.match, isNull);
  });
}
