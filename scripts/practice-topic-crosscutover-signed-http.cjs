#!/usr/bin/env node
'use strict';
// #574. Authenticated JWT/PostgREST against disposable PG17 only.
// Tests the exact hosted Topic resume+submit RPC snapshots, not a live client.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
assert(process.env.CI==='true' &&
  process.env.PRACTICE_SEASON2_ISOLATED==='true' &&
  process.env.PRACTICE_TOPIC_CUTOVER_ISOLATED==='true' &&
  process.env.PGHOST==='127.0.0.1' &&
  process.env.PRACTICE_TOPIC_DB==='practice_topic_cutover',
  'REFUSED: disposable CI Topic PG17 required');
const secret=process.env.PRACTICE_SEASON2_JWT_SECRET;
assert(secret&&secret.length>=48,'ephemeral secret missing');
const base='http://127.0.0.1:3001/rpc/';
const A='11111111-1111-4111-8111-111111111111';
const B='22222222-2222-4222-8222-222222222222';
const b64=v=>Buffer.from(JSON.stringify(v)).toString('base64url');
const jwt=(uid,expires=600)=>{
 const h=b64({alg:'HS256',typ:'JWT'});
 const now=Math.floor(Date.now()/1000);
 const raw=h+'.'+b64({role:'authenticated',sub:uid,aud:'authenticated',iat:now,exp:now+expires});
 return raw+'.'+crypto.createHmac('sha256',secret).update(raw).digest('base64url');
};
async function post(fn,body,token){
 const r=await fetch(base+fn,{
   method:'POST',headers:{'Content-Type':'application/json',
     ...(token?{Authorization:'Bearer '+token}:{})},
   body:JSON.stringify(body)
 });
 let data=null;try{data=await r.json()}catch{}
 return {ok:r.ok,status:r.status,data};
}
const resume=(id,t)=>post('get_practice_drill_resume_safe_v4',{p_session_id:id},t);
const submit=(id,q,answer,t)=>post('submit_practice_drill_answer_safe_v5',
 {p_session_id:id,p_question_id:q,p_user_answer:answer,p_picked_index:null,p_time_spent:9},t);
(async()=>{
 const tokenA=jwt(A), tokenB=jwt(B);
 const anon=await resume(104,null);
 assert(!anon.ok,'anonymous Topic restore accepted');
 const expired=await resume(104,jwt(A,-3600));
 assert(!expired.ok,'expired Topic bearer accepted');
 const owner=await resume(104,tokenA);
 assert(owner.ok,'owner cannot restore S1 after subject S2: '+owner.status);
 assert.equal(owner.data?.length,1,'owner lost S1 saved question');
 assert.equal(owner.data?.[0]?.was_answered,false,'unfinished Topic incorrectly answered');
 assert.equal(owner.data?.[0]?.correct_answer,null,'unanswered Topic solution leaked');
 const notOwner=await resume(104,tokenB);
 assert(notOwner.ok&&Array.isArray(notOwner.data)&&notOwner.data.length===0,
   'cross-owner Topic question restored');
 const wrong=await submit(104,15,'RIGHT',tokenB);
 assert(!wrong.ok,'cross-owner Topic submit accepted');
 const result=await submit(104,15,'RIGHT',tokenA);
 assert(result.ok,'owner Topic submit denied '+result.status);
 assert.equal(result.data?.complete,true,'S1 Topic did not finalize across cutover');
 assert.equal(result.data?.score_so_far,1,'S1 Topic evaluated result missing');
 const repeat=await submit(104,15,'RIGHT',tokenA);
 assert(repeat.ok&&repeat.data?.idempotent===true,'duplicate finalization changed answers');
 const completed=await resume(104,tokenA);
 assert(completed.ok&&completed.data?.[0]?.was_answered===true,
   'finished S1 Topic inaccessible in history');
 assert.equal(completed.data?.[0]?.saved_is_correct,true,
   'S1 saved objective result was lost');
 console.log('PRACTICE_S1_TOPIC_SIGNED_HTTP_PASS: anonymous/expired/other-owner blocked, S1 restored and finalized after S2, idempotent');
})().catch(e=>{console.error('PRACTICE_S1_TOPIC_SIGNED_HTTP_FAILED:',e.message);process.exit(1)});
