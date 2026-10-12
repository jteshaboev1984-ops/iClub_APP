// node --test qa/ai-layer-v21-synthetic-pipeline.test.cjs
'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {SyntheticAIPipeline}=require('./ai-layer-v21-synthetic-pipeline.cjs');
const {PreviewFeatureRegistry,key,gates}=require('./ai-layer-v21-readiness-registry.cjs');
const pass=Object.fromEntries(gates.map(g=>[g,true]));
const math={surface:'exam_prep',subject:'mathematics',feature:'theory',topic:'P1-ALG-01',locale:'ru',featureId:'math-topic',sourceId:'math-QA',sourceVersion:'test-v1',gates:{...pass}};
const econ={surface:'lesson',subject:'economics',feature:'theory',topic:'ECO-01',locale:'ru',featureId:'econ-topic',sourceId:'econ-QA',sourceVersion:'test-v1',gates:{...pass}};
const src=x=>({surface:x.surface,subject:x.subject,feature:x.feature,topic:x.topic,locale:x.locale,sourceId:x.sourceId,version:x.sourceVersion,
 approved:true,rightsApproved:true,readinessPassed:true,generationAllowed:true,
 variants:{topic_main:'Синтетическое готовое объяснение'},aliases:{'объясни тему':'topic_main'},
 syntheticGeneratedReply:'Искусственная генерация без настоящего провайдера'});
