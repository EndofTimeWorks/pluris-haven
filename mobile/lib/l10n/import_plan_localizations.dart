import '../data/import/import_plan.dart';
import '../data/import/import_sources.dart';
import 'app_localizations.dart';

String localizeImportSource(AppLocalizations l10n, ImportSource source) {
  return switch (source) {
    ImportSource.plurisHavenArchive => l10n.importSourcePlurisHavenArchive,
    ImportSource.simplyPlural => l10n.importSourceSimplyPlural,
    ImportSource.pluralKitFile => l10n.importSourcePluralKitFile,
    ImportSource.pluralKitLive => l10n.importSourcePluralKitLive,
    ImportSource.tupperbox => l10n.importSourceTupperbox,
    ImportSource.pluralSpace => l10n.importSourcePluralSpace,
    ImportSource.prism => l10n.importSourcePrism,
  };
}

String localizeImportInput(AppLocalizations l10n, ImportSource source) {
  return switch (source) {
    ImportSource.plurisHavenArchive ||
    ImportSource.simplyPlural ||
    ImportSource.pluralKitFile ||
    ImportSource.tupperbox ||
    ImportSource.pluralSpace => l10n.importInputFile,
    ImportSource.pluralKitLive => l10n.importInputLiveToken,
    ImportSource.prism => l10n.importInputEncryptedFile,
  };
}

String localizeImportDedupe(AppLocalizations l10n, ImportSource source) {
  return switch (source) {
    ImportSource.plurisHavenArchive => l10n.importDedupePlurisHaven,
    ImportSource.simplyPlural => l10n.importDedupeSimplyPlural,
    ImportSource.pluralKitFile => l10n.importDedupePluralKitFile,
    ImportSource.pluralKitLive => l10n.importDedupePluralKitLive,
    ImportSource.tupperbox => l10n.importDedupeTupperbox,
    ImportSource.pluralSpace => l10n.importDedupePluralSpace,
    ImportSource.prism => l10n.importDedupePrism,
  };
}

String localizeImportConflictStrategy(
  AppLocalizations l10n,
  ImportConflictStrategy strategy,
) {
  return switch (strategy) {
    ImportConflictStrategy.prompt => l10n.importConflictPrompt,
    ImportConflictStrategy.create => l10n.importConflictCreate,
    ImportConflictStrategy.skip => l10n.importConflictSkip,
    ImportConflictStrategy.update => l10n.importConflictUpdate,
  };
}

String localizeImportPlanStatus(
  AppLocalizations l10n,
  ImportPlanStatus status,
) {
  return switch (status) {
    ImportPlanStatus.ready => l10n.importPlanStatusReady,
    ImportPlanStatus.next => l10n.importPlanStatusNext,
    ImportPlanStatus.planned => l10n.importPlanStatusPlanned,
  };
}

String localizeImportDetectionReason(
  AppLocalizations l10n,
  ImportDetectionReason reason,
) {
  return switch (reason) {
    ImportDetectionReason.prismExtension => l10n.importReasonPrismExtension,
    ImportDetectionReason.plurisFileName => l10n.importReasonPlurisFileName,
    ImportDetectionReason.simplyPluralFileName =>
      l10n.importReasonSimplyPluralFileName,
    ImportDetectionReason.pluralKitFileName =>
      l10n.importReasonPluralKitFileName,
    ImportDetectionReason.tupperboxFileName =>
      l10n.importReasonTupperboxFileName,
    ImportDetectionReason.pluralSpaceFileName =>
      l10n.importReasonPluralSpaceFileName,
    ImportDetectionReason.chooseAfterUpload =>
      l10n.importReasonChooseAfterUpload,
    ImportDetectionReason.encryptedPlurisArchive =>
      l10n.importReasonEncryptedPlurisArchive,
    ImportDetectionReason.localPlurisArchive =>
      l10n.importReasonLocalPlurisArchive,
    ImportDetectionReason.tupperboxFields => l10n.importReasonTupperboxFields,
    ImportDetectionReason.pluralKitFields => l10n.importReasonPluralKitFields,
    ImportDetectionReason.simplyPluralFields =>
      l10n.importReasonSimplyPluralFields,
    ImportDetectionReason.pluralSpaceMarkers =>
      l10n.importReasonPluralSpaceMarkers,
    ImportDetectionReason.ambiguousMemberGroupJson =>
      l10n.importReasonAmbiguousMemberGroupJson,
    ImportDetectionReason.unrecognised => l10n.importReasonUnrecognised,
  };
}

