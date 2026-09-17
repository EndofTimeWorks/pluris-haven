import 'haven_repository.dart';

Future<void> runLocalMigrations(LocalHavenRepository repository) async {
  await repository.ensureLocalSystem();
  await repository.migrateLegacyLocalTextToAad();
  await repository.migrateUnauthenticatedEmptyCiphertexts();
  await repository.migrateMemberNamesToEncryption();
  await repository.migrateBlindIndexesToUnicodeNormalization();
}
