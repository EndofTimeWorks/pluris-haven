import 'import_sources.dart';

enum ImportDedupeDisposition { created, skipped, updated }

class ImportMemberCandidate {
  const ImportMemberCandidate({
    required this.source,
    required this.displayName,
    this.sourceMemberId,
    this.pluralKitId,
    this.isCustomFront = false,
  });

  final ImportSource source;
  final String displayName;
  final String? sourceMemberId;
  final String? pluralKitId;
  final bool isCustomFront;

  String get normalizedName => normalizeImportName(displayName);

  bool get hasStrongId =>
      (pluralKitId?.trim().isNotEmpty ?? false) ||
      (sourceMemberId?.trim().isNotEmpty ?? false);
}

class ExistingMemberIdentity {
  const ExistingMemberIdentity({
    required this.localId,
    required this.displayName,
    this.source,
    this.sourceMemberId,
    this.pluralKitId,
    this.isCustomFront = false,
  });

  final String localId;
  final String displayName;
  final ImportSource? source;
  final String? sourceMemberId;
  final String? pluralKitId;
  final bool isCustomFront;

  String get normalizedName => normalizeImportName(displayName);
}

class ImportMemberResolution {
  const ImportMemberResolution({
    required this.candidate,
    required this.disposition,
    this.match,
  });

  final ImportMemberCandidate candidate;
  final ImportDedupeDisposition disposition;
  final ExistingMemberIdentity? match;
}

class MemberDedupeIndex {
  MemberDedupeIndex(Iterable<ExistingMemberIdentity> existingMembers) {
    for (final member in existingMembers) {
      _register(member);
    }
  }

  final Map<String, ExistingMemberIdentity> _byPluralKitId = {};
  final Map<String, ExistingMemberIdentity> _bySourceId = {};
  final Map<_NameKey, ExistingMemberIdentity> _byName = {};

  ImportMemberResolution resolve(
    ImportMemberCandidate candidate, {
    required ImportConflictStrategy strategy,
  }) {
    if (strategy == ImportConflictStrategy.create) {
      return ImportMemberResolution(
        candidate: candidate,
        disposition: ImportDedupeDisposition.created,
      );
    }

    final match = _find(candidate);
    if (match == null) {
      _registerCandidate(candidate);
      return ImportMemberResolution(
        candidate: candidate,
        disposition: ImportDedupeDisposition.created,
      );
    }

    return ImportMemberResolution(
      candidate: candidate,
      match: match,
      disposition: strategy == ImportConflictStrategy.update
          ? ImportDedupeDisposition.updated
          : ImportDedupeDisposition.skipped,
    );
  }

  ExistingMemberIdentity? _find(ImportMemberCandidate candidate) {
    final pluralKitId = candidate.pluralKitId?.trim();
    if (pluralKitId != null && pluralKitId.isNotEmpty) {
      final match = _byPluralKitId[pluralKitId];
      if (match != null) {
        return match;
      }
    }

    final sourceMemberId = candidate.sourceMemberId?.trim();
    if (sourceMemberId != null && sourceMemberId.isNotEmpty) {
      final match = _bySourceId[_sourceKey(candidate.source, sourceMemberId)];
      if (match != null) {
        return match;
      }
    }

    if (candidate.hasStrongId) {
      return null;
    }

    return _byName[_NameKey(candidate.isCustomFront, candidate.normalizedName)];
  }

  void _register(ExistingMemberIdentity member) {
    final pluralKitId = member.pluralKitId?.trim();
    if (pluralKitId != null && pluralKitId.isNotEmpty) {
      _byPluralKitId.putIfAbsent(pluralKitId, () => member);
    }

    final source = member.source;
    final sourceMemberId = member.sourceMemberId?.trim();
    if (source != null && sourceMemberId != null && sourceMemberId.isNotEmpty) {
      _bySourceId.putIfAbsent(_sourceKey(source, sourceMemberId), () => member);
    }

    _byName.putIfAbsent(
      _NameKey(member.isCustomFront, member.normalizedName),
      () => member,
    );
  }

  void _registerCandidate(ImportMemberCandidate candidate) {
    _register(
      ExistingMemberIdentity(
        localId:
            'candidate:${candidate.source.name}:${candidate.sourceMemberId ?? candidate.normalizedName}',
        displayName: candidate.displayName,
        source: candidate.source,
        sourceMemberId: candidate.sourceMemberId,
        pluralKitId: candidate.pluralKitId,
        isCustomFront: candidate.isCustomFront,
      ),
    );
  }

  String _sourceKey(ImportSource source, String sourceMemberId) {
    return '${source.jobSource}:$sourceMemberId';
  }
}

String normalizeImportName(String name) {
  return name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

class _NameKey {
  const _NameKey(this.isCustomFront, this.normalizedName);

  final bool isCustomFront;
  final String normalizedName;

  @override
  bool operator ==(Object other) {
    return other is _NameKey &&
        other.isCustomFront == isCustomFront &&
        other.normalizedName == normalizedName;
  }

  @override
  int get hashCode => Object.hash(isCustomFront, normalizedName);
}
