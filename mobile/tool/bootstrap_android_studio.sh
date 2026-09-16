#!/usr/bin/env bash

# Prepare a fresh clone for Android Studio without committing machine-specific
# SDK paths. Safe to rerun: an existing local.properties is never replaced.
set -euo pipefail

mobile_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
android_dir="$mobile_dir/android"
local_properties="$android_dir/local.properties"

if ! command -v mise >/dev/null 2>&1; then
  echo "mise is required. Install mise, then from the repository root run: mise trust && mise install" >&2
  exit 1
fi

flutter_bin=$(mise exec -- which flutter)

if [[ ! -f "$local_properties" ]]; then
  android_sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}
  if [[ -z "$android_sdk" || ! -d "$android_sdk" ]]; then
    echo "Set ANDROID_SDK_ROOT (or ANDROID_HOME) before bootstrapping Android Studio." >&2
    exit 1
  fi
  flutter_sdk=$(cd -- "$(dirname -- "$flutter_bin")/.." && pwd)
  {
    printf 'sdk.dir=%s\n' "${android_sdk//\\/\\\\}"
    printf 'flutter.sdk=%s\n' "${flutter_sdk//\\/\\\\}"
  } >"$local_properties"
  echo "Created ignored android/local.properties for this machine."
fi

cd "$mobile_dir"
mise exec -- flutter pub get
echo "Android Studio is ready: open $mobile_dir as the Flutter project."
