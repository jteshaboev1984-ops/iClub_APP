const fs=require('fs');
const assert=(c,m)=>{if(!c)throw new Error(m)};
const src=fs.readFileSync('supabase/migrations/20260926020500_practice_ai4_chemistry_p1_electrons_precise_v1.sql','utf8');
const ids=[1908,1917,1927,1931,1937,1939,1941,1945,1953,1956,1960,1962,1968,1971,3036,3037,3039,3046];
const keys=[...src.matchAll(/practice:chemistry:p1:q\d+:(?:ru|uz|en):v1/g)].map(m=>m[0]);
assert(keys.length===54,`Chemistry Electrons pack must contain 54 cards, got ${keys.length}`);
assert(new Set(keys).size===54,'Chemistry Electrons pack contains duplicate keys');
for(const id of ids) for(const locale of ['ru','uz','en'])
  assert(keys.includes(`practice:chemistry:p1:q${id}:${locale}:v1`),`missing q${id}/${locale}`);
assert((src.match(/encode\(digest\(convert_to\(/g)||[]).length===54,'All Electrons hashes must be body-derived');
assert(src.includes("'approved','original_iclub',true"),'Approved original_iClub boundary missing');
assert(src.includes("q.topic<>'Electrons in atoms'"),'Topic drift guard missing');
for(const f of [
 'correct_answer','answer_key','update public.questions','delete from public.questions',
 'update public.practice_attempts','update public.practice_answers','insert into public.practice_attempts',
 'insert into public.practice_answers','update public.user_answer_diagnosis','insert into public.user_answer_diagnosis',
 'insert into private.practice_ai_entitlements','update private.practice_ai_policy'
]) assert(!src.toLowerCase().includes(f),`Source-only boundary violated: ${f}`);
console.log('AI-4 Chemistry Practice 1 Electrons precise source contract: GREEN');