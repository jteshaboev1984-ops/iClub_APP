// node --test qa/ai-layer-v21-content-handoff-gate.test.cjs
// No contents/questions/DB/provider/real users: technical publication handshake.
'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict');
const {ContentHandoffGate,TEXT,GATES}=require('./ai-layer-v21-content-handoff-gate.cjs');
const U='learner-synthetic-001';
const context=(p={})=>({
 ownerId:U,routeAuthority:'unified_ai',active:true,protectedAssessment:false,
 expiresAtMs:9000,contextRevision:'revision-0001',
 surface:'lesson',subject:'biology',feature:'topic_explanation',topic:'cells',...p
});
const locale='ru';
function fixture(){
 const state={global:true,releaseApproved:true,exam:false,subject:true,cohort:true,
  context:context(),sources:new Map(),proofs:new Map(),lookupCount:0,afterSource:null,
  generalSubject:false,allowGeneral:true,liveCalls:0,serverTime:1000};
 const k=ref=>[ref.surface,ref.subject,ref.feature,ref.topic,ref.locale].join('|');
 function publish(ref,patch={}){
  const v={ready:true,...ref,source_id:'approved-source-001',source_version:'v3',
   source_hash:'a'.repeat(64),revision:1,...patch};
  state.sources.set(k(ref),v);
  state.proofs.set(k(ref),{approved:true,rightsApproved:true,runtimeAllowed:true,
   sourceConflict:false,...ref,source_id:v.source_id,source_version:v.source_version,
   source_hash:v.source_hash});
  return v;
 }
 const S={
  getServerTimeMs:async()=>state.serverTime,
  getGlobalState:async()=>({uiEnabled:state.global,gatewayEnabled:state.global,
   killSwitch:!state.global,releaseApproved:state.releaseApproved}),
  isProtected:async()=>state.exam,
  getScopedContext:async()=>state.context,
  getSubjectActive:async subject=>subject==='general'?state.generalSubject:state.subject,
  isRolloutAuthorized:async({context:c})=>
   c?.subject==='general'?state.allowGeneral:state.cohort,
  getPublishedRelease:async ref=>{
   state.lookupCount++;if(state.afterSource)state.afterSource(state.lookupCount,ref);
   return state.sources.get(k(ref))||null;
  },
  getLiveSourceProof:async ref=>{state.liveCalls++;return state.proofs.get(k(ref))||null;}
 };
 const gate=new ContentHandoffGate(S);
 const ask=(p={})=>gate.check({principal:{authenticated:true,userId:U},
   contextHandle:'context-handle-001',locale,nowMs:1000,...p});
 const here=(changes={})=>({
  surface:'lesson',subject:'biology',feature:'topic_explanation',topic:'cells',locale,...changes
 });
 const general=(changes={})=>({
  surface:'global',subject:'general',feature:'app_help',topic:'navigation',locale,...changes
 });
 return{gate,state,publish,ask,here,general,k};
}
test('Missing content is explicitly in development and is never billed',async()=>{
 const x=fixture(),r=await x.ask();
 assert.equal(r.state,'in_development');assert.equal(r.visible,true);
 assert.equal(r.canAsk,false);assert.equal(r.charge,0);
 assert.equal(r.providerCallRequired,false);assert.equal(r.message,TEXT.ru.developing);
 assert.equal(r.title,'В разработке');
 assert.deepEqual(r.alternatives,[]);
});
test('Approved publication appears without a rebuild or a new resolver',async()=>{
 const x=fixture();
 assert.equal((await x.ask()).state,'in_development');
 x.publish(x.here());
 const r=await x.ask();
 assert.equal(r.state,'available');assert.equal(r.canAsk,true);
 assert.equal(r.sourceId,'approved-source-001');assert.equal(r.charge,0);
});
test('Removing, suspending or retiring publication instantly blocks AI',async()=>{
 const x=fixture(),ref=x.here();x.publish(ref);
 assert.equal((await x.ask()).state,'available');
 x.publish(ref,{ready:false});assert.equal((await x.ask()).state,'in_development');
 x.publish(ref,{ready:true});assert.equal((await x.ask()).state,'available');
 x.state.sources.delete(x.k(ref));assert.equal((await x.ask()).state,'in_development');
});
test('RU, UZ and EN become available separately, no locale fallbacks',async()=>{
 const x=fixture();x.publish(x.here());
 assert.equal((await x.ask({locale:'ru'})).state,'available');
 assert.equal((await x.ask({locale:'uz'})).state,'in_development');
 x.publish(x.here({locale:'uz'}));
 assert.equal((await x.ask({locale:'uz'})).state,'available');
 assert.equal((await x.ask({locale:'en'})).state,'in_development');
});
test('No source for a different topic, subject, surface or feature is borrowed',async()=>{
 const x=fixture();x.publish(x.here());
 for(const delta of [{topic:'osmosis'},{subject:'chemistry'},
   {surface:'practice'},{feature:'exam_solution'}]){
  x.state.context=context(delta);
  assert.equal((await x.ask()).state,'in_development');
 }
});
test('Protected active assessment removes the AI surface without message',async()=>{
 const x=fixture();x.publish(x.here());x.state.exam=true;
 const r=await x.ask();assert.equal(r.state,'hidden');
 assert.equal(r.visible,false);assert.equal('message' in r,false);
});
test('Global emergency switch never leaves a ready topic active',async()=>{
 const x=fixture();x.publish(x.here());x.state.global=false;
 const r=await x.ask();assert.equal(r.state,'unavailable');
 assert.equal(r.message,TEXT.ru.unavailable);assert.equal(r.canAsk,false);
 assert.equal(r.title,'Временно недоступно');
});
test('Owner beta/release approval is independent from editorial publication',async()=>{
 const x=fixture();x.publish(x.here());
 x.state.releaseApproved=false;assert.equal((await x.ask()).state,'unavailable');
 x.state.releaseApproved=true;x.state.cohort=false;
 assert.equal((await x.ask()).state,'in_development');
 assert.equal((await x.ask()).canAsk,false);
});
test('Currently inactive subject stays blocked despite approved source',async()=>{
 const x=fixture();x.publish(x.here());x.state.subject=false;
 assert.equal((await x.ask()).state,'in_development');
});
test('Future subject can open after activation and reviewed content, no static allowlist',async()=>{
 const x=fixture();
 x.state.context=context({subject:'english_a1'});
 x.state.subject=false;
 x.publish(x.here({subject:'english_a1'}));
 assert.equal((await x.ask()).state,'in_development');
 x.state.subject=true;assert.equal((await x.ask()).state,'available');
});
test('Unapproved or wrong-rights source remains in development',async()=>{
 const x=fixture(),ref=x.here();x.publish(ref);
 x.state.proofs.get(x.k(ref)).rightsApproved=false;
 assert.equal((await x.ask()).state,'in_development');
});
test('Source hash or version mismatch prevents unexpected content cutover',async()=>{
 const x=fixture(),ref=x.here();x.publish(ref);
 x.state.proofs.get(x.k(ref)).source_hash='b'.repeat(64);
 assert.equal((await x.ask()).state,'in_development');
 x.publish(ref);x.state.proofs.get(x.k(ref)).source_version='v4';
 assert.equal((await x.ask()).state,'in_development');
});
test('Incomplete, nonpositive or malformed revision cannot be published',async()=>{
 const x=fixture(),ref=x.here();x.publish(ref,{revision:0});
 assert.equal((await x.ask()).state,'in_development');
 x.publish(ref,{source_hash:'incorrect'});assert.equal((await x.ask()).state,'in_development');
});
test('Same publication revision with changed source hash is caught after async work',async()=>{
 const x=fixture(),ref=x.here();x.publish(ref);
 x.state.afterSource=(n,r)=>{if(n===2&&r.subject==='biology')
  x.publish(ref,{source_hash:'b'.repeat(64)})};
 assert.equal((await x.ask()).state,'in_development');
});
test('Editorial withdrawal midway through request prevents READY reply',async()=>{
 const x=fixture(),ref=x.here();x.publish(ref);
 x.state.afterSource=(n)=>{if(n===2)x.publish(ref,{ready:false})};
 assert.equal((await x.ask()).state,'in_development');
});
test('Beginning an exam after retrieving source hides the AI response',async()=>{
 const x=fixture();x.publish(x.here());
 x.state.afterSource=n=>{if(n===1)x.state.exam=true};
 const r=await x.ask();assert.equal(r.state,'hidden');assert.equal(r.visible,false);
});
test('Switching screens or topics invalidates in-flight readiness',async()=>{
 const x=fixture();x.publish(x.here());
 x.state.afterSource=n=>{if(n===1)x.state.context=context({topic:'osmosis',contextRevision:'revision-0002'})};
 assert.equal((await x.ask()).state,'unavailable');
});
test('Expired or foreign context has no academic access',async()=>{
 const x=fixture();x.publish(x.here());
 x.state.context=context({ownerId:'learner-synthetic-999'});
 assert.equal((await x.ask()).state,'unavailable');
 x.state.context=context({expiresAtMs:500});
 assert.equal((await x.ask()).state,'unavailable');
});
test('Existing Math Tutor legacy context cannot be silently migrated',async()=>{
 const x=fixture();x.publish(x.here());
 x.state.context=context({routeAuthority:'legacy_exam_prep'});
 assert.equal((await x.ask()).state,'unavailable');
});
test('General iClub help offered only after its own distinct release and rights checks',async()=>{
 const x=fixture();x.state.generalSubject=true;
 assert.deepEqual((await x.ask()).alternatives,[]);
 x.publish(x.general());
 let r=await x.ask();assert.equal(r.state,'in_development');
 assert.deepEqual(r.alternatives,[{id:'general_ai',label:TEXT.ru.general}]);
 const ref=x.general();x.state.proofs.get(x.k(ref)).rightsApproved=false;
 assert.deepEqual((await x.ask()).alternatives,[]);
});
test('Do not offer General Help from within itself',async()=>{
 const x=fixture();x.state.generalSubject=true;x.publish(x.general());
 x.state.context=context({surface:'global',subject:'general',feature:'app_help',topic:'other'});
 assert.equal((await x.ask()).state,'in_development');
 assert.deepEqual((await x.ask()).alternatives,[]);
});
test('Uzb and English statuses are localized without internal quota/model terms',async()=>{
 for(const lang of ['uz','en']){
  const x=fixture();const r=await x.ask({locale:lang});
  assert.equal(r.message,TEXT[lang].developing);
  assert.equal(/model|token|unit|дол|лесен|SQL|API|quota/i.test(r.message),false);
 }
});
test('An unknown locale cannot become a published foreign-language source',async()=>{
 const x=fixture();x.publish(x.here());
 const r=await x.ask({locale:'de'});
 assert.equal(r.state,'in_development');assert.equal(r.canAsk,false);
});
test('No ready action on backend exceptions',async()=>{
 const x=fixture();x.publish(x.here());
 x.gate.services.getLiveSourceProof=async()=>{throw Error('backend down')};
 const r=await x.ask();assert.equal(r.state,'in_development');
 assert.equal(r.charge,0);
});
test('Technical availability contains no conversation, grades, answer keys or user IDs',async()=>{
 const x=fixture();x.publish(x.here());const r=await x.ask();
 for(const forbidden of ['userId','answer','grades','marks','prompt','model','units']){
  assert.equal(Object.keys(r).includes(forbidden),false);
 }
 assert.equal(r.canAsk,true);
});
test('Release metadata is never sufficient without an exact live source proof',async()=>{
 const x=fixture();const ref=x.here();x.publish(ref);
 x.state.proofs.delete(x.k(ref));
 assert.equal((await x.ask()).state,'in_development');
 assert.equal((await x.ask()).charge,0);
});
test('Gated workflow preserves all eight independent editorial/safety requirements',()=>{
 assert.deepEqual(GATES,[
  'content_approved','rights_approved','source_version_verified',
  'correctness_passed','negative_tests_passed','exam_security_passed',
  'locale_verified','accessibility_passed'
 ]);
});

