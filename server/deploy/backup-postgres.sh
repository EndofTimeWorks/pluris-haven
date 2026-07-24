#!/bin/sh
set -eu

umask 077
: "${PLURIS_BACKUP_DATABASE_URL:?PLURIS_BACKUP_DATABASE_URL is required}"

backup_dir="${PLURIS_BACKUP_DIR:-/var/backups/pluris-haven}"
retention_days="${PLURIS_BACKUP_RETENTION_DAYS:-14}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
temporary="$backup_dir/.pluris-$timestamp.dump.tmp"
destination="$backup_dir/pluris-$timestamp.dump"

mkdir -p "$backup_dir"
pg_dump \
  --format=custom \
  --compress=9 \
  --no-owner \
  --no-acl \
  --file="$temporary" \
  "$PLURIS_BACKUP_DATABASE_URL"
mv "$temporary" "$destination"
find "$backup_dir" -type f -name 'pluris-*.dump' -mtime "+$retention_days" -delete
printf '%s\n' "$destination"

