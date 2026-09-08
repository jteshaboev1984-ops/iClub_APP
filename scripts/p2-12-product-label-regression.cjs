const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const p211 = read('supabase/migrations/20260908143000_exam_prep_p2_11_student_product_roadmap_separation_v1.sql');
const p212 = read('supabase/migrations/20260908153000_exam_prep_p2_12_product_content_complete_label_guard_v1.sql');

for (const token of [
  "'product_content_complete','product_content_complete',date '2027-02-15','Product Content-Complete'",
  "'product_status_does_not_equal_learner_readiness',true",
  "'can_label_learner_exam_ready',false"
]) assert(p211.includes(token), `P2-12 dependency contract missing: ${token}`);

for (const token of [
  'exam_prep_product_roadmap_label_governance_v1',
  "milestone_kind<>'product_content_complete' or product_label='Product Content-Complete'",
  "lower(product_label) not like '%as ready%'",
  "lower(product_label) not like '%exam ready%'",
  'validate constraint exam_prep_product_roadmap_label_governance_v1'
]) assert(p212.includes(token), `P2-12 label guard missing: ${token}`);

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
  /update\s+public\.certificates/i,
  /insert\s+into\s+public\.certificates/i,
  /delete\s+from\s+public\.certificates/i,
  /set\s+ai_enabled\s*=\s*true/i,
  /set\s+mentor_enabled\s*=\s*true/i
]) assert(!forbidden.test(p212), `forbidden P2-12 learner/legacy mutation: ${forbidden}`);

assert(!/product_label\s*=\s*'[^']*(?:AS READY|Exam Ready)[^']*'/i.test(p211), 'P2-11 contains forbidden product readiness label assignment');
assert(!/product_label\s*=\s*'[^']*(?:AS READY|Exam Ready)[^']*'/i.test(p212), 'P2-12 contains forbidden product readiness label assignment');

console.log('P2-12 Product Content-Complete label regression: GREEN');
