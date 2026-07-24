#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s BACKUP.dump\n' "$0" >&2
  exit 2
fi

backup="$1"
if [ ! -r "$backup" ]; then
  printf 'Backup is not readable: %s\n' "$backup" >&2
  exit 2
fi

database="pluris_restore_$(date -u +%Y%m%d%H%M%S)_$$"
cleanup() {
  dropdb --if-exists "$database" >/dev/null
}
trap cleanup EXIT INT TERM

pg_restore --list "$backup" >/dev/null
createdb "$database"
pg_restore --exit-on-error --no-owner --no-acl --dbname="$database" "$backup"

table_count="$(psql --dbname="$database" --tuples-only --no-align --command="
  SELECT count(*)
  FROM information_schema.tables
  WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
")"

if [ "$table_count" -lt 6 ]; then
  printf 'Restore completed but only %s application tables were found.\n' "$table_count" >&2
  exit 1
fi

printf 'Restore rehearsal passed with %s application tables.\n' "$table_count"

