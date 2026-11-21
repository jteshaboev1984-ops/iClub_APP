#!/usr/bin/env node
"use strict";
// Independent signed-HS256 JWT -> real local PostgREST -> disposable PG17.
// NOT GoTrue-issued tokens, not Telegram, NOT a hosted Supabase call.
const assert=require("node:assert/strict");
const crypto=require("node:crypto");
const {execFileSync}=require("node:child_process");
const HOST="http://127.0.0.1:3000";
assert(process.env.CI==="true"&&
  process.env.ICLUB_TUTOR_HISTORY_SIGNED_ISOLATED==="true"&&
  process.env.PGHOST==="127.0.0.1"&&
  process.env.PGDATABASE==="postgres"&&
  process.env.PGUSER==="postgres",
  "Refused: test must run against disposable loopback PG17 only");
const SECRET=process.env.ICLUB_TUTOR_HISTORY_SIGNED_JWT_SECRET;
assert(typeof SECRET==="string"&&SECRET.length>=48,
  "Ephemeral signed JWT secret missing");
const A="00000000-0000-4000-8000-000000000011";
const B="00000000-0000-4000-8000-000000000022";
const ID="cccccccc-cccc-4ccc-8ccc-cccccccccccc";
const fn="iclub_ai_tutor_history_service_v1";
const b64=x=>Buffer.from(JSON.stringify(x)).toString("base64url");
function jwt(id,role="authenticated",custom={}) {
 const now=Math.floor(Date.now()/1000);
 const pair=b64({alg:"HS256",typ:"JWT"})+"."+
   b64({aud:"authenticated",sub:id,role,iat:now,exp:now+600,...custom});
 return pair+"."+crypto.createHmac("sha256",SECRET).update(pair).digest("base64url");
}
async function post(action,args={},token=jwt(A)) {
 const response=await fetch(HOST+"/rpc/"+fn,{
   method:"POST",headers:{"Content-Type":"application/json",
     Accept:"application/json",...(token?{Authorization:"Bearer "+token}:{})},
   body:JSON.stringify({p_action:action,...args})
 });
 let payload=null;
 try{payload=await response.json()}catch{}
 return{http:response.status,ok:response.ok,data:payload};
}
function sql(q) {
 return execFileSync("psql",["-X","-At","-v","ON_ERROR_STOP=1","-c",q],
   {encoding:"utf8",env:process.env}).trim();
}
function success(x,why) {
 assert(x.ok,why+" HTTP "+x.http+" "+JSON.stringify(x.data)?.slice(0,230));
 assert.equal(x.data?.ok,true,why+" app-level refusal");
 return x.data;
}
function refused(x,reason,why) {
 assert(x.http>=400 || (x.data?.ok===false),
   why+" unexpectedly accepted");
 if(reason)assert.equal(x.data?.reason,reason,why+" incorrect refusal");
}
async function run(){
 assert.equal(sql("SELECT enabled::text FROM private.iclub_ai_tutor_history_v1_control WHERE singleton=1"),"false");
 refused(await post("status"),"not_released","OFF status");
 sql("UPDATE private.iclub_ai_tutor_history_v1_control SET enabled=true WHERE singleton=1");
 let a=success(await post("status"),"signed learner A status");
 assert.equal(a.consented,false);
 refused(await post("read",{p_thread_key:"mathematics"}),"history_consent_required","no consent read");
 success(await post("opt_in"),"signed A opt-in");
 const params={p_thread_key:"mathematics",p_request_id:ID,p_locale:"uz"};
 a=success(await post("append",{...params,p_speaker:"user",p_text:"Practice nima?"}),"signed A store question");
 assert.equal(a.inserted,true);
 a=success(await post("append",{...params,p_speaker:"user",p_text:"TAMPERED"}),"same UUID replay");
 assert.equal(a.inserted,false,"duplicate must not overwrite");
 a=success(await post("append",{...params,p_speaker:"assistant",p_text:"Practice o‘quv mashqi."}),"signed A answer");
 assert.equal(a.inserted,true);
 a=success(await post("read",{p_thread_key:"mathematics"}),"signed A restore");
 assert.equal(a.messages.length,2);
 assert.equal(a.messages[0].text,"Practice nima?");
 assert.equal(a.messages[1].text,"Practice o‘quv mashqi.");
 assert.equal(a.provider_called,false);
 // B must not see A's transcript. Caller-supplied p_user_id is never accepted.
 success(await post("opt_in",{},jwt(B)),"signed B opt-in");
 const b=success(await post("read",{p_thread_key:"mathematics"},jwt(B)),"signed B read");
 assert.equal(b.messages.length,0);
 let spoof=await post("read",{p_thread_key:"mathematics",p_user_id:A},jwt(B));
 assert(spoof.http>=400,"Cross-owner user ID parameter unexpectedly accepted");
 // Auth-less, wrong signature, expired, and elevated service-role tokens denied.
 refused(await post("read",{p_thread_key:"mathematics"},null),null,"anon request");
 const wrong=jwt(A).slice(0,-1)+"A";
 refused(await post("read",{p_thread_key:"mathematics"},wrong),null,"forged signature");
 refused(await post("read",{p_thread_key:"mathematics"},
   jwt(A,"authenticated",{iat:Math.floor(Date.now()/1000)-7200,
     exp:Math.floor(Date.now()/1000)-3600})),null,"expired JWT");
 refused(await post("read",{p_thread_key:"mathematics"},jwt(A,"service_role")),null,"service role");
 // Direct table read is inaccessible via the public PostgREST schema.
 const table=await fetch(HOST+"/iclub_ai_tutor_history_v1_messages",{
   headers:{Authorization:"Bearer "+jwt(A),Accept:"application/json"}});
 assert(table.status>=400,"direct private transcript exposed");
 // Both Tour/Exam and unfinished Practice independently deny a signed learner.
 sql("INSERT INTO private.qa_protected(user_id) VALUES ('"+A+"')");
 refused(await post("read",{p_thread_key:"mathematics"}),"active_assessment","protected Tour");
 sql("DELETE FROM private.qa_protected WHERE user_id='"+A+"'");
 sql("INSERT INTO public.practice_sessions_v4(user_id,status) VALUES ('"+A+"','in_progress')");
 refused(await post("read",{p_thread_key:"mathematics"}),"active_assessment","active Practice");
 sql("DELETE FROM public.practice_sessions_v4 WHERE user_id='"+A+"'");
 // Owner B opt-out can delete only B, not A.
 success(await post("opt_out",{},jwt(B)),"signed B opt-out");
 assert.equal(success(await post("read",{p_thread_key:"mathematics"}),
   "signed A remains after B opt-out").messages.length,2);
 // Disabling new history cannot prevent the learner deleting saved text.
 sql("UPDATE private.iclub_ai_tutor_history_v1_control SET enabled=false WHERE singleton=1");
 success(await post("opt_out"),"signed A opt-out while OFF");
 assert.equal(sql("SELECT count(*) FROM private.iclub_ai_tutor_history_v1_messages"),"0");
 assert.equal(sql("SELECT score FROM private.qa_core_grade WHERE user_id='"+A+"'"),"17");
 console.log("PASS signed JWT -> real loopback PostgREST -> PostgreSQL17: owner A/B, auth/anon/forged/expired/service denied, consent, OFF, protected Tour/Practice, idempotency, purge, unchanged Core");
 console.log("BOUNDARY: synthetic locally signed JWT, NOT real GoTrue issuance or hosted Telegram WebApp; no AI provider invocation.");
}
run().catch(e=>{console.error(e);process.exitCode=1});
