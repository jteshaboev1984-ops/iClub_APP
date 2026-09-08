const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20260908143000_exam_prep_p2_11_student_product_roadmap_separation_v1.sql');

for (const token of [
  'private.exam_prep_student_roadmap_windows',
  'private.exam_prep_product_roadmap_milestones',
  "'beta_2026_09_15_v1'",
  "'product_calendar_2026_2027_v1'",
  "'evidence_only'",
  'calendar_auto_promotion boolean not null default false check(not calendar_auto_promotion)',
  "date '2026-09-21',date '2026-09-28'",
  "date '2026-10-12',date '2026-10-19'",
  "date '2027-02-01',date '2027-02-08'",
  "date '2027-02-22',date '2027-03-01'",
  "date '2027-03-29',date '2027-04-05'",
  "date '2027-04-26',date '2027-04-30'",
  "date '2027-05-24',null::date,'official_component_date'",
  "date '2026-09-15','Controlled beta availability'",
  "date '2027-02-15','Product Content-Complete'",
  'can_force_learner_stage boolean not null default false check(not can_force_learner_stage)',
  'can_raise_learner_mastery boolean not null default false check(not can_raise_learner_mastery)',
  'can_label_learner_exam_ready boolean not null default false check(not can_label_learner_exam_ready)',
  'private.exam_prep_product_dependency_for_week_v1',
  "'dependency_mode','block_new_learning_only'",
  "'hard_floor_weeks',2",
  "'can_force_learner_stage',false",
  "'can_raise_learner_mastery',false",
  "'can_create_learner_evidence',false",
  "'can_label_learner_exam_ready',false",
  'create or replace function private.exam_prep_skill_runway_ready_for_week_v1',
  "->>'hard_floor_2w_green'",
  'public.get_exam_prep_student_roadmap_safe_v1',
  "'clock_type','active_week_plus_target_latest_safe'",
  "'progression_basis','evidence_only'",
  "'calendar_auto_promotion',false",
  "'product_deadline_can_force_stage',false",
  "'product_content_complete_is_syllabus_closure',false",
  "'product_content_complete_is_learner_exam_ready',false",
  "revoke all on private.exam_prep_student_roadmap_windows from public,anon,authenticated",
  "revoke all on private.exam_prep_product_roadmap_milestones from public,anon,authenticated",
  "revoke execute on function public.get_exam_prep_student_roadmap_safe_v1(text) from public,anon"
]) assert(migration.includes(token), `P2-11 contract missing: ${token}`);

for (const forbidden of [
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
  /set\s+ai_enabled\s*=\s*true/i,
  /set\s+mentor_enabled\s*=\s*true/i,
  /operational_stage\s*:=\s*[1-6]/i,
  /objective_level\s*:=/i,
  /app_readiness_estimate\s*:=/i
]) assert(!forbidden.test(migration), `forbidden P2-11 learner/legacy mutation: ${forbidden}`);

assert(!/product_label[^\n]*AS READY/i.test(migration), 'product milestone must never be labeled AS READY');
assert(!/product_label[^\n]*Exam Ready/i.test(migration), 'product milestone must never be labeled Exam Ready');

console.log('P2-11 Student/Product Roadmap separation regression: GREEN');
