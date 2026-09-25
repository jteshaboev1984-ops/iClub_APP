const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };

const edge = fs.readFileSync('supabase/functions/practice-ai/index.ts', 'utf8');
const migration = fs.readFileSync(
  'supabase/migrations/20260925190000_practice_ai3_deterministic_diagnosis_context_v1.sql',
  'utf8'
);

for (const token of [
  "'diagnostic_mapped'",
  "'diagnostic'",
  'd.diagnostic_id is not null',
  'd.mistake_type is not null',
  "'feedback'",
  "'next_action'",
]) {
  assert(migration.includes(token), `AI-3 deterministic diagnosis token missing: ${token}`);
}

assert(
  migration.includes("a.is_correct is false") && migration.includes("d.is_correct=false"),
  'AI-3 must expose misconception diagnosis only for confirmed wrong answers'
);
assert(
  !/jsonb_build_object\([\s\S]{0,1800}'correct_answer'/i.test(migration),
  'AI-3 context exposes correct_answer'
);
assert(
  !/jsonb_build_object\([\s\S]{0,1800}'answer_key'/i.test(migration),
  'AI-3 context exposes answer_key'
);
assert(
  edge.includes('Do not claim a specific misconception unless diagnostic_patterns or a deterministic diagnostic field explicitly provides it.'),
  'Practice AI prompt lost the deterministic-only misconception rule'
);
assert(
  edge.includes('get_practice_ai_review_question_context_service_v1'),
  'Practice AI does not consume finalized deterministic review context'
);
assert(
  !edge.toLowerCase().includes('correct_answer') && !edge.toLowerCase().includes('answer_key'),
  'Practice AI Edge references private answer material'
);

console.log('AI-3 deterministic Practice diagnosis contract: GREEN');
