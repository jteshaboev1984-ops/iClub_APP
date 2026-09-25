const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };
const src = fs.readFileSync(
  'supabase/migrations/20260926014500_practice_ai4_chemistry_p1_atomic_structure_precise_v1.sql',
  'utf8'
);

const ids = [1909,1914,1916,1921,1925,1929,1933,1943,1944,1954,1959,1964,3041,3043,3044];
const keys = [...src.matchAll(/practice:chemistry:p1:q\d+:(?:ru|uz|en):v1/g)].map(m => m[0]);

assert(keys.length===45, `Chemistry P1 Atomic structure pack must contain 45 cards, got ${keys.length}`);
assert(new Set(keys).size===45, 'Chemistry P1 Atomic structure pack contains duplicate keys');

for (const id of ids) {
  for (const locale of ['ru','uz','en']) {
    assert(keys.includes(`practice:chemistry:p1:q${id}:${locale}:v1`),
      `Chemistry P1 Atomic structure source missing: q${id}/${locale}`);
  }
}

assert((src.match(/encode\(digest\(convert_to\(/g)||[]).length===45,
  'All 45 Chemistry Atomic structure hashes must be derived from card bodies');
assert(src.includes("'approved','original_iclub',true"),
  'Chemistry Atomic structure pack lost approved original_iClub boundary');
assert(src.includes("q.topic<>'Atomic structure'"),
  'Chemistry Atomic structure content-drift guard lost topic scope');

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
    `Chemistry Atomic structure precise pack violates source-only boundary: ${forbidden}`);
}

console.log('AI-4 Chemistry Practice 1 Atomic structure precise source contract: GREEN');
