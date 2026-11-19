#!/usr/bin/env node
'use strict';
// #574 · signed-JWT/HTTP user-owner regression. Disposable local PG17 ONLY.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
assert(process.env.CI==='true' &&
       process.env.PRACTICE_SEASON2_ISOLATED==='true' &&
       process.env.PGHOST==='127.0.0.1' &&
       process.env.PGDATABASE==='postgres',
       'REFUSED: requires disposable CI PostgreSQL17');
const secret=process.env.PRACTICE_SEASON2_JWT_SECRET;
assert(secret && secret.length>=48,'Refused without ephemeral test secret');
const base='http://127.0.0.1:3000';
const A='11111111-1111-4111-8111-111111111111';
const B='22222222-2222-4222-8222-222222222222';
const C='33333333-3333-4333-8333-333333333333';
const encode=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function jwt(uid,ttl=600){
 const now=Math.floor(Date.now()/1000);
 const head=encode({alg:'HS256',typ:'JWT'});
 const body=[head,encode({role:'authenticated',sub:uid,aud:'authenticated',iat:now,exp:now+ttl})].join('.');
 return body+'.'+crypto.createHmac('sha256',secret).update(body).digest('base64url');
}
async function post(token,key='mathematics'){
 const r=await fetch(base+'/rpc/get_practice_season2_progress_safe_v1',{
  method:'POST',
  headers:{'Content-Type':'application/json',
           ...(token===null?{}:{Authorization:'Bearer '+token})},
  body:JSON.stringify({p_subject_key:key})
 });
 const v=await r.text();let result;try{result=JSON.parse(v)}catch{result=null}
 return {status:r.status,ok:r.ok,result};
}
(async()=>{
 const anon=await post(null);
 assert(!anon.ok && anon.status>=400,'anonymous can read season progress');
 const expired=await post(jwt(A,-3600)); // Outside PostgREST JWT clock-skew allowance
 assert(!expired.ok && expired.status>=400,'expired token succeeded');
 const a=await post(jwt(A));
 assert(a.ok,'signed A denied '+a.status);
 assert.equal(a.result?.period_active,true,'season 2 not active');
 assert.equal(a.result?.practice_access?.open_season_no,2,'S2 math must be the only open new-attempt period');
 assert.equal(a.result?.practice_access?.season1_new_attempts_open,false,'S1 math still open after S2');
 assert.equal(a.result?.practice_access?.season2_new_attempts_open,true,'S2 math not open');
 assert.equal(a.result?.main?.attempts_count,2,'wrong current main count');
 assert.equal(a.result?.main?.archived_attempts_count,1,'history not preserved separately');
 assert.equal(a.result?.main?.best?.id,103,'best current contaminated');
 assert.equal(a.result?.topic?.sessions_count,1,'topic count contaminated');
 assert.equal(a.result?.topic?.archived_sessions_count,1,'topic archive mismatch');
 const b=await post(jwt(B));
 assert(b.ok,'signed B denied');
 assert.equal(b.result?.main?.attempts_count,1,'cross-user main leak');
 assert.equal(b.result?.main?.archived_attempts_count,0,'cross-user archive leak');
 assert.equal(b.result?.topic?.sessions_count,1,'cross-user topic leak');
 assert(!JSON.stringify(b.result).includes('103'),'cross-user private attempt exposed');
 const c=await post(jwt(C));
 assert(c.ok,'signed C denied');
 assert.equal(c.result?.main?.attempts_count,0,'fresh user not at zero');
 assert.equal(c.result?.topic?.sessions_count,0,'fresh user topic not at zero');
 const other=await post(jwt(A),'chemistry');
 assert(other.ok,'other subject denied');
 assert.equal(other.result?.period_active,false,
   'undated other-subject Tour1 must not inherit Mathematics reset');
 assert.equal(other.result?.practice_access?.open_season_no,1,
   'undated Chemistry must keep S1 Practice open');
 assert.equal(other.result?.practice_access?.season1_new_attempts_open,true,
   'Math S2 cannot close Chemistry S1 Practice');
 assert.equal(other.result?.history_snapshot?.practice_open,true,
   'Chemistry S1 History must remain available');
 assert.equal(other.result?.reason,'season_not_started',
   'undated subject period should remain dormant');
 const unknown=await post(jwt(A),'unknown');
 assert(!unknown.ok,'unknown subject accepted');
 console.log('PRACTICE_SEASON_ACCESS_SIGNED_HTTP_PASS: Math S2 closes only Math S1, Chemistry S1 stays open; owner isolation and history intact');
})().catch(e=>{console.error('PRACTICE_SEASON2_SIGNED_HTTP_FAILED:',e.message);process.exit(1)});
