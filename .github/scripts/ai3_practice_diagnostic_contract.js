const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };

const migration = fs.readFileSync('supabase/migrations/20260925190000_practice_ai3_diagnostic_review_context_v1.sql', 'utf8');
const edge = fs.readFileSync('supabase/functions/practice-ai/index.ts', 'utf8');
const sourcePack = fs.readFileSync('supabase/migrations/20260925170000_practice_ai2_economics_source_pack_v1.sql', 'utf8');

assert(migration.includes("'context_type','practice_review_answer_v2'"), 'AI-3 review context version missing');
assert(migration.includes("'diagnostic_mapped'"), 'AI-3 deterministic diagnosis flag missing');
assert(migration.includes("d.diagnostic_id is not null"), 'AI-3 diagnosis is not bound to a matched deterministic rule');
assert(migration.includes("'feedback',case v_locale"), 'AI-3 localized deterministic feedback missing');
assert(migration.includes("'next_action',case v_locale"), 'AI-3 localized deterministic next action missing');
assert(migration.includes("and d.diagnostic_id is not null"), 'AI-3 result patterns are not restricted to mapped diagnostics');
assert(!migration.includes("'diagnostic_id',d.diagnostic_id"), 'internal diagnostic id leaked into model context');
assert(!migration.toLowerCase().includes("'correct_answer'"), 'AI-3 context exposes correct_answer');

assert(edge.includes('diagnostic_patterns or a deterministic diagnostic field explicitly provides it'), 'provider prompt can invent misconceptions');
assert(edge.includes('For a wrong answer, explain the governing principle and what to review.'), 'AI-3 safe wrong-answer guidance missing');
assert(!edge.toLowerCase().includes('correct_answer'), 'Practice AI Edge Function references correct_answer');

for (const qid of [1071,1081,1115,1135]) {
  assert(sourcePack.includes(String(qid)), `Economics AI-3 pilot source coverage missing question ${qid}`);
}

console.log('AI-3 deterministic diagnosis contract: GREEN');
