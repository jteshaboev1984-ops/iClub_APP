const fs = require('fs');

function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = fs.readFileSync('supabase/migrations/20260912181500_exam_prep_p2_08_progress_preservation_v1.sql','utf8');
const hotfix = fs.readFileSync('supabase/migrations/20260912182600_exam_prep_p2_08_progress_preservation_hotfix_v1.sql','utf8');
const api = fs.readFileSync('exam-prep/exam-prep-api.js','utf8');
const ui = fs.readFileSync('exam-prep/exam-prep-recovery.js','utf8');

for (const token of [
  'exam_prep_recovery_cases',
  'exam_prep_progress_revalidation_cases',
  'exam_prep_progress_revalidation_items',
  'exam_prep_recovery_policy_v1',
  'get_exam_prep_recovery_safe_v2',
  'record_my_exam_prep_interruption_v2',
  'authorize_exam_prep_revalidation_item_safe_v1'
]) assert(migration.includes(token) || hotfix.includes(token), `P2-08 migration contract missing ${token}`);

assert(migration.includes("v_reval_recommended:=(v_days>=22 and coalesce(v_prior_confirmed,0)>0)"), 'revalidation must depend on prior confirmed progress and 22+ day gap');
assert(migration.includes("v_readiness_reval:=(v_days>=31 and coalesce(v_recovery.stage_snapshot,0)>=4"), 'readiness freshness check must only apply to long break with prior high-stage progress');
assert(migration.includes("verification_status='app_checked_noncredit'"), 'revalidation evidence must remain app_checked_noncredit');
assert(migration.includes("is_correct=null"), 'revalidation evidence must not write canonical correctness');
assert(migration.includes("academic_state_mutation_allowed',false"), 'recovery learner payload must explicitly deny academic-state mutation');
assert(migration.includes("academic_credit',false"), 'recovery learner payload must explicitly deny academic credit');
assert(migration.includes("progress_retained',true"), 'recovery payload must explicitly preserve progress');
assert(migration.includes("P1"), 'P1 recovery component support missing');
assert(migration.includes("P5"), 'P5 recovery component support missing');
assert(hotfix.includes("p_action_code='RECOVERY_REFRESH_RETAINED_SKILL'"), 'hotfix must add explicit recovery refresh action');
assert(hotfix.includes("e.verification_status='app_checked'"), 'hotfix must preserve verified retest gate before recovery closure');
assert(hotfix.includes("coalesce(e.is_correct,false) is true"), 'hotfix must require verified correct retest before restoring retained skill');

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
  'Oldingi natijalar va tarix o‘chirilmaydi',
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