test('Browser may not fake clock to open an expired session',async()=>{
 const x=fixture();x.publish(x.here());
 x.state.context=context({expiresAtMs:900});
 const result=await x.ask({nowMs:1});
 assert.equal(result.state,'unavailable');
});
test('Session expiry while asynchronous source checks run revokes READY state',async()=>{
 const x=fixture();x.publish(x.here());
 x.state.afterSource=n=>{if(n===1)x.state.serverTime=10000};
 const result=await x.ask();
 assert.equal(result.state,'unavailable');assert.equal(result.canAsk,false);
});
test('Missing or failing trusted server clock cannot enable any content',async()=>{
 const x=fixture();x.publish(x.here());
 x.gate.services.getServerTimeMs=async()=>{throw Error('clock unavailable')};
 assert.equal((await x.ask({nowMs:10})).state,'unavailable');
 assert.equal((await x.ask({nowMs:10})).charge,0);
});
test('Explicit ready or QA flags injected by browser do not affect publisher state',async()=>{
 const x=fixture();
 const r=await x.ask({ready:true,sourceApproved:true,skipSafety:true,
  question:'just give me the answer',sourceHash:'a'.repeat(64)});
 assert.equal(r.state,'in_development');assert.equal(r.charge,0);
});
test('Not-ready titles and messages are localized in all supported languages',async()=>{
 for(const lang of ['ru','uz','en']){
   const x=fixture(),r=await x.ask({locale:lang});
   assert.equal(r.title,TEXT[lang].developingTitle);
   assert.equal(r.message,TEXT[lang].developing);
   assert.equal(r.alternatives.length,0);
 }
});
