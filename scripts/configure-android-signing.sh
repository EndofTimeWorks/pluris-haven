#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
android_directory="${repository_root}/mobile/android"
keystore_path="${android_directory}/app/pluris-haven-upload.jks"
properties_path="${android_directory}/key.properties"

required_variables=(
  ANDROID_KEYSTORE_BASE64
  ANDROID_KEYSTORE_PASSWORD
  ANDROID_KEY_ALIAS
  ANDROID_KEY_PASSWORD
)
for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "${variable_name} is not configured." >&2
    exit 1
  fi
done

umask 077
printf '%s' "${ANDROID_KEYSTORE_BASE64}" | base64 --decode > "${keystore_path}"

keytool_output="$(mktemp)"
trap 'rm -f "${keytool_output}"' EXIT
if ! keytool -list \
  -keystore "${keystore_path}" \
  -storepass "${ANDROID_KEYSTORE_PASSWORD}" \
  -alias "${ANDROID_KEY_ALIAS}" >"${keytool_output}" 2>&1; then
  cat "${keytool_output}" >&2
  echo "Android signing key alias was not found in the uploaded keystore." >&2
  exit 1
fi

{
  echo "storeFile=pluris-haven-upload.jks"
  echo "storePassword=${ANDROID_KEYSTORE_PASSWORD}"
  echo "keyAlias=${ANDROID_KEY_ALIAS}"
  echo "keyPassword=${ANDROID_KEY_PASSWORD}"
} > "${properties_path}"
