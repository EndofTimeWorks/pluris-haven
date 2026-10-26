import 'dart:io';

/// Limit other Linux users' access to local ciphertext and its metadata.
Future<void> protectLocalDirectory(Directory directory) async {
  if (!Platform.isLinux) return;
  await _chmod('0700', directory.path);
}

Future<void> protectLocalFile(File file) async {
  if (!Platform.isLinux) return;
  await _chmod('0600', file.path);
}

Future<void> _chmod(String mode, String path) async {
  final result = await Process.run('chmod', [mode, path]);
  if (result.exitCode != 0) {
    throw FileSystemException(
      'Could not protect local app data',
      path,
      OSError(result.stderr.toString().trim(), result.exitCode),
    );
  }
}
