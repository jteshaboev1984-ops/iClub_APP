// Run: node --test qa/ai-layer-v21-math-tutor-bridge.test.cjs
'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {resolveMathPrepared}=require('./ai-layer-v21-math-tutor-bridge.cjs');
const card={
 component_code:'P1',skill_code:'P1-CIR-01',locale:'ru',content_version:'tutor_v3_learner_first',
 source_card_key:'p1:P1-CIR-01:theory:ru:v2',
 main_explanation:'Проверенное основное объяснение.',
 simple_explanation:'Простое объяснение.',
 alternative_explanation:'Альтернативное объяснение.',
 focus_explanation:'Главное, что нужно запомнить.'
};
const valid=(change={})=>({
 entrypoint:'unified_ai',subject:'mathematics',componentCode:'P1',skillCode:'P1-CIR-01',locale:'ru',
 mode:'main',card,approvedSourceKeys:[card.source_card_key],
 sourceVersion:'tutor_v3_learner_first',expectedSourceVersion:'tutor_v3_learner_first',
 contextVerified:true,topicApproved:true,protectedAssessment:false,...change
});
test('Legacy Math Tutor bypasses new unified quota entirely',()=>{
 const out=resolveMathPrepared({entrypoint:'legacy_exam_prep'});
 assert.equal(out.ok,true);assert.equal(out.action,'legacy_passthrough');
 assert.equal(out.unifiedQuotaUnits,0);assert.equal(out.message,undefined);
});
test('Exact approved card in unified UI becomes prepared1, no model call',()=>{
 const out=resolveMathPrepared(valid());
 assert.equal(out.ok,true);assert.equal(out.action,'unified_prepared');
 assert.equal(out.unifiedQuotaUnits,1);assert.equal(out.providerCallRequired,false);
 assert.equal(out.message,card.main_explanation);
});
test('All four existing Math Tutor variants retain exact approved copy',()=>{
 for(const [mode,field] of Object.entries({
   main:'main_explanation',simplify:'simple_explanation',
   rephrase:'alternative_explanation',focus:'focus_explanation'
 })){
  assert.equal(resolveMathPrepared(valid({mode})).message,card[field],mode);
 }
});
test('Freeform question never gets falsely classified as static card',()=>{
 assert.equal(resolveMathPrepared(valid({mode:'question'})).reason,'requires_separate_governed_route');
});
test('P1 must not be replaced with P5 card or skill',()=>{
 assert.equal(resolveMathPrepared(valid({componentCode:'P5'})).reason,'skill_invalid');
 assert.equal(resolveMathPrepared(valid({skillCode:'P5-PRO-01'})).reason,'skill_invalid');
});
test('A wrong-subject card is never used in Math',()=>{
 assert.equal(resolveMathPrepared(valid({subject:'economics'})).reason,'subject_mismatch');
});
test('Locale mismatch and invalid locale fail closed',()=>{
 assert.equal(resolveMathPrepared(valid({locale:'en'})).reason,'tutor_card_mismatch');
 assert.equal(resolveMathPrepared(valid({locale:'fr'})).reason,'language_unverified');
});
test('Untrusted topic, unauthorized learner or active exam returns no card',()=>{
 assert.equal(resolveMathPrepared(valid({contextVerified:false})).reason,'context_unverified');
 assert.equal(resolveMathPrepared(valid({topicApproved:false})).reason,'context_unverified');
 assert.equal(resolveMathPrepared(valid({protectedAssessment:true})).reason,'protected_assessment');
});
test('Source card must be in approved source bundle',()=>{
 assert.equal(resolveMathPrepared(valid({approvedSourceKeys:[]})).reason,'source_not_approved');
 assert.equal(resolveMathPrepared(valid({approvedSourceKeys:['other-card']})).reason,'source_not_approved');
});
test('Tutor source version drift blocks only unified bridge, not legacy route',()=>{
 assert.equal(resolveMathPrepared(valid({sourceVersion:'tutor_v2'})).reason,'source_version_mismatch');
 assert.equal(resolveMathPrepared(valid({entrypoint:'legacy_exam_prep',sourceVersion:'tutor_v2'})).action,'legacy_passthrough');
});
test('Missing or potentially unsafe card content is never delivered',()=>{
 assert.equal(resolveMathPrepared(valid({card:{...card,main_explanation:'   '}})).reason,'prepared_variant_unavailable');
 assert.equal(resolveMathPrepared(valid({card:{...card,main_explanation:'<script>bad</script>'}})).reason,'prepared_variant_unavailable');
});
test('Duplicate or unknown entrypoint cannot sneak into legacy bypass',()=>{
 assert.equal(resolveMathPrepared(valid({entrypoint:'unknown'})).reason,'unknown_entrypoint');
 assert.equal(resolveMathPrepared(valid({entrypoint:'global-chat'})).reason,'unknown_entrypoint');
});
test('Proposed bridge has no mutation of progress or legacy subscription state',()=>{
 const snapshot=JSON.stringify(card);
 const out=resolveMathPrepared(valid());
 assert.equal(out.ok,true);
 assert.equal(JSON.stringify(card),snapshot);
 assert.equal(Object.hasOwn(out,'academic_state_changed'),false);
});
