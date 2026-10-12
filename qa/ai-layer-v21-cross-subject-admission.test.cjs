// node --test qa/ai-layer-v21-cross-subject-admission.test.cjs
// Uses MOCK data only. Never a live feature release.
'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {CrossSubjectAdmission}=require('./ai-layer-v21-cross-subject-admission.cjs');
const {MockServerContextResolver}=require('./ai-layer-v21-server-context-existing-db.cjs');
const {PreviewFeatureRegistry,key,gates}=require('./ai-layer-v21-readiness-registry.cjs');
const U='11111111-1111-4111-8111-111111111111',OTHER='22222222-2222-4222-8222-222222222222';
const finish='2026-10-12T14:00:00Z';
const GREEN=Object.fromEntries(gates.map(g=>[g,true]));
const spec={
 economics:{topic:'demand',id:5,featureId:'eco-practice',sourceId:'e-source'},
 chemistry:{topic:'kinetics',id:4,featureId:'chem-practice',sourceId:'c-source'}
};
function make({subject='economics',locale='ru',release=true,
  archiveRelease=false,sourceEnabled=true}={}){
 const flags={active:false,global:true,verified:true,finished:true,archive:true,
  exact:true,sourceEnabled,rights:true,subjectActive:true,
  release,sourceHash:'a'.repeat(64),sourceVersion:'v3',change:false,contextChange:false};
 const id=spec[subject]?.id??3;
 const db={
  hasProtectedAssessment:async()=>flags.active,
  getExamPrepSession:async()=>null,
  getPracticeSession:async()=>({id:7,user_id:U,subject_id:id,
    status:flags.finished?'finalized':'in_progress',
    finalized_at:flags.finished?finish:null}),
  getTourAttempt:async()=>({id:9,user_id:U,tour_id:4,status:flags.finished?'submitted':'in_progress'}),
  getTourRuntime:async()=>({attempt_id:9,user_id:U,tour_id:4,
    finalized_at:flags.finished?finish:null}),
  getTourArchiveAccess:async()=>({unlocked:flags.archive,ownerVerified:true}),
  getSubjectById:async s=>({id:s,subject_key:subject,is_active:flags.subjectActive}),
  getTourById:async()=>({id:4,subject_id:id}),
  subjectAccessAllowed:async()=>true
 };
 const resolver=new MockServerContextResolver(db);
 const registry=new PreviewFeatureRegistry();
 const rows=[];
 if(spec[subject])rows.push({surface:'practice',subject,feature:'answer_explanation',
  topic:spec[subject].topic,locale,featureId:spec[subject].featureId,
  sourceId:spec[subject].sourceId,sourceVersion:'v3',gates:GREEN});
 if(archiveRelease)rows.push({surface:'tour_archive',subject,feature:'archive_explanation',
  topic:'tour_result',locale,featureId:'tour',sourceId:'tour-source',sourceVersion:'v3',gates:GREEN});
 for(const row of rows){
  registry.register(row);
  if(release)registry.enableAfterGates(key(row));
 }
 let sourceCalls=0,evidenceCalls=0,completedChecks=0;
 const services={
  getGlobalRuntime:async()=>({uiEnabled:flags.global,gatewayEnabled:flags.global,killSwitch:!flags.global}),
  getSubjectStatus:async key=>({subjectKey:key,active:flags.subjectActive}),
  hasActiveProtectedAssessment:async()=>flags.active,
  getTopicEvidence:async({userId,kind,resourceId,questionId})=>{
   evidenceCalls++;
   if(flags.contextChange&&evidenceCalls>1)return {userId,kind,resourceId,topic:'different',evidenceId:'changed-evidence'};
   return {userId,kind,resourceId,subject,topic:kind==='tour_archive'?'tour_result':spec[subject]?.topic||'no-topic',
    questionId:questionId??null,verifiedAnswer:flags.verified,archiveUnlocked:flags.archive,
    evidenceId:'synthetic-verified-result-001'};
  },
  getSourceProof:async({subject:resolved,scope,topic,locale:requested,questionId})=>{
   sourceCalls++;
   if(!flags.sourceEnabled)return null;
   const p=spec[subject],revoked=flags.change&&sourceCalls>1;
   return{allowed:true,subject:resolved,scope,topic,locale:requested,
     sourceId:scope==='practice'?p?.sourceId:'tour-source',
     sourceKey:'SYNTHETIC-'+subject+'-'+String(questionId),
     sourceHash:revoked?'b'.repeat(64):flags.sourceHash,
     sourceVersion:flags.sourceVersion,
     approvalStatus:revoked?'retired':'approved',
     rightsStatus:flags.rights?'original_iclub':'restricted',
     runtimeAllowed:true,
     feature:scope==='practice'?'answer_explanation':'archive_explanation',
     proofKind:scope==='practice'?(flags.exact?'exact_question':'topic_only'):'opened_archive',
     questionId:flags.exact?questionId:null};
  },
  getFeatureId:async(_,scope)=>scope==='practice'?spec[subject]?.featureId:'tour',
  getLearnerKind:async()=> 'synthetic',
  getLearnerCohort:async()=> 'qa-synthetic-cohort'
 };
 const gate=new CrossSubjectAdmission({resolver,registry,services});
 const request=(kind='practice_result',changes={})=>({
  principal:{authenticated:true,userId:U},kind,resourceId:kind==='tour_archive'?'9':'7',
  questionId:101,locale,nowMs:1000,...changes
 });
 return{gate,flags,request,services,registry,sourceCalls:()=>sourceCalls};
}
test('Approved Economics exact-question after finalized Practice receives ONLY proof',async()=>{
 const x=make(),v=await x.gate.admit(x.request());
 assert.equal(v.ok,true);assert.equal(v.subject,'economics');assert.equal(v.topic,'demand');
 assert.equal(v.charge,0);assert.equal(v.providerCallRequired,false);
 assert.equal(v.authority,'server_proof_only');
 assert.equal('reply' in v,false);
});
test('Approved Chemistry exact question uses its own verified source',async()=>{
 const x=make({subject:'chemistry'}),v=await x.gate.admit(x.request());
 assert.equal(v.ok,true);assert.equal(v.subject,'chemistry');
 assert.equal(v.sourceId,'c-source');assert.equal(v.topic,'kinetics');
});
test('Economics and Chemistry never share a card by client subject spoofing',async()=>{
 for(const sub of ['economics','chemistry']){
  const x=make({subject:sub}),r=await x.gate.admit(x.request('practice_result',{subject:sub==='economics'?'chemistry':'economics'}));
  assert.equal(r.ok,true);assert.equal(r.subject,sub);
 }
});
test('Active assessment blocks BEFORE source lookup for every subject',async()=>{
 for(const sub of ['economics','chemistry']){
  const x=make({subject:sub});x.flags.active=true;
  assert.equal((await x.gate.admit(x.request())).reason,'protected_assessment');
  assert.equal(x.sourceCalls(),0);
 }
});
test('Incomplete or unowned Practice never accesses any source',async()=>{
 const x=make();x.flags.finished=false;
 assert.equal((await x.gate.admit(x.request())).reason,'practice_not_finished');
 assert.equal(x.sourceCalls(),0);
 const y=make();
 assert.equal((await y.gate.admit(y.request('practice_result',{principal:{authenticated:true,userId:OTHER}}))).reason,'context_not_authorized');
 assert.equal(y.sourceCalls(),0);
});
test('Unverified question-level evidence is not an error explanation',async()=>{
 const x=make();x.flags.verified=false;
 assert.equal((await x.gate.admit(x.request())).reason,'exact_question_unverified');
 assert.equal(x.sourceCalls(),0);
});
test('Most economics cards are generic topic cards: never substitute for exact question',async()=>{
 const x=make();x.flags.exact=false;
 assert.equal((await x.gate.admit(x.request())).reason,'exact_question_source_missing');
});
test('Approved card counts alone never unlock a disabled gate',async()=>{
 const x=make({release:false});
 assert.equal((await x.gate.admit(x.request())).reason,'feature_disabled');
});
test('Sources without rights or approved current status are refused',async()=>{
 const x=make();x.flags.rights=false;
 assert.equal((await x.gate.admit(x.request())).reason,'approved_source_not_ready');
 const y=make({sourceEnabled:false});
 assert.equal((await y.gate.admit(y.request())).reason,'approved_source_not_ready');
});
test('Global AI kill switch protects all subjects without touching older AI',async()=>{
 const x=make();x.flags.global=false;
 assert.equal((await x.gate.admit(x.request())).reason,'global_ai_disabled');
 assert.equal(x.sourceCalls(),0);
});
test('Closed subject or missing server-side subject membership refuses',async()=>{
 const x=make();x.flags.subjectActive=false;
 assert.equal((await x.gate.admit(x.request())).ok,false);
 assert.equal(x.sourceCalls(),0);
});
test('Biology and Informatics active subjects remain not ready without sources',async()=>{
 for(const subject of ['biology','informatics']){
   const x=make({subject});
   assert.equal((await x.gate.admit(x.request())).ok,false);
 }
});
test('Inactive English A1/A2/B1, SAT, IELTS stay disabled',async()=>{
 for(const subject of ['english_a1','english_a2','english_b1','sat','ielts']){
  const x=make({subject});
  assert.equal((await x.gate.admit(x.request())).reason,'subject_not_released');
 }
});
test('Home, Profile, Lesson, Videos and General help cannot fake topic evidence',async()=>{
 const x=make();
 for(const kind of ['home_next_step','profile_progress','lesson_topic','video_explanation','general_help']){
  assert.equal((await x.gate.admit(x.request(kind))).reason,'in_development');
 }
});
test('Opened Tour still needs separately approved exact archive source',async()=>{
 const x=make({archiveRelease:false});
 assert.equal((await x.gate.admit(x.request('tour_archive'))).ok,false);
});
test('Full synthetic Tour archive source can be independently enabled by gates',async()=>{
 const x=make({archiveRelease:true});
 const v=await x.gate.admit(x.request('tour_archive'));
 assert.equal(v.ok,true);assert.equal(v.scope,'tour_archive');
});
test('Tour with unfinished attempt or locked archive never reaches answer',async()=>{
 for(const opts of [{archive:false},{finished:false}]){
  const x=make({archiveRelease:true});Object.assign(x.flags,opts);
  assert.equal((await x.gate.admit(x.request('tour_archive'))).ok,false);
 }
});
test('Revoked approved source while processing is blocked without quota',async()=>{
 const x=make();x.flags.change=true;
 const v=await x.gate.admit(x.request());
 assert.equal(v.reason,'context_changed');assert.equal(v.charge,0);
});
test('Subject evidence changes while checking source cannot reuse old explanation',async()=>{
 const x=make();x.flags.contextChange=true;
 assert.equal((await x.gate.admit(x.request())).reason,'context_changed');
});
test('Exam starts mid-request: source proof is discarded',async()=>{
 const x=make();const original=x.services.getSourceProof;
 let calls=0;x.services.getSourceProof=async p=>{
  calls++;const v=await original(p);if(calls===1)x.flags.active=true;return v;
 };
 const v=await x.gate.admit(x.request());assert.equal(v.ok,false);
});
test('Missing or incorrect source hash is not approved',async()=>{
 const x=make();x.flags.sourceHash='invalid';
 assert.equal((await x.gate.admit(x.request())).reason,'approved_source_not_ready');
});
test('Locale availability is independent, no fallback to wrong language',async()=>{
 const x=make();
 const v=await x.gate.admit(x.request('practice_result',{locale:'en'}));
 assert.equal(v.ok,false);
 assert.equal((await x.gate.admit(x.request('practice_result',{locale:'de'}))).reason,'language_not_ready');
});
test('User-provided quota, route or upgrade claims are ignored by eligibility proof',async()=>{
 const x=make(),v=await x.gate.admit(x.request('practice_result',{
  plan:'pro',allowGeneration:true,skipExamGuard:true,userAnswer:'invented'}));
 assert.equal(v.ok,true);assert.equal(v.charge,0);assert.equal('plan' in v,false);
});
test('No student grade, raw question, answer or source key returned to client',async()=>{
 const x=make(),r=await x.gate.admit(x.request());
 assert.deepEqual(Object.keys(r).sort(),
 ['ok','charge','providerCallRequired','authority','scope','subject','topic','locale','sourceId','sourceVersion','sourceHash'].sort());
 assert.equal('sourceKey' in r,false);
 assert.equal('userId' in r,false);
});

test('A switched topic using the same evidence ID cannot reuse the old source',async()=>{
 const x=make();
 const initial=x.services.getTopicEvidence;
 let calls=0;
 x.services.getTopicEvidence=async request=>{
  const original=await initial(request);
  return ++calls===1?original:{...original,topic:'unexpected_other_topic'};
 };
 const result=await x.gate.admit(x.request());
 assert.equal(result.reason,'context_changed');
 assert.equal(result.charge,0);
});
