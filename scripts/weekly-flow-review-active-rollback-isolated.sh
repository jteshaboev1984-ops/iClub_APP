#!/usr/bin/env bash
# Run only after isolated review install and baseline negative rollback tests.
# All writes are synthetic, in disposable GitHub Actions PostgreSQL 17 only.
set -euo pipefail
if [[ "${GITHUB_ACTIONS:-}" != true || "${PGHOST:-}" != 127.0.0.1 || "${PGDATABASE:-}" != postgres || "${PGOPTIONS:-}" != *weekly_goal.isolated_db=true* ]]; then
  echo 'REFUSED: active-review rollback test requires isolated CI PostgreSQL' >&2; exit 1
fi
log=/tmp/weekly-review-rollback-active.log
psql -X -v ON_ERROR_STOP=1 -f supabase/tests/weekly_flow_review_active_rollback_seed.sql > "$log" 2>&1 || {
 tail -60 "$log"; exit 1;
}
q() { psql -X -q -A -t -v ON_ERROR_STOP=1 -c "$1"; }
preconditions="$(q "SELECT count(*)::text||':'||
 (SELECT count(*) FROM private.exam_prep_learning_review_starts_v1 r
   JOIN private.exam_prep_sessions s ON s.authorization_id=r.authorization_id
   JOIN weekly_rollback_ci.fixture f ON f.session_id=s.id
   WHERE s.status='active')::text||':'||
 (SELECT count(*) FROM private.exam_prep_responses r
   JOIN weekly_rollback_ci.fixture f ON f.session_id=r.session_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_evidence_events e
   JOIN weekly_rollback_ci.fixture f ON f.session_id=e.session_id)::text
 FROM weekly_rollback_ci.fixture")"
[[ "$preconditions" == '1:1:1:1' ]] || { echo "REFUSED: synthetic review is not fully populated ($preconditions)" >&2; exit 1; }
# Compare actual row content, not just counts, across two independent backends.
# Include program feature config, five RPC definitions and their owner/ACL.
snapshot_query="$(cat <<'SQL'
WITH f AS (SELECT user_id,session_id FROM weekly_rollback_ci.fixture),
 facts AS (
 SELECT 'auth_identity' k,to_jsonb(u)::text v FROM auth.users u JOIN f ON f.user_id=u.id
 UNION ALL SELECT 'public_identity',to_jsonb(u)::text FROM public.users u JOIN f ON f.user_id=u.id
 UNION ALL SELECT 'exam_profile',to_jsonb(p)::text FROM private.exam_prep_exam_profiles p JOIN f ON f.user_id=p.user_id
 UNION ALL SELECT 'plan',to_jsonb(p)::text FROM private.exam_prep_weekly_plans p JOIN f ON f.user_id=p.user_id
 UNION ALL SELECT 'plan_item',to_jsonb(i)::text FROM private.exam_prep_weekly_plan_items i
   JOIN private.exam_prep_weekly_plans p ON p.id=i.plan_id JOIN f ON f.user_id=p.user_id
 UNION ALL SELECT 'goal',to_jsonb(g)::text FROM private.exam_prep_weekly_goal_snapshots g JOIN f ON f.user_id=g.user_id
 UNION ALL SELECT 'correction',to_jsonb(c)::text FROM private.exam_prep_correction_cases c JOIN f ON f.user_id=c.user_id
 UNION ALL SELECT 'retest',to_jsonb(r)::text FROM private.exam_prep_retest_events r
   JOIN private.exam_prep_correction_cases c ON c.id=r.correction_case_id JOIN f ON f.user_id=c.user_id
 UNION ALL SELECT 'authorization',to_jsonb(a)::text FROM private.exam_prep_session_authorizations a JOIN f ON f.user_id=a.user_id
 UNION ALL SELECT 'session',to_jsonb(s)::text FROM private.exam_prep_sessions s JOIN f ON f.user_id=s.user_id
 UNION ALL SELECT 'session_item',to_jsonb(i)::text FROM private.exam_prep_session_items i JOIN f ON f.session_id=i.session_id
 UNION ALL SELECT 'saved_response',to_jsonb(r)::text FROM private.exam_prep_responses r JOIN f ON f.user_id=r.user_id
 UNION ALL SELECT 'academic_evidence',to_jsonb(e)::text FROM private.exam_prep_evidence_events e JOIN f ON f.user_id=e.user_id
 UNION ALL SELECT 'review_ledger',to_jsonb(l)::text FROM private.exam_prep_learning_review_starts_v1 l JOIN f ON f.user_id=l.user_id
 UNION ALL SELECT 'feature_config',to_jsonb(c)::text FROM private.exam_prep_feature_config c WHERE c.program_key='math_as_p1_p5'
 UNION ALL SELECT 'enrollment',to_jsonb(e)::text FROM private.exam_prep_weekly_flow_enrollment_v1 e
 UNION ALL SELECT 'rpc_metadata',jsonb_build_object('signature',b.signature,'definition',md5(pg_get_functiondef(p.oid)),
   'owner',p.proowner::text,'acl',p.proacl::text,'security',p.prosecdef,'volatility',p.provolatile)::text
   FROM private.exam_prep_weekly_review_rpc_backup_v1 b JOIN pg_proc p ON p.oid=b.installed_oid
)
SELECT md5(string_agg(k||':'||md5(v),'|' ORDER BY k,v)) FROM facts;
SQL
)"
before="$(q "$snapshot_query")"
[[ "$before" =~ ^[a-f0-9]{32}$ ]] || { echo 'REFUSED: invalid before fingerprint' >&2; exit 1; }
rollback=docs/patch-proposals/20260921_exam_prep_learning_review_sealed_rollback_v1.sql
body="$(cat "$rollback")"
[[ "$body" == *$'\nBEGIN;'* && "$body" == *$'\nCOMMIT;'* ]] || { echo 'REFUSED: rollback transaction boundaries drifted' >&2; exit 1; }
# The production candidate must fail even when Core is off and nobody is
# enrolled, because an actual review still has an active session and saved work.
if psql -X -v ON_ERROR_STOP=1 <<< "$body" > "$log" 2>&1; then
 echo 'FAILED: rollback allowed an active review with saved response' >&2; exit 1
fi
if ! grep -Fq 'review_rollback_requires_zero_active_review_sessions' "$log"; then
 echo 'FAILED: rollback refused for unexpected reason' >&2; tail -50 "$log"; exit 1
fi
after="$(q "$snapshot_query")"
if [[ "$after" != "$before" ]]; then
 echo 'FAILED: synthetic row-content/RPC metadata fingerprint changed after denied rollback' >&2; exit 1
fi
[[ "$(q "SELECT count(*) FROM private.exam_prep_learning_review_starts_v1 r
 JOIN private.exam_prep_sessions s ON s.authorization_id=r.authorization_id
 JOIN weekly_rollback_ci.fixture f ON f.session_id=s.id
 WHERE s.status='active'")" == 1 ]] || { echo 'FAILED: active synthetic review lost' >&2; exit 1; }
echo 'GREEN: active FK-complete learning review, saved response, academic evidence and sealed RPC definitions unchanged across correctly refused rollback (record-level fingerprints). Disposable PostgreSQL only.'
