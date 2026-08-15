enum ImportDiagnosticCode {
  jsonParseFailed,
  expectedTopLevelObject,
  prismNeedsDecryption,
  notPlurisArchive,
  unsupportedArchiveVersion,
  foundMembersAndFronts,
  recognizedRecords,
  noImportableRecords,
  preservedRawPayloads,
  remoteAvatarsWithoutZip,
  bestEffortImport,
  encryptedArchiveLocked,
  encryptedArchiveDecryptFailed,
  skippedExpectedObject,
  skippedMissingFields,
  ignoredMissingRelation,
  ignoredSelfParent,
  reminderMissingMember,
  pollTooFewOptions,
  ignoredMissingReference,
  frontReversed,
  stringClamped,
  listClamped,
}

class ImportDiagnostic {
  const ImportDiagnostic(this.code, [this.arguments = const {}]);

  final ImportDiagnosticCode code;
  final Map<String, Object?> arguments;

  T argument<T>(String name) => arguments[name] as T;
}

class ImportDiagnosticException implements Exception {
  const ImportDiagnosticException(this.diagnostic);

  final ImportDiagnostic diagnostic;
}
