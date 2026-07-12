#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mobile_dir="${repo_root}/mobile"

restore_dangling_directory_link() {
  local path="$1"
  local target

  if [[ -L "${path}" && ! -e "${path}" ]]; then
    target="$(readlink "${path}")"
    if [[ "${target}" != /* ]]; then
      target="$(dirname "${path}")/${target}"
    fi
    mkdir -p "${target}"
  fi
}

usage() {
  cat <<'EOF'
Usage: scripts/build-mobile.sh <target> [flutter build options]

Targets:
  android-debug    Build an installable debug APK.
  android-release  Build a release APK using the configured Android signing key.
  android-split    Build release APKs split by Android ABI.
  ios-check        Compile an unsigned release iOS app. Requires macOS and Xcode.
  ios-debug        Compile an unsigned debug iOS app. Requires macOS and Xcode.

Additional arguments are passed to `flutter build`.
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 64
fi

target="$1"
shift

case "${target}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not available on PATH." >&2
  exit 127
fi

cd "${mobile_dir}"
restore_dangling_directory_link "${mobile_dir}/.dart_tool"
restore_dangling_directory_link "${mobile_dir}/build"
flutter pub get

case "${target}" in
  android-debug)
    flutter build apk --debug "$@"
    ;;
  android-release)
    flutter build apk --release "$@"
    ;;
  android-split)
    flutter build apk --release --split-per-abi "$@"
    ;;
  ios-check)
    if [[ "$(uname -s)" != "Darwin" ]]; then
      echo "The iOS target requires macOS with Xcode installed." >&2
      exit 69
    fi
    flutter build ios --release --no-codesign "$@"
    ;;
  ios-debug)
    if [[ "$(uname -s)" != "Darwin" ]]; then
      echo "The iOS target requires macOS with Xcode installed." >&2
      exit 69
    fi
    flutter build ios --debug --no-codesign "$@"
    ;;
  *)
    echo "Unknown target: ${target}" >&2
    usage >&2
    exit 64
    ;;
esac
