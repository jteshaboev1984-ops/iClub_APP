const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };
const migration = fs.readFileSync(
  'supabase/migrations/20260925235500_practice_ai4_economics_p1_diagnostics_ch2_v1.sql',
  'utf8'
);

const targetIds = ['1083','1112','1118','1126','1129','1130'];
for (const id of targetIds) {
  assert(migration.includes(id), `AI-4 Chapter 2 target missing: ${id}`);
}

assert(
  migration.includes("raise exception 'AI-4 diagnostic batch refused: one or more Chapter 2 questions changed'"),
  'AI-4 Chapter 2 migration lost content-drift guard'
);
assert(
  migration.includes("published mappings already exist for a target question"),
  'AI-4 Chapter 2 migration lost pre-existing mapping guard'
);
assert(
  migration.includes("insert into public.question_answer_diagnostics"),
  'AI-4 Chapter 2 diagnostic insert missing'
);

const valuesSection = migration.split('insert into public.question_answer_diagnostics')[1] || '';
const optionRows = [...valuesSection.matchAll(/\(\d+,'mcq_option','[ABCD]'/g)];
assert(optionRows.length === 24, `AI-4 Chapter 2 must insert exactly 24 option mappings, got ${optionRows.length}`);

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

assert(!migration.includes("1013,'mcq_option'"), 'AI-4 Chapter 2 batch must not overwrite existing Chapter 1 mappings');

console.log('AI-4 Economics Practice 1 Chapter 2 diagnostic contract: GREEN');
