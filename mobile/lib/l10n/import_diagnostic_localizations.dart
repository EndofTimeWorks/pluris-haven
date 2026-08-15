import '../data/import/import_diagnostic.dart';
import '../data/import/import_preview.dart';
import '../data/import/import_sources.dart';
import 'app_localizations.dart';
import 'import_plan_localizations.dart';

String localizeImportPreviewStage(
  AppLocalizations l10n,
  ImportPreviewStage stage,
) {
  return switch (stage) {
    ImportPreviewStage.parse => l10n.importStageParse,
    ImportPreviewStage.decrypt => l10n.importStageDecrypt,
    ImportPreviewStage.validate => l10n.importStageValidate,
    ImportPreviewStage.preview => l10n.importStagePreview,
    ImportPreviewStage.normalize => l10n.importStageNormalize,
    ImportPreviewStage.preserve => l10n.importStagePreserve,
    ImportPreviewStage.avatars => l10n.importStageAvatars,
  };
}

String localizeImportDiagnostic(
  AppLocalizations l10n,
  ImportDiagnostic diagnostic,
) {
  return switch (diagnostic.code) {
    ImportDiagnosticCode.jsonParseFailed =>
      l10n.importDiagnosticJsonParseFailed(
        diagnostic.argument<String>('error'),
      ),
    ImportDiagnosticCode.expectedTopLevelObject =>
      l10n.importDiagnosticExpectedTopLevelObject,
    ImportDiagnosticCode.prismNeedsDecryption =>
      l10n.importDiagnosticPrismNeedsDecryption,
    ImportDiagnosticCode.notPlurisArchive =>
      l10n.importDiagnosticNotPlurisArchive,
    ImportDiagnosticCode.unsupportedArchiveVersion =>
      l10n.importDiagnosticUnsupportedArchiveVersion(
        diagnostic.argument<String>('version'),
      ),
    ImportDiagnosticCode.foundMembersAndFronts =>
      l10n.importDiagnosticFoundMembersAndFronts(
        diagnostic.argument<int>('members'),
        diagnostic.argument<int>('fronts'),
      ),
    ImportDiagnosticCode.recognizedRecords =>
      l10n.importDiagnosticRecognizedRecords,
    ImportDiagnosticCode.noImportableRecords =>
      l10n.importDiagnosticNoImportableRecords,
    ImportDiagnosticCode.preservedRawPayloads =>
      l10n.importDiagnosticPreservedRawPayloads(
        diagnostic.argument<int>('count'),
        _localizeRawPayloadCollections(
          l10n,
          diagnostic.argument<List<String>>('collections'),
        ),
      ),
    ImportDiagnosticCode.remoteAvatarsWithoutZip =>
      l10n.importDiagnosticRemoteAvatarsWithoutZip,
    ImportDiagnosticCode.bestEffortImport => l10n.importDiagnosticBestEffort(
      localizeImportSource(l10n, diagnostic.argument<ImportSource>('source')),
    ),
    ImportDiagnosticCode.encryptedArchiveLocked =>
      l10n.encryptedArchiveLockedPreview,
    ImportDiagnosticCode.encryptedArchiveDecryptFailed =>
      l10n.couldNotDecryptArchive(diagnostic.argument<String>('error')),
    ImportDiagnosticCode.skippedExpectedObject =>
      l10n.importDiagnosticSkippedExpectedObject(
        diagnostic.argument<String>('record'),
        diagnostic.argument<int>('index'),
      ),
    ImportDiagnosticCode.skippedMissingFields =>
      l10n.importDiagnosticSkippedMissingFields(
        diagnostic.argument<String>('record'),
        diagnostic.argument<int>('index'),
        diagnostic.argument<String>('fields'),
      ),
    ImportDiagnosticCode.ignoredMissingRelation =>
      l10n.importDiagnosticIgnoredMissingRelation(
        diagnostic.argument<String>('ownerKind'),
        diagnostic.argument<String>('owner'),
        diagnostic.argument<String>('relationKind'),
        diagnostic.argument<String>('relation'),
      ),
    ImportDiagnosticCode.ignoredSelfParent =>
      l10n.importDiagnosticIgnoredSelfParent(
        diagnostic.argument<String>('group'),
      ),
    ImportDiagnosticCode.reminderMissingMember =>
      l10n.importDiagnosticReminderMissingMember(
        diagnostic.argument<int>('index'),
      ),
    ImportDiagnosticCode.pollTooFewOptions =>
      l10n.importDiagnosticPollTooFewOptions(
        diagnostic.argument<String>('question'),
      ),
    ImportDiagnosticCode.ignoredMissingReference =>
      l10n.importDiagnosticIgnoredMissingReference(
        diagnostic.argument<String>('record'),
        diagnostic.argument<String>('relation'),
        diagnostic.argument<String>('value'),
      ),
    ImportDiagnosticCode.frontReversed => l10n.importDiagnosticFrontReversed(
      diagnostic.argument<int>('index'),
    ),
    ImportDiagnosticCode.stringClamped => l10n.importDiagnosticStringClamped(
      diagnostic.argument<int>('count'),
      diagnostic.argument<String>('field'),
      diagnostic.argument<int>('limit'),
    ),
    ImportDiagnosticCode.listClamped => l10n.importDiagnosticListClamped(
      diagnostic.argument<int>('count'),
      diagnostic.argument<String>('field'),
      diagnostic.argument<int>('limit'),
    ),
  };
}

String _localizeRawPayloadCollections(
  AppLocalizations l10n,
  List<String> collections,
) {
  if (collections.isEmpty) {
    return '';
  }
  const visibleLimit = 6;
  final visible = collections.take(visibleLimit).join(', ');
  final hiddenCount = collections.length - visibleLimit;
  return hiddenCount > 0
      ? l10n.importDiagnosticCollectionNamesWithMore(visible, hiddenCount)
      : l10n.importDiagnosticCollectionNames(visible);
}