function setUp({beta=false,ownerApprovedBeta=false,releaseMath=true,releaseEcon=true,mathBlocked=false,econBlocked=false,budgetOpen=true}={}) {
 const reg=new PreviewFeatureRegistry({mode:beta?'beta':'preview',ownerApprovedBeta,authorizedCohorts:['approved-three']});
 const rows=[{...math,gates:{...pass}},{...econ,gates:{...pass}}];
 for(const row of rows)reg.register(row);
 if(releaseMath)assert.equal(reg.enableAfterGates(key(math)).allowed,true);
 if(releaseEcon)assert.equal(reg.enableAfterGates(key(econ)).allowed,true);
 if(mathBlocked)reg.emergencyStopFeature('math-topic');
 if(econBlocked)reg.emergencyStopFeature('econ-topic');
 const contexts=new Map([
 ['math-handle-001',{id:'math-ctx',ownerId:'synthetic-learner',activeForUser:true,expiresAt:100000,
  surface:math.surface,subject:math.subject,feature:math.feature,topic:math.topic,protectedAssessment:false}],
 ['econ-handle-001',{id:'econ-ctx',ownerId:'synthetic-learner',activeForUser:true,expiresAt:100000,
  surface:econ.surface,subject:econ.subject,feature:econ.feature,topic:econ.topic,protectedAssessment:false}]
 ]);
 const services={
   runtime:{killSwitch:false,gatewayEnabled:true},
   getContext:(handle,id)=>contexts.get(handle),
   getUserEntitlement:(id,subject,feature)=>id==='synthetic-learner'&&['mathematics','economics'].includes(subject),
   getRelease:({surface,subject,feature,topic,locale})=>{
     const row=rows.find(x=>x.surface===surface&&x.subject===subject&&x.feature===feature&&x.topic===topic&&x.locale===locale);
     return row?{approved:true,qaPassed:true,sourceId:row.sourceId,sourceVersion:row.sourceVersion,locale,promptKeys:['topic_main'],conflicting:false}:null;
   },
   getFeatureId:(surface,subject)=>subject==='mathematics'?'math-topic':subject==='economics'?'econ-topic':'unknown',
   getLearnerCohort:()=>'approved-three',
   getLearnerKind:()=>beta?'authorized_beta':'synthetic',
   getLearnerPlan:()=> 'plus',
   providerBudgetAllows:()=>budgetOpen
 };
 const p=new SyntheticAIPipeline({services,registry:reg,sources:rows.map(src)});
 const principal={authenticated:true,userId:'synthetic-learner'};
 let i=0;
 const ask=(handle,opts={})=>p.submit({requestId:'request-'+(++i),principal,handle,question:'',promptKey:'topic_main',nowMs:100,...opts});
 return {p,reg,services,contexts,principal,ask};
}
test('All subjects share exactly one global mixed quota',()=>{
 const x=setUp();
 for(let i=0;i<7;i++)assert.equal(x.ask('math-handle-001').ok,true);
 assert.equal(x.p.gateway.ledger.inspect('synthetic-learner','plus',100).remaining,2);
 assert.equal(x.ask('econ-handle-001',{question:'Приведи нестандартный пример',promptKey:''}).reason,'route_insufficient');
 assert.equal(x.p.gateway.modelCallAttempts,0);
 assert.equal(x.ask('econ-handle-001').ok,true);
 assert.equal(x.ask('math-handle-001').ok,true);
 assert.equal(x.p.gateway.ledger.inspect('synthetic-learner','plus',100).remaining,0);
});
test('A ready Math source never accidentally authorizes Economics',()=>{
 const x=setUp({releaseEcon:false});
 assert.equal(x.ask('math-handle-001').ok,true);
 assert.equal(x.ask('econ-handle-001').reason,'feature_disabled');
});
test('A live emergency kill switch can block Economics alone',()=>{
 const x=setUp({econBlocked:true});
 assert.equal(x.ask('econ-handle-001').reason,'feature_disabled');
 assert.equal(x.ask('math-handle-001').ok,true);
});
test('A global emergency kill switch stops both routes',()=>{
 const x=setUp();x.reg.emergencyStopAll();
 assert.equal(x.ask('math-handle-001').reason,'emergency_off');
 assert.equal(x.ask('econ-handle-001').reason,'emergency_off');
});
test('Client guesses for subject or topic are ignored; server resolves handle',()=>{
 const x=setUp();
 const r=x.ask('econ-handle-001',{subject:'mathematics',topic:'P1-ALG-01'});
 assert.equal(r.ok,true);
 assert.equal(x.p.gateway.ledger.inspect('synthetic-learner','plus',100).committed,1);
});
test('Altered context owner cannot read or write usage',()=>{
 const x=setUp();
 x.contexts.set('econ-handle-001',{...x.contexts.get('econ-handle-001'),ownerId:'another-user'});
 assert.equal(x.ask('econ-handle-001').reason,'context_not_authorized');
 assert.equal(x.p.gateway.ledger.inspect('synthetic-learner','plus',100).committed,0);
});
test('Protected exam interrupts the route before metering',()=>{
 const x=setUp();
 x.contexts.set('math-handle-001',{...x.contexts.get('math-handle-001'),protectedAssessment:true});
 assert.equal(x.ask('math-handle-001').reason,'protected_assessment');
 assert.equal(x.p.gateway.ledger.inspect('synthetic-learner','plus',100).committed,0);
});
test('Provider failures after successful admission release quota',()=>{
 const x=setUp();const r=x.ask('math-handle-001',{question:'Приведи нестандартный пример',promptKey:'',provider:'timeout'});
 assert.equal(r.reason,'provider_timeout');
 assert.equal(x.p.gateway.ledger.inspect('synthetic-learner','plus',100).remaining,9);
});
test('Blocked backend spend gate cannot be bypassed with a client claim',()=>{
 const x=setUp({budgetOpen:false});
 const q=x.ask('math-handle-001',{question:'Приведи нестандартный пример',promptKey:'',budgetAllowed:true});
 assert.equal(q.reason,'provider_budget_unavailable');
 assert.equal(x.p.gateway.modelCallAttempts,0);
 assert.equal(x.p.gateway.ledger.inspect('synthetic-learner','plus',100).committed,0);
 assert.equal(x.ask('math-handle-001').ok,true);
});
test('RU question cannot silently use only EN sources',()=>{
 const x=setUp();const r=x.ask('math-handle-001',{question:'Почему это верно?',promptKey:'',appLocale:'en'});
 assert.equal(r.ok,true);
 assert.equal(x.p.gateway.modelCallAttempts,1);
});
test('No beta use before explicit release authorization',()=>{
 const x=setUp({beta:true,ownerApprovedBeta:false,releaseMath:false,releaseEcon:false});
 assert.equal(x.ask('math-handle-001').reason,'cohort_not_authorized');
});
test('Approved beta cohort is still blocked for unapproved topic',()=>{
 const x=setUp({beta:true,ownerApprovedBeta:true,releaseEcon:false});
 assert.equal(x.ask('math-handle-001').ok,true);
 assert.equal(x.ask('econ-handle-001').reason,'feature_disabled');
});
test('Return shape never leaks hidden usage units, source ids or tariffs',()=>{
 const x=setUp();
 const r=x.ask('math-handle-001');assert.deepEqual(Object.keys(r).sort(),['ok','reply','duplicate'].sort());
 assert.ok(!JSON.stringify(r).includes('sourceId'));
});
