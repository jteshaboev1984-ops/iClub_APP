#!/usr/bin/env node
'use strict';
// Issue #574. Signed HMAC JWT -> real localhost PostgREST -> disposable PG17.
// All question and user IDs in this file are synthetic. No production calls.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');

assert(
  process.env.CI === 'true' &&
  process.env.PRACTICE_V4_ISOLATED === 'true' &&
  process.env.PGHOST === '127.0.0.1' &&
  process.env.PGDATABASE === 'postgres' &&
  process.env.PGUSER === 'postgres' &&
  process.env.PGPORT === '5432',
  'REFUSED: requires disposable CI PostgreSQL17'
);
const secret = process.env.PRACTICE_V4_JWT_SECRET;
assert(secret && secret.length >= 48, 'Refused: no ephemeral JWT secret');
const BASE = 'http://127.0.0.1:3000';
const A = '11111111-1111-4111-8111-111111111191';
const B = '22222222-2222-4222-8222-222222222292';
const enc = obj => Buffer.from(JSON.stringify(obj)).toString('base64url');
function jwt(uid, expireSeconds = 1200) {
  const now = Math.floor(Date.now() / 1000);
  const head = enc({ alg:'HS256', typ:'JWT' });
  const data = [head,enc({
    role:'authenticated',sub:uid,aud:'authenticated',
    iat:now,exp:now+expireSeconds
  })].join('.');
  return data+'.'+crypto.createHmac('sha256',secret).update(data).digest('base64url');
}
async function req(endpoint, payload, token) {
  const response = await fetch(BASE+endpoint,{
    method:'POST',
    headers:{
      'Content-Type':'application/json',
      'Accept':'application/json',
      ...(token === null ? {} : {Authorization:'Bearer '+token})
    },
    body:JSON.stringify(payload)
  });
  const raw = await response.text();
  let body;
  try { body=JSON.parse(raw); } catch { body=raw.slice(0,250); }
  return {ok:response.ok,status:response.status,body};
}
const submit = (sessionId,questionId,answer,token) => req(
  '/rpc/submit_practice_session_answer_safe_v5',
  {p_session_id:sessionId,p_question_id:questionId,p_user_answer:answer,
   p_picked_index:null,p_time_spent:3},token
);
const finalize = (sessionId,token) => req('/rpc/finalize_practice_session_safe_v5',
  {p_session_id:sessionId,p_total_time:4},token);
function pass(result,label,correct,idempotent=false) {
  assert(result.ok, label+' unexpected HTTP '+result.status+' '+JSON.stringify(result.body).slice(0,180));
  assert.equal(result.body.is_correct,correct,label+' wrong correctness');
  assert.equal(result.body.idempotent,idempotent,label+' idempotence failed');
}
function deny(result,label) {
  assert(!result.ok && result.status>=400,label+' unexpectedly succeeded');
}
function sql(query) {
  return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',query],
    {encoding:'utf8',env:process.env}).trim();
}
(async()=>{
  const baseline=Number(sql('select count(*) from public.practice_attempts'));
  const a=jwt(A),b=jwt(B);
  const wrong={p_session_id:995101,p_question_id:995001,p_user_answer:'4',p_picked_index:null,p_time_spent:3};
  deny(await req('/rpc/submit_practice_session_answer_safe_v5',wrong,null),
    'anonymous practice submit');
  deny(await submit(995101,995001,'4',jwt(A,-30)),'expired JWT');
  deny(await submit(995101,995001,'4',b),'cross-user session');
  deny(await submit(995101,995002,'-7',a),'question not in session');
  pass(await submit(995101,995001,'4',a),'wrong positive for negative key',false);
  pass(await submit(995101,995001,'-4',a),'first answer immutable',false,true);
  pass(await submit(995102,995001,'−4',a),'Unicode minus',true);
  pass(await submit(995103,995002,'7',a),'other subject wrong positive',false);
  const aResult=await finalize(995101,a);
  assert(aResult.ok,aResult.status+' finalize A denied');
  assert.equal(aResult.body.score,0,'incorrect answer should score zero');
  const repeat=await finalize(995101,a);
  assert(repeat.ok && repeat.body.idempotent===true,'finalize retry must be idempotent');
  const bResult=await finalize(995102,a);
  assert(bResult.ok && bResult.body.score===1,'correct answer should score one');
  const other=await finalize(995103,a);
  assert(other.ok && other.body.score===0,'non-math incorrect answer should score zero');
  const after=Number(sql('select count(*) from public.practice_attempts'));
  assert.equal(after,baseline+3,'expected exactly three new synthetic attempts');
  assert.equal(sql(
    'select count(*) from public.practice_answers where question_id in (995001,995002)'
  ),'3','exactly one answer per owned synthetic session');
  deny(await req('/rpc/submit_practice_session_answer_safe_v5',wrong,null),
    'anonymous retry');
  console.log('PRACTICE_V4_SIGNED_HTTP_POSTGREST_PG17_PASS: '+
    'anonymous+expired+cross-owner denied; wrong-positive rejected; '+
    'Unicode and independent non-Math paths; retry/finalization and history isolation');
})().catch(error=>{
  console.error('PRACTICE_V4_SIGNED_HTTP_FAILED:',String(error?.message||error));
  process.exit(1);
});
