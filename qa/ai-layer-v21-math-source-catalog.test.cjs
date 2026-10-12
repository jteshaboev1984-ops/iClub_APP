// node --test qa/ai-layer-v21-math-source-catalog.test.cjs
// Metadata-only inventory; no actual Tutor text, no learner data and no DB writes.
'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const catalog=require('./ai-layer-v21-math-source-catalog.snapshot.json');
const {resolveMathPrepared}=require('./ai-layer-v21-math-tutor-bridge.cjs');
const skills=new Map();
for(const row of catalog.rows){
 const k=row.component+'|'+row.skill;
 if(!skills.has(k))skills.set(k,new Set());
 skills.get(k).add(row.locale);
}
const cardFor=(r)=>({
 component_code:r.component,skill_code:r.skill,locale:r.locale,
 content_version:'tutor_v3_learner_first',source_card_key:r.source_key,
 main_explanation:'QA — main '+r.skill+' '+r.locale,
 simple_explanation:'QA — simple '+r.skill+' '+r.locale,
 alternative_explanation:'QA — alternative '+r.skill+' '+r.locale,
 focus_explanation:'QA — focus '+r.skill+' '+r.locale
});
const ask=(row,over={})=>{
 const c=cardFor(row);
 return resolveMathPrepared({
  entrypoint:'unified_ai',subject:'mathematics',componentCode:row.component,
  skillCode:row.skill,locale:row.locale,mode:'main',card:c,
  approvedSourceKeys:[row.source_key],sourceVersion:'tutor_v3_learner_first',
  expectedSourceVersion:'tutor_v3_learner_first',
  contextVerified:true,topicApproved:true,protectedAssessment:false,...over
 });
};
test('Full QA metadata snapshot has exactly 243 source cards and only non-personal fields',()=>{
 assert.equal(catalog.rows.length,243);
 assert.equal(catalog.approved_skill_locale_count,243);
 assert.equal(catalog.contains_student_data,false);
 assert.equal(catalog.contains_answer_text,false);
 const keys=Object.keys(catalog.rows[0]).sort();
 assert.deepEqual(keys,['component','locale','skill','source_key']);
});
test('Math skills are exactly 45 P1 + 36 P5 in every RU/UZ/EN locale',()=>{
 assert.equal(skills.size,81);
 for(const locale of ['en','ru','uz']){
  assert.equal(catalog.counts['P1-'+locale],45);
  assert.equal(catalog.counts['P5-'+locale],36);
 }
 for(const [key,languages] of skills){
  assert.deepEqual([...languages].sort(),['en','ru','uz'],'Missing locale on '+key);
 }
});
test('Every source identifier matches exactly its component, skill and locale',()=>{
 const seen=new Set();
 for(const row of catalog.rows){
   assert.match(row.skill,/^P[15]-[A-Z0-9]+-[0-9]{2}$/);
   assert.equal(row.skill.startsWith(row.component+'-'),true);
   assert.equal(row.source_key,
     row.component.toLowerCase()+':'+row.skill+':theory:'+row.locale+':v2');
   const k=row.component+'|'+row.skill+'|'+row.locale;
   assert.equal(seen.has(k),false,'Duplicate approved metadata '+k);seen.add(k);
 }
 assert.equal(seen.size,243);
});
test('Exact approved P1/P5 cards admit all four static modes (972 candidate routes)',()=>{
 const modes=['main','simplify','rephrase','focus'];let valid=0;
 for(const r of catalog.rows)for(const mode of modes){
  const response=ask(r,{mode});
  assert.equal(response.ok,true,r.skill+' '+r.locale+' '+mode+' reason='+response.reason);
  assert.equal(response.route,'prepared');
  assert.equal(response.unifiedQuotaUnits,1);
  assert.equal(response.providerCallRequired,false);
  valid++;
 }
 assert.equal(valid,972);
});
test('No P1/P5 locale-mismatch or neighboring topic may borrow approved explanation',()=>{
 for(const r of catalog.rows){
  const other=r.locale==='ru'?'en':'ru';
  const bad=ask(r,{locale:other});
  assert.equal(bad.ok,false,r.skill+' should not use '+r.locale+' card for '+other);
 }
});
test('Forged source card key cannot pass even if caller claims key approved',()=>{
 for(const r of catalog.rows){
  const c=cardFor(r);c.source_card_key='arbitrary-approved-by-client';
  const result=ask(r,{card:c,approvedSourceKeys:['arbitrary-approved-by-client']});
  assert.equal(result.reason,'source_catalog_mismatch',r.skill+' '+r.locale);
 }
});
test('A syntactically plausible but unapproved skill cannot pass',()=>{
 const model=catalog.rows[0];
 const fake='P1-FOO-99',c=cardFor(model);
 c.skill_code=fake;c.source_card_key='p1:'+fake+':theory:'+model.locale+':v2';
 const result=ask(model,{skillCode:fake,card:c,approvedSourceKeys:[c.source_card_key]});
 assert.equal(result.reason,'skill_not_in_verified_catalog');
});
test('Prepared mode never swallows a freeform question into a cheap static response',()=>{
 for(const r of catalog.rows.slice(0,12)){
  assert.equal(ask(r,{mode:'question'}).reason,'requires_separate_governed_route');
 }
});
test('Legacy Tutor remains unmetered by this new adapter, regardless of catalog',()=>{
 const result=resolveMathPrepared({entrypoint:'legacy_exam_prep'});
 assert.equal(result.action,'legacy_passthrough');
 assert.equal(result.unifiedQuotaUnits,0);
});
