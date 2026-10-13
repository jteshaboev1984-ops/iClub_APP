#!/usr/bin/env bash
# Real concurrency in two independent PG connections, scratch DB only.
set -euo pipefail
cd "$(dirname "$0")/.."
DB="${ICLUB_PGTEST_DB:-}"
HOST="${ICLUB_PGTEST_HOST:-127.0.0.1}"
PORT="${ICLUB_PGTEST_PORT:-5432}"
if [[ ! "$DB" =~ ^iclub_ai_v21_scratch_[a-z0-9_]+$ ]] ||
   [[ "$HOST" != "127.0.0.1" ]] ||
   [[ ! "$PORT" =~ ^[0-9]{1,5}$ ]]; then
 echo "STOP: only a named scratch DB through local loopback may be used" >&2
 exit 2
fi
unset DATABASE_URL SUPABASE_DB_URL SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY
unset PGHOST PGHOSTADDR PGDATABASE PGPORT PGSERVICE PGSERVICEFILE PGOPTIONS
export PGAPPNAME=iclub_ai_v21_local_scratch
PG=(psql -X -w -v ON_ERROR_STOP=1 -h "$HOST" -p "$PORT" -U postgres -d "$DB")
check="$("${PG[@]}" -Atc "
 SELECT CASE WHEN current_database() ~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 AND (inet_server_addr() IN ('127.0.0.1'::inet,'::1'::inet)
  OR (inet_server_addr() << '172.16.0.0/12'::cidr
   AND current_setting('application_name')='iclub_ai_v21_local_scratch'))
 AND NOT EXISTS(SELECT 1 FROM pg_tables WHERE schemaname NOT IN
  ('pg_catalog','information_schema') AND schemaname !~ '^pg_')
 THEN 'SCRATCH_OK' ELSE 'UNSAFE' END;")"
[[ "$check" == "SCRATCH_OK" ]] || { echo "STOP: not empty local scratch DB" >&2; exit 3; }
"${PG[@]}" <<'SQL'
CREATE SCHEMA private;
DO $roles$
DECLARE r text;
BEGIN
 FOREACH r IN ARRAY ARRAY['anon','authenticated','service_role'] LOOP
  IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname=r) THEN
   EXECUTE format('CREATE ROLE %I NOLOGIN',r);
  END IF;
 END LOOP;
END $roles$;
CREATE TABLE private.iclub_ai_usage_reservations(
 request_id uuid PRIMARY KEY,user_id uuid NOT NULL,request_fingerprint text NOT NULL,
 route_class text NOT NULL,status text NOT NULL,expires_at timestamptz NOT NULL);
INSERT INTO private.iclub_ai_usage_reservations VALUES(
 '11111111-1111-4111-8111-111111111111',
 '22222222-2222-4222-8222-222222222222',
 repeat('b',64),'generated','reserved',now()+interval '90 seconds');
SQL
"${PG[@]}" -f qa/sql_drafts/iclub_ai_delivery_claim_v21_UNAPPLIED.sql >/dev/null
q="SELECT public.claim_iclub_ai_delivery_service_v21(
 '11111111-1111-4111-8111-111111111111'::uuid,
 '22222222-2222-4222-8222-222222222222'::uuid,
 repeat('a',64),repeat('b',64),'generated')->>'allowed';"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# Worker 1 holds transaction to force worker 2 to wait for unique PK.
("${PG[@]}" -Atc "BEGIN; $q SELECT pg_sleep(0.6); COMMIT;" >"$tmp/worker1" 2>"$tmp/err1") &
pid1=$!
sleep 0.08
("${PG[@]}" -Atc "$q" >"$tmp/worker2" 2>"$tmp/err2") &
pid2=$!
wait "$pid1" || { cat "$tmp/err1" >&2; exit 4; }
wait "$pid2" || { cat "$tmp/err2" >&2; exit 4; }
success_count="$( (grep -hxc 'true' "$tmp/worker1" "$tmp/worker2" || true) | awk '{s+=$1} END{print s+0}')"
failure_count="$( (grep -hxc 'false' "$tmp/worker1" "$tmp/worker2" || true) | awk '{s+=$1} END{print s+0}')"
if [[ "$success_count" != "1" || "$failure_count" != "1" ]]; then
 echo "FAIL: expected 1 cross-connection claim; got success=$success_count failure=$failure_count" >&2
 cat "$tmp/worker1" "$tmp/worker2" >&2
 exit 5
fi
stored="$("${PG[@]}" -Atc "SELECT count(*) FROM private.iclub_ai_request_tombstones_v21 WHERE status='claimed';")"
[[ "$stored" == "1" ]] || { echo "FAIL: duplicate durable claims" >&2; exit 6; }
echo "GREEN: 2 real PostgreSQL sessions; 1 claim, 1 refusal, 0 transcripts."
