const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };
const migration = fs.readFileSync(
  'supabase/migrations/20260926002500_practice_ai4_economics_p1_diagnostics_ch5_v1.sql',
  'utf8'
);

for (const id of ['1090','1116']) {
  assert(migration.includes(id), `AI-4 Chapter 5 target missing: ${id}`);
}

assert(
  migration.includes("raise exception 'AI-4 diagnostic batch refused: one or more Chapter 5 questions changed'"),
  'AI-4 Chapter 5 migration lost content-drift guard'
);
assert(
  migration.includes("published mappings already exist for a target question"),
  'AI-4 Chapter 5 migration lost pre-existing mapping guard'
);

const valuesSection = migration.split('insert into public.question_answer_diagnostics')[1] || '';
const mcqRows = [...valuesSection.matchAll(/\(1090,'mcq_option','[ABCD]'/g)];
assert(mcqRows.length === 4, `AI-4 Chapter 5 q1090 must insert exactly 4 option mappings, got ${mcqRows.length}`);
assert(valuesSection.includes("(1116,'input_exact',null,'2',true"), 'AI-4 Chapter 5 q1116 exact correct mapping missing');
assert(valuesSection.includes("(1116,'fallback',null,null,false"), 'AI-4 Chapter 5 q1116 fallback mapping missing');

for (const forbidden of [
  'update public.questions',
  'delete from public.questions',
  'update public.practice_attempts',
  'update public.practice_answers',
  'insert into public.practice_attempts',
  'insert into public.practice_answers',
  'update public.user_answer_diagnosis',
  'insert into public.user_answer_diagnosis',
  'update public.tour_attempts',
  'update public.tour_answers',
]) {
  assert(!migration.toLowerCase().includes(forbidden), `AI-4 diagnostic migration may mutate academic/history table: ${forbidden}`);
}

assert(!migration.includes("1102,'mcq_option'"), 'AI-4 Chapter 5 batch must not overwrite existing Chapter 4 mappings');

console.log('AI-4 Economics Practice 1 Chapter 5 diagnostic contract: GREEN');
