#!/usr/bin/env bash
# §34. Exact two-PG-session money race. SCRATCH ONLY.
set -euo pipefail
cd "$(dirname "$0")/.."
DB="$(printenv ICLUB_PGTEST_DB || true)"
HOST="$(printenv ICLUB_PGTEST_HOST || true)"
PORT="$(printenv ICLUB_PGTEST_PORT || true)"
if [[ ! "$DB" =~ ^iclub_ai_v21_scratch_[a-z0-9_]+$ ]] ||
 [[ "$HOST" != "127.0.0.1" ]] || [[ ! "$PORT" =~ ^[0-9]{1,5}$ ]]; then
 echo "STOP: only named local scratch PostgreSQL allowed" >&2;exit 2
fi
unset PGHOST PGHOSTADDR PGDATABASE PGPORT PGOPTIONS PGSERVICE PGSERVICEFILE
unset DATABASE_URL SUPABASE_DB_URL SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY
export PGAPPNAME=iclub_ai_v21_local_scratch
sql() { psql -X -w -v ON_ERROR_STOP=1 -h "$HOST" -p "$PORT" -U postgres -d "$DB" "$@"; }
check="$(sql -Atc "SELECT CASE WHEN current_database() ~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
AND (inet_server_addr() IN ('127.0.0.1'::inet,'::1'::inet) OR
 (inet_server_addr() << '172.16.0.0/12'::cidr AND current_setting('application_name')='iclub_ai_v21_local_scratch'))
AND NOT EXISTS(SELECT 1 FROM pg_tables WHERE schemaname NOT IN
 ('pg_catalog','information_schema') AND schemaname !~ '^pg_')
THEN 'SCRATCH_OK' ELSE 'UNSAFE' END;")"
[[ "$check" == "SCRATCH_OK" ]] || { echo "STOP: nonempty or unsafe database" >&2;exit 3; }
sql <<'SQL'
CREATE SCHEMA private;
DO $roles$
DECLARE name text;
BEGIN
 FOREACH name IN ARRAY ARRAY['anon','authenticated','service_role'] LOOP
  IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname=name) THEN
   EXECUTE format('CREATE ROLE %I NOLOGIN',name);
  END IF;
 END LOOP;
END $roles$;
CREATE TABLE private.iclub_global_ai_runtime_config(
 id smallint PRIMARY KEY,kill_switch boolean NOT NULL,
 gateway_enabled boolean NOT NULL,generation_enabled boolean NOT NULL);
INSERT INTO private.iclub_global_ai_runtime_config VALUES(1,false,true,true);
CREATE TABLE private.iclub_ai_v21_release_control(
 id smallint PRIMARY KEY,release_approved boolean NOT NULL);
INSERT INTO private.iclub_ai_v21_release_control VALUES(1,true);
CREATE FUNCTION private.iclub_ai_has_active_protected_assessment_v1(p_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SET search_path='' AS $$ SELECT false $$;
CREATE TABLE private.iclub_ai_usage_reservations(
 request_id uuid PRIMARY KEY,user_id uuid NOT NULL,request_fingerprint text NOT NULL,
 route_class text NOT NULL,status text NOT NULL,expires_at timestamptz NOT NULL);
CREATE TABLE private.iclub_ai_request_tombstones_v21(
 request_id uuid PRIMARY KEY,user_id uuid NOT NULL,session_fingerprint text NOT NULL,
 request_fingerprint text NOT NULL,route_class text NOT NULL,
 status text NOT NULL,claim_expires_at timestamptz NOT NULL);
INSERT INTO private.iclub_ai_usage_reservations VALUES
 ('11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222',
 repeat('b',64),'generated','reserved',now()+interval '120 seconds'),
 ('33333333-3333-4333-8333-333333333333','22222222-2222-4222-8222-222222222222',
 repeat('b',64),'generated','reserved',now()+interval '120 seconds');
INSERT INTO private.iclub_ai_request_tombstones_v21 VALUES
 ('11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222',
 repeat('a',64),repeat('b',64),'generated','claimed',now()+interval '120 seconds'),
 ('33333333-3333-4333-8333-333333333333','22222222-2222-4222-8222-222222222222',
 repeat('a',64),repeat('b',64),'generated','claimed',now()+interval '120 seconds');
SQL
sql -f qa/sql_drafts/iclub_ai_v21_provider_spend_UNAPPLIED.sql >/dev/null
sql -c "INSERT INTO private.iclub_ai_v21_provider_spend_control
 (singleton,enabled,lifetime_cap_microusd,per_request_ceiling_microusd,
  daily_cap_microusd,per_user_daily_cap_microusd,max_concurrent_requests,
  policy_revision)
 VALUES(1,true,80,80,80,80,2,'synthetic_money_race');" >/dev/null
q1="SELECT public.reserve_iclub_ai_v21_provider_spend_service(
'11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222',
repeat('a',64),repeat('b',64))->>'allowed';"
q2="SELECT public.reserve_iclub_ai_v21_provider_spend_service(
'33333333-3333-4333-8333-333333333333','22222222-2222-4222-8222-222222222222',
repeat('a',64),repeat('b',64))->>'allowed';"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
(sql -Atc "BEGIN; $q1 SELECT pg_sleep(0.6); COMMIT;" >"$tmp/one" 2>"$tmp/err1") &
p1=$!
sleep 0.08
(sql -Atc "$q2" >"$tmp/two" 2>"$tmp/err2") &
p2=$!
wait "$p1" || { cat "$tmp/err1" >&2;exit 4; }
wait "$p2" || { cat "$tmp/err2" >&2;exit 4; }
yes="$( (grep -hxc true "$tmp/one" "$tmp/two" || true)|awk '{s+=$1} END{print s+0}')"
no="$( (grep -hxc false "$tmp/one" "$tmp/two" || true)|awk '{s+=$1} END{print s+0}')"
[[ "$yes" == "1" && "$no" == "1" ]] || { echo "FAIL: approve/refuse $yes/$no" >&2;exit 5; }
actual="$(sql -Atc "SELECT count(*)||':'||coalesce(sum(held_microusd),0) FROM private.iclub_ai_v21_provider_spend_leases;")"
[[ "$actual" == "1:80" ]] || { echo "FAIL: budget overspend $actual" >&2;exit 6; }
echo "GREEN: two independent PostgreSQL connections, one money hold, one refusal, no overspend."
