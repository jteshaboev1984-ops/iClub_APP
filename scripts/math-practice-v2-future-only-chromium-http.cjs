#!/usr/bin/env node
'use strict';
// Real Chromium browser -> signed JWT fetch -> local PostgREST -> actual v5.
// Not full iClub UI acceptance; verifies browser transport, ownership,
// session-bound questions and future-only version switch on disposable PG17.
const assert=require('node:assert/strict'),crypto=require('node:crypto');
const {chromium}=require('playwright');
assert(process.env.CI==='true' &&
  process.env.PRACTICE_FUTURE_ONLY_ISOLATED==='true' &&
  process.env.PGHOST==='127.0.0.1' &&
  process.env.PGDATABASE==='practice_http',
  'REFUSED: browser test requires isolated CI PG17');
const secret=process.env.PRACTICE_FUTURE_ONLY_JWT_SECRET;
assert(secret?.length>=48,'ephemeral local JWT secret missing');
const phase=process.argv[2];
assert(['published','rollback'].includes(phase),'one of published/rollback expected');
const a='11111111-1111-4111-8111-111111111191';
const b='22222222-2222-4222-8222-222222222292';
const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function jwt(uid){
 const now=Math.floor(Date.now()/1000);
 const s=enc({alg:'HS256',typ:'JWT'})+'.'+
         enc({role:'authenticated',sub:uid,aud:'authenticated',iat:now,exp:now+900});
 return s+'.'+crypto.createHmac('sha256',secret).update(s).digest('base64url');
}
async function invoke(page,route,body,token){
 return page.evaluate(async ({route,body,token})=>{
  const r=await fetch('/rpc/'+route,{
   method:'POST',headers:{
    'Content-Type':'application/json',
    ...(token?{Authorization:'Bearer '+token}:{})
   },body:JSON.stringify(body)
  });
  const raw=await r.text();let val;
  try{val=JSON.parse(raw)}catch{val=null}
  return {ok:r.ok,status:r.status,body:val};
 },{route,body,token});
}
const ask=(page,sid,q,t)=>invoke(page,'submit_practice_session_answer_safe_v5',{
 p_session_id:sid,p_question_id:q,p_user_answer:'A',
 p_picked_index:0,p_time_spent:2
},t);
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 try{
  const context=await browser.newContext({viewport:{width:375,height:812}});
  const page=await context.newPage();
  // Real PostgREST root returns OpenAPI JSON and establishes SAME origin.
  const root=await page.goto('http://127.0.0.1:3000/',{waitUntil:'domcontentloaded'});
  assert(root,'local PostgREST root unavailable');
  const me=jwt(a),other=jwt(b);
  const name=phase==='published'?'chromium-released-001':'chromium-rollback-001';
  const started=await invoke(page,'start_practice_session_auto_safe_v5',{
    p_pool_id:501,p_client_session_id:name
  },me);
  assert(started.ok,'Chromium could not start v5 session '+started.status);
  const sid=Number(started.body.session_id);
  assert(sid>0,'session ID missing');
  const expected=phase==='published'?3001:2001,retired=phase==='published'?2001:3001;
  const cross=await ask(page,sid,expected,other);
  assert(!cross.ok,'Chromium cross-user write accepted');
  const wrong=await ask(page,sid,retired,me);
  assert(!wrong.ok,'Chromium old pool membership leak into new selection');
  const answer=await ask(page,sid,expected,me);
  assert(answer.ok&&answer.body.is_correct===true,'Chromium keyed v5 scoring failed');
  assert.equal(answer.body.explanation,
    phase==='published'?'New synthetic explanation':'Explanation 1',
    'Chromium wrong question version rendered by scoring response');
  const again=await ask(page,sid,expected,me);
  assert(again.ok&&again.body.idempotent===true,'Chromium retried answer mutated');
  const anon=await ask(page,sid,expected,null);
  assert(!anon.ok,'Chromium anonymous answer accepted');
  const privileged=await invoke(page,'math_practice_future_only_rollback_v1',{
    p_release:'math_p1_practice_v2_fix_20261120',p_pairs:[]
  },me);
  assert(!privileged.ok,'private rollback exposed through browser API');
  await context.close();
  console.log('PRACTICE_FUTURE_ONLY_CHROMIUM_PG17_PASS '+phase+
    ' signed browser selection, correct version, owner/anon firewall, retry');
 }finally{await browser.close();}
})().catch(e=>{
 console.error('PRACTICE_FUTURE_ONLY_CHROMIUM_FAILED',phase,String(e.message||e));
 process.exit(1);
});
