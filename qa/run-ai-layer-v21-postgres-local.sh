#!/usr/bin/env bash
# iClub AI Layer v2.1: ONE-TIME disposable local PostgreSQL verification.
# This script NEVER connects to production Supabase and NEVER creates a database.
# Operator creates a NEW empty scratch DB separately, then runs this script.
set -euo pipefail
cd "$(dirname "$0")/.."

DB="${ICLUB_PGTEST_DB:-}"
HOST="${ICLUB_PGTEST_HOST:-127.0.0.1}"
PORT="${ICLUB_PGTEST_PORT:-5432}"
SUITE="${ICLUB_PGTEST_SUITE:-meter}"
case "$SUITE" in
  meter) TEST_FILE="qa/sql_drafts/iclub_ai_v21_local_pg_regression.psql" ;;
  math) TEST_FILE="qa/sql_drafts/iclub_ai_math_authority_local_pg.psql" ;;
  *) echo "STOP: ICLUB_PGTEST_SUITE must be meter or math" >&2; exit 2 ;;
esac

if [[ ! "$DB" =~ ^iclub_ai_v21_scratch_[a-z0-9_]+$ ]]; then
  echo "STOP: ICLUB_PGTEST_DB must be a NEW disposable database named iclub_ai_v21_scratch_*" >&2
  exit 2
fi
if [[ "$HOST" != "127.0.0.1" && "$HOST" != "localhost" && "$HOST" != "::1" ]]; then
  echo "STOP: remote PostgreSQL hosts are prohibited for the AI Layer test." >&2
  exit 2
fi
if [[ ! "$PORT" =~ ^[0-9]{1,5}$ ]] || (( 10#$PORT < 1 || 10#$PORT > 65535 )); then
  echo "STOP: invalid local port." >&2
  exit 2
fi
if ! command -v psql >/dev/null 2>&1; then
  echo "NO-GO: PostgreSQL psql is not installed. No test was executed." >&2
  exit 3
fi

# Ensure no accidental Supabase network credentials are used.
unset PGHOST PGHOSTADDR PGDATABASE PGPORT PGSERVICE PGSERVICEFILE PGOPTIONS
unset DATABASE_URL SUPABASE_DB_URL SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY

echo "Checking that $HOST:$PORT/$DB is a brand-new LOCAL scratch database..."
check="$(psql -X -w -v ON_ERROR_STOP=1 -h "$HOST" -p "$PORT" -d "$DB" -Atc "
  select case when current_database() ~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
     and (inet_server_addr() is null or inet_server_addr() in ('127.0.0.1'::inet,'::1'::inet))
     and not exists (select 1 from pg_tables where schemaname not in ('pg_catalog','information_schema'))
    then 'SCRATCH_OK' else 'NOT_EMPTY_OR_UNSAFE' end;" 2>&1)" || {
  echo "NO-GO: cannot safely verify scratch connection: $check" >&2
  exit 4
}
if [[ "$check" != "SCRATCH_OK" ]]; then
  echo "STOP: scratch DB is not empty or failed the local-only guard: $check" >&2
  exit 4
fi
echo "Scratch-only checks passed. Running SQL in the local disposable database..."
psql -X -w -v ON_ERROR_STOP=1 -h "$HOST" -p "$PORT" -d "$DB" -f "$TEST_FILE"
echo "LOCAL SQL TEST COMPLETE. Scratch DB must be destroyed separately after review."
