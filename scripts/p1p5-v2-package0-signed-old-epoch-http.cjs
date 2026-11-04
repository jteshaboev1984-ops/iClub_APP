#!/usr/bin/env node
// Issue #450 P0-13. Test ONLY local signed JWT->PostgREST->PG17 with
// fabricated epoch/response tables. Never touch live Supabase or learner data.
'use strict';
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const HOST='http://127.0.0.1:3000';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
const phase=process.argv[2];
const FIXED_IAT=Number(process.env.P0_13_FIXED_IAT);
assert(Number.isSafeInteger(FIXED_IAT) && FIXED_IAT>1700000000,
  'P0-13 requires same pre-cutover JWT timestamp for all phases');
assert(['before','during','after'].includes(phase),'P0-13 requires explicit phase');
assert(process.env.P1P5_E2E_ISOLATED==='true','disposable environment required');
assert(process.env.PGDATABASE==='postgres','production database blocked');
assert(SECRET&&SECRET.length>=32,'disposable local JWT key required');
assert(HOST==='http://127.0.0.1:3000','external host blocked');

const enc=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
function token(uid){
 const now=FIXED_IAT; // exact same still-valid signed JWT across before/during/after
 const body=enc({alg:'HS256',typ:'JWT'})+'.'+
   enc({role:'authenticated',aud:'authenticated',sub:uid,iat:now,exp:now+1200});
 return body+'.'+crypto.createHmac('sha256',SECRET).update(body).digest('base64url');
}
const digest=o=>crypto.createHash('sha256').update(o).digest('hex');
async function request(epoch,key,payload,authToken){
 const u=HOST+'/rpc/p0_13_submit_signed_epoch_test_v1';
 const response=await fetch(u,{
   method:'POST',
   headers:{'Content-Type':'application/json','Accept':'application/json',
     ...(authToken?{Authorization:'Bearer '+authToken}:{})},
   body:JSON.stringify({p_epoch:epoch,p_request_key:key,p_payload_digest:digest(payload)}),
   signal:AbortSignal.timeout(15000)
 });
 const raw=await response.text();let data=null;
 try{data=JSON.parse(raw);}catch{}
 return {status:response.status,ok:response.ok,data};
}
function success(r,duplicate){
 assert.equal(r.status,200,'P0-13 expected 200: '+JSON.stringify(r));
 assert.equal(r.data?.contract_version,'p0_13_disposable_only');
 assert.equal(r.data?.duplicate,duplicate);
 assert.equal(r.data?.accepted,true);
}
function denied(r,label){
 assert(!r.ok,label+' unexpectedly allowed: '+JSON.stringify(r));
 assert([400,401,403,404,409].includes(r.status),
  label+' unexpected HTTP status: '+r.status);
}
function conflict(r,label){
 assert.equal(r.status,409,label+' should be immediate HTTP 409: '+JSON.stringify(r));
 assert.equal(r.data?.code,'PT409',label+' should not trigger PostgREST retries');
}
(async()=>{
 const a=token(A),b=token(B),other=token(A).slice(0,-2)+'zz';
 if(phase==='before'){
   success(await request(1,'epoch-one-request','alpha',a),false);
   success(await request(1,'epoch-one-request','alpha',a),true);
   conflict(await request(1,'epoch-one-request','changed-payload',a),'same key changed payload');
   conflict(await request(2,'premature-epoch-two','alpha',a),'premature new epoch');
   denied(await request(1,'foreign-owner','alpha',b),'foreign learner');
   denied(await request(1,'anon-attempt','alpha',null),'anonymous');
   denied(await request(1,'tampered-token','alpha',other),'bad JWT');
   console.log('PASS P0-13 signed owner, idempotent replay, payload conflict, foreign/anon/tampered denial');
 }else if(phase==='during'){
   conflict(await request(1,'during-maintenance-old','alpha',a),'paused old epoch');
   conflict(await request(2,'during-maintenance-new','alpha',a),'paused new epoch');
   console.log('PASS P0-13 held release maintenance denies every learner write');
 }else{
   conflict(await request(1,'old-tab-after-cutover','alpha',a),'post-cutover stale tab');
   conflict(await request(2,'old-tab-after-cutover','alpha',a),'tampered new epoch with old issued session');
   success(await request(2,'epoch-two-request','beta',a),false);
   success(await request(2,'epoch-two-request','beta',a),true);
   denied(await request(2,'foreign-new-epoch','beta',b),'foreign learner after cutover');
   console.log('PASS P0-13 old signed JWT/tab denied after epoch bump; fresh epoch and replay behavior intact');
 }
})().catch(e=>{console.error('P0-13 '+phase+' FAIL: '+e.message);process.exit(1)});
