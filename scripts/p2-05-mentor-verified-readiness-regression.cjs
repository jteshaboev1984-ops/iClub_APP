const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20260908061000_exam_prep_p2_05_mentor_verified_readiness_v1.sql');
const roleHotfix = read('supabase/migrations/20260908062500_exam_prep_p2_05_readiness_audit_role_hotfix_v1.sql');

for (const token of [
  'private.exam_prep_readiness_signoffs',
  'enable row level security',
  'exam_prep_readiness_signoffs_immutable_v1',
  'exam_prep_readiness_review_snapshot_v1',
  'exam_prep_guard_readiness_mentor_review_v1',
  'exam_prep_materialize_readiness_signoff_v1',
  'exam_prep_maybe_recommend_readiness_v1',
  'exam_prep_mentor_verified_readiness_status_v1',
  'get_exam_prep_mentor_verified_readiness_safe_v1',
  'get_exam_prep_readiness_review_packet_safe_v1',
  'exam_prep_readiness_confirmation_requires_app_readiness',
  'exam_prep_readiness_evidence_changed',
  "array['lead_mentor','academic_moderator']",
  "new.requires_second_check:=true",
  "new.review_status:='pending_second_check'",
  "recommendation_type,source_object_type,source_object_id",
  "'readiness','readiness_fingerprint'",
  "mentor_verified_readiness',true",
  'private.exam_prep_latest_threshold_reference_v1'
]) assert(migration.includes(token), `P2-05 Mentor Verified contract missing: ${token}`);

assert(/unique\(learner_user_id,program_version_id,component_code,readiness_fingerprint\)/i.test(migration), 'component/evidence-bound unique signoff missing');
assert(/check\(mentor_user_id<>moderator_user_id\)/i.test(migration), 'independent reviewer constraint missing');
assert(/if new\.reviewer_user_id=v_r\.mentor_user_id then raise exception 'exam_prep_second_check_must_be_independent'/i.test(migration), 'runtime independent second-check guard missing');
assert(/if v_expected<>\(v_state->>'fingerprint'\)/i.test(migration), 'stale evidence fingerprint comparison missing');
assert(/coalesce\(new\.operational_stage,0\)<6/i.test(migration), 'readiness recommendation must not enqueue before Stage 6');
assert(/private\.exam_prep_active_mentor_assignment_v1\(new\.user_id,new\.component_code\)/i.test(migration), 'readiness queue must remain assignment-scoped');
assert(/raw_responses_editable',false/i.test(migration), 'staff packet must state raw responses are immutable');
assert(/mentor_verified_readiness',coalesce\(\(v_human->>'mentor_verified'\)::boolean,false\)/i.test(migration), 'learner readiness payload must keep human status separate');

for (const token of [
  "v_actor_role:='academic_moderator'",
  "v_actor_role:='lead_mentor'",
  "new.reviewer_user_id=v_r.mentor_user_id",
  "exam_prep_readiness_evidence_changed",
  "'mentor_verified_readiness_confirmed'"
]) assert(roleHotfix.includes(token), `readiness audit-role hotfix missing: ${token}`);
assert(!/'math_as_p1_p5',new\.reviewer_user_id,'academic_moderator','mentor_verified_readiness_confirmed'/.test(roleHotfix), 'hotfix must not mislabel a lead mentor as academic moderator');

for (const source of [migration, roleHotfix]) {
  for (const forbidden of [
    /update\s+private\.exam_prep_responses/i,
    /delete\s+from\s+private\.exam_prep_evidence_events/i,
    /update\s+private\.exam_prep_skill_states/i,
    /insert\s+into\s+private\.exam_prep_stage5_thresholds/i,
    /set\s+mentor_enabled\s*=\s*true/i,
    /set\s+ai_enabled\s*=\s*true/i,
    /correct_answer/i
  ]) assert(!forbidden.test(source), `forbidden P2-05 Mentor Verified mutation/surface: ${forbidden}`);
}

assert(migration.includes("if v_approved<>0"), 'release must preserve zero approved Stage-5 threshold policy');
assert(migration.includes("p_component_code not in ('P1','P5')"), 'P1/P5 component boundary missing');

console.log('P2-05 Mentor Verified Readiness regression: GREEN');
