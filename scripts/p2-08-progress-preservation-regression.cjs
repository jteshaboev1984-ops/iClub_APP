const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20260908090000_exam_prep_p2_08_progress_preservation_revalidation_v1.sql');
const hotfix = read('supabase/migrations/20260908091000_exam_prep_p2_08_revalidation_resume_fix_v1.sql');
const api = read('exam-prep/exam-prep-api.js');
const ui = read('exam-prep/exam-prep-recovery.js');

for (const token of [
  'progress_retained boolean not null default true',
  'check(progress_retained is true)',
  'academic_credit boolean not null default true',
  'app_checked_noncredit',
  'exam_prep_noncredit_evidence_guard_v1',
  'exam_prep_progress_revalidation_cases',
  'exam_prep_progress_revalidation_items',
  'academic_state_mutation_allowed boolean not null default false',
  'check(academic_state_mutation_allowed is false)',
  "'day_band','1_7'",
  "'day_band','8_13'",
  "'day_band','14_21'",
  "'day_band','22_30'",
  "'day_band','31_plus'",
  "'user_amendment','conservative_reentry_without_reset'",
  "'user_amendment','extended_recovery_with_optional_revalidation'",
  "'user_amendment','planning_rebaseline_not_progress_reset'",
  'record_my_exam_prep_interruption_v2',
  'get_exam_prep_recovery_safe_v2',
  'authorize_exam_prep_revalidation_item_safe_v1',
  'exam_prep_revalidation_finalize_v1',
  'generate_exam_prep_weekly_plan_safe_v3',
  "'RECOVERY_REFRESH_RETAINED_SKILL'",
  "'progress_retained',true",
  "'academic_stage_changed_by_recovery',false"
]) assert(migration.includes(token), `P2-08 contract missing: ${token}`);

assert(migration.includes("v_reval_recommended:=(v_days>=22 and coalesce(v_prior_confirmed,0)>0)"), 'revalidation must depend on prior confirmed progress and 22+ day gap');
assert(migration.includes("v_readiness_reval:=(v_days>=31 and coalesce(v_recovery.stage_snapshot,0)>=4"), 'readiness freshness check must only apply to long break with prior high-stage progress');
assert(migration.includes("'retest','issued'"), 'revalidation must reuse governed same-skill retest content');
assert(migration.includes("false,'progress_revalidation'"), 'revalidation authorization must be non-crediting');
assert(migration.includes("where rv.user_id=v_uid and rv.component_code=p_component_code"), 'revalidation refresh must remain component-scoped');

for (const token of [
  "status in ('recommended','in_progress','refresh_recommended')",
  "credit_context='progress_revalidation'",
  "'resumed',true",
  "action_code='RECOVERY_REFRESH_RETAINED_SKILL'",
  "'progress_retained',true",
  "'academic_stage_changed_by_recovery',false"
]) assert(hotfix.includes(token), `P2-08 resume/refresh hotfix missing: ${token}`);

for (const token of [
  'get_exam_prep_recovery_safe_v2',
  'record_my_exam_prep_interruption_v2',
  'authorize_exam_prep_revalidation_item_safe_v1',
  'generate_exam_prep_weekly_plan_safe_v3'
]) assert(api.includes(token), `P2-08 learner API is not wired to ${token}`);

for (const token of [
  'Сам перерыв не отменяет ваши прежние результаты.',
  'Подтверждённый прогресс и прежние результаты сохраняются.',
  'Короткая проверка сохранённых знаний',
  'Эта проверка не может удалить прежние результаты.',
  'Проверить сохранённые знания',
  'Oldingi progress va tarix o‘chirilmaydi',
  'Previous progress and history are not deleted',
  'data-ep-recovery-check',
  'authorizeRevalidationItem',
  'finalizeSession',
  'generateWeeklyPlan(component)'
]) assert(ui.includes(token), `P2-08 learner recovery flow missing: ${token}`);

for (const forbidden of [
  /delete\s+from\s+private\.exam_prep_evidence_events/i,
  /delete\s+from\s+private\.exam_prep_skill_states/i,
  /update\s+private\.exam_prep_skill_states/i,
  /update\s+private\.exam_prep_stage_states/i,
  /insert\s+into\s+private\.exam_prep_stage5_thresholds/i,
  /update\s+private\.exam_prep_stage5_thresholds/i,
  /set\s+mentor_enabled\s*=\s*true/i,
  /set\s+ai_enabled\s*=\s*true/i,
  /correct_answer/i
]) {
  assert(!forbidden.test(migration), `forbidden P2-08 base mutation/surface: ${forbidden}`);
  assert(!forbidden.test(hotfix), `forbidden P2-08 hotfix mutation/surface: ${forbidden}`);
}

for (const internalTerm of ['source_gap_review','app_checked_noncredit','RECOVERY_REFRESH_RETAINED_SKILL','academic_state_mutation_allowed']) {
  assert(!ui.includes(`>${internalTerm}<`), `internal recovery term rendered as learner text: ${internalTerm}`);
}

console.log('P2-08 progress preservation / revalidation regression: GREEN');
