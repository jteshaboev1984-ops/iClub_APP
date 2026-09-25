const fs=require('fs');
const assert=(c,m)=>{if(!c)throw new Error(m)};
const src=fs.readFileSync('supabase/migrations/20260926015500_practice_ai4_chemistry_p1_atomic_structure_diagnostics_v1.sql','utf8');

const mcqIds=['1909','1914','1916','1921','1925','1929','1933','1943','1959','3041','3044'];
const inputIds=['1944','1954','1964','3043'];

for(const id of [...mcqIds,...inputIds]) assert(src.includes(id),`Atomic diagnostic target missing: ${id}`);
assert(src.includes('one or more target questions changed'),'Atomic diagnostic drift guard missing');
assert(src.includes('published mappings already exist for a target question'),'Atomic diagnostic pre-existing guard missing');

const values=src.split('insert into public.question_answer_diagnostics')[1]||'';
assert([...values.matchAll(/\(\d+,'mcq_option','[ABCD]'/g)].length===44,'Atomic diagnostics must contain 44 MCQ option rows');
for(const id of inputIds){
  assert(values.includes(`(${id},'input_exact',null,`),`Atomic exact input mapping missing: ${id}`);
  assert(values.includes(`(${id},'fallback',null,null,false`),`Atomic fallback mapping missing: ${id}`);
}

for(const forbidden of [
 'update public.questions','delete from public.questions',
 'update public.practice_attempts','update public.practice_answers',
 'insert into public.practice_attempts','insert into public.practice_answers',
 'update public.user_answer_diagnosis','insert into public.user_answer_diagnosis',
 'update public.tour_attempts','update public.tour_answers',
 'insert into private.practice_ai_entitlements','update private.practice_ai_policy'
]) assert(!src.toLowerCase().includes(forbidden),`Atomic diagnostic mutation boundary violated: ${forbidden}`);

console.log('AI-4 Chemistry Practice 1 Atomic structure diagnostic contract: GREEN');