#!/usr/bin/env node
'use strict';
// D03: signed HTTP negative check against EPHEMERAL GitHub Actions PostgreSQL17.
// NEVER connect to Supabase production or use a real user's bearer/JWT.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const API='http://127.0.0.1:3000';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
       process.env.PGHOST==='127.0.0.1'&&process.env.PGPORT==='5432'&&
       process.env.PGDATABASE==='postgres','D03 REFUSED: only ephemeral PG17 in CI');
assert(typeof SECRET==='string'&&SECRET.length>=32,'D03 REFUSED: missing ephemeral JWT secret');
const OWNER='11111111-1111-4111-8111-111111111191';
const OTHER='22222222-2222-4222-8222-222222222292';
const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const jwt=id=>{
 const t=enc({alg:'HS256',typ:'JWT'})+'.'+enc({role:'authenticated',aud:'authenticated',
    sub:id,iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+1800});
 return t+'.'+crypto.createHmac('sha256',SECRET).update(t).digest('base64url');
};
function db(sql){
 assert(/^\s*SELECT\s/i.test(sql),'D03 REFUSED: SELECT-only database evidence');
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',sql],
   {encoding:'utf8'}).trim();
}
function counts(){
 return db("SELECT (SELECT count(*) FROM public.users)::text||':'||(SELECT count(*) FROM private.exam_prep_timed_attempt_results)::text");
}
async function rpc(method,payload,token){
 const response=await fetch(API+'/rpc/'+method,{method:'POST',headers:{
   'Content-Type':'application/json','Accept':'application/json',
   Authorization:'Bearer '+token
 },body:JSON.stringify(payload)});
 const body=await response.text();
 let parsed=null;try{parsed=JSON.parse(body)}catch{}
 return {status:response.status,ok:response.ok,error:parsed?.code||null};
}
(async()=>{
 assert.equal(db("SELECT has_function_privilege('authenticated','public.submit_exam_prep_timed_written_self_mark_safe_v1(uuid,integer,integer,text,text)','EXECUTE')"),'f',
  'D03 direct learner self-grading function still executable');
 assert.equal(db("SELECT position('exam_prep_written_self_marks_disabled' IN pg_get_functiondef('public.submit_exam_prep_timed_written_self_mark_safe_v1(uuid,integer,integer,text,text)'::regprocedure))>0"),'t',
  'D03 old-client function did not become fail-closed');
 assert.equal(db("SELECT position('objective_only' IN pg_get_functiondef('public.get_exam_prep_timed_result_safe_v1(uuid)'::regprocedure))>0"),'t',
  'D03 Paper result still includes unverified self-graded marks');
 const before=counts(),owner=jwt(OWNER),other=jwt(OTHER);
 for(const [description,token] of [['own-signed',owner],['foreign-signed',other],
    ['anonymous','not-a-real-jwt']]){
   const result=await rpc('submit_exam_prep_timed_written_self_mark_safe_v1',{
      p_session_id:'00000000-0000-4000-8000-000000000000',
      p_item_order:1,p_marks_awarded:100,p_idempotency_key:'D03-OLD-TAB-CALL',
      p_review_note:null
    },token);
   assert(!result.ok&&[400,401,403,404].includes(result.status),
     'D03 '+description+' unexpectedly accepted forged written mark, HTTP '+result.status);
 }
 const capabilities=await rpc('get_exam_prep_capabilities_v1',{},owner);
 assert(capabilities.ok,'valid local signed JWT failed owner-bound PostgREST capability request: '+JSON.stringify(capabilities));
 assert.equal(counts(),before,'D03 direct RPC test mutated synthetic learner records');
 console.log('D03 SIGNED JWT→LOCAL POSTGREST→EPHEMERAL PG17: PASS; 3 old-client denial cases; valid signed capabilities; DB rows unchanged');
})().catch(err=>{console.error(err.message);process.exitCode=1});
