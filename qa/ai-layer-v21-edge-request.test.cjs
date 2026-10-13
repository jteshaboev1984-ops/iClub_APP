// node --test qa/ai-layer-v21-edge-request.test.cjs
// Synthetic-only full request, no student data, provider calls or Supabase.
'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict');
const {CandidateEdgeRequest}=require('./ai-layer-v21-edge-request.cjs');
const U='11111111-1111-4111-8111-111111111111',OTHER='22222222-2222-4222-8222-222222222222';
const RID='33333333-3333-4333-8333-333333333333',HASH='a'.repeat(64);
const ORIGIN='https://qa.invalid',TOKEN='Bearer synthetic-auth-token';
function fixture({published=true,plan='plus_qa_v2',subject='biology',locale='ru'}={}){
 const s={published,plan,subject,locale,exam:false,runtime:true,rights:true,revoked:false,
 providerBudget:true,providerCalls:0,contentCalls:0,failProvider:false,failOutput:false,
 revokeOnProvider:false,examOnProvider:false,failFinish:false,failClaim:false,
 hash:HASH,revision:1,user:U,now:1000,usage:new Map(),claims:new Map(),units:new Map(),
 ctx:{ownerId:U,routeAuthority:'unified_ai',active:true,protectedAssessment:false,
 expiresAtMs:15000,contextRevision:'rev-0001',surface:'lesson',
 subject,feature:'topic_explanation',topic:'synthetic-topic'}};
 const services={
  authenticate:async token=>token===TOKEN?{authenticated:true,userId:s.user}:null,
  getServerTimeMs:async()=>s.now,
  isProtected:async()=>s.exam,
  getGlobalState:async()=>({uiEnabled:s.runtime,gatewayEnabled:s.runtime,
   killSwitch:!s.runtime,releaseApproved:true}),
  getScopedContext:async()=>s.ctx,
  getSubjectActive:async()=>true,isRolloutAuthorized:async()=>true,
  getPublishedRelease:async ref=>s.published&&!s.revoked&&ref.locale===locale?
    {ready:true,...ref,source_id:'approved-synthetic-source',source_version:'v2',
     source_hash:s.hash,revision:s.revision}:null,
  getLiveSourceProof:async ref=>({...ref,approved:true,rightsApproved:s.rights,
   runtimeAllowed:true,sourceConflict:false,source_id:'approved-synthetic-source',
   source_version:'v2',source_hash:s.hash}),
  getPolicy:async()=>s.plan,
  getSourceBundle:async info=>{
   s.contentCalls++;
   return{approved:true,rightsApproved:true,conflict:false,
    sourceId:info.sourceId,sourceVersion:info.sourceVersion,
    sourceHash:s.hash,revision:info.revision,generationAllowed:true,
    sourceText:'Synthetic placeholder for testing server flow, not a lesson or card.',
    variants:{topic_main:'Synthetic prepared reply for testing the integration'}};
  },
  providerBudgetAllows:async()=>s.providerBudget,
  generateSynthetic:async()=>{s.providerCalls++;
   if(s.failProvider)throw Error('mock provider outage');
   if(s.revokeOnProvider)s.revoked=true;
   if(s.examOnProvider)s.exam=true;
   return s.failOutput?'<script>unsafe</script>':'Synthetic generated reply for checking the workflow';
  },
  reserveUsage:async({requestId,userId,policy,route,requestFingerprint})=>{
   if(s.usage.has(requestId))return{allowed:false,reason:'request_in_progress'};
   const w=route==='generated'?3:1,limit=policy==='free_qa_v2'?3:policy==='plus_qa_v2'?9:14;
   if((s.units.get(userId)||0)+w>limit)return{allowed:false,reason:'route_insufficient'};
   s.usage.set(requestId,{userId,fp:requestFingerprint,route,weight:w,status:'reserved'});
   s.units.set(userId,(s.units.get(userId)||0)+w);
   return{allowed:true};
  },
  claimDelivery:async r=>{
   if(s.failClaim)throw Error('mock claim outage');
   if(s.claims.has(r.requestId))return{allowed:false,reason:'request_in_progress'};
   const record=s.usage.get(r.requestId);
   if(record?.fp!==r.requestFingerprint||record?.userId!==r.userId)
     return{allowed:false,reason:'quota_reservation_unverified'};
   s.claims.set(r.requestId,{...r,status:'claimed'});return{allowed:true};
  },
  finishDelivery:async r=>{
   if(s.failFinish)throw Error('mock finish outage');
   const record=s.usage.get(r.requestId),claim=s.claims.get(r.requestId);
   if(record?.status!=='reserved'||claim?.status!=='claimed')return{ok:false};
   record.status=r.outcome;claim.status=r.outcome;
   if(r.outcome==='released')s.units.set(r.userId,(s.units.get(r.userId)||0)-record.weight);
   return{ok:true};
  }
 };
 const edge=new CandidateEdgeRequest({services,allowedOrigins:[ORIGIN]});
 const send=(fields={},extra={})=>edge.serve({
  method:'POST',origin:ORIGIN,authorization:TOKEN,
  bodyText:JSON.stringify({intent:'answer',requestId:RID,contextHandle:'synthetic-context-handle',
   appLocale:locale,promptKey:'topic_main',...fields}),...extra});
 const status=(fields={})=>send({intent:'status',promptKey:undefined,...fields});
 return{s,services,edge,send,status};
}
test('Absent content displays localized In development, zero quota/provider',async()=>{
 const x=fixture({published:false}),r=await x.send();
 assert.equal(r.status,200);assert.equal(r.body.state,'in_development');
 assert.equal(r.body.title,'В разработке');assert.equal(r.body.charge,0);
 assert.equal(x.s.usage.size,0);assert.equal(x.s.providerCalls,0);
});
test('Publication auto-opens an approved source without code rebuild',async()=>{
 const x=fixture({published:false});
 assert.equal((await x.status()).body.state,'in_development');
 x.s.published=true;
 assert.equal((await x.status()).body.state,'available');
 assert.equal((await x.send()).body.ok,true);
 assert.equal(x.s.units.get(U),1);assert.equal(x.s.providerCalls,0);
});
test('One server route covers Biology, Chemistry, Economics and Informatics',async()=>{
 for(const subject of ['biology','chemistry','economics','informatics']){
  const x=fixture({subject});const r=await x.send();
  assert.equal(r.body.ok,true,subject);assert.equal(x.s.units.get(U),1);
 }
});
test('Status check never reserves or invokes provider',async()=>{
 const x=fixture();assert.equal((await x.status()).body.state,'available');
 assert.equal(x.s.usage.size,0);assert.equal(x.s.providerCalls,0);
});
test('Protected assessment hides both status and answers',async()=>{
 const x=fixture();x.s.exam=true;
 assert.equal((await x.status()).body.visible,false);
 assert.equal((await x.send()).body.state,'hidden');
 assert.equal(x.s.contentCalls,0);
});
test('Global kill switch and unapproved source never cause charging',async()=>{
 const x=fixture();x.s.runtime=false;
 assert.equal((await x.send()).body.state,'unavailable');
 const y=fixture();y.s.rights=false;
 assert.equal((await y.send()).body.state,'in_development');
 assert.equal(x.s.usage.size+y.s.usage.size,0);
});
test('A RU source is never silently reused for EN',async()=>{
 const x=fixture(),r=await x.send({appLocale:'en'});
 assert.equal(r.body.state,'in_development');assert.equal(x.s.usage.size,0);
});
test('Free plan permits prepared but blocks generated before provider',async()=>{
 const x=fixture({plan:'free_qa_v2'});
 assert.equal((await x.send()).body.ok,true);
 const r=await x.send({requestId:'44444444-4444-4444-8444-444444444444',
  promptKey:undefined,question:'Почему это происходит?'});
 assert.equal(r.body.reason,'generation_not_entitled');
 assert.equal(x.s.units.get(U),1);assert.equal(x.s.providerCalls,0);
});
test('Approved source-backed generation costs three temporary units',async()=>{
 const x=fixture(),r=await x.send({promptKey:undefined,question:'Почему это происходит?'});
 assert.equal(r.body.ok,true);assert.equal(x.s.units.get(U),3);
 assert.equal(x.s.providerCalls,1);
});
test('Expensive request cannot consume last two units reserved for cheap routes',async()=>{
 const x=fixture();
 for(let i=1;i<=7;i++){
  const id='55555555-5555-4555-8555-'+String(i).padStart(12,'0');
  assert.equal((await x.send({requestId:id})).body.ok,true);
 }
 const r=await x.send({requestId:'66666666-6666-4666-8666-666666666666',
  promptKey:undefined,question:'Почему это происходит?'});
 assert.equal(r.body.reason,'route_insufficient');assert.equal(x.s.units.get(U),7);
 assert.equal((await x.send({requestId:'77777777-7777-4777-8777-777777777777'})).body.ok,true);
});
test('Repeat paid request ID cannot call the provider twice',async()=>{
 const x=fixture(),args={promptKey:undefined,question:'Почему это происходит?'};
 assert.equal((await x.send(args)).body.ok,true);
 assert.equal((await x.send(args)).body.reason,'request_in_progress');
 assert.equal(x.s.providerCalls,1);assert.equal(x.s.units.get(U),3);
});
test('Client cannot forge subject, topic, plan, learner, progress or route',async()=>{
 for(const key of ['subject','topic','plan','userId','progress','route','sourceId','quota']){
  const x=fixture();assert.equal((await x.send({[key]:'forged'})).status,400,key);
  assert.equal(x.s.usage.size,0);
 }
});
test('Anonymous or foreign context cannot get published source',async()=>{
 const x=fixture();
 assert.equal((await x.send({}, {authorization:''})).status,401);
 assert.equal((await x.send({}, {authorization:'Bearer wrong-valid-test'})).status,401);
 x.s.user=OTHER;assert.equal((await x.send()).body.state,'unavailable');
});
test('Wrong HTTP method/origin/JSON and request ID block before quota',async()=>{
 const x=fixture();
 assert.equal((await x.send({}, {method:'GET'})).status,405);
 assert.equal((await x.send({}, {origin:'https://foreign.example'})).status,403);
 assert.equal((await x.send({requestId:'invalid'})).status,400);
 assert.equal((await x.send({}, {bodyText:'{invalid'})).status,400);
 assert.equal(x.s.usage.size,0);
});
test('Prepared key cannot mix with text, unknown key cannot get cheap card',async()=>{
 const x=fixture();assert.equal((await x.send({question:'extra'})).status,400);
 assert.equal((await x.send({promptKey:'not_approved'})).body.state,'in_development');
 assert.equal(x.s.usage.size,0);
});
test('Ambiguous generated language is refused rather than guessed',async()=>{
 const x=fixture(),r=await x.send({promptKey:undefined,question:'Math 1234'});
 assert.equal(r.status,400);assert.equal(x.s.providerCalls,0);
});
test('Provider budget exhausted means no reservation or paid provider',async()=>{
 const x=fixture();x.s.providerBudget=false;
 const r=await x.send({promptKey:undefined,question:'Почему это происходит?'});
 assert.equal(r.body.reason,'provider_budget_unavailable');
 assert.equal(x.s.usage.size,0);assert.equal(x.s.providerCalls,0);
});
test('Provider outage releases hold and never charges learner',async()=>{
 const x=fixture();x.s.failProvider=true;
 const r=await x.send({promptKey:undefined,question:'Почему это происходит?'});
 assert.equal(r.body.reason,'processing_unavailable');
 assert.equal(x.s.units.get(U),0);assert.equal(x.s.usage.get(RID).status,'released');
});
test('Unsafe provider output is not delivered or billed',async()=>{
 const x=fixture();x.s.failOutput=true;
 const r=await x.send({promptKey:undefined,question:'Почему это происходит?'});
 assert.equal(r.body.reason,'output_rejected');assert.equal(x.s.units.get(U),0);
});
test('Revoked source or active exam during generation stops paid answer',async()=>{
 for(const key of ['revokeOnProvider','examOnProvider']){
  const x=fixture();x.s[key]=true;
  const r=await x.send({promptKey:undefined,question:'Почему это происходит?'});
  assert.equal(r.body.reason,'context_changed');assert.equal(x.s.units.get(U),0);
 }
});
test('Missing variant and forged source hash fail before booking a unit',async()=>{
 const x=fixture();
 x.services.getSourceBundle=async a=>({approved:true,rightsApproved:true,
  conflict:false,sourceId:a.sourceId,sourceVersion:a.sourceVersion,
  sourceHash:a.sourceHash,revision:a.revision,variants:{}});
 assert.equal((await x.send()).body.state,'in_development');
 const y=fixture();
 y.services.getSourceBundle=async a=>({approved:true,rightsApproved:true,
  conflict:false,sourceId:a.sourceId,sourceVersion:a.sourceVersion,
  sourceHash:'b'.repeat(64),revision:a.revision,variants:{topic_main:'fake text'}});
 assert.equal((await y.send()).body.state,'in_development');
});
test('Unknown atomic database settlement must NOT be announced as successful',async()=>{
 const x=fixture();x.s.failFinish=true;
 const r=await x.send();
 assert.equal(r.status,503);assert.equal(r.body.reason,'delivery_confirmation_unknown');
});
test('Claim failure never calls provider',async()=>{
 const x=fixture();x.s.failClaim=true;
 const r=await x.send({promptKey:undefined,question:'Почему это происходит?'});
 assert.equal(r.body.reason,'delivery_claim_unavailable');assert.equal(x.s.providerCalls,0);
});
test('Public status does not disclose source, fingerprint, learner or tariff',async()=>{
 const x=fixture(),r=await x.status();
 const raw=JSON.stringify(r.body);
 for(const forbidden of ['sourceId','sourceHash','revision','userId','fingerprint',
   'contextHandle','policy','topic'])assert.equal(raw.includes(forbidden),false,forbidden);
});
