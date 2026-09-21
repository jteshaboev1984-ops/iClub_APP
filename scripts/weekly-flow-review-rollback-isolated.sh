#!/usr/bin/env bash
# Executable ONLY in GitHub's disposable Postgres service. All proposed SQL
# applies there; candidate rollback itself is tested inside ROLLBACK.
set -euo pipefail
if [[ "${GITHUB_ACTIONS:-}" != true || "${PGHOST:-}" != 127.0.0.1 || "${PGDATABASE:-}" != postgres || "${PGOPTIONS:-}" != *weekly_goal.isolated_db=true* ]]; then
  echo 'REFUSED: only disposable CI PostgreSQL is permitted' >&2; exit 1
fi
log=/tmp/weekly-review-rollback-isolated.log
: > "$log"
run_file() { psql -X -v ON_ERROR_STOP=1 -f "$1" >> "$log" 2>&1 || { tail -80 "$log"; exit 1; }; }
run_sql() { psql -X -q -A -t -v ON_ERROR_STOP=1 -c "$1"; }
run_file supabase/tests/p0_15_contract_bootstrap.sql
run_file supabase/tests/p1_03_ephemeral_legacy_helpers.sql
run_file supabase/tests/p1_05_ephemeral_legacy_fixture.sql
mapfile -t migrations < <(find supabase/migrations -maxdepth 1 -type f -name '*exam_prep*.sql' | sort)
[[ "${#migrations[@]}" -gt 20 ]] || { echo 'Migration inventory too small'; exit 1; }
recent=(
  '20260910121500_exam_prep_p2_17_preserve_learning_priority_v1.sql'
  '20260910160000_exam_prep_mixed_same_section_transfer_fix.sql'
  '20260910162000_exam_prep_retention_authorizer_reconcile.sql'
  '20260910164500_exam_prep_p2_18_weekly_plan_actionability_v1.sql'
  '20260910121001_exam_prep_p2_19_fresh_retest_and_plan_binding_v1.sql'
  '20260910130529_exam_prep_p2_20_mixed_mastery_area_guard_v1.sql'
)
apply_migration() {
  local f="$1" b
  b="$(basename "$f")"
  if [[ "$b" == 20260907061000_exam_prep_stage3_key_registry_v1.sql ]]; then
    run_sql "UPDATE private.exam_prep_feature_config SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now() WHERE id=1" > /dev/null
  fi
  if [[ "$b" == 20260911114829_exam_prep_p2_34_stage4_timed_section_majority_gate_v1.sql ]]; then
    run_file supabase/tests/p2_36_current_schema_replay_compat.sql
  fi
  if [[ "$b" == 20260911121959_exam_prep_p2_36_real_expansion_governance_gate_v1.sql ]]; then
    run_sql "INSERT INTO private.exam_prep_beta_cohorts(cohort_key,program_key,cohort_status,planned_size,current_wave,monitoring_hours,notes) VALUES('review-rollback-ci','math_as_p1_p5','draft',12,0,72,'isolated review rollback dependency') ON CONFLICT(cohort_key) DO NOTHING" > /dev/null
  fi
  run_file "$f"
}
for f in "${migrations[@]}"; do
  b="$(basename "$f")"
  case "$b" in
    20260910121500_exam_prep_p2_17_preserve_learning_priority_v1.sql|\
    20260910160000_exam_prep_mixed_same_section_transfer_fix.sql|\
    20260910162000_exam_prep_retention_authorizer_reconcile.sql|\
    20260910164500_exam_prep_p2_18_weekly_plan_actionability_v1.sql|\
    20260910121001_exam_prep_p2_19_fresh_retest_and_plan_binding_v1.sql|\
    20260910130529_exam_prep_p2_20_mixed_mastery_area_guard_v1.sql)
      if [[ "$b" == 20260910164500_exam_prep_p2_18_weekly_plan_actionability_v1.sql ]]; then
        for r in "${recent[@]}"; do apply_migration "supabase/migrations/$r"; done
      fi
      continue;;
  esac
  apply_migration "$f"
done
run_sql "UPDATE private.exam_prep_feature_config SET rollout_state='off',core_enabled=false,ai_enabled=false,mentor_enabled=false,kill_switch=true,updated_at=now() WHERE id=1" > /dev/null
# Restore the exact observed live v1 function into disposable CI only. The
# fixture requires the known synthetic replay hash and independently asserts
# its resulting hash against the original production pin. No legacy migration
# or production function is changed by this test adaptation.
run_file supabase/tests/weekly_flow_live_generator_v1_definition_fixture.sql
# Extract exactly the eight immutable LIVE expected hashes from the original
# backup proposal itself. Diagnose *all* replay mismatches without weakening
# the pinned gate or manufacturing a matching function definition/hash.
expected_values="$(python3 - <<'PY'
from pathlib import Path
import re
text=Path('docs/patch-proposals/20260920_weekly_flow_preinstall_rpc_backup_v1.sql').read_text()
pairs=re.findall(r"\('([^']+)',\s*'([a-f0-9]{32})'\)",text)
if len(pairs)!=8 or len({signature for signature,_ in pairs})!=8:
    raise SystemExit('REFUSED: expected eight unique pinned production signatures')
