const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };
const migration = fs.readFileSync(
  'supabase/migrations/20260926004500_practice_ai4_economics_p1_diagnostics_ch7_v1.sql',
  'utf8'
);

const targetIds = ['1020','1021','1030','1070','1072','1078','1085','1092','1093','1106'];
for (const id of targetIds) {
  assert(migration.includes(id), `AI-4 Chapter 7 target missing: ${id}`);
}

assert(
  migration.includes("raise exception 'AI-4 diagnostic batch refused: one or more Chapter 7 questions changed'"),
  'AI-4 Chapter 7 migration lost content-drift guard'
);
assert(
  migration.includes("published mappings already exist for a target question"),
  'AI-4 Chapter 7 migration lost pre-existing mapping guard'
);

const valuesSection = migration.split('insert into public.question_answer_diagnostics')[1] || '';
const optionRows = [...valuesSection.matchAll(/\(\d+,'mcq_option','[ABCD]'/g)];
assert(optionRows.length === 40, `AI-4 Chapter 7 must insert exactly 40 option mappings, got ${optionRows.length}`);

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

assert(!migration.includes("1071,'mcq_option'"), 'AI-4 Chapter 7 batch must not overwrite existing q1071 mappings');

console.log('AI-4 Economics Practice 1 Chapter 7 diagnostic contract: GREEN');
