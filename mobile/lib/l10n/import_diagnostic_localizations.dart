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
        localizeImportDiagnosticTerm(
          l10n,
          diagnostic.argument<ImportDiagnosticTerm>('record'),
        ),
        diagnostic.argument<int>('index'),
      ),
    ImportDiagnosticCode.skippedMissingFields =>
      l10n.importDiagnosticSkippedMissingFields(
        localizeImportDiagnosticTerm(
          l10n,
          diagnostic.argument<ImportDiagnosticTerm>('record'),
        ),
        diagnostic.argument<int>('index'),
        localizeImportDiagnosticTerm(
          l10n,
          diagnostic.argument<ImportDiagnosticTerm>('fields'),
        ),
      ),
    ImportDiagnosticCode.ignoredMissingRelation =>
      l10n.importDiagnosticIgnoredMissingRelation(
        localizeImportDiagnosticTerm(
          l10n,
          diagnostic.argument<ImportDiagnosticTerm>('ownerKind'),
          sentenceStart: true,
        ),
        diagnostic.argument<String>('owner'),
        localizeImportDiagnosticTerm(
          l10n,
          diagnostic.argument<ImportDiagnosticTerm>('relationKind'),
        ),
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
    ImportDiagnosticCode.ignoredMissingReference => _localizeMissingReference(
      l10n,
      diagnostic,
    ),
    ImportDiagnosticCode.frontReversed => l10n.importDiagnosticFrontReversed(
      diagnostic.argument<int>('index'),
    ),
    ImportDiagnosticCode.stringClamped => l10n.importDiagnosticStringClamped(
      diagnostic.argument<int>('count'),
      localizeImportDiagnosticTerm(
        l10n,
        diagnostic.argument<ImportDiagnosticTerm>('field'),
      ),
      diagnostic.argument<int>('limit'),
    ),
    ImportDiagnosticCode.listClamped => l10n.importDiagnosticListClamped(
      diagnostic.argument<int>('count'),
      localizeImportDiagnosticTerm(
        l10n,
        diagnostic.argument<ImportDiagnosticTerm>('field'),
      ),
      diagnostic.argument<int>('limit'),
    ),
  };
}

String _localizeMissingReference(
  AppLocalizations l10n,
  ImportDiagnostic diagnostic,
) {
  final record = localizeImportDiagnosticTerm(
    l10n,
    diagnostic.argument<ImportDiagnosticTerm>('record'),
  );
  final recordName = diagnostic.arguments['recordName'] as String?;
  return l10n.importDiagnosticIgnoredMissingReference(
    recordName == null
        ? record
        : l10n.importDiagnosticNamedRecord(record, recordName),
    localizeImportDiagnosticTerm(
      l10n,
      diagnostic.argument<ImportDiagnosticTerm>('relation'),
    ),
    diagnostic.argument<String>('value'),
  );
}

String localizeImportDiagnosticTerm(
  AppLocalizations l10n,
  ImportDiagnosticTerm term, {
  bool sentenceStart = false,
}) {
  if (sentenceStart) {
    return switch (term) {
      ImportDiagnosticTerm.member => l10n.importTermMemberSentenceStart,
      ImportDiagnosticTerm.group => l10n.importTermGroupSentenceStart,
      ImportDiagnosticTerm.front => l10n.importTermFrontSentenceStart,
      _ => localizeImportDiagnosticTerm(l10n, term),
    };
  }
  return switch (term) {
    ImportDiagnosticTerm.member => l10n.importTermMember,
    ImportDiagnosticTerm.privacyBucket => l10n.importTermPrivacyBucket,
    ImportDiagnosticTerm.idOrName => l10n.importTermIdOrName,
    ImportDiagnosticTerm.name => l10n.importTermName,
    ImportDiagnosticTerm.group => l10n.importTermGroup,
    ImportDiagnosticTerm.customFront => l10n.importTermCustomFront,
    ImportDiagnosticTerm.label => l10n.importTermLabel,
    ImportDiagnosticTerm.customField => l10n.importTermCustomField,
    ImportDiagnosticTerm.customFieldValue => l10n.importTermCustomFieldValue,
    ImportDiagnosticTerm.note => l10n.importTermNote,
    ImportDiagnosticTerm.titleAndBody => l10n.importTermTitleAndBody,
    ImportDiagnosticTerm.journal => l10n.importTermJournal,
    ImportDiagnosticTerm.chatChannel => l10n.importTermChatChannel,
    ImportDiagnosticTerm.chatCategory => l10n.importTermChatCategory,
    ImportDiagnosticTerm.message => l10n.importTermMessage,
    ImportDiagnosticTerm.body => l10n.importTermBody,
    ImportDiagnosticTerm.reminder => l10n.importTermReminder,
    ImportDiagnosticTerm.titleOrSchedule => l10n.importTermTitleOrSchedule,
    ImportDiagnosticTerm.poll => l10n.importTermPoll,
    ImportDiagnosticTerm.question => l10n.importTermQuestion,
    ImportDiagnosticTerm.front => l10n.importTermFront,
    ImportDiagnosticTerm.startTime => l10n.importTermStartTime,
    ImportDiagnosticTerm.memberIdsOrCustomLabel =>
      l10n.importTermMemberIdsOrCustomLabel,
    ImportDiagnosticTerm.importedRecord => l10n.importTermImportedRecord,
    ImportDiagnosticTerm.parent => l10n.importTermParent,
    ImportDiagnosticTerm.systemName => l10n.importTermSystemName,
    ImportDiagnosticTerm.memberName => l10n.importTermMemberName,
    ImportDiagnosticTerm.memberPronouns => l10n.importTermMemberPronouns,
    ImportDiagnosticTerm.memberBirthday => l10n.importTermMemberBirthday,
    ImportDiagnosticTerm.memberEmoji => l10n.importTermMemberEmoji,
    ImportDiagnosticTerm.memberDescription => l10n.importTermMemberDescription,
    ImportDiagnosticTerm.avatarUrl => l10n.importTermAvatarUrl,
    ImportDiagnosticTerm.groupName => l10n.importTermGroupName,
    ImportDiagnosticTerm.customFieldName => l10n.importTermCustomFieldName,
    ImportDiagnosticTerm.contentTitle => l10n.importTermContentTitle,
    ImportDiagnosticTerm.longTextField => l10n.importTermLongTextField,
    ImportDiagnosticTerm.journalBody => l10n.importTermJournalBody,
    ImportDiagnosticTerm.messageBody => l10n.importTermMessageBody,
    ImportDiagnosticTerm.reminderTitle => l10n.importTermReminderTitle,
    ImportDiagnosticTerm.reminderBody => l10n.importTermReminderBody,
    ImportDiagnosticTerm.reminderSchedule => l10n.importTermReminderSchedule,
    ImportDiagnosticTerm.pollQuestion => l10n.importTermPollQuestion,
    ImportDiagnosticTerm.pollDescription => l10n.importTermPollDescription,
    ImportDiagnosticTerm.pollOption => l10n.importTermPollOption,
    ImportDiagnosticTerm.pollOptionList => l10n.importTermPollOptionList,
    ImportDiagnosticTerm.frontStatusNote => l10n.importTermFrontStatusNote,
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
