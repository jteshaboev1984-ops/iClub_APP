const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20260909070000_exam_prep_p2_14_single_stage_taxonomy_guard_v1.sql');
const placementUi = read('exam-prep/exam-prep-overview-placement.js');

for (const token of [
  "'contract_version','p2_14_c25_v1'",
  "'progression_taxonomy','stages_0_6'",
  "'authoritative_progression_field','exam_prep_stage_states.operational_stage'",
  "'placement_scope','stage_0_local_state'",
  "'placement_status_role','local_state_only'",
  "'placement_route_role','local_direction_only'",
  "'placement_labels_are_progression',false",
  "'placement_labels_can_set_operational_stage',false",
  "'active_week_can_set_operational_stage',false",
  'private.exam_prep_assert_single_stage_taxonomy_v1',
  'exam_prep_c25_stage_requires_completed_stage0',
  'zz_exam_prep_c25_access_stage_guard_v1',
  'zz_exam_prep_c25_stage_state_guard_v1'
]) {
  assert(migration.includes(token), `P2-14 C25 migration missing ${token}`);
}

for (const forbidden of [
  /\b(?:update|delete\s+from|truncate)\s+private\.exam_prep_(?:evidence_events|skill_states|correction_cases|weekly_plans|timed_attempt_results)\b/i,
  /\b(?:update|delete\s+from|truncate)\s+public\.(?:practice_attempts|practice_answers|tour_attempts|tour_answers|certificates)\b/i,
  /\bcreate\s+table\s+.*(?:placement_level|route_level|progression_level)/i
]) {
  assert(!forbidden.test(migration), `P2-14 C25 destructive/parallel-progression pattern detected: ${forbidden}`);
}

for (const token of [
  'stageLabel(data.operational_stage)',
  'currentDirection:',
  'routeLabel(data?.provisional_route)',
  'placementResult:'
]) {
  assert(placementUi.includes(token), `P2-14 C25 learner UI no longer separates Stage from placement direction: ${token}`);
}

for (const forbidden of [
  /placement\s+level/i,
  /route\s+stage/i,
  /placement\s+stage\s+[1-6]/i,
  /provisional\s+stage/i
]) {
  assert(!forbidden.test(placementUi), `P2-14 C25 parallel learner ladder wording detected: ${forbidden}`);
}

console.log('P2-14 C25 single Stage 0-6 taxonomy static regression: GREEN');
