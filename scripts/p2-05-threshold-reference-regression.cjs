const fs = require('fs');

function read(path) {
  return fs.readFileSync(path, 'utf8');
}
function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const migration = read('supabase/migrations/20260908053500_exam_prep_latest_threshold_reference_v1.sql');
const ui = read('exam-prep/exam-prep-threshold-reference.js');
const loader = read('exam-prep/exam-prep-profile-completeness.js');

for (const token of [
  "('P1','9709/12','A',61,75",
  "('P1','9709/12','B',51,75",
  "('P1','9709/12','C',37,75",
  "('P1','9709/12','D',23,75",
  "('P1','9709/12','E',10,75",
  "('P5','9709/52','A',41,50",
  "('P5','9709/52','B',35,50",
  "('P5','9709/52','C',28,50",
  "('P5','9709/52','D',21,50",
  "('P5','9709/52','E',13,50",
  "reference_only',true",
  "readiness_gate_active',false",
  "no_cross_component_compensation',true"
]) assert(migration.includes(token), `threshold reference contract missing: ${token}`);

assert(!/insert\s+into\s+private\.exam_prep_stage5_thresholds/i.test(migration), 'reference migration must not approve/write Stage-5 thresholds');
assert(migration.includes("if v_approved<>0"), 'migration must fail if an approved Stage-5 threshold unexpectedly exists');
assert(migration.includes('761530-mathematics-9709-june-2026-grade-threshold-table.pdf'), 'official Cambridge threshold source missing');
assert(migration.includes('paper12_replacement') && migration.includes('paper52_assessed_marks'), 'June 2026 special-handling notes missing');

for (const text of [
  'Текущий ориентир',
  'Это не прогноз и не гарантия оценки.',
  'P1 и P5 оцениваются отдельно',
  'Joriy mezon',
  'Bu baho prognozi yoki kafolati emas.',
  'P1 va P5 alohida baholanadi',
  'Current reference',
  'It is not a grade prediction or guarantee.',
  'P1 and P5 are assessed separately'
]) assert(ui.includes(text), `learner note missing: ${text}`);

for (const forbidden of ['Core beta', 'Synthetic learner data', 'Screening']) {
  assert(!ui.includes(forbidden), `internal learner-facing wording leaked: ${forbidden}`);
}

assert(loader.includes('exam-prep-threshold-reference.js?v=p205threshold1'), 'threshold reference learner layer is not loaded');
assert(ui.includes('reference.reference_only !== true'), 'UI must require explicit reference-only metadata');
assert(ui.includes('https:\\/\\/www\\.cambridgeinternational\\.org\\/'), 'UI must only link to official Cambridge domain');

console.log('P2-05 latest threshold reference regression: GREEN');