String localizeImportPlanCount(AppLocalizations l10n, ImportPlanCount count) {
  return switch (count) {
    ImportPlanCount.members => l10n.importCountMembers,
    ImportPlanCount.groups => l10n.importCountGroups,
    ImportPlanCount.notes => l10n.importCountNotes,
    ImportPlanCount.journals => l10n.importCountJournals,
    ImportPlanCount.messages => l10n.importCountMessages,
    ImportPlanCount.reminders => l10n.importCountReminders,
    ImportPlanCount.tags => l10n.importCountTags,
    ImportPlanCount.customFields => l10n.importCountCustomFields,
    ImportPlanCount.polls => l10n.importCountPolls,
    ImportPlanCount.frontHistory => l10n.importCountFrontHistory,
    ImportPlanCount.notifications => l10n.importCountNotifications,
    ImportPlanCount.preferences => l10n.importCountPreferences,
    ImportPlanCount.customFronts => l10n.importCountCustomFronts,
    ImportPlanCount.switches => l10n.importCountSwitches,
    ImportPlanCount.frontIntervals => l10n.importCountFrontIntervals,
    ImportPlanCount.tuppers => l10n.importCountTuppers,
    ImportPlanCount.avatars => l10n.importCountAvatars,
    ImportPlanCount.fronts => l10n.importCountFronts,
  };
}

({String title, String detail}) localizeImportPlanStep(
  AppLocalizations l10n,
  ImportPlanStep step,
) {
  return switch (step) {
    ImportPlanStep.readPlurisArchive => (
      title: l10n.importStepReadArchiveTitle,
      detail: l10n.importStepReadPlurisArchiveDetail,
    ),
    ImportPlanStep.validatePlurisArchive => (
      title: l10n.importStepValidateFormatTitle,
      detail: l10n.importStepValidatePlurisArchiveDetail,
    ),
    ImportPlanStep.reviewPlurisArchive => (
      title: l10n.importStepReviewContentsTitle,
      detail: l10n.importStepReviewPlurisArchiveDetail,
    ),
    ImportPlanStep.restorePlurisArchive => (
      title: l10n.importStepRestoreLocallyTitle,
      detail: l10n.importStepRestorePlurisArchiveDetail,
    ),
    ImportPlanStep.readSimplyPlural => (
      title: l10n.importStepReadExportTitle,
      detail: l10n.importStepReadSimplyPluralDetail,
    ),
    ImportPlanStep.normalizeSimplyPlural => (
      title: l10n.importStepNormalizeFieldsTitle,
      detail: l10n.importStepNormalizeSimplyPluralDetail,
    ),
    ImportPlanStep.prepareSimplyPluralAvatars => (
      title: l10n.importStepPrepareAvatarsTitle,
      detail: l10n.importStepPrepareSimplyPluralAvatarsDetail,
    ),
    ImportPlanStep.reviewSimplyPlural => (
      title: l10n.importStepReviewMatchesTitle,
      detail: l10n.importStepReviewSimplyPluralDetail,
    ),
    ImportPlanStep.writeSimplyPlural => (
      title: l10n.importStepWriteLocallyTitle,
      detail: l10n.importStepWriteSimplyPluralDetail,
    ),
    ImportPlanStep.readPluralKitFile => (
      title: l10n.importStepReadExportTitle,
      detail: l10n.importStepReadPluralKitFileDetail,
    ),
    ImportPlanStep.buildPluralKitRoster => (
      title: l10n.importStepBuildRosterTitle,
      detail: l10n.importStepBuildPluralKitRosterDetail,
    ),
    ImportPlanStep.convertPluralKitSwitches => (
      title: l10n.importStepConvertSwitchesTitle,
      detail: l10n.importStepConvertPluralKitSwitchesDetail,
    ),
    ImportPlanStep.reviewPluralKitFile => (
      title: l10n.importStepReviewMatchesTitle,
      detail: l10n.importStepReviewPluralKitFileDetail,
    ),
    ImportPlanStep.validatePluralKitToken => (
      title: l10n.importStepValidateTokenTitle,
      detail: l10n.importStepValidatePluralKitTokenDetail,
    ),
    ImportPlanStep.fetchPluralKitRoster => (
      title: l10n.importStepFetchRosterTitle,
      detail: l10n.importStepFetchPluralKitRosterDetail,
    ),
    ImportPlanStep.fetchPluralKitSwitches => (
      title: l10n.importStepFetchSwitchesTitle,
      detail: l10n.importStepFetchPluralKitSwitchesDetail,
    ),
    ImportPlanStep.reviewPluralKitLive => (
      title: l10n.importStepReviewMatchesTitle,
      detail: l10n.importStepReviewPluralKitLiveDetail,
    ),
    ImportPlanStep.readTupperbox => (
      title: l10n.importStepReadRosterTitle,
      detail: l10n.importStepReadTupperboxDetail,
    ),
    ImportPlanStep.mapTupperbox => (
      title: l10n.importStepMapTuppersTitle,
      detail: l10n.importStepMapTupperboxDetail,
    ),
    ImportPlanStep.reviewTupperbox => (
      title: l10n.importStepReviewMatchesTitle,
      detail: l10n.importStepReviewTupperboxDetail,
    ),
    ImportPlanStep.readPluralSpace => (
      title: l10n.importStepReadExportTitle,
      detail: l10n.importStepReadPluralSpaceDetail,
    ),
    ImportPlanStep.mapPluralSpace => (
      title: l10n.importStepMapRecordsTitle,
      detail: l10n.importStepMapPluralSpaceDetail,
    ),
    ImportPlanStep.reviewPluralSpace => (
      title: l10n.importStepReviewMatchesTitle,
      detail: l10n.importStepReviewPluralSpaceDetail,
    ),
    ImportPlanStep.choosePrism => (
      title: l10n.importStepChoosePrismTitle,
      detail: l10n.importStepChoosePrismDetail,
    ),
    ImportPlanStep.decryptPrism => (
      title: l10n.importStepDecryptPreviewTitle,
      detail: l10n.importStepDecryptPrismDetail,
    ),
    ImportPlanStep.reviewPrism => (
      title: l10n.importStepReviewMatchesTitle,
      detail: l10n.importStepReviewPrismDetail,
    ),
  };
}

