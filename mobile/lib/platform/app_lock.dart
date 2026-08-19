import 'package:local_auth/local_auth.dart';

/// Thin wrapper around [LocalAuthentication] for the optional app-lock
/// gate. Delegates to whatever the device already has configured
/// (biometrics, PIN, pattern, or password) rather than storing a
/// separate app-specific secret.
class AppLock {
  AppLock._();

  static final _auth = LocalAuthentication();

  /// Whether this device has any usable authentication method (biometric
  /// or device credential) so the app-lock setting can be offered at all.
  static Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  /// Prompts the device's own unlock UI. Returns false on any failure or
  /// cancellation rather than throwing, so a platform quirk never locks
  /// someone out of their own local data.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on Object {
      return false;
    }
  }
}
