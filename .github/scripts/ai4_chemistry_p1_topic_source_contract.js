const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };
const src = fs.readFileSync(
  'supabase/migrations/20260926013500_practice_ai4_chemistry_p1_topic_source_pack_v1.sql',
  'utf8'
);

const keys = [...src.matchAll(/practice:chemistry:p1:topic:[a-z0-9-]+:(?:ru|uz|en):v1/g)].map(m => m[0]);
assert(keys.length === 15, `Chemistry P1 topic pack must contain exactly 15 cards, got ${keys.length}`);
assert(new Set(keys).size === 15, 'Chemistry P1 topic pack contains duplicate source_card_key values');

for (const topic of [
  'atomic-structure',
  'electrons-in-atoms',
  'stoichiometry',
  'atoms-molecules-stoichiometry',
  'chemical',
]) {
  for (const locale of ['ru','uz','en']) {
    assert(
      keys.includes(`practice:chemistry:p1:topic:${topic}:${locale}:v1`),
      `Chemistry P1 topic source missing: ${topic}/${locale}`
    );
  }
}

assert(src.includes("'approved','original_iclub',true"),
  'Chemistry P1 topic pack lost approved original_iClub runtime boundary');
assert(src.includes('Broad fallback only: question_id and subtopic are intentionally NULL.'),
  'Chemistry P1 topic pack lost broad-fallback boundary');
assert((src.match(/encode\(digest\(convert_to\(/g) || []).length === 15,
  'Chemistry P1 topic pack must derive all 15 hashes from card bodies');

for (const forbidden of [
  'correct_answer',
  'answer_key',
  'update public.questions',
  'delete from public.questions',
  'update public.practice_attempts',
  'update public.practice_answers',
  'insert into public.practice_attempts',
  'insert into public.practice_answers',
  'update public.user_answer_diagnosis',
  'insert into public.user_answer_diagnosis',
  'insert into private.practice_ai_entitlements',
  'update private.practice_ai_policy',
]) {
  assert(!src.toLowerCase().includes(forbidden),
    `Chemistry P1 topic pack violates source-only boundary: ${forbidden}`);
}

console.log('AI-4 Chemistry Practice 1 topic source contract: GREEN');
