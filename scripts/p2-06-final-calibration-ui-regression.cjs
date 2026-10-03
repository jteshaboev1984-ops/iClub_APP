const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const api = read('exam-prep/exam-prep-api.js');
const live = read('exam-prep/exam-prep-live.js');
const css = read('exam-prep/exam-prep-host.css');
const ops = read('supabase/migrations/20260908070000_exam_prep_p2_06_exam_operations_v1.sql');
const revision = read('supabase/migrations/20260908103000_exam_prep_p2_09_exam_map_revision_v1.sql');

for (const token of [
  'async function examOps(componentCode)',
  'get_exam_prep_exam_ops_safe_v1',
  'async function saveExamAppointment(componentCode, scheduledStartAt)',
  'save_my_exam_prep_exam_appointment_v1',
  'async function setExamOpsConfirmation(componentCode, itemCode, confirmed)',
  'set_my_exam_prep_exam_ops_confirmation_v1',
  'readiness, readinessSummary, examOps, saveExamAppointment, setExamOpsConfirmation, finalCalibration',
  'exam-prep-live.js?v=p304aitutor1'
]) assert(api.includes(token), `P2-06 API integration missing: ${token}`);

for (const token of [
  'const VERSION = "p206finalops1"',
  'function localDateTimeValue(value)',
  'new Date(value)',
  'date.toISOString()',
  'function renderExamOperations(component, data, stage4Data)',
  'data-ep-live-exam-ops',
  'data-ep-live-exam-start',
  'data-ep-live-exam-start-save',
  'data-ep-live-ops-check',
  'internal.api.saveExamAppointment(component, date.toISOString())',
  'internal.api.setExamOpsConfirmation(component, control.dataset.epLiveOpsCheck, control.checked)',
  'typeof internal.api?.stage4Consolidation === "function"',
  'consolidationReferenceMarkup(stage4Data, c)',
  'calibrationReferenceLabel',
  'calibrationReferenceNote'
]) assert(live.includes(token), `P2-06 learner final-calibration surface missing: ${token}`);

for (const copy of [
  'План на день экзамена',
  'Проверка перед экзаменом',
  'iClub не угадывает дату или время экзамена.',
  'До экзамена меньше 24 часов: не начинайте большую новую работу.',
  'Официальный Cambridge June 2026 reference',
  'Он не заменяет актуальное расписание и инструкции вашего центра.',
  'Exam-day plan',
  'Before-exam checklist',
  'iClub does not guess the exam date or start time.',
  'Less than 24 hours remain: do not start major new work.',
  'Official Cambridge June 2026 reference',
  'It does not replace your current exam timetable or centre instructions.',
  'Imtihon kuni rejasi',
  'Imtihon oldidan tekshiruv',
  'iClub sana yoki vaqtni taxmin qilmaydi.',
  'Imtihonga 24 soatdan kam qoldi: katta yangi ishni boshlamang.'
]) assert(live.includes(copy), `P2-06 trilingual learner copy missing: ${copy}`);

for (const token of [
  '.ep-live-ops-source',
  '.ep-live-ops-start',
  '.ep-live-ops-checklist',
  '.ep-live-ops-check'
]) assert(css.includes(token), `P2-06 checklist styling missing: ${token}`);

for (const token of [
  "v_appointment.scheduled_start_at-interval '24 hours'",
  "'major_work_stop_rule_hours',24",
  "'readiness_can_be_created_by_checklist',false",
  "'new_mastery_allowed',false",
  'school_date_session_checked',
  'exact_start_arrival_checked',
  'allowed_equipment_checked',
  'travel_arrival_plan_ready',
  'sleep_recovery_plan_ready',
  'short_review_plan_ready',
  'major_work_stop_understood'
]) assert(ops.includes(token), `P2-06 governed exam-operations contract missing: ${token}`);

assert(revision.includes('exam_series_snapshot') && revision.includes('paper_comparability_epoch'),
  'P2-06 exam operations must remain bound to the current exam-map/comparability epoch');
assert(live.includes('url.hostname === "www.cambridgeinternational.org"') &&
       live.includes('url.hostname.endsWith(".cambridgeinternational.org")'),
  'P2-06 official timetable link must be pinned to Cambridge International HTTPS');

for (const forbidden of [
  'calibrationL2',
  'calibrationL3',
  'calibrationKeySkill',
  'data-ep-live-ops-reset',
  'localStorage.setItem',
  'sessionStorage.setItem'
]) assert(!live.includes(forbidden), `P2-06 learner surface contains forbidden/internal behavior: ${forbidden}`);

new Function(api);
new Function(live);

console.log('P2-06 Final Calibration learner UI regression: GREEN');
