const fs=require('fs');
const assert=(c,m)=>{if(!c)throw new Error(m)};
const migration=fs.readFileSync('supabase/migrations/20260926012500_practice_ai4_economics_p1_diagnostics_ch11_v1.sql','utf8');

for(const id of ['1028','1029','1079','1121','1133'])
  assert(migration.includes(id),`AI-4 Chapter 11 target missing: ${id}`);

assert(migration.includes('one or more Chapter 11 questions changed'),'AI-4 Chapter 11 drift guard missing');
assert(migration.includes('published mappings already exist for a target question'),'AI-4 Chapter 11 pre-existing guard missing');

const values=migration.split('insert into public.question_answer_diagnostics')[1]||'';
assert([...values.matchAll(/\(\d+,'mcq_option','[ABCD]'/g)].length===20,'AI-4 Chapter 11 must contain 20 MCQ mappings');

for(const f of [
 'update public.questions','delete from public.questions',
 'update public.practice_attempts','update public.practice_answers',
 'insert into public.practice_attempts','insert into public.practice_answers',
 'update public.user_answer_diagnosis','insert into public.user_answer_diagnosis',
 'update public.tour_attempts','update public.tour_answers'
]) assert(!migration.toLowerCase().includes(f),`AI-4 mutation boundary violated: ${f}`);

assert(!migration.includes("1081,'mcq_option'"),'AI-4 Chapter 11 must not overwrite existing q1081 mappings');
assert(!migration.includes("1115,'mcq_option'"),'AI-4 Chapter 11 must not overwrite existing q1115 mappings');

console.log('AI-4 Economics Practice 1 Chapter 11 diagnostic contract: GREEN');