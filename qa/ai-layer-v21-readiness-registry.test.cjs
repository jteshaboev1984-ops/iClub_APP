// node --test qa/ai-layer-v21-readiness-registry.test.cjs
'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict');
const {PreviewFeatureRegistry,key,gates}=require('./ai-layer-v21-readiness-registry.cjs');
const GREEN=Object.fromEntries(gates.map(g=>[g,true]));
const row=(changes={})=>({surface:'exam_prep',subject:'mathematics',feature:'topic_explanation',topic:'P1-ALG-01',locale:'ru',featureId:'math-topic',sourceId:'qa-source',sourceVersion:'v1',gates:{...GREEN},sourceConflict:false,...changes});
const query=(changes={})=>({surface:'exam_prep',subject:'mathematics',feature:'topic_explanation',topic:'P1-ALG-01',locale:'ru',featureId:'math-topic',userKind:'synthetic',cohort:'fake-cohort',...changes});
const setup=(props={},rows=[row()])=>{const reg=new PreviewFeatureRegistry(props);for(let r of rows)reg.register(r);return reg;};
test('No feature is enabled merely because source exists',()=>{const r=setup();assert.equal(r.evaluate(query()).reason,'feature_disabled');});
test('Full gates allow automatic enablement in synthetic Preview',()=>{const r=setup();assert.equal(r.enableAfterGates(key(row())).allowed,true);assert.equal(r.evaluate(query()).allowed,true);});
test('A failing gate prevents enabling that topic and its locale',()=>{
 for(const g of gates) {const r=setup({},[row({gates:{...GREEN,[g]:false}})]);assert.equal(r.enableAfterGates(key(row())).reason,'qa_not_green',g);}
});
test('Language readiness is independent for RU / UZ / EN',()=>{
 const r=setup({},[row(),row({locale:'uz',sourceId:'uz-source',gates:{...GREEN,correctnessPassed:false}})]);
 r.enableAfterGates(key(row()));assert.equal(r.evaluate(query()).allowed,true);
 assert.equal(r.evaluate(query({locale:'uz'})).reason,'qa_not_green');
 assert.equal(r.evaluate(query({locale:'en'})).reason,'in_development');
});
test('Another subject is not accidentally authorised',()=>{
 const r=setup();r.enableAfterGates(key(row()));
 assert.equal(r.evaluate(query({subject:'economics'})).reason,'in_development');
});
test('Contradictory sources always stop disputed topic',()=>{
 const r=setup({},[row({sourceConflict:true})]);
 assert.equal(r.enableAfterGates(key(row())).reason,'source_conflict');
});
test('Feature is disabled without disabling unrelated working feature',()=>{
 const r=setup({},[row(),row({topic:'P5-PROB-01',featureId:'math-p5',sourceId:'qa-p5'})]);
 r.enableAfterGates(key(row()));r.enableAfterGates(key(row({topic:'P5-PROB-01'})));
 r.emergencyStopFeature('math-topic');
 assert.equal(r.evaluate(query()).reason,'feature_disabled');
 assert.equal(r.evaluate(query({topic:'P5-PROB-01',featureId:'math-p5'})).allowed,true);
});
test('Global emergency stop blocks every new AI capability',()=>{
 const r=setup();r.enableAfterGates(key(row()));r.emergencyStopAll();
 assert.equal(r.evaluate(query()).reason,'emergency_off');
});
test('Preview refuses real users even when technically ready',()=>{
 const r=setup();r.enableAfterGates(key(row()));
 assert.equal(r.evaluate(query({userKind:'authorized_beta'})).reason,'preview_requires_synthetic');
});
test('Beta cohort not approved cannot enable any new AI feature',()=>{
 const r=setup({mode:'beta',ownerApprovedBeta:false,authorizedCohorts:['cohort-1']});
 assert.equal(r.enableAfterGates(key(row())).reason,'beta_not_approved');
});
test('Approved beta release is restricted to precisely authorized cohort',()=>{
 const r=setup({mode:'beta',ownerApprovedBeta:true,authorizedCohorts:['cohort-1']});
 r.enableAfterGates(key(row()));
 assert.equal(r.evaluate(query({cohort:'unknown',userKind:'authorized_beta'})).reason,'cohort_not_authorized');
 assert.equal(r.evaluate(query({cohort:'cohort-1',userKind:'authorized_beta'})).allowed,true);
});
test('Duplicate identities and incomplete governance rows are rejected',()=>{
 const r=setup();assert.throws(()=>r.register(row()),/duplicate/);
 assert.throws(()=>r.register(row({sourceId:''})),/incomplete/);
});
