// Run: node --test qa/ai-layer-v21-server-context-existing-db.test.cjs
// Uses exact column/status contracts of existing iClub tables (metadata read-only).
'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {MockServerContextResolver}=require('./ai-layer-v21-server-context-existing-db.cjs');
const U='11111111-1111-4111-8111-111111111111',V='22222222-2222-4222-8222-222222222222';
const E='33333333-3333-4333-8333-333333333333', FIN='2026-10-12T14:00:00Z';
const exam=(change={})=>({id:E,user_id:U,status:'finalized',finalized_at:FIN,
 component_code:'P1',content_version_id:23,...change});
const practice=(change={})=>({id:7,user_id:U,subject_id:1,status:'finalized',finalized_at:FIN,...change});
const tour=(change={})=>({id:9,user_id:U,tour_id:4,status:'submitted',...change});
const runtime=(change={})=>({attempt_id:9,user_id:U,tour_id:4,finalized_at:FIN,...change});
const settings=(over={})=>{
 const calls=[];
 const db={
  hasProtectedAssessment:async()=>false,
  getExamPrepSession:async()=>exam(),
  getPracticeSession:async()=>practice(),
  getTourAttempt:async()=>tour(),
  getTourRuntime:async()=>runtime(),
  getTourArchiveAccess:async()=>({unlocked:true,ownerVerified:true}),
  getTourById:async()=>({id:4,subject_id:1,is_active:true}),
  getSubjectById:async()=>({id:1,subject_key:'economics',is_active:true}),
  subjectAccessAllowed:async()=>true,...over
 };
 const services=Object.fromEntries(Object.entries(db).map(([name,fn])=>
  [name,async(...args)=>{calls.push([name,...args]);return fn(...args)}]));
 return {resolver:new MockServerContextResolver(services),services,calls};
};
const request=(kind='exam_prep_result',change={})=>({
 principal:{authenticated:true,userId:U},
 kind,resourceId:kind==='exam_prep_result'?E:kind==='practice_result'?'7':'9',
 nowMs:200,...change
});
test('Existing finalized P1 Exam Prep session verifies math without inventing skill',async()=>{
 const x=settings(),r=await x.resolver.resolve(request());
 assert.equal(r.ok,true);assert.equal(r.context.subject,'mathematics');
 assert.equal(r.context.component,'P1');assert.equal(r.context.topic,null);
 assert.equal(r.context.sourceReady,false);
 assert.equal(r.context.routeAuthority,'unified_ai');
});
test('P5 stays independent; wrong components rejected',async()=>{
 assert.equal((await settings({getExamPrepSession:async()=>exam({component_code:'P5'})}).resolver.resolve(request())).context.component,'P5');
 assert.equal((await settings({getExamPrepSession:async()=>exam({component_code:'P3'})}).resolver.resolve(request())).reason,'component_unverified');
});
test('Math active, abandoned and not-finalized session cannot allow AI',async()=>{
 for(const state of ['active','abandoned']){
  const x=settings({getExamPrepSession:async()=>exam({status:state})});
  assert.equal((await x.resolver.resolve(request())).reason,'exam_prep_not_finalized');
 }
 assert.equal((await settings({getExamPrepSession:async()=>exam({finalized_at:null})}).resolver.resolve(request())).reason,'exam_prep_not_finalized');
});
test('Practice finalized state and timestamp are both required',async()=>{
 const ok=await settings().resolver.resolve(request('practice_result'));assert.equal(ok.ok,true);
 assert.equal(ok.context.subject,'economics');
 for(const row of [practice({status:'in_progress'}),practice({status:'abandoned'}),practice({finalized_at:null})]){
  assert.equal((await settings({getPracticeSession:async()=>row}).resolver.resolve(request('practice_result'))).reason,'practice_not_finished');
 }
});
test('Practice subject identity derives from server subjects table',async()=>{
 const x=settings();
 const r=await x.resolver.resolve(request('practice_result',{subject:'mathematics',subject_id:999,finalized:true}));
 assert.equal(r.context.subject,'economics');
 assert.ok(x.calls.some(c=>c[0]==='getSubjectById'&&c[1]===1));
});
test('Practice cannot open inactive or mismatched subject',async()=>{
 for(const subject of [{id:1,subject_key:'economics',is_active:false},{id:2,subject_key:'economics',is_active:true}]){
  const x=settings({getSubjectById:async()=>subject});
  assert.equal((await x.resolver.resolve(request('practice_result'))).reason,'subject_unverified');
 }
});
test('Tour archive requires submitted/time_expired state AND runtime finalized_at',async()=>{
 const good=await settings().resolver.resolve(request('tour_archive'));
 assert.equal(good.ok,true);assert.equal(good.context.subject,'economics');
 for(const state of ['in_progress','abandoned','anti_cheat']){
  const x=settings({getTourAttempt:async()=>tour({status:state})});
  assert.equal((await x.resolver.resolve(request('tour_archive'))).reason,'tour_not_finished');
 }
 const timeExpired=await settings({getTourAttempt:async()=>tour({status:'time_expired'})}).resolver.resolve(request('tour_archive'));
 assert.equal(timeExpired.ok,true);
});
test('Tour attempt without finalized runtime cannot open archive',async()=>{
 for(const bad of [runtime({finalized_at:null}),runtime({attempt_id:99}),runtime({tour_id:5}),runtime({user_id:V})]){
  assert.equal((await settings({getTourRuntime:async()=>bad}).resolver.resolve(request('tour_archive'))).reason,'tour_not_finished');
 }
});
test('Tour archive unlock permission is independent from finished attempt',async()=>{
 for(const archive of [{unlocked:false,ownerVerified:true},{unlocked:true,ownerVerified:false},null]){
  assert.equal((await settings({getTourArchiveAccess:async()=>archive}).resolver.resolve(request('tour_archive'))).reason,'archive_locked');
 }
});
test('Tour source subject resolved through actual tours -> subjects relations',async()=>{
 const x=settings();
 const out=await x.resolver.resolve(request('tour_archive',{subject:'mathematics'}));
 assert.equal(out.context.subject,'economics');
 assert.ok(x.calls.some(c=>c[0]==='getTourById'&&c[1]===4));
});
test('Foreign learner cannot read any of the three contexts',async()=>{
 for(const kind of ['exam_prep_result','practice_result','tour_archive']){
  const x=settings();
  const r=await x.resolver.resolve(request(kind,{principal:{authenticated:true,userId:V}}));
  assert.equal(r.reason,'context_not_authorized');
  assert.ok(!x.calls.some(c=>c[0]==='getSubjectById'));
 }
});
test('A protected assessment globally blocks before any resource fetch',async()=>{
 const x=settings({hasProtectedAssessment:async()=>true});
 assert.equal((await x.resolver.resolve(request('practice_result'))).reason,'protected_assessment');
 assert.ok(!x.calls.some(c=>c[0]==='getPracticeSession'));
});
test('New exam starting during async lookups blocks final reply',async()=>{
 let n=0;
 const x=settings({hasProtectedAssessment:async()=>++n>1});
 assert.equal((await x.resolver.resolve(request('tour_archive'))).reason,'context_changed');
});
test('Practice session changing from finalized to active is refused',async()=>{
 let n=0;const x=settings({getPracticeSession:async()=>++n===1?practice():practice({status:'in_progress'})});
 assert.equal((await x.resolver.resolve(request('practice_result'))).reason,'context_changed');
});
test('Tour archive revoked while resolving is refused',async()=>{
 let n=0;const x=settings({getTourArchiveAccess:async()=>({unlocked:++n===1,ownerVerified:true})});
 assert.equal((await x.resolver.resolve(request('tour_archive'))).reason,'context_changed');
});
test('Subject access is checked on the server rather than client boolean',async()=>{
 const x=settings({subjectAccessAllowed:async()=>false});
 assert.equal((await x.resolver.resolve(request('practice_result',{hasAccess:true}))).reason,'subject_not_entitled');
});
test('Inconclusive backend errors never result in an approved context',async()=>{
 const x=settings({getPracticeSession:async()=>{throw Error('DB offline')}});
 assert.equal((await x.resolver.resolve(request('practice_result'))).reason,'context_unavailable');
 const y=settings({hasProtectedAssessment:async()=>{throw Error('RLS error')}});
 assert.equal((await y.resolver.resolve(request())).reason,'protected_assessment');
});
test('No source/answer key, mastery, score or learner private records in context output',async()=>{
 for(const kind of ['exam_prep_result','practice_result','tour_archive']){
  const out=await settings().resolver.resolve(request(kind));
  assert.equal(out.ok,true);
  assert.deepEqual(Object.keys(out).sort(),['ok','verifiedBy','context'].sort());
  assert.deepEqual(Object.keys(out.context).sort(),
   ['kind','subject','scope','component','sessionRef','finalizedAt','topic','sourceReady','routeAuthority'].sort());
  assert.equal(out.context.sourceReady,false);
 }
});
test('Bad/unknown resource IDs and anonymous calls fail before DB fetch',async()=>{
 const x=settings();
 assert.equal((await x.resolver.resolve(request('exam_prep_result',{resourceId:'7'}))).reason,'invalid_resource_id');
 assert.equal((await x.resolver.resolve(request('practice_result',{resourceId:'not-an-id'}))).reason,'invalid_resource_id');
 assert.equal((await x.resolver.resolve(request('tour_archive',{principal:{authenticated:false,userId:U}}))).reason,'auth_required');
 assert.equal((await x.resolver.resolve(request('unsafe_raw_db_write'))).reason,'surface_not_supported');
});

test('Subject entitlement revoked while resolving is rejected before final context',async()=>{
 let checks=0;
 const x=settings({subjectAccessAllowed:async()=>++checks===1});
 assert.equal((await x.resolver.resolve(request('practice_result'))).reason,'context_changed');
});
test('Tour finalized timestamp changed between lookups cannot replay previous archive state',async()=>{
 let reads=0;
 const x=settings({getTourRuntime:async()=>++reads===1?runtime():runtime({finalized_at:'2026-10-12T15:00:00Z'})});
 assert.equal((await x.resolver.resolve(request('tour_archive'))).reason,'context_changed');
});
