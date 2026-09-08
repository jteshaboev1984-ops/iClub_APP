const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20260908130000_exam_prep_p2_10_source_hierarchy_working_tools_v1.sql');

for (const token of [
  'private.exam_prep_source_registry',
  'source_level smallint not null check(source_level between 1 and 6)',
  "'cambridge_9709_current_syllabus','9709:2026-2027',1",
  "'coursebook_teacher_learning','p1_p5_reference:v1',2",
  "'iclub_original_topic_content','content_governance:v1.1',3",
  "'cambridge_official_past_paper_workflow','metadata_workflow:v1',4",
  "'cambridge_examiner_feedback','feedback_workflow:v1',5",
  "'supplementary_gap_aids','downstream_only:v1',6",
  'can_define_scope boolean not null default false',
  'can_define_coverage_denominator boolean not null default false',
  'can_support_assessment_evidence boolean not null default false',
  'downstream_only boolean not null default false',
  'add column if not exists source_level smallint not null default 1',
  'add column if not exists source_level smallint not null default 3',
  'add column if not exists source_level smallint not null default 4',
  'add column if not exists source_level smallint not null default 6',
  'private.exam_prep_material_library',
  "access_mode text not null check(access_mode in ('official_external','licensed_reference','school_request'))",
  "(access_mode in ('licensed_reference','school_request') and official_url is null)",
  'get_exam_prep_materials_library_safe_v1',
  'get_exam_prep_working_tools_safe_v1',
  'private.exam_prep_require_core_access_v1()',
  "'denominator_count',(v_p1_tracker->>'denominator_count')::int",
  "'denominator_count',(v_p5_tracker->>'denominator_count')::int",
  "'p1_p5_separate',true",
  "'legacy_state_mutated',false",
  "'protected_content_embedded',false",
  "revoke all on private.exam_prep_source_registry from public,anon,authenticated",
  "revoke all on private.exam_prep_material_library from public,anon,authenticated",
  "revoke execute on function public.get_exam_prep_materials_library_safe_v1(text) from public,anon",
  "revoke execute on function public.get_exam_prep_working_tools_safe_v1() from public,anon"
]) assert(migration.includes(token), `P2-10 contract missing: ${token}`);

for (const exactMapping of [
  'exam_prep_syllabus_nodes_source_level_check check(source_level=1)',
  'exam_prep_component_paper_profiles_source_level_check check(source_level=1)',
  'exam_prep_exam_calendar_source_level_check check(source_level=1)',
  'exam_prep_content_versions_source_level_check check(source_level=3)',
  'exam_prep_paper_metadata_source_level_check check(source_level=4)',
  'exam_prep_threshold_references_source_level_check check(source_level=4)',
  'exam_prep_ai_source_cards_source_level_check check(source_level=6)'
]) assert(migration.includes(exactMapping), `P2-10 structural source mapping missing: ${exactMapping}`);

assert(migration.includes("check(not can_define_scope or source_level=1)"), 'lower levels must never define scope');
assert(migration.includes("check(not can_define_coverage_denominator or source_level=1)"), 'lower levels must never define the denominator');
assert(migration.includes("check(not can_support_assessment_evidence or source_level in (3,4))"), 'only L3/L4 may support assessment evidence');
assert(migration.includes("check(not downstream_only or source_level=6)"), 'downstream-only aids must stay at level 6');

for (const forbidden of [
  /delete\s+from\s+private\.exam_prep_evidence_events/i,
  /delete\s+from\s+private\.exam_prep_skill_states/i,
  /delete\s+from\s+private\.exam_prep_stage_states/i,
  /delete\s+from\s+private\.exam_prep_correction_cases/i,
  /update\s+private\.exam_prep_evidence_events/i,
  /update\s+private\.exam_prep_skill_states/i,
  /update\s+private\.exam_prep_stage_states/i,
  /update\s+private\.exam_prep_correction_cases/i,
  /insert\s+into\s+private\.exam_prep_evidence_events/i,
  /insert\s+into\s+private\.exam_prep_skill_states/i,
  /insert\s+into\s+private\.exam_prep_stage_states/i,
  /insert\s+into\s+private\.exam_prep_correction_cases/i,
  /delete\s+from\s+public\.practice_attempts/i,
  /delete\s+from\s+public\.tour_attempts/i,
  /update\s+public\.practice_attempts/i,
  /update\s+public\.tour_attempts/i,
  /insert\s+into\s+public\.practice_attempts/i,
  /insert\s+into\s+public\.tour_attempts/i,
  /set\s+mentor_enabled\s*=\s*true/i,
  /set\s+ai_enabled\s*=\s*true/i,
  /\bcorrect_answer\s+(?:text|jsonb|varchar|character\s+varying)\b/i,
  /jsonb_build_object\s*\([^)]*['"]correct_answer['"]/i,
  /mark_scheme_text\s+(?:text|jsonb|varchar|character\s+varying)\b/i,
  /question_text\s+(?:text|jsonb|varchar|character\s+varying)\b/i
]) assert(!forbidden.test(migration), `forbidden P2-10 mutation/protected surface: ${forbidden}`);

console.log('P2-10 Source Hierarchy & Working Tools regression: GREEN');
