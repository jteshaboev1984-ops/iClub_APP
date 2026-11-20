#!/usr/bin/env node
'use strict';
// #574 / #610. Real signed HS256 JWT -> localhost PostgREST -> actual
// production-source Tour submission RPCs on DISPOSABLE PostgreSQL 17.
// All IDs/answers here are invented fixtures; no live URLs or learner data.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
assert(process.env.CI==='true' &&
  process.env.MATH_S2_TOUR_DISPOSABLE==='true' &&
  process.env.PGHOST==='127.0.0.1' &&
  process.env.PGPORT==='5432' &&
  process.env.PGDATABASE==='postgres' &&
  process.env.PGUSER==='postgres',
 'REFUSED: test requires disposable postgres:17 in CI');
const secret=process.env.MATH_S2_TOUR_JWT_SECRET;
assert(secret&&secret.length>=48,'requires ephemeral JWT secret');
const base='http://127.0.0.1:3000';
const aUser='11111111-1111-4111-8111-111111111111';
const bUser='22222222-2222-4222-8222-222222222222';
const enc=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
function jwt(uid,ttl=600){
 const now=Math.floor(Date.now()/1000);
 const body=enc({alg:'HS256',typ:'JWT'})+'.'+
  enc({role:'authenticated',sub:uid,aud:'authenticated',
       iat:now,exp:now+ttl});
 return body+'.'+crypto.createHmac('sha256',secret).update(body).digest('base64url');
}
function psql(sql){
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',sql],
  {encoding:'utf8',env:process.env}).trim();
}
async function post(url,payload,token) {
 const response=await fetch(base+url,{
  method:'POST',
  headers:{'Content-Type':'application/json',
   'Accept':'application/json',
   ...(token===null?{}:{Authorization:'Bearer '+token})},
  body:JSON.stringify(payload)
 });
 const text=await response.text();
 let body;
 try{body=JSON.parse(text)}catch{body=text.slice(0,250)}
 return {status:response.status,ok:response.ok,body};
}
function answer(attempt,question,userAnswer,pickedIndex=null){
 return {p_attempt_id:attempt,p_question_id:question,p_user_answer:userAnswer,
   p_picked_index:pickedIndex,p_time_spent:4,p_answered:true,p_finish_reason:null};
}
function expectOk(result,label,repeat=false){
 assert(result.ok,label+' HTTP '+result.status+' '+JSON.stringify(result.body).slice(0,140));
 assert.equal(result.body.ok,true,label+' response not recorded');
 assert.equal(result.body.idempotent,repeat,label+' retry changed prior answer');
}
function denied(result,label){
 assert(!result.ok && result.status>=400,label+' unexpectedly succeeded');
}
(async()=>{
 const A=jwt(aUser),B=jwt(bUser);
 const endpoint='/rpc/submit_tour_answer_safe_v4';
 denied(await post(endpoint,answer(996101,995001,'2/4'),null),
  'no-token Tour submit');
 denied(await post(endpoint,answer(996101,995001,'2/4'),jwt(aUser,-3600)),
  'expired token Tour submit');
 denied(await post(endpoint,answer(996104,995001,'2/4'),A),
  'cross-user Tour submit');
 denied(await post(endpoint,answer(996101,995021,'1/2'),A),
  'question outside issued Tour session');

 // The low-level answer oracle must remain private even to authenticated users.
 denied(await post('/rpc/iclub_eval_tour_question_safe_v4',
  {p_question_id:995001,p_user_answer:'2/4',p_picked_index:null,p_answered:true},A),
  'direct authenticated evaluation oracle');
 denied(await post('/rpc/iclub_eval_tour_question_safe_v4',
  {p_question_id:995001,p_user_answer:'2/4',p_picked_index:null,p_answered:true},null),
  'direct anonymous evaluation oracle');

 const main=[
  [995001,'2/4',null],
  [995002,'9/2',null],
  [995003,'−8',null],
  [995004,'28/6',null],
  [995005,null,2],
  [995006,'4.5',null]
 ];
 for(const [id,val,picked] of main){
   expectOk(await post(endpoint,answer(996101,id,val,picked),A),
    'owned Math S2 '+id);
 }
 expectOk(await post(endpoint,answer(996101,995001,'0',null),A),
  'idempotent answer does not overwrite a correct answer',true);
 expectOk(await post(endpoint,answer(996102,995011,'2/4'),A),
  'Math Season1 old literal-equality path');
 expectOk(await post(endpoint,answer(996103,995021,'2/4'),A),
  'Chemistry old input path');
 expectOk(await post(endpoint,answer(996104,995001,'2/3'),B),
  'Math S2 truly wrong fraction');

 const summary=psql("SELECT count(*)||':'||count(*) filter (where is_correct)::text FROM public.tour_session_answers_v4");
 assert.equal(summary,'9:6','wrong persisted results / side effects '+summary);
 const preserved=psql("SELECT is_correct::text||':'||user_answer FROM public.tour_session_answers_v4 WHERE attempt_id=996101 AND question_id=995001");
 assert.equal(preserved,'true:2/4','immutable retry was overwritten');
 const exclusions=psql("SELECT array_agg(attempt_id ORDER BY attempt_id)::text FROM public.tour_session_answers_v4 WHERE NOT is_correct");
 assert.equal(exclusions,'{996102,996103,996104}',
  'S1/Chemistry/wrong-fraction must not change scoring');

 // Independent Chromium context, performing an actual signed HTTP fetch.
 // NOT a claim of whole production iClub Tours UI acceptance.
 const {chromium}=require('playwright');
 const browser=await chromium.launch({headless:true});
 try{
  const page=await browser.newPage({viewport:{width:375,height:812}});
  await page.goto(base+'/',{waitUntil:'domcontentloaded'});
  const q=await page.evaluate(async({token,payload})=>{
    const resp=await fetch('/rpc/submit_tour_answer_safe_v4',{
     method:'POST',headers:{'Content-Type':'application/json',
       'Accept':'application/json','Authorization':'Bearer '+token},
     body:JSON.stringify(payload)
    });
    return {status:resp.status,body:await resp.json()};
  },{token:A,payload:answer(996105,995001,'0.5')});
  assert.equal(q.status,200,'Chromium signed HTTP Tour submit denied');
  assert.equal(q.body.ok,true,'Chromium Tour response missing');
  assert.equal(psql("SELECT is_correct::text FROM public.tour_session_answers_v4 WHERE attempt_id=996105 AND question_id=995001"),'true',
    'Chromium correct equivalent decimal did not score');
  await page.close();
 } finally{await browser.close()}
 assert.equal(psql("SELECT count(*) FROM public.tour_session_answers_v4"),'10',
  'browser scenario must add exactly one synthetic Tour answer');
 console.log('MATH_S2_TOUR_PG17_SIGNED_POSTGREST_CHROMIUM_PASS: real RPCs; fractions, decimals, unicode, wrong, S1/Chemistry isolation, auth, retry, Chromium');
})().catch(e=>{
 console.error('MATH_S2_TOUR_PG17_SIGNED_POSTGREST_CHROMIUM_FAILED:',e.stack||e.message);
 process.exit(1);
});
