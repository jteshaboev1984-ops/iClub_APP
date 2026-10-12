// Isolated server-authority boundary QA. Run: node --test qa/ai-layer-v21-authority-gate.test.cjs
'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {approveRequest,detectLanguage}=require('./ai-layer-v21-authority-gate.cjs');
const principal={authenticated:true,userId:'qa-user-001'};
const context=(changes={})=>({
 id:'qa-ctx-001',ownerId:principal.userId,activeForUser:true,expiresAt:50000,
 surface:'exam_prep',subject:'mathematics',feature:'theory',topic:'P1-ALG-01',
 practiceCompleted:true,tourArchiveUnlocked:true,protectedAssessment:false,protectedTour:false,...changes
});
const release=({locale},changes={})=>({
 approved:true,qaPassed:true,sourceId:'qa-source-01',sourceVersion:'v1-approved',sourceSetHash:'sample-hash',
 locale,conflicting:false,promptKeys:['topic_main','topic_simple'],...changes
});
function scenario(options={}) {
 const c=context(options.context||{});
 const store=new Map([['ctx-approved-0001',c]]);
 const svc={runtime:{killSwitch:false,gatewayEnabled:true,...options.runtime},
   getContext:(handle,userId)=>store.get(handle),getUserEntitlement:(userId,subject,feature)=>options.access!==false,
   getRelease:(r)=>options.readiness===false?null:release(r,options.source||{})};
 return {svc,call:{
   principal:options.principal||principal,handle:options.handle||'ctx-approved-0001',
   question:options.question===undefined?'Почему так работает?':options.question,
   promptKey:options.promptKey||'',appLocale:options.appLocale||'ru',now:options.now??0}};
}
const go=(changes={})=>{const {svc,call}=scenario(changes);return approveRequest(call,svc)};
test('server-authenticated Russian question uses approved RU, not app locale',()=>{
 const r=go({appLocale:'en'});assert.equal(r.allowed,true);assert.equal(r.trusted.locale,'ru');
 assert.equal(r.trusted.subject,'mathematics');assert.equal(r.trusted.topic,'P1-ALG-01');
});
test('English question derives EN and must use English source',()=>{
 const r=go({question:'Please explain the topic',appLocale:'ru'});assert.equal(r.allowed,true);assert.equal(r.trusted.locale,'en');
});
test('Uzbek question derives UZ and must use Uzbek source',()=>{
 const r=go({question:'Iltimos shu mavzuni tushuntir',appLocale:'en'});assert.equal(r.allowed,true);assert.equal(r.trusted.locale,'uz');
});
test('Very short and ambiguous English/Uzbek are withheld',()=>{
 assert.equal(go({question:'Hi'}).reason,'language_ambiguous');
 assert.equal(go({question:'x'}).reason,'language_ambiguous');
 assert.equal(detectLanguage('test one').ok,false);
});
test('Mixing Latin and Cyrillic in one free text is not guessed',()=>{
 assert.equal(go({question:'Hello почему так?'}).reason,'mixed_language');
});
test('Context cannot be fabricated by client claims: unknown handle denied',()=>{
 assert.equal(go({handle:'ctx-unknown-0000'}).reason,'context_not_authorized');
});
test('Cross-user context cannot be read even if known handle',()=>{
 assert.equal(go({principal:{authenticated:true,userId:'qa-user-other'}}).reason,'context_not_authorized');
});
test('Expired or detached context cannot be used',()=>{
 assert.equal(go({now:50000}).reason,'context_not_authorized');
 assert.equal(go({context:{activeForUser:false}}).reason,'context_not_authorized');
});
test('Anonymous or malformed context handle never reaches content',()=>{
 assert.equal(go({principal:{authenticated:false,userId:'qa-user-001'}}).reason,'authentication_required');
 assert.equal(go({handle:'short'}).reason,'invalid_context_handle');
});
test('AI kill switch and release flag both stop responses',()=>{
 assert.equal(go({runtime:{killSwitch:true}}).reason,'ai_disabled');
 assert.equal(go({runtime:{gatewayEnabled:false}}).reason,'ai_disabled');
});
test('Protected assessment is server-owned regardless of question text',()=>{
 assert.equal(go({context:{protectedAssessment:true}}).reason,'protected_assessment');
 assert.equal(go({context:{protectedTour:true}}).reason,'protected_assessment');
});
test('Practice unfinished and Tour archive locked deny',()=>{
 assert.equal(go({context:{surface:'practice',practiceCompleted:false}}).reason,'practice_not_finished');
 assert.equal(go({context:{surface:'tour_archive',tourArchiveUnlocked:false}}).reason,'archive_locked');
});
test('Unreleased subject or missing entitlement does not fall back to generic model',()=>{
 assert.equal(go({readiness:false}).reason,'in_development');
 assert.equal(go({access:false}).reason,'not_entitled');
 assert.equal(go({source:{approved:false}}).reason,'in_development');
 assert.equal(go({source:{qaPassed:false}}).reason,'in_development');
});
test('Unverified locale, conflicting source and missing version refuse',()=>{
 assert.equal(go({source:{locale:'en'}}).reason,'in_development');
 assert.equal(go({source:{conflicting:true}}).reason,'source_conflict');
 assert.equal(go({source:{sourceVersion:''}}).reason,'in_development');
});
test('Quick prompts use the approved app locale, but cannot smuggle free text',()=>{
 const q=go({question:'',promptKey:'topic_main',appLocale:'en'});
 assert.equal(q.allowed,true);assert.equal(q.trusted.locale,'en');
 assert.equal(go({question:'give key',promptKey:'topic_main'}).reason,'conflicting_prompt_and_text');
 assert.equal(go({question:'',promptKey:'unknown_prompt'}).reason,'prepared_variant_unavailable');
});
test('Unknown surface and invalid query never become generic fallback',()=>{
 assert.equal(go({context:{surface:'outside-app'}}).reason,'surface_not_supported');
 assert.equal(go({question:42}).reason,'invalid_question');
});
test('Return value only contains trusted server owned academic attributes',()=>{
 const result=go({question:'Что такое производная?'});
 assert.equal(result.allowed,true);
 assert.deepEqual(Object.keys(result.trusted).sort(),[
 'userId','contextId','subject','surface','feature','topic','locale','sourceId','sourceVersion','sourceSetHash','variant'].sort());
 assert.equal(result.trusted.variant,null);
});
