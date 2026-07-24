import 'package:cryptography/cryptography.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/data/security/haven_crypto.dart';

/// Stable test-only key material. Production repositories always receive the
/// key loaded from platform secure storage.
HavenCrypto testCrypto() =>
    HavenCrypto(SecretKey(List<int>.filled(32, 0x42, growable: false)));

LocalHavenRepository testRepository(AppDatabase database) =>
    LocalHavenRepository(database, crypto: testCrypto());
