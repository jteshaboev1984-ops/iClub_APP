// node --test qa/ai-layer-v21-math-authority-service.test.cjs
// Authenticated-server mock; exercises actual staged RPC contract, not live DB.
'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict');
const {MathAuthorityV21}=require('./ai-layer-v21-math-authority-service.cjs');
const USER='11111111-1111-4111-8111-111111111111';
const SESSION='22222222-2222-4222-8222-222222222222';
const args=(patch={})=>({principal:{authenticated:true,userId:USER},
 handle:'exam-result-handle-001',locale:'ru',...patch});
const context=(patch={})=>({ownerId:USER,routeAuthority:'unified_ai',
 subject:'mathematics',kind:'exam_prep_result',active:true,
 protectedAssessment:false,sessionId:SESSION,component:'P1',skill:'P1-CIR-01',...patch});
const proof=(patch={})=>({allowed:true,subject:'mathematics',scope:'exam_prep',
 component:'P1',skill_code:'P1-CIR-01',locale:'ru',
 source_card_key:'p1:P1-CIR-01:theory:ru:v2',source_version:'v2',
 source_hash:'a'.repeat(64),tutor_content_version:'tutor_v3_learner_first',
 tutor_content_hash:'b'.repeat(32),...patch});
function setup({ctx=context(),result=proof(),guard=true,release=true}={}){
 const events=[],state={ctx,result,guard,release};
 const adapter=new MathAuthorityV21({
  verifyContext:async({userId,handle})=>{events.push(['context',userId,handle]);return typeof state.ctx==='function'?state.ctx():state.ctx},
  globalGuard:async(t)=>{events.push(['guard',t]);return {allowed:state.guard===true,reason:'global_ai_disabled'};},
  readAuthorityRpc:async(name,params)=>{events.push(['rpc',name,params]);return typeof state.result==='function'?state.result():state.result;},
  releaseGate:async(payload)=>{events.push(['release',payload]);return {allowed:state.release===true,reason:'topic_not_released'}}
 });
 return{adapter,events,state};
}
test('approved source returns only minimal Math P1 authority proof',async()=>{
 const x=setup(),r=await x.adapter.evaluate(args());
 assert.equal(r.ok,true);assert.equal(r.proof.skill,'P1-CIR-01');
 assert.equal(r.proof.sourceVersion,'v2');assert.equal(r.authority,'server_verified');
 assert.deepEqual(Object.keys(r).sort(),['authority','ok','proof']);
 assert.equal('reply' in r,false);assert.equal('quota' in r,false);
});
test('RPC can only be called with JWT principal and server-owned session/skill',async()=>{
 const x=setup();
 const r=await x.adapter.evaluate(args({subject:'economics',skill:'P5-PRO-01',p_user_id:'another'}));
 assert.equal(r.ok,true);
 const call=x.events.find(e=>e[0]==='rpc');
 assert.equal(call[1],'get_iclub_ai_math_skill_context_service_v2');
 assert.deepEqual(call[2],{p_user_id:USER,p_session_id:SESSION,
   p_skill_code:'P1-CIR-01',p_locale:'ru'});
});
test('old Exam Prep route is refused before Global AI or RPC calls',async()=>{
 const x=setup({ctx:context({routeAuthority:'legacy_exam_prep'})});
 assert.equal((await x.adapter.evaluate(args())).reason,'context_unverified');
 assert.equal(x.events.some(e=>e[0]==='rpc'),false);
});
test('other learner, anonymous, bad session or fake subject refused',async()=>{
 for(const c of [{ownerId:'22222222-2222-4222-8222-222222222222'},
  {subject:'economics'},{sessionId:'not-a-uuid'},{active:false}]){
  const x=setup({ctx:context(c)});
  assert.equal((await x.adapter.evaluate(args())).ok,false);
  assert.equal(x.events.some(e=>e[0]==='rpc'),false);
 }
 assert.equal((await setup().adapter.evaluate(args({principal:{authenticated:false,userId:USER}}))).reason,'auth_required');
});
test('new active assessment stops without source retrieval',async()=>{
 const x=setup({ctx:context({protectedAssessment:true})});
 assert.equal((await x.adapter.evaluate(args())).reason,'context_unverified');
 assert.equal(x.events.some(e=>e[0]==='rpc'),false);
});
test('Global AI kill switch or disabled generation is respected',async()=>{
 const x=setup({guard:false});
 assert.equal((await x.adapter.evaluate(args())).reason,'global_ai_disabled');
 assert.equal(x.events.some(e=>e[0]==='rpc'),false);
});
test('rejected session evidence never becomes an approved source',async()=>{
 const x=setup({result:{allowed:false,reason:'skill_evidence_unverified'}});
 assert.equal((await x.adapter.evaluate(args())).reason,'skill_evidence_unverified');
});
test('source/topic mismatch and changed locale refuse before reply',async()=>{
 for(const r of [proof({skill_code:'P5-PRO-01'}),proof({locale:'en'}),
  proof({component:'P5'}),proof({source_hash:'bad'}),
  proof({tutor_content_hash:'bad'}),proof({tutor_content_version:'retired'})]){
  const x=setup({result:r});
  assert.equal((await x.adapter.evaluate(args())).reason,'source_contract_mismatch');
 }
});
test('source version only released by governed release gate',async()=>{
 const x=setup({release:false});
 assert.equal((await x.adapter.evaluate(args())).reason,'topic_not_released');
 assert.equal(x.events.some(e=>e[0]==='release'),true);
});
test('revoked protected exam while awaiting RPC refuses final authority',async()=>{
 let n=0;
 const x=setup({ctx:()=>++n===1?context():context({protectedAssessment:true})});
 assert.equal((await x.adapter.evaluate(args())).reason,'context_changed');
});
test('skill or session changed during request refuses before provider',async()=>{
 for(const patch of [{skill:'P1-CIR-02'},{sessionId:'33333333-3333-4333-8333-333333333333'}]){
  let n=0;const x=setup({ctx:()=>++n===1?context():context(patch)});
  assert.equal((await x.adapter.evaluate(args())).reason,'context_changed');
 }
});
test('global gate revoked while awaiting content refuses',async()=>{
 const x=setup();let n=0;
 x.adapter.globalGuard=async()=>({allowed:++n===1});
 assert.equal((await x.adapter.evaluate(args())).reason,'context_changed');
});
test('before-delivery recheck refuses changed version without exposing answer',async()=>{
 const x=setup(),first=await x.adapter.evaluate(args());
 assert.equal(first.ok,true);
 x.state.result=proof({source_hash:'c'.repeat(64)});
 const second=await x.adapter.stillValid(args(),first.proof);
 assert.equal(second.reason,'source_changed');
});
test('safe before-delivery recheck accepts only same source and session',async()=>{
 const x=setup(),first=await x.adapter.evaluate(args());
 const second=await x.adapter.stillValid(args(),first.proof);
 assert.equal(first.ok,true);assert.equal(second.ok,true);
 assert.deepEqual(first.proof,second.proof);
});
test('non-supported locales and malicious skill code fail closed',async()=>{
 const x=setup();
 assert.equal((await x.adapter.evaluate(args({locale:'de'}))).reason,'locale_unverified');
 x.state.ctx=context({skill:'P1-FOO;DROP TABLE'});
 assert.equal((await x.adapter.evaluate(args())).reason,'context_unverified');
});
test('backend/network failure denies without retrying legacy Tutor',async()=>{
 const x=setup();
 x.adapter.readAuthorityRpc=async()=>{throw Error('simulated outage')};
 assert.equal((await x.adapter.evaluate(args())).reason,'authority_backend_unavailable');
 assert.equal(x.events.some(e=>e[1]==='exam-prep-ai'),false);
});
