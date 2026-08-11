import 'dart:io';

/// Returns whether an imported remote avatar URL resolves only to a public
/// address and uses a supported web port.
///
/// Imported archives are untrusted input. The caller must also disable
/// redirect following so a public URL cannot redirect into a private network.
typedef RemoteAvatarLookup =
    Future<List<InternetAddress>> Function(String host);

Future<List<InternetAddress>?> allowedRemoteAvatarAddresses(
  Uri uri, {
  RemoteAvatarLookup lookup = InternetAddress.lookup,
}) async {
  if (uri.scheme != 'https' ||
      uri.host.trim().isEmpty ||
      uri.userInfo.isNotEmpty ||
      (uri.port != 0 && uri.port != 80 && uri.port != 443) ||
      !uri.hasAbsolutePath) {
    return null;
  }

  try {
    final addresses = await lookup(uri.host);
    if (addresses.isEmpty || !addresses.every(_isPublicAddress)) {
      return null;
    }
    return List.unmodifiable(addresses);
  } on SocketException {
    return null;
  }
}

Future<bool> isAllowedRemoteAvatarUri(Uri uri) async =>
    await allowedRemoteAvatarAddresses(uri) != null;

bool _isPublicAddress(InternetAddress address) {
  final bytes = address.rawAddress;
  if (bytes.length == 4) {
    return !_isBlockedIpv4(bytes);
  }
  if (bytes.length != 16) {
    return false;
  }

  final isIpv4Mapped =
      bytes.sublist(0, 10).every((byte) => byte == 0) &&
      bytes[10] == 0xff &&
      bytes[11] == 0xff;
  if (isIpv4Mapped) {
    return !_isBlockedIpv4(bytes.sublist(12));
  }

  final isIpv4Compatible = bytes.sublist(0, 12).every((byte) => byte == 0);
  if (isIpv4Compatible) {
    return !_isBlockedIpv4(bytes.sublist(12));
  }

  final first = bytes[0];
  final isUnspecified = bytes.every((byte) => byte == 0);
  final isUniqueLocal = first >= 0xfc && first <= 0xfd;
  final isLinkLocal = first == 0xfe && (bytes[1] & 0xc0) == 0x80;
  final isMulticast = first >= 0xff;
  return !isUnspecified && !isUniqueLocal && !isLinkLocal && !isMulticast;
}

bool _isBlockedIpv4(List<int> bytes) {
  final first = bytes[0];
  final second = bytes[1];
  final third = bytes[2];

  return first == 0 ||
      first == 10 ||
      first == 127 ||
      (first == 100 && second >= 64 && second <= 127) ||
      (first == 169 && second == 254) ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 0 && third == 0) ||
      (first == 192 && second == 0 && third == 2) ||
      (first == 192 && second == 168) ||
      (first == 198 && (second == 18 || second == 19)) ||
      (first == 198 && second == 51 && third == 100) ||
      (first == 203 && second == 0 && third == 113) ||
      first >= 224;
}
