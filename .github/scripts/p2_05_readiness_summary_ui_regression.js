const fs = require('fs');

const api = fs.readFileSync('exam-prep/exam-prep-api.js','utf8');
const live = fs.readFileSync('exam-prep/exam-prep-live.js','utf8');
const migration = fs.readFileSync('supabase/migrations/20261002060000_exam_prep_p2_05_readiness_summary_safe_v1.sql','utf8');

function must(condition,message){ if(!condition) throw new Error(`P2-05 readiness UI regression: ${message}`); }

for(const token of [
  'async function readiness(componentCode)',
  'async function readinessSummary(componentCode)',
  'get_exam_prep_readiness_safe_v1',
  'get_exam_prep_readiness_summary_safe_v1',
  'readiness, readinessSummary, examOps, saveExamAppointment, setExamOpsConfirmation, finalCalibration',
  'exam-prep-live.js?v=p304aitutor1'
]) must(api.includes(token), `API integration missing: ${token}`);

for(const token of [
  'function normalizeReadiness(data)',
  'typeof internal.api?.readinessSummary === "function"',
  'internal.api.readinessSummary(component)',
  'data-ep-live-readiness-summary',
  'data-ep-live-mentor-readiness',
  'data?.mentor_care_active === true || data?.mentor_verified === true',
  'data?.p1_p5_separate === false',
  'data?.not_official_cambridge_grade === false',
  'data?.mentor_verification_optional_for_core === false',
  'readinessEstimateNote',
  'mentorReadinessSeparate'
]) must(live.includes(token), `learner readiness surface missing: ${token}`);

for(const copy of [
  'Оценка готовности iClub',
  'Это не официальная оценка Cambridge и не прогноз будущей оценки.',
  'официальный показатель Cambridge June 2026 ниже дан только как ориентир.',
  'Это отдельная проверка человеком. Для продолжения в Core она не обязательна.',
  'iClub readiness estimate',
  'It is not an official Cambridge grade or a prediction of a future grade.',
  'the official Cambridge June 2026 figure below is reference only.',
  'This is a separate human check. It is not required to continue in Core.',
  'iClub tayyorgarlik bahosi',
  'Bu Cambridge bahosi yoki kelajakdagi baho prognozi emas.',
  'quyidagi rasmiy Cambridge June 2026 ko‘rsatkichi faqat ma’lumot uchun.',
  'Bu alohida inson tekshiruvi. Core’da davom etish uchun majburiy emas.'
]) must(live.includes(copy), `trilingual readiness copy missing: ${copy}`);

must(!live.includes('readinessEstimateTitle: "App Readiness Estimate"'),
  'internal product label must not replace learner-friendly copy');
must(!live.includes('mentorReadinessTitle: "Mentor Verified READY"'),
  'Mentor Verified internal/status label must not be used as learner heading');
must(!live.includes('readinessSkills: "L3'),
  'learner readiness copy must not expose internal level labels');

for(const token of [
  'create or replace function public.get_exam_prep_readiness_summary_safe_v1',
  'private.exam_prep_stage5_readiness_status_v1',
  'private.exam_prep_mentor_verified_readiness_status_v1',
  'private.exam_prep_latest_threshold_reference_v1',
  "'not_official_cambridge_grade',true",
  "'mentor_verification_optional_for_core',true",
  "'p1_p5_separate',true",
  "'reference_only',true",
  "'reference_label','Official Cambridge 9709 · June 2026 reference'",
  "'readiness_gate_active',false",
  'v_approved_thresholds<>0',
  'exam_prep_second_check_must_be_independent',
  'exam_prep_readiness_evidence_changed'
]) must(migration.toLowerCase().includes(token.toLowerCase()), `safe readiness contract missing: ${token}`);

for(const forbidden of [
  "'rule_version',",
  "'program_version_id',v_program",
  "'readiness_fingerprint',",
  "'last_three_evaluation',"
]) must(!migration.includes(forbidden), `internal implementation field leaked by summary: ${forbidden}`);

new Function(api);
new Function(live);
console.log('P2-05 learner readiness summary UI regression: GREEN');
