#!/usr/bin/env node
"use strict";
// Real JWT/PostgREST/PG17 Extra Hard route; tests only synthetic "1+1" text.
// Never runs against production or inserts actual protected problems/answers.
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const {execFileSync} = require("node:child_process");
const HOST="http://127.0.0.1:3000";
const A="11111111-1111-4111-8111-111111111191";
const B="22222222-2222-4222-8222-222222222292";
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.P1P5_E2E_ISOLATED==="true" &&
 process.env.PGHOST==="127.0.0.1" && process.env.PGPORT==="5432" &&
 process.env.PGDATABASE==="postgres" && process.env.CI==="true",
 "REFUSED: synthetic Extra Hard proof requires isolated GitHub PG17");
assert(SECRET && SECRET.length>=32,"REFUSED: local signing key missing");
const encode=x=>Buffer.from(JSON.stringify(x)).toString("base64url");
function jwt(uid){
 const part=encode({alg:"HS256",typ:"JWT"})+"."+encode({
  role:"authenticated",aud:"authenticated",sub:uid,
  iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+900
 });
 return part+"."+crypto.createHmac("sha256",SECRET).update(part).digest("base64url");
}
async function rpc(name,args={},token){
 assert(/^[a-z_0-9]+$/.test(name),"invalid RPC name");
 const response=await fetch(HOST+"/rpc/"+name,{
  method:"POST",
  headers:{"Content-Type":"application/json","Accept":"application/json",
   ...(token?{Authorization:"Bearer "+token}:{})},
  body:JSON.stringify(args)
 });
 const raw=await response.text();
 let data;try{data=JSON.parse(raw);}catch{data=null;}
 return {status:response.status,ok:response.ok,data};
}
const localEnv={...process.env,PGOPTIONS:"-c iclub.e2e_isolated=true"};
function fixture(filename){
 assert(/^p1p5_extra_hard_disposable_real_http_(seed|cleanup)\.sql$/.test(filename));
 execFileSync("psql",["-X","-v","ON_ERROR_STOP=1",
  "-f","supabase/tests/"+filename],{env:localEnv,encoding:"utf8"});
}
function sqlRead(statement){
 assert(/^SELECT\b/.test(statement),"SQL test reads only");
 return execFileSync("psql",["-X","-At","-v","ON_ERROR_STOP=1","-c",statement],
  {env:localEnv,encoding:"utf8"}).trim();
}
(async()=>{
 const tokenA=jwt(A),tokenB=jwt(B);
 const noAnon=await rpc("get_my_exam_prep_extra_hard_catalog_safe_v1",
  {p_component_code:"P1",p_language:"en"});
 assert([401,403].includes(noAnon.status),"anon received challenge catalog");
 const off=await rpc("get_my_exam_prep_extra_hard_catalog_safe_v1",
  {p_component_code:"P1",p_language:"en"},tokenA);
 assert(off.ok&&off.data?.available===false&&off.data.items?.length===0,
  "Extra Hard default OFF did not fail closed");
 const denied=await rpc("start_my_exam_prep_extra_hard_safe_v1",
  {p_task_key:"CI-EXTRA-HARD-TEST-01",p_language:"en"},tokenA);
 assert(!denied.ok,"No approval but synthetic task started");
 assert.equal(sqlRead("SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1"),"0",
  "Protected task bank must be EMPTY in source migration");
 fixture("p1p5_extra_hard_disposable_real_http_seed.sql");
 try {
  const catalog=await rpc("get_my_exam_prep_extra_hard_catalog_safe_v1",
   {p_component_code:"P1",p_language:"en"},tokenA);
  assert(catalog.ok&&catalog.data?.available===true&&catalog.data.items?.length===1,
   "Approved private synthetic catalog unavailable");
  const p5=await rpc("get_my_exam_prep_extra_hard_catalog_safe_v1",
   {p_component_code:"P5",p_language:"ru"},tokenA);
  assert(p5.ok&&p5.data?.available===false&&p5.data.items?.length===0,
   "P1 challenge leaked into P5");
  const task=await rpc("start_my_exam_prep_extra_hard_safe_v1",
   {p_task_key:"CI-EXTRA-HARD-TEST-01",p_language:"en"},tokenA);
  assert(task.ok&&task.data?.attempt_id&&task.data?.solution===null&&
   task.data.noncredit===true&&task.data.status==="started",
   "Worked solution leaked before submission or owner start failed");
  const id=task.data.attempt_id;
  const replayStart=await rpc("start_my_exam_prep_extra_hard_safe_v1",
   {p_task_key:"CI-EXTRA-HARD-TEST-01",p_language:"en"},tokenA);
  assert(replayStart.ok&&replayStart.data?.attempt_id===id,
   "Start replay duplicated a task");
  const foreign=await rpc("get_my_exam_prep_extra_hard_attempt_safe_v1",
   {p_attempt_id:id,p_language:"en"},tokenB);
  assert(!foreign.ok,"Second learner accessed first learner's attempt");
  const foreignWrite=await rpc("submit_my_exam_prep_extra_hard_safe_v1",
   {p_attempt_id:id,p_response_text:"2",p_idempotency_key:"CI-FOREIGN-DENIED-001",p_language:"en"},tokenB);
  assert(!foreignWrite.ok,"Second learner wrote first learner's response");
  const key="CI-EXTRA-HARD-DURABLE-ACK-001";
  const saved=await rpc("submit_my_exam_prep_extra_hard_safe_v1",
   {p_attempt_id:id,p_response_text:"1 + 1 = 2",p_idempotency_key:key,p_language:"en"},tokenA);
  assert(saved.ok&&saved.data?.saved===true&&saved.data.replayed===false&&
   saved.data.solution==="1 + 1 = 2."&&saved.data.noncredit===true&&
   saved.data.written_correctness==="unknown",
   "Owner submission failed to durably unlock only an ungraded example");
  const lostAck=await rpc("submit_my_exam_prep_extra_hard_safe_v1",
   {p_attempt_id:id,p_response_text:"1 + 1 = 2",p_idempotency_key:key,p_language:"en"},tokenA);
  assert(lostAck.ok&&lostAck.data.replayed===true,"Lost ACK produced duplicate");
  const reopened=await rpc("get_my_exam_prep_extra_hard_attempt_safe_v1",
   {p_attempt_id:id,p_language:"ru"},tokenA);
  assert(reopened.ok&&reopened.data.status==="submitted"&&
   reopened.data.solution==="1 + 1 = 2."&&reopened.data.noncredit===true,
   "Resume lost response or solution");
  const secondWrite=await rpc("submit_my_exam_prep_extra_hard_safe_v1",
   {p_attempt_id:id,p_response_text:"999",p_idempotency_key:"CI-CHANGED-KEY-002",p_language:"en"},tokenA);
  assert(!secondWrite.ok,"Different key overwrote saved response");
  console.log("PASS Extra Hard actual JWT/PostgREST: owner, hidden key, P1/P5 isolation, durable retry, no grade");
 }finally{
  fixture("p1p5_extra_hard_disposable_real_http_cleanup.sql");
 }
 assert.equal(sqlRead("SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1"),"0",
  "Synthetic challenge content remained in disposable DB");
 assert.equal(sqlRead("SELECT count(*) FROM private.exam_prep_extra_hard_attempts_v1"),"0",
  "Synthetic attempts remained in disposable DB");
 assert.equal(sqlRead("SELECT enabled::int FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5'"),"0",
  "Extra Hard release left enabled after testing");
})().catch(e=>{console.error("EXTRA HARD REAL HTTP FAILED:",e.message);process.exitCode=1;});
