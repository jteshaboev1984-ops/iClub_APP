#!/usr/bin/env node
// Issue #450 P0-16: real existing six Math Exam Prep public RPCs, not test RPCs.
// REAL signed HTTP to localhost PostgREST and isolated PG17 ONLY; no live data.
'use strict';
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const HOST='http://127.0.0.1:3000';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
const OLD_IAT=Number(process.env.P0_16_OLD_IAT);
const STALE_SESSION=process.env.P0_16_STALE_SESSION_ID;
const STALE_AUTH=process.env.P0_16_STALE_AUTH_ID;
const phase=process.argv[2];
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
assert(['before','paused','after'].includes(phase));
assert(process.env.P1P5_E2E_ISOLATED==='true','P0-16 forbids non-isolated runtime');
assert(process.env.PGDATABASE==='postgres'&&process.env.PGHOST==='127.0.0.1',
  'P0-16 forbids nonlocal PostgreSQL');
assert(SECRET?.length>=32,'P0-16 local signing key absent');
assert(Number.isSafeInteger(OLD_IAT)&&OLD_IAT>1700000000,
  'P0-16 old bearer token must have immutable pre-cutover iat');
assert(/^[a-f0-9-]{36}$/i.test(STALE_SESSION||''),
  'P0-16 must use a genuine frozen PG17 prelaunch session id');
assert(/^[a-f0-9-]{36}$/i.test(STALE_AUTH||''),
  'P0-16 must use a real frozen PG17 session authorization');

const enc=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
function jwt(uid,iat){
 const header=enc({alg:'HS256',typ:'JWT'});
 const body=enc({role:'authenticated',aud:'authenticated',sub:uid,iat,exp:iat+1800});
 const part=header+'.'+body;
 return part+'.'+crypto.createHmac('sha256',SECRET).update(part).digest('base64url');
}
async function rpc(name,args,token){
 assert(/^[a-z_0-9]+$/.test(name),'unexpected real RPC route');
 const r=await fetch(HOST+'/rpc/'+name,{
  method:'POST',signal:AbortSignal.timeout(15000),
  headers:{'Content-Type':'application/json','Accept':'application/json',
   ...(token?{Authorization:'Bearer '+token}:{})},
  body:JSON.stringify(args)
 });
 const raw=await r.text();let data;
 try{data=raw?JSON.parse(raw):null;}catch{data=null;}
 return {status:r.status,ok:r.ok,data};
}
const profile=['save_exam_prep_exam_profile_v2',{
 p_exam_series:'May/June 2027',
 p_target_grade:'A',
 p_total_student_hours_available:12,
 p_mathematics_hours_budget:6
}];
const next=['start_exam_prep_next_diagnostic_safe_v1',{
 p_component_code:'P1',p_idempotency_key:'p016-disposable-diag-attempt-0001'
}];
const timed=['authorize_exam_prep_timed_safe_v1',{p_assessment_id:1}];
const start=['start_exam_prep_session_safe_v1',{
 p_authorization_id:STALE_AUTH,
 p_idempotency_key:'p016-isolated-authorize-session-0001'
}];
const answer=['submit_exam_prep_response_safe_v1',{
 p_session_id:STALE_SESSION,p_item_order:1,p_payload:{answer:'1'},
 p_idempotency_key:'p016-expired-session-answer-0001',p_elapsed_ms:1000,p_language:'en'
}];
const finalize=['finalize_exam_prep_session_safe_v1',{
 p_session_id:STALE_SESSION,p_idempotency_key:'p016-expired-session-finalize-0001'
}];
const six=[profile,next,timed,start,answer,finalize];
const oldToken=jwt(A,OLD_IAT);
function epoch409(r,route,kind){
 assert.equal(r.status,409,kind+'/'+route+' expected HTTP 409: '+JSON.stringify(r));
 assert.equal(r.data?.code,'PT409',kind+'/'+route+' expected nonretryable PT409');
 assert(/p0_16_/.test(r.data?.message||''),kind+'/'+route+' did not reach real epoch fence');
}
(async()=>{
 if(phase==='before'){
   const good=await rpc(...profile,oldToken);
   assert(good.ok,'P0-16 actual owner profile RPC not writable before cutover: '+JSON.stringify(good));
   const pre=await rpc(...answer,oldToken);
   assert(pre.data?.code!=='PT409',
     'P0-16 pre-cutover original response RPC unexpectedly blocked by epoch: '+JSON.stringify(pre));
   console.log('PASS P0-16 old signed JWT works on real profile writer and reaches original response path before maintenance');
 }else if(phase==='paused'){
   for(const [name,args] of six)epoch409(await rpc(name,args,oldToken),name,'maintenance pause');
   console.log('PASS P0-16 SIX genuine Exam Prep RPCs refuse active maintenance with old bearer');
 }else {
   for(const [name,args] of six)epoch409(await rpc(name,args,oldToken),name,'old signed JWT');
   const now=Math.floor(Date.now()/1000);
   assert(now>OLD_IAT,'new post-cutover JWT must actually have a later signed issue time');
   const fresh=jwt(A,now);
   const saved=await rpc(...profile,fresh);
   assert(saved.ok,'P0-16 genuine profile writer failed with fresh signed JWT: '+JSON.stringify(saved));
   epoch409(await rpc(...start,fresh),'start_exam_prep_session_safe_v1',
     'fresh JWT trying stale server-issued authorization');
   epoch409(await rpc(...answer,fresh),'submit_exam_prep_response_safe_v1',
     'fresh JWT trying stale server-issued session');
   epoch409(await rpc(...finalize,fresh),'finalize_exam_prep_session_safe_v1',
     'fresh JWT trying stale server-issued session');
   const other=jwt(B,OLD_IAT);
   epoch409(await rpc(...profile,other),'save_exam_prep_exam_profile_v2','other stale bearer');
   const noAuth=await rpc(...profile,null);
   assert(!noAuth.ok,'P0-16 anon unexpectedly passed actual learner RPC');
   console.log('PASS P0-16 SIX actual server RPCs reject old signed token; fresh signed profile works; fresh JWT cannot resurrect stale session; anon denied');
 }
})().catch(e=>{console.error('P0-16 '+phase+' FAIL: '+e.message);process.exitCode=1;});
