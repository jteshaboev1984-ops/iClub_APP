const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20260908070000_exam_prep_p2_06_exam_operations_v1.sql');

for (const token of [
  'private.exam_prep_exam_calendar',
  'private.exam_prep_exam_appointments',
  'private.exam_prep_exam_ops_checklist_items',
  'private.exam_prep_exam_ops_confirmations',
  'enable row level security',
  'exam_prep_exam_ops_status_v1',
  'get_exam_prep_exam_ops_safe_v1',
  'save_my_exam_prep_exam_appointment_v1',
  'set_my_exam_prep_exam_ops_confirmation_v1',
  "v_appointment.scheduled_start_at-interval '24 hours'",
  "'major_work_stop_rule_hours',24",
  "'readiness_can_be_created_by_checklist',false",
  "'new_mastery_allowed',false",
  "status='final_verified'",
  "'exam_operations',v_ops",
  'order by derived_at desc',
  'school_date_session_checked',
  'exact_start_arrival_checked',
  'allowed_equipment_checked',
  'travel_arrival_plan_ready',
  'sleep_recovery_plan_ready',
  'short_review_plan_ready',
  'major_work_stop_understood'
]) assert(migration.includes(token), `P2-06 exam-operations contract missing: ${token}`);

assert(migration.includes('release must not invent a 2027 final timetable row'), 'release must explicitly fail if it seeds a fake final timetable');
assert(!/insert\s+into\s+private\.exam_prep_exam_calendar/i.test(migration), 'P2-06 must not seed a Cambridge 2027 date before final timetable verification');

for (const forbidden of [
  /update\s+private\.exam_prep_skill_states/i,
  /insert\s+into\s+private\.exam_prep_evidence_events/i,
  /update\s+private\.exam_prep_stage_states/i,
  /insert\s+into\s+private\.exam_prep_stage5_thresholds/i,
  /set\s+mentor_enabled\s*=\s*true/i,
  /set\s+ai_enabled\s*=\s*true/i,
  /correct_answer/i
]) assert(!forbidden.test(migration), `forbidden P2-06 academic/config mutation: ${forbidden}`);

for (const text of [
  'Не начинать большую новую работу менее чем за 24 часа до экзамена',
  'Imtihonga 24 soatdan kam qolganda katta yangi ishni boshlamaslik',
  'Do not start major new work within 24 hours of the exam'
]) assert(migration.includes(text), `P2-06 learner checklist translation missing: ${text}`);

console.log('P2-06 Exam Operations regression: GREEN');
