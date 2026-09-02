import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/types/auth_exception.dart';

enum AppLockAvailability { available, unsupported, error }

enum AppLockAuthenticationResult { authenticated, unavailable, failed }

/// Thin wrapper around [LocalAuthentication] for the optional app-lock
/// gate. Delegates to whatever the device already has configured
/// (biometrics, PIN, pattern, or password) rather than storing a
/// separate app-specific secret.
class AppLock {
  AppLock._();

  static final _auth = LocalAuthentication();

  /// Whether this device has a usable authentication method. Platform failures
  /// are distinct from a device that genuinely has no credentials configured.
  static Future<AppLockAvailability> availability() async {
    try {
      return await _auth.isDeviceSupported()
          ? AppLockAvailability.available
          : AppLockAvailability.unsupported;
    } on Object {
      return AppLockAvailability.error;
    }
  }

  /// Prompts the device's own unlock UI. A missing device credential is
  /// distinct from a cancellation or platform failure so callers can avoid
  /// claiming that App Lock remains enabled when it cannot work.
  static Future<AppLockAuthenticationResult> authenticate(String reason) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return authenticated
          ? AppLockAuthenticationResult.authenticated
          : AppLockAuthenticationResult.failed;
    } on LocalAuthException catch (error) {
      return error.code == LocalAuthExceptionCode.noCredentialsSet
          ? AppLockAuthenticationResult.unavailable
          : AppLockAuthenticationResult.failed;
    } on Object {
      return AppLockAuthenticationResult.failed;
    }
  }
}
