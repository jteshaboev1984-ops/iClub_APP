#!/usr/bin/env bash
# Ephemeral PostgreSQL only. Two independent paid routes compete for ONE shared cap.
set -euo pipefail
psql -v ON_ERROR_STOP=1 -Atqc "UPDATE private.iclub_ai_all_route_spend_control_v1 SET enabled=true,max_day_microusd=7000,max_lifetime_microusd=7000 WHERE singleton=1"
test "$(psql -Atqc "SELECT count(*) FROM private.exam_prep_ai_provider_leases")" = "0"
test "$(psql -Atqc "SELECT count(*) FROM private.practice_ai_provider_leases")" = "0"
(
  psql -v ON_ERROR_STOP=1 -Atqc "
    BEGIN;
    SELECT public.reserve_exam_prep_ai_provider_call_service_v1(
      '00000000-0000-4000-8000-000000000051',
      '00000000-0000-4000-8000-000000000001',0.005)->>'allowed';
    SELECT pg_sleep(2);
    COMMIT;" >finance-first.txt
) &
first_pid=$!
sleep 0.25
psql -v ON_ERROR_STOP=1 -Atqc "
 SELECT public.reserve_practice_ai_provider_call_service_v1(
    '00000000-0000-4000-8000-000000000052',
    '00000000-0000-4000-8000-000000000002',0.005)->>'allowed';" >finance-second.txt
wait "$first_pid"
first=$(grep -E '^(true|false)$' finance-first.txt | head -1)
second=$(grep -E '^(true|false)$' finance-second.txt | head -1)
test "$first" != "$second"
test "$(psql -Atqc "SELECT (SELECT count(*) FROM private.exam_prep_ai_provider_leases)+(SELECT count(*) FROM private.practice_ai_provider_leases)")" = "1"
echo "PASS cross-route concurrent admission: one allowed, one denied, shared cost <= 7000 microUSD"
