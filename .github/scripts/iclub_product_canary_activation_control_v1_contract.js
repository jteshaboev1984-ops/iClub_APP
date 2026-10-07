const fs = require('fs');

const migrationPath = 'supabase/migrations/20261007093000_iclub_product_canary_activation_control_v1.sql';
const revertPath = 'supabase/reversions/20261007093000_iclub_product_canary_activation_control_v1_revert.sql';
const testPath = 'supabase/tests/iclub_product_canary_activation_control_v1_matrix.sql';
const runbookPath = 'docs/iclub-product-canary-activation-runbook-v1.md';

const migration = fs.readFileSync(migrationPath, 'utf8');
const revert = fs.readFileSync(revertPath, 'utf8');
const matrix = fs.readFileSync(testPath, 'utf8');
const runbook = fs.readFileSync(runbookPath, 'utf8');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

for (const fn of [
  'get_iclub_product_canary_activation_snapshot_service_v1',
  'activate_iclub_plans_subject_canary_service_v1',
  'deactivate_iclub_plans_subject_canary_service_v1'
]) {
  assert(migration.includes(fn), 'missing activation control function: ' + fn);
}

assert(
  migration.includes("v_active_beta=3") &&
  migration.includes("v_active_core_ai=3") &&
  migration.includes("v_overlap=3"),
  'activation preflight does not require the exact three-user Exam Prep authority set'
);

assert(
  migration.includes("v_active_mentor=0"),
  'activation preflight does not keep Mentor Care outside this phase'
);

assert(
  migration.includes("v_subscription_rows=0"),
  'activation preflight does not reject real subscription rows'
);

assert(
  migration.includes("plans_rollout_mode='canary'") &&
  migration.includes("subject_limits_mode='shadow'"),
  'activation does not pin Plans to canary and subjects to shadow'
);

assert(
  migration.includes("global_ai_rollout_mode='off'") &&
  migration.includes("ui_enabled=false") &&
  migration.includes("gateway_enabled=false") &&
  migration.includes("generation_enabled=false") &&
  migration.includes("kill_switch=true"),
  'activation does not keep Global AI dormant'
);

assert(
  migration.includes("lifecycle_enabled=false") &&
  migration.includes("checkout_enabled=false"),
  'activation does not keep lifecycle/checkout dormant'
);

assert(
  migration.includes("perform pg_advisory_xact_lock") &&
  migration.includes("lock table private.exam_prep_beta_members in share mode") &&
  migration.includes("lock table private.exam_prep_feature_entitlements in share mode"),
  'activation is missing serialization against cohort/entitlement drift'
);

assert(
  migration.includes("count(*) filter(where enabled and test_plan_code='free')") &&
  migration.includes("count(*) filter(where enabled and test_plan_code='plus')") &&
  migration.includes("count(*) filter(where enabled and test_plan_code='pro')"),
  'activation does not prove one Free, one Plus and one Pro canary'
);

for (const role of ['public,anon,authenticated']) {
  assert(
    migration.includes('from ' + role),
    'service-only revoke missing for role set: ' + role
  );
}

const forbiddenPublicMutation = /\b(?:insert\s+into|update|delete\s+from|truncate(?:\s+table)?)\s+public\.(?:users|user_subjects|practice_attempts|practice_answers|tour_attempts|tour_answers|ratings_cache|certificates|recommendations)\b/i;
assert(!forbiddenPublicMutation.test(migration), 'activation migration mutates a protected public learner/history table');
assert(!forbiddenPublicMutation.test(revert), 'activation reversion mutates a protected public learner/history table');

assert(
  !/drop\s+table/i.test(revert) &&
  !/delete\s+from\s+private\./i.test(revert),
  'activation-control reversion deletes retained canary/shadow data'
);

for (const phrase of [
  'Wrong three-user identity set was not rejected',
  'Non-canary escaped Plans server gate',
  'Non-canary escaped subject-selection server gate',
  'Rollback deleted shadow evidence or left enabled canaries',
  'Activation ignored explicit subscription row',
  'Browser role received canary activation authority'
]) {
  assert(matrix.includes(phrase), 'SQL matrix missing safety proof: ' + phrase);
}

for (const phrase of [
  'Do not use Vercel',
  'Free / Plus / Pro',
  'subject_limits_mode = shadow',
  'Production activation is a separate explicit step'
]) {
  assert(runbook.includes(phrase), 'runbook missing release law: ' + phrase);
}

console.log('iClub product canary activation control v1 static contract: GREEN');
