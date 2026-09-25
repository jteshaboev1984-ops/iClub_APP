const fs=require('fs');
const assert=(c,m)=>{if(!c)throw new Error(m)};
const migration=fs.readFileSync('supabase/migrations/20260926011500_practice_ai4_economics_p1_diagnostics_ch10_v1.sql','utf8');

for(const id of ['1032','1074','1075','1076','1086','1088','1096','1097','1117'])
  assert(migration.includes(id),`AI-4 Chapter 10 target missing: ${id}`);

assert(migration.includes('one or more Chapter 10 questions changed'),'AI-4 Chapter 10 drift guard missing');
assert(migration.includes('published mappings already exist for a target question'),'AI-4 Chapter 10 pre-existing guard missing');

const values=migration.split('insert into public.question_answer_diagnostics')[1]||'';
assert([...values.matchAll(/\(\d+,'mcq_option','[ABCD]'/g)].length===28,'AI-4 Chapter 10 must contain 28 MCQ mappings');

for(const [id,answer] of [['1032','10'],['1076','15']]){
  assert(values.includes(`(${id},'input_exact',null,'${answer}',true`),`exact input missing ${id}`);
  assert(values.includes(`(${id},'fallback',null,null,false`),`fallback missing ${id}`);
}

for(const f of [
 'update public.questions','delete from public.questions',
 'update public.practice_attempts','update public.practice_answers',
 'insert into public.practice_attempts','insert into public.practice_answers',
 'update public.user_answer_diagnosis','insert into public.user_answer_diagnosis',
 'update public.tour_attempts','update public.tour_answers'
]) assert(!migration.toLowerCase().includes(f),`AI-4 mutation boundary violated: ${f}`);

assert(!migration.includes("1087,'mcq_option'"),'AI-4 Chapter 10 must not overwrite Chapter 9 mappings');

console.log('AI-4 Economics Practice 1 Chapter 10 diagnostic contract: GREEN');