String localizeImportPrivacyNote(
  AppLocalizations l10n,
  ImportPrivacyNote note,
) {
  return switch (note) {
    ImportPrivacyNote.previewBeforeWrite =>
      l10n.importPrivacyPreviewBeforeWrite,
    ImportPrivacyNote.localBackupRestore =>
      l10n.importPrivacyLocalBackupRestore,
    ImportPrivacyNote.simplyPluralDedupe =>
      l10n.importPrivacySimplyPluralDedupe,
    ImportPrivacyNote.simplyPluralAvatars =>
      l10n.importPrivacySimplyPluralAvatars,
    ImportPrivacyNote.pluralKitIdentifiers =>
      l10n.importPrivacyPluralKitIdentifiers,
    ImportPrivacyNote.pluralKitSwitches => l10n.importPrivacyPluralKitSwitches,
    ImportPrivacyNote.pluralKitTokenEphemeral =>
      l10n.importPrivacyPluralKitTokenEphemeral,
    ImportPrivacyNote.pluralKitLiveNetwork =>
      l10n.importPrivacyPluralKitLiveNetwork,
    ImportPrivacyNote.tupperboxIdentifiers =>
      l10n.importPrivacyTupperboxIdentifiers,
    ImportPrivacyNote.tupperboxProxyMetadata =>
      l10n.importPrivacyTupperboxProxyMetadata,
    ImportPrivacyNote.pluralSpaceIdentifiers =>
      l10n.importPrivacyPluralSpaceIdentifiers,
    ImportPrivacyNote.pluralSpaceUnknownFields =>
      l10n.importPrivacyPluralSpaceUnknownFields,
    ImportPrivacyNote.prismPassphraseMemoryOnly =>
      l10n.importPrivacyPrismPassphraseMemoryOnly,
    ImportPrivacyNote.prismIdentifiers => l10n.importPrivacyPrismIdentifiers,
  };
}
