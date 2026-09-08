const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20260908163000_exam_prep_p2_13_stage0_multi_session_placement_contract_v1.sql');

for (const token of [
  'private.exam_prep_stage0_workflow_contract_v1',
  'public.get_exam_prep_stage0_workflow_safe_v1',
  "'workflow_type','component_specific_full_placement'",
  "'placement_model','multi_session'",
  "'single_session_completion_required',false",
  "'time_based_stage_completion',false",
  "'phase_key','broad_screening'",
  "'delivery_model','governed_short_packages'",
  "'fixed_duration_minutes',null",
  "'duration_policy','not_fixed_by_current_governance'",
  "'phase_key','targeted_confirmation_if_needed'",
  "'usage','only_if_needed'",
  "'duplicated_broad_testing_allowed',false",
  "'mentor_required_for_core',false",
  "'core_conservative_route_allowed',true",
  "'p1_p5_separate',true",
  "'calendar_cannot_complete_placement',true",
  "'duration_cannot_complete_placement',true",
  "'advanced_route_auto_awarded',false",
  'v_rule.p1_broad_required_items<>24',
  'v_rule.p1_broad_required_areas<>8',
  'v_rule.p5_broad_required_items<>15',
  'v_rule.p5_broad_required_areas<>5',
  'v_rule.targeted_min_items<>3',
  'v_rule.targeted_max_items<>5',
  "revoke all on function public.get_exam_prep_stage0_workflow_safe_v1(text) from public,anon"
]) assert(migration.includes(token), `P2-13 C24 contract missing: ${token}`);

for (const forbidden of [
  /update\s+private\.exam_prep_component_placements/i,
  /insert\s+into\s+private\.exam_prep_component_placements/i,
  /delete\s+from\s+private\.exam_prep_component_placements/i,
  /update\s+private\.exam_prep_skill_states/i,
  /insert\s+into\s+private\.exam_prep_skill_states/i,
  /delete\s+from\s+private\.exam_prep_skill_states/i,
  /update\s+private\.exam_prep_stage_states/i,
  /insert\s+into\s+private\.exam_prep_stage_states/i,
  /delete\s+from\s+private\.exam_prep_stage_states/i,
  /update\s+private\.exam_prep_evidence_events/i,
  /insert\s+into\s+private\.exam_prep_evidence_events/i,
  /delete\s+from\s+private\.exam_prep_evidence_events/i,
  /update\s+private\.exam_prep_correction_cases/i,
  /insert\s+into\s+private\.exam_prep_correction_cases/i,
  /delete\s+from\s+private\.exam_prep_correction_cases/i,
  /update\s+public\.practice_attempts/i,
  /insert\s+into\s+public\.practice_attempts/i,
  /delete\s+from\s+public\.practice_attempts/i,
  /update\s+public\.tour_attempts/i,
  /insert\s+into\s+public\.tour_attempts/i,
  /delete\s+from\s+public\.tour_attempts/i,
  /update\s+public\.certificates/i,
  /insert\s+into\s+public\.certificates/i,
  /delete\s+from\s+public\.certificates/i,
  /set\s+ai_enabled\s*=\s*true/i,
  /set\s+mentor_enabled\s*=\s*true/i
]) assert(!forbidden.test(migration), `forbidden P2-13 learner/legacy mutation: ${forbidden}`);

assert(!/45\s*[-–]\s*60\s*(?:min|minute|minutes|мин)/i.test(migration), 'C24 must not invent a 45-60 minute single-session contract');
assert(!/155\s*[-–]\s*200/i.test(migration), 'C24 must not hardcode legacy full-placement duration estimates');

console.log('P2-13 Stage-0 broad-screen / multi-session placement regression: GREEN');
