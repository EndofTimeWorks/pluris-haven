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

enum ImportDiagnosticTerm {
  member,
  privacyBucket,
  idOrName,
  name,
  group,
  customFront,
  label,
  customField,
  customFieldValue,
  note,
  titleAndBody,
  journal,
  chatChannel,
  chatCategory,
  message,
  body,
  reminder,
  titleOrSchedule,
  poll,
  question,
  front,
  startTime,
  memberIdsOrCustomLabel,
  importedRecord,
  parent,
  systemName,
  memberName,
  memberPronouns,
  memberBirthday,
  memberEmoji,
  memberDescription,
  avatarUrl,
  groupName,
  customFieldName,
  customFieldConfiguration,
  contentTitle,
  longTextField,
  journalBody,
  messageBody,
  reminderTitle,
  reminderBody,
  reminderSchedule,
  pollQuestion,
  pollDescription,
  pollOption,
  pollOptionList,
  frontStatusNote,
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
