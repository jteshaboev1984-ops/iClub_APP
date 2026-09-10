const fs = require('fs');

const base = fs.readFileSync('supabase/migrations/20260910050000_exam_prep_identity_recovery_continuity_v1.sql', 'utf8');
const hardening = fs.readFileSync('supabase/migrations/20260910052500_exam_prep_identity_recovery_continuity_v1_1.sql', 'utf8');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

for (const token of [
  'private.exam_prep_reassign_user_identity_v1',
  'v_exam_prep_moved := private.exam_prep_reassign_user_identity_v1(v_old.id, p_current_uid)',
  "'exam_prep', v_exam_prep_moved",
  'delete from public.users',
]) {
  assert(base.includes(token), `base recovery continuity token missing: ${token}`);
}

for (const token of [
  "current_setting('iclub.exam_prep_identity_recovery', true) = 'on'",
  "set_config('iclub.exam_prep_identity_recovery', 'on', true)",
  'exam_prep_identity_recovery_target_not_clean',
  'exam_prep_identity_recovery_incomplete',
  "revoke all on function private.exam_prep_reassign_user_identity_v1(uuid, uuid) from anon",
  "revoke all on function private.exam_prep_reassign_user_identity_v1(uuid, uuid) from authenticated",
  "c.relname like 'exam_prep_%'",
  "fc.relname = 'users'",
]) {
  assert(hardening.includes(token), `hardening token missing: ${token}`);
}

for (const trigger of [
  'exam_prep_maybe_recommend_readiness_v1',
  'exam_prep_readiness_projection_v1',
  'exam_prep_stage0_gate_projection_v1',
  'exam_prep_stage_access_sync_v1',
]) {
  assert(hardening.includes(`drop trigger if exists ${trigger}`), `identity-only stage guard missing: ${trigger}`);
}

assert(hardening.includes("to_jsonb(new) - array['user_id','learner_user_id','mentor_user_id','reviewer_user_id','raised_by_user_id','moderator_user_id']"), 'immutable facts must permit identity-only reassignment and nothing else');
assert(!hardening.includes("set_config('session_replication_role'"), 'hosted Postgres must not depend on session_replication_role');
assert(!hardening.match(/delete\s+from\s+private\.exam_prep_/i), 'identity continuity must never delete Exam Prep rows');
assert(!hardening.match(/truncate\s+/i), 'identity continuity must never truncate data');

console.log('Exam Prep identity recovery continuity regression: PASS');
