const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20260908080000_exam_prep_p2_07_recovery_engine_v1.sql');
const api = read('exam-prep/exam-prep-api.js');
const ui = read('exam-prep/exam-prep-recovery.js');
const thresholdLayer = read('exam-prep/exam-prep-threshold-reference.js');

for (const token of [
  'private.exam_prep_recovery_cases',
  'exam_prep_one_active_recovery_case_component_idx',
  'exam_prep_recovery_mode_for_missed_days_v1',
  "if p_missed_days<=7 then return 'reserve_1w'",
  "if p_missed_days between 14 and 21 then return 'recovery_2_3w'",
  "if p_missed_days>=31 then return 'rebaseline_over_1mo'",
  "return 'source_gap_review'",
  "'undefined_ranges_days',jsonb_build_array('8-13','22-30')",
  "'mandatory_uncovered_topics_pct',50",
  "'questions_on_those_topics_pct',25",
  "'older_topics_pct',15",
  "'timed_practice_pct',10",
  "'recovery_horizon_days',14",
  "'preserve_retest',true",
  "'preserve_timed_practice',true",
  "'sleep_debt_catch_up_prohibited',true",
  'record_my_exam_prep_interruption_v1',
  'get_exam_prep_recovery_safe_v1',
  'generate_exam_prep_weekly_plan_safe_v2',
  'get_exam_prep_weekly_plan_safe_v2',
  "'recovery_server_derived',true",
  "'p1_p5_separate',true",
  "'evidence_standards_unchanged',true",
  "'stage_changed_by_recovery',false",
  "'REVIEW_RECOVERY_PATH'",
  "'REBASELINE_COMPONENT'",
  "'RECOVERY_MANDATORY_TOPIC'",
  "'RECOVERY_RESERVE_LEARNING'"
]) assert(migration.includes(token), `P2-07 recovery contract missing: ${token}`);

assert(/check\(evidence_standards_preserved is true\)/i.test(migration), 'recovery case must hard-lock evidence standards');
assert(/check\(absence_stage_downgrade_allowed is false\)/i.test(migration), 'absence-only stage downgrade must be hard-disabled');
assert(/recovery_mode='recovery_2_3w' and recovery_window_started_on is not null and recovery_window_ends_on=recovery_window_started_on\+13/i.test(migration), '14-day recovery window contract missing');
assert(/where user_id=v_uid and component_code=v_component and status='active'/i.test(migration), 'component-scoped active recovery handling missing');
assert(migration.includes("if p_recovery_mode not in ('reserve_1w','source_gap_review','recovery_2_3w','rebaseline_over_1mo')"), 'recovery policy mode validation missing');

for (const forbidden of [
  /update\s+private\.exam_prep_skill_states/i,
  /update\s+private\.exam_prep_stage_states/i,
  /insert\s+into\s+private\.exam_prep_stage5_thresholds/i,
  /update\s+private\.exam_prep_stage5_thresholds/i,
  /set\s+mentor_enabled\s*=\s*true/i,
  /set\s+ai_enabled\s*=\s*true/i,
  /correct_answer/i
]) assert(!forbidden.test(migration), `forbidden recovery mutation/surface: ${forbidden}`);

// Later hardening moved recovery/interruption reads to v2 and the weekly planner to v3.
// The browser still must not choose a recovery mode; server policy remains authoritative.
assert(api.includes('generate_exam_prep_weekly_plan_safe_v3'), 'API is not using current server-derived recovery planner v3');
assert(api.includes('get_exam_prep_weekly_plan_safe_v2'), 'API is not reading recovery-aware weekly plan v2');
assert(api.includes('record_my_exam_prep_interruption_v2'), 'API current interruption recorder v2 missing');
assert(api.includes('get_exam_prep_recovery_safe_v2'), 'API current recovery reader v2 missing');
assert(!/async function generateWeeklyPlan\(componentCode,\s*recoveryMode/i.test(api), 'browser recovery mode parameter must not remain authoritative');

assert(thresholdLayer.includes('exam-prep-recovery.js?v=p207recovery1'), 'recovery learner layer is not loaded');
for (const token of [
  'data-ep-recovery-card',
  'data-ep-recovery-form',
  'recordInterruption',
  'Promise.allSettled',
  'generateWeeklyPlan("P1")',
  'generateWeeklyPlan("P5")',
  '50% — обязательные непройденные темы',
  '25% — задачи по ним',
  '15% — более ранние темы',
  '10% — практика на время',
  'На следующие 14 дней',
  'Прежние результаты сохраняются',
  'P1 и P5 перепланируются отдельно',
  '50% majburiy o‘tilmagan mavzular',
  'For the next 14 days: 50% required uncovered topics'
]) assert(ui.includes(token), `learner recovery UI contract missing: ${token}`);

for (const forbidden of [
  'source_gap_review',
  'Core beta',
  'Synthetic learner data',
  'Screening',
  'REBASELINE_COMPONENT',
  'RECOVERY_MANDATORY_TOPIC'
]) assert(!ui.includes(forbidden), `internal recovery wording leaked to learner UI source: ${forbidden}`);

console.log('P2-07 recovery engine + learner flow regression: GREEN');
