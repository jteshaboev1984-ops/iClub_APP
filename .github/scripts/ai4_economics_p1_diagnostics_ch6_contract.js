const fs=require('fs');
const assert=(c,m)=>{if(!c)throw new Error(m)};
const migration=fs.readFileSync('supabase/migrations/20260926003500_practice_ai4_economics_p1_diagnostics_ch6_v1.sql','utf8');
for(const id of ['1100','1111','1123','1124']) assert(migration.includes(id),`AI-4 Chapter 6 target missing: ${id}`);
assert(migration.includes("one or more Chapter 6 questions changed"),'AI-4 Chapter 6 drift guard missing');
assert(migration.includes("published mappings already exist for a target question"),'AI-4 Chapter 6 pre-existing guard missing');
const values=migration.split('insert into public.question_answer_diagnostics')[1]||'';
assert([...values.matchAll(/\(\d+,'mcq_option','[ABCD]'/g)].length===16,'AI-4 Chapter 6 must contain 16 option mappings');
for(const f of ['update public.questions','delete from public.questions','update public.practice_attempts','update public.practice_answers','insert into public.practice_attempts','insert into public.practice_answers','update public.user_answer_diagnosis','insert into public.user_answer_diagnosis','update public.tour_attempts','update public.tour_answers'])
  assert(!migration.toLowerCase().includes(f),`AI-4 mutation boundary violated: ${f}`);
assert(!migration.includes("1090,'mcq_option'"),'AI-4 Chapter 6 must not overwrite Chapter 5 mappings');
console.log('AI-4 Economics Practice 1 Chapter 6 diagnostic contract: GREEN');