print(','.join("('%s','%s')" % pair for pair in pairs))
PY
)"
replay_drift="$(run_sql "SELECT x.signature||' actual='||coalesce(md5(pg_get_functiondef(to_regprocedure(x.signature))),'MISSING')||' pinned_live='||x.expected_md5 FROM (VALUES ${expected_values}) AS x(signature,expected_md5) WHERE md5(pg_get_functiondef(to_regprocedure(x.signature))) IS DISTINCT FROM x.expected_md5 ORDER BY x.signature")"
if [[ -n "$replay_drift" ]]; then
  printf 'BLOCKED: disposable migration replay differs from the eight pinned LIVE original RPCs:\n%s\n' "$replay_drift" >&2
  echo 'No hash changed, no production access or writes; review SQL and rollback were NOT applied.' >&2
  exit 1
fi
echo 'PASS: eight replayed original RPC definition hashes exactly match independently pinned live hashes.'
# Exact prerequisites and original 11 entrypoints, all on disposable DB.
run_file docs/patch-proposals/20260918_exam_prep_resume_lookup_v1.sql
run_file docs/patch-proposals/20260918_exam_prep_goal_eligibility_v1.sql
run_file docs/patch-proposals/20260919_exam_prep_stable_plan_once_v1.sql
run_file docs/patch-proposals/20260920_weekly_flow_preinstall_rpc_backup_v1.sql
run_file docs/patch-proposals/20260919_exam_prep_atomic_legacy_rpc_dispatch_v1.sql
run_file docs/patch-proposals/20260920_weekly_flow_postinstall_attestation_v1.sql
run_file docs/patch-proposals/20260920_exam_prep_previous_week_adherence_readonly_v1.sql
# Review snapshot must precede ANY review change.
run_file docs/patch-proposals/20260921_exam_prep_learning_review_preinstall_backup_v1.sql
run_file docs/patch-proposals/20260921_exam_prep_learning_review_verdict_v1.sql
run_file docs/patch-proposals/20260921_exam_prep_learning_review_start_v1.sql
run_file docs/patch-proposals/20260921_exam_prep_learning_review_exact_goal_binding_v1.sql
run_file docs/patch-proposals/20260921_exam_prep_learning_review_recovery_v1.sql
run_file docs/patch-proposals/20260921_exam_prep_learning_review_goal_eligibility_v1.sql
run_file docs/patch-proposals/20260921_exam_prep_learning_review_weekly_accounting_v1.sql
run_file docs/patch-proposals/20260921_exam_prep_learning_review_postinstall_attestation_v1.sql
seal="$(run_sql "SELECT count(*) FROM private.exam_prep_weekly_review_rpc_backup_v1 b WHERE b.installed_md5 IS NOT NULL AND md5(pg_get_functiondef(b.installed_oid))=b.installed_md5")"
[[ "$seal" == 5 ]] || { echo "Wrong review seal: $seal"; exit 1; }
# An OFF flag, zero enrollment, exact seal and zero active reviews permit a
# non-destructive rehearsal; replace only the trailing COMMIT with ROLLBACK.
rollback=docs/patch-proposals/20260921_exam_prep_learning_review_sealed_rollback_v1.sql
body="$(cat "$rollback")"
[[ "$body" == *$'\nBEGIN;'* && "$body" == *$'\nCOMMIT;'* ]] || { echo 'Rollback transaction boundaries drifted'; exit 1; }
fail_gate() {
  local variant="$1" expected="$2" injected="$3" result
  result="${body/BEGIN;/BEGIN;$'\n'$injected}"
  result="${result/%COMMIT;/ROLLBACK;}"
  if psql -X -v ON_ERROR_STOP=1 <<< "$result" > "$log" 2>&1; then
    echo "Refusal gate DID NOT reject $variant"; exit 1
  fi
  grep -q "$expected" "$log" || { echo "Wrong refusal for $variant"; tail -40 "$log"; exit 1; }
}
fail_gate core_on review_rollback_requires_core_off "UPDATE private.exam_prep_feature_config SET rollout_state='controlled_beta',core_enabled=true,kill_switch=false WHERE program_key='math_as_p1_p5';"
fail_gate acl_drift review_rollback_refuses_installed_drift_ "REVOKE EXECUTE ON FUNCTION public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text) FROM authenticated;"
result="${body/%COMMIT;/SELECT 'RESTORED='||count(*) FROM private.exam_prep_weekly_review_rpc_backup_v1 b WHERE b.operation='modified' AND md5(pg_get_functiondef(b.original_oid))=b.original_md5;$'\n'ROLLBACK;}"
echo "$result" | psql -X -q -A -t -v ON_ERROR_STOP=1 > "$log" 2>&1 || { tail -100 "$log"; exit 1; }
grep -q '^RESTORED=4$' "$log" || { echo 'Did not restore all four original RPCs in rehearsal'; tail -70 "$log"; exit 1; }
[[ "$(run_sql "SELECT count(*) FROM private.exam_prep_weekly_review_rpc_backup_v1 b WHERE md5(pg_get_functiondef(b.installed_oid))=b.installed_md5")" == 5 ]] || {
 echo 'Rehearsal changed installed review candidate'; exit 1; }
[[ "$(run_sql "SELECT count(*) FROM private.exam_prep_learning_review_starts_v1")" == 0 ]] || { echo 'Unexpected learner review rows'; exit 1; }
echo 'GREEN: disposable PostgreSQL 17 review rollback. Sealed 5 RPCs, refused Core ON/ACL drift, restored four bodies in rolled-back rehearsal, no review rows modified.'