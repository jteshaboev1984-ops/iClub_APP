const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };
const migration = fs.readFileSync(
  'supabase/migrations/20260926005500_practice_ai4_economics_p1_diagnostics_ch8_v1.sql',
  'utf8'
);

for (const id of ['1023','1024','1077','1080','1094','1127','1134']) {
  assert(migration.includes(id), `AI-4 Chapter 8 target missing: ${id}`);
}

assert(
  migration.includes("raise exception 'AI-4 diagnostic batch refused: one or more Chapter 8 questions changed'"),
  'AI-4 Chapter 8 migration lost content-drift guard'
);
assert(
  migration.includes("published mappings already exist for a target question"),
  'AI-4 Chapter 8 migration lost pre-existing mapping guard'
);

const valuesSection = migration.split('insert into public.question_answer_diagnostics')[1] || '';
assert([...valuesSection.matchAll(/\(\d+,'mcq_option','[ABCD]'/g)].length===24,
  'AI-4 Chapter 8 must insert exactly 24 MCQ mappings');
assert(valuesSection.includes("(1094,'input_exact',null,'2',true"),
  'AI-4 Chapter 8 q1094 exact correct mapping missing');
assert(valuesSection.includes("(1094,'fallback',null,null,false"),
  'AI-4 Chapter 8 q1094 fallback mapping missing');

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
  assert(!migration.toLowerCase().includes(forbidden), `AI-4 mutation boundary violated: ${forbidden}`);
}

assert(!migration.includes("1020,'mcq_option'"), 'AI-4 Chapter 8 must not overwrite Chapter 7 mappings');

console.log('AI-4 Economics Practice 1 Chapter 8 diagnostic contract: GREEN');
