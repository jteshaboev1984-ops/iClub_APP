#!/usr/bin/env bash
# Additional negative tests AFTER the principal isolated review-install/rollback
# rehearsal, on the same disposable PostgreSQL 17 container only.
set -euo pipefail
if [[ "${GITHUB_ACTIONS:-}" != true || "${PGHOST:-}" != 127.0.0.1 || "${PGDATABASE:-}" != postgres || "${PGOPTIONS:-}" != *weekly_goal.isolated_db=true* ]]; then
  echo 'REFUSED: negative review rollback tests require disposable CI PostgreSQL' >&2
  exit 1
fi
rollback=docs/patch-proposals/20260921_exam_prep_learning_review_sealed_rollback_v1.sql
body="$(cat "$rollback")"
[[ "$body" == *$'\nBEGIN;'* && "$body" == *$'\nCOMMIT;'* ]] || { echo 'Rollback transaction boundary drift' >&2; exit 1; }
q() { psql -X -q -A -t -v ON_ERROR_STOP=1 -c "$1"; }
assert_state() {
  local state
  state="$(q "SELECT
    (SELECT count(*) FROM private.exam_prep_weekly_review_rpc_backup_v1 b WHERE b.installed_md5 IS NOT NULL AND md5(pg_get_functiondef(b.installed_oid))=b.installed_md5)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_learning_review_starts_v1)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_sessions)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_responses)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_evidence_events)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_session_authorizations)::text;")"
  [[ "$state" == "$baseline" ]] || { printf 'BLOCKED: negative test changed sealed/function or synthetic learner record counts: %s != %s\n' "$state" "$baseline" >&2; exit 1; }
}
baseline="$(q "SELECT
    (SELECT count(*) FROM private.exam_prep_weekly_review_rpc_backup_v1 b WHERE b.installed_md5 IS NOT NULL AND md5(pg_get_functiondef(b.installed_oid))=b.installed_md5)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_learning_review_starts_v1)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_sessions)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_responses)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_evidence_events)::text || ':' ||
    (SELECT count(*) FROM private.exam_prep_session_authorizations)::text;")"
[[ "$baseline" == 5:0:0:* ]] || { echo "REFUSED: unexpected initial sealed/enrollment/review state $baseline" >&2; exit 1; }
negative() {
  local label="$1" expected="$2" mutation="$3" sql output
  sql="${body/BEGIN;/BEGIN;$'\n'$mutation}"
  sql="${sql/%COMMIT;/ROLLBACK;}"
  if output="$(psql -X -v ON_ERROR_STOP=1 <<< "$sql" 2>&1)"; then
    echo "BLOCKED: rollback accepted unsafe $label scenario" >&2
    exit 1
  fi
  if ! grep -Fq "$expected" <<< "$output"; then
    echo "BLOCKED: wrong failure reason for $label: $output" >&2
    exit 1
  fi
  assert_state
  echo "PASS: rollback refused $label and transaction left test state intact."
}
enrollment="$(cat <<'SQL'
INSERT INTO auth.users(id,email)
VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','review-rollback-disposable@example.invalid');
INSERT INTO private.exam_prep_weekly_flow_enrollment_v1(user_id,enabled,approved_by,approved_at)
VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true,'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',now());
SQL
)"
negative enrollment review_rollback_requires_zero_enrollment "$enrollment"
owner_drift="$(cat <<'SQL'
CREATE ROLE review_rollback_disposable_bad_owner NOLOGIN;
ALTER FUNCTION public.get_exam_prep_weekly_progress_safe_v1(text)
OWNER TO review_rollback_disposable_bad_owner;
SQL
)"
negative owner_drift review_rollback_refuses_installed_drift_ "$owner_drift"
negative volatility_drift review_rollback_refuses_installed_drift_ \
  'ALTER FUNCTION public.get_exam_prep_weekly_progress_safe_v1(text) VOLATILE;'
echo 'GREEN: three additional disposable rollback-refusal tests; sealed five-RPC candidate, enrollment, review and synthetic record counts preserved. No production access.'