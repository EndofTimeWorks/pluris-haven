import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/remote_avatar_policy.dart';

void main() {
  test(
    'rejects loopback, link-local, private, and metadata addresses',
    () async {
      for (final host in [
        '0.0.0.0',
        '10.0.0.1',
        '127.0.0.1',
        '169.254.169.254',
        '172.16.0.1',
        '192.168.1.1',
      ]) {
        expect(
          await isAllowedRemoteAvatarUri(Uri.parse('http://$host/avatar.png')),
          isFalse,
          reason: 'should reject $host',
        );
      }
    },
  );

  test('rejects unsupported schemes, credentials, and ports', () async {
    expect(
      await isAllowedRemoteAvatarUri(Uri.parse('file:///etc/passwd')),
      isFalse,
    );
    expect(
      await isAllowedRemoteAvatarUri(
        Uri.parse('http://user:password@127.0.0.1/avatar.png'),
      ),
      isFalse,
    );
    expect(
      await isAllowedRemoteAvatarUri(
        Uri.parse('http://127.0.0.1:8080/avatar.png'),
      ),
      isFalse,
    );
  });
}
