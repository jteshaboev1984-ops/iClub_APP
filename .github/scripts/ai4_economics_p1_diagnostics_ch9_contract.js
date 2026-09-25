const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };
const migration = fs.readFileSync(
  'supabase/migrations/20260926010500_practice_ai4_economics_p1_diagnostics_ch9_v1.sql',
  'utf8'
);

for (const id of ['1087','1095','1103','1104','1113','1119','1120','1132']) {
  assert(migration.includes(id), `AI-4 Chapter 9 target missing: ${id}`);
}

assert(migration.includes("one or more Chapter 9 questions changed"),
  'AI-4 Chapter 9 content-drift guard missing');
assert(migration.includes("published mappings already exist for a target question"),
  'AI-4 Chapter 9 pre-existing mapping guard missing');

const values = migration.split('insert into public.question_answer_diagnostics')[1] || '';
assert([...values.matchAll(/\(\d+,'mcq_option','[ABCD]'/g)].length===20,
  'AI-4 Chapter 9 must contain 20 MCQ mappings');

for (const [id,answer] of [['1095','2'],['1103','3'],['1120','2']]) {
  assert(values.includes(`(${id},'input_exact',null,'${answer}',true`),
    `AI-4 Chapter 9 exact input mapping missing for ${id}`);
  assert(values.includes(`(${id},'fallback',null,null,false`),
    `AI-4 Chapter 9 fallback mapping missing for ${id}`);
}

for (const forbidden of [
  'update public.questions','delete from public.questions',
  'update public.practice_attempts','update public.practice_answers',
  'insert into public.practice_attempts','insert into public.practice_answers',
  'update public.user_answer_diagnosis','insert into public.user_answer_diagnosis',
  'update public.tour_attempts','update public.tour_answers'
]) {
  assert(!migration.toLowerCase().includes(forbidden), `AI-4 mutation boundary violated: ${forbidden}`);
}

assert(!migration.includes("1023,'mcq_option'"), 'AI-4 Chapter 9 must not overwrite Chapter 8 mappings');

console.log('AI-4 Economics Practice 1 Chapter 9 diagnostic contract: GREEN